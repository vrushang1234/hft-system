#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

#define MAX_CLIENTS 64
#define READ_BUF_SIZE 8192
#define WRITE_BUF_SIZE 4096

typedef struct {
  int fd;
  int active;
} Client;

typedef struct {
  double price;
  double spread;
} Book;

typedef struct {
  int order_id;
  char side;
  double price;
  int size;
  int queue_ahead;
  int queue_behind;
  char status[10];
} Order;

static const char *SYMBOLS[] = {"AAPL", "MSFT", "AMZN", "TSLA", "NVDA"};
static const int SYMBOL_COUNT = 5;

static const char *WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

static double rand_between(double min, double max) {
  return min + ((double)rand() / (double)RAND_MAX) * (max - min);
}

static long long now_ns(void) {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  return (long long)ts.tv_sec * 1000000000LL + (long long)ts.tv_nsec;
}

static long long now_ms(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (long long)ts.tv_sec * 1000LL + (long long)ts.tv_nsec / 1000000LL;
}

static int append(char *buf, size_t cap, size_t *off, const char *fmt, ...) {
  if (*off >= cap) {
    return -1;
  }
  va_list args;
  va_start(args, fmt);
  int written = vsnprintf(buf + *off, cap - *off, fmt, args);
  va_end(args);
  if (written < 0 || (size_t)written >= cap - *off) {
    return -1;
  }
  *off += (size_t)written;
  return 0;
}

typedef struct {
  unsigned int state[5];
  unsigned int count[2];
  unsigned char buffer[64];
} Sha1Context;

static void sha1_transform(unsigned int state[5],
                           const unsigned char buffer[64]) {
  unsigned int a, b, c, d, e;
  unsigned int w[80];
  for (int i = 0; i < 16; i++) {
    w[i] = (unsigned int)buffer[i * 4] << 24;
    w[i] |= (unsigned int)buffer[i * 4 + 1] << 16;
    w[i] |= (unsigned int)buffer[i * 4 + 2] << 8;
    w[i] |= (unsigned int)buffer[i * 4 + 3];
  }
  for (int i = 16; i < 80; i++) {
    unsigned int value = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
    w[i] = (value << 1) | (value >> 31);
  }

  a = state[0];
  b = state[1];
  c = state[2];
  d = state[3];
  e = state[4];

  for (int i = 0; i < 80; i++) {
    unsigned int f;
    unsigned int k;
    if (i < 20) {
      f = (b & c) | (~b & d);
      k = 0x5A827999;
    } else if (i < 40) {
      f = b ^ c ^ d;
      k = 0x6ED9EBA1;
    } else if (i < 60) {
      f = (b & c) | (b & d) | (c & d);
      k = 0x8F1BBCDC;
    } else {
      f = b ^ c ^ d;
      k = 0xCA62C1D6;
    }
    unsigned int temp = ((a << 5) | (a >> 27)) + f + e + k + w[i];
    e = d;
    d = c;
    c = (b << 30) | (b >> 2);
    b = a;
    a = temp;
  }

  state[0] += a;
  state[1] += b;
  state[2] += c;
  state[3] += d;
  state[4] += e;
}

static void sha1_init(Sha1Context *ctx) {
  ctx->state[0] = 0x67452301;
  ctx->state[1] = 0xEFCDAB89;
  ctx->state[2] = 0x98BADCFE;
  ctx->state[3] = 0x10325476;
  ctx->state[4] = 0xC3D2E1F0;
  ctx->count[0] = 0;
  ctx->count[1] = 0;
}

static void sha1_update(Sha1Context *ctx, const unsigned char *data,
                        size_t len) {
  unsigned int i = 0;
  unsigned int index = (ctx->count[0] >> 3) & 0x3F;
  ctx->count[0] += (unsigned int)len << 3;
  if (ctx->count[0] < ((unsigned int)len << 3)) {
    ctx->count[1]++;
  }
  ctx->count[1] += (unsigned int)len >> 29;
  unsigned int part_len = 64 - index;

  if (len >= part_len) {
    memcpy(&ctx->buffer[index], data, part_len);
    sha1_transform(ctx->state, ctx->buffer);
    for (i = part_len; i + 63 < len; i += 64) {
      sha1_transform(ctx->state, &data[i]);
    }
    index = 0;
  } else {
    i = 0;
  }
  memcpy(&ctx->buffer[index], &data[i], len - i);
}

static void sha1_final(Sha1Context *ctx, unsigned char digest[20]) {
  unsigned char bits[8];
  bits[0] = (unsigned char)((ctx->count[1] >> 24) & 0xFF);
  bits[1] = (unsigned char)((ctx->count[1] >> 16) & 0xFF);
  bits[2] = (unsigned char)((ctx->count[1] >> 8) & 0xFF);
  bits[3] = (unsigned char)(ctx->count[1] & 0xFF);
  bits[4] = (unsigned char)((ctx->count[0] >> 24) & 0xFF);
  bits[5] = (unsigned char)((ctx->count[0] >> 16) & 0xFF);
  bits[6] = (unsigned char)((ctx->count[0] >> 8) & 0xFF);
  bits[7] = (unsigned char)(ctx->count[0] & 0xFF);

  unsigned int index = (ctx->count[0] >> 3) & 0x3F;
  unsigned int pad_len = (index < 56) ? (56 - index) : (120 - index);
  unsigned char padding[64];
  padding[0] = 0x80;
  memset(padding + 1, 0, 63);

  sha1_update(ctx, padding, pad_len);
  sha1_update(ctx, bits, 8);
  for (int i = 0; i < 20; i++) {
    digest[i] =
        (unsigned char)((ctx->state[i / 4] >> ((3 - (i % 4)) * 8)) & 0xFF);
  }
}

static void base64_encode(const unsigned char *input, size_t len, char *out,
                          size_t out_len) {
  static const char table[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  size_t out_index = 0;
  for (size_t i = 0; i < len; i += 3) {
    unsigned int value = 0;
    int remaining = (int)(len - i);
    value |= input[i] << 16;
    if (remaining > 1) {
      value |= input[i + 1] << 8;
    }
    if (remaining > 2) {
      value |= input[i + 2];
    }

    for (int j = 0; j < 4; j++) {
      if (out_index + 1 >= out_len) {
        out[out_index] = '\0';
        return;
      }
      if (j <= remaining) {
        unsigned int idx = (value >> (18 - j * 6)) & 0x3F;
        out[out_index++] = table[idx];
      } else {
        out[out_index++] = '=';
      }
    }
  }
  if (out_index < out_len) {
    out[out_index] = '\0';
  }
}

static int ws_send_text(int fd, const char *msg, size_t len) {
  unsigned char header[10];
  size_t header_len = 0;
  header[0] = 0x81;
  if (len <= 125) {
    header[1] = (unsigned char)len;
    header_len = 2;
  } else if (len <= 65535) {
    header[1] = 126;
    header[2] = (unsigned char)((len >> 8) & 0xFF);
    header[3] = (unsigned char)(len & 0xFF);
    header_len = 4;
  } else {
    header[1] = 127;
    header[2] = header[3] = header[4] = header[5] = 0;
    header[6] = (unsigned char)((len >> 24) & 0xFF);
    header[7] = (unsigned char)((len >> 16) & 0xFF);
    header[8] = (unsigned char)((len >> 8) & 0xFF);
    header[9] = (unsigned char)(len & 0xFF);
    header_len = 10;
  }
  if (send(fd, header, header_len, 0) < 0) {
    return -1;
  }
  if (send(fd, msg, len, 0) < 0) {
    return -1;
  }
  return 0;
}

static int handle_handshake(int fd, const char *expected_path) {
  char buffer[READ_BUF_SIZE];
  ssize_t read_len = recv(fd, buffer, sizeof(buffer) - 1, 0);
  if (read_len <= 0) {
    return -1;
  }
  buffer[read_len] = '\0';

  char *get_line = strstr(buffer, "GET ");
  if (!get_line) {
    return -1;
  }
  char *path_start = get_line + 4;
  char *path_end = strchr(path_start, ' ');
  if (!path_end) {
    return -1;
  }
  char path[256];
  size_t path_len = (size_t)(path_end - path_start);
  if (path_len >= sizeof(path)) {
    return -1;
  }
  memcpy(path, path_start, path_len);
  path[path_len] = '\0';
  if (strcmp(path, expected_path) != 0) {
    return -1;
  }

  char *key_hdr = strstr(buffer, "Sec-WebSocket-Key:");
  if (!key_hdr) {
    return -1;
  }
  key_hdr += strlen("Sec-WebSocket-Key:");
  while (*key_hdr == ' ') {
    key_hdr++;
  }
  char *key_end = strstr(key_hdr, "\r\n");
  if (!key_end) {
    return -1;
  }
  char key[256];
  size_t key_len = (size_t)(key_end - key_hdr);
  if (key_len >= sizeof(key)) {
    return -1;
  }
  memcpy(key, key_hdr, key_len);
  key[key_len] = '\0';

  char accept_src[256];
  snprintf(accept_src, sizeof(accept_src), "%s%s", key, WS_GUID);
  unsigned char digest[20];
  Sha1Context ctx;
  sha1_init(&ctx);
  sha1_update(&ctx, (unsigned char *)accept_src, strlen(accept_src));
  sha1_final(&ctx, digest);

  char accept_key[64];
  base64_encode(digest, 20, accept_key, sizeof(accept_key));

  char response[512];
  snprintf(response, sizeof(response),
           "HTTP/1.1 101 Switching Protocols\r\n"
           "Upgrade: websocket\r\n"
           "Connection: Upgrade\r\n"
           "Sec-WebSocket-Accept: %s\r\n\r\n",
           accept_key);
  if (send(fd, response, strlen(response), 0) < 0) {
    return -1;
  }
  return 0;
}

static void broadcast(Client *clients, const char *payload) {
  for (int i = 0; i < MAX_CLIENTS; i++) {
    if (!clients[i].active) {
      continue;
    }
    if (ws_send_text(clients[i].fd, payload, strlen(payload)) < 0) {
      close(clients[i].fd);
      clients[i].active = 0;
    }
  }
}

static void next_price(Book *book) {
  book->price += rand_between(-0.08, 0.08);
  if (book->price < 1.0) {
    book->price = 1.0;
  }
  book->spread += rand_between(-0.003, 0.003);
  if (book->spread < 0.01) {
    book->spread = 0.01;
  }
}

static void build_order_book(char *out, size_t cap, Book *books,
                             int symbol_index) {
  size_t off = 0;
  long long ts = now_ns();
  Book *book = &books[symbol_index];
  next_price(book);
  double bid = book->price - book->spread / 2.0;
  double ask = book->price + book->spread / 2.0;
  int bid_size = (int)rand_between(100, 2500);
  int ask_size = (int)rand_between(100, 2500);
  append(
      out, cap, &off,
      "{\"type\":\"order_book_snapshot\",\"data\":{\"ts\":%lld,\"symbol\":\"%"
      "s\",\"bids\":[{\"price\":%.2f,\"size\":%d},{\"price\":%.2f,\"size\":%d}]"
      ",\"asks\":[{\"price\":%.2f,\"size\":%d},{\"price\":%.2f,\"size\":%d}]}}",
      ts, SYMBOLS[symbol_index], bid, bid_size, bid - 0.01,
      (int)(bid_size * 0.6), ask, ask_size, ask + 0.01, (int)(ask_size * 0.6));
}

static void build_trade_tape(char *out, size_t cap, Book *books,
                             int symbol_index) {
  size_t off = 0;
  long long ts = now_ns();
  Book *book = &books[symbol_index];
  double price = book->price + rand_between(-0.02, 0.02);
  int size = (int)rand_between(10, 700);
  const char *aggressor = rand_between(0, 1) > 0.5 ? "BUY" : "SELL";
  append(out, cap, &off,
         "{\"type\":\"trade_tape\",\"data\":{\"ts\":%lld,\"price\":%.2f,"
         "\"size\":%d,\"aggressor\":\"%s\"}}",
         ts, price, size, aggressor);
}

static void build_latency_race(char *out, size_t cap) {
  size_t off = 0;
  int my_latency = (int)rand_between(90000, 230000);
  int fastest = (int)rand_between(70000, 200000);
  const char *outcome = my_latency <= fastest + 15000 ? "WON" : "LOST";
  double fill = rand_between(0.25, 0.95);
  append(
      out, cap, &off,
      "{\"type\":\"latency_race\",\"data\":{\"my_latency_ns\":%d,\"fastest_"
      "competitor_ns\":%d,\"race_outcome\":\"%s\",\"fill_probability\":%.2f}}",
      my_latency, fastest, outcome, fill);
}

static int maybe_add_order(Order *orders, int count, int *order_id,
                           Book *books) {
  if (count >= 20) {
    return count;
  }
  if (rand_between(0, 1) < 0.4) {
    int symbol_index = rand() % SYMBOL_COUNT;
    Book *book = &books[symbol_index];
    Order order;
    order.order_id = (*order_id)++;
    order.side = rand_between(0, 1) > 0.5 ? 'B' : 'S';
    order.price = book->price + (order.side == 'B' ? -0.01 : 0.01);
    order.size = (int)rand_between(50, 800);
    order.queue_ahead = (int)rand_between(0, 3000);
    order.queue_behind = (int)rand_between(0, 3000);
    strcpy(order.status, "ACTIVE");
    orders[count++] = order;
  }
  return count;
}

static int mutate_orders(Order *orders, int count) {
  int next_count = 0;
  for (int i = 0; i < count; i++) {
    Order order = orders[i];
    if (strcmp(order.status, "ACTIVE") != 0) {
      continue;
    }
    if (rand_between(0, 1) < 0.1) {
      strcpy(order.status, rand_between(0, 1) > 0.5 ? "FILLED" : "CANCELED");
    }
    order.queue_ahead = order.queue_ahead - (int)rand_between(0, 80);
    if (order.queue_ahead < 0) {
      order.queue_ahead = 0;
    }
    order.queue_behind = order.queue_behind + (int)rand_between(-40, 40);
    if (order.queue_behind < 0) {
      order.queue_behind = 0;
    }
    if (strcmp(order.status, "ACTIVE") == 0) {
      orders[next_count++] = order;
    }
  }
  return next_count;
}

static void build_active_orders(char *out, size_t cap, Order *orders,
                                int count) {
  size_t off = 0;
  append(out, cap, &off, "{\"type\":\"active_orders\",\"data\":[");
  for (int i = 0; i < count; i++) {
    if (i > 0) {
      append(out, cap, &off, ",");
    }
    append(out, cap, &off,
           "{\"order_id\":%d,\"side\":\"%c\",\"price\":%.2f,\"size\":%d,"
           "\"queue_ahead\":%d,\"queue_behind\":%d,\"status\":\"%s\"}",
           orders[i].order_id, orders[i].side, orders[i].price, orders[i].size,
           orders[i].queue_ahead, orders[i].queue_behind, orders[i].status);
  }
  append(out, cap, &off, "]}");
}

static void build_inventory_pnl(char *out, size_t cap, int *position,
                                double *realized, double *unrealized) {
  size_t off = 0;
  *position += (int)rand_between(-12, 12);
  if (*position > 1000) {
    *position = 1000;
  }
  if (*position < -1000) {
    *position = -1000;
  }
  *realized += rand_between(-50, 65);
  *unrealized += rand_between(-30, 40);
  const char *skew =
      *position > 40 ? "LONG" : (*position < -40 ? "SHORT" : "FLAT");
  append(out, cap, &off,
         "{\"type\":\"inventory_pnl\",\"data\":{\"position\":%d,\"realized_"
         "pnl\":%.2f,\"unrealized_pnl\":%.2f,\"inventory_skew\":\"%s\"}}",
         *position, *realized, *unrealized, skew);
}

static void build_system_health(char *out, size_t cap) {
  size_t off = 0;
  int event_rate = (int)rand_between(120000, 240000);
  int dropped = (int)rand_between(0, 20);
  double replay = rand_between(0.95, 1.08);
  append(out, cap, &off,
         "{\"type\":\"system_health\",\"data\":{\"event_rate\":%d,\"dropped_"
         "events\":%d,\"replay_speed\":%.2f}}",
         event_rate, dropped, replay);
}

int main(void) {
  const char *port_env = getenv("PORT");
  const char *path_env = getenv("WS_PATH");
  int port = port_env ? atoi(port_env) : 8080;
  const char *path = path_env ? path_env : "/ws";

  int server_fd = socket(AF_INET, SOCK_STREAM, 0);
  if (server_fd < 0) {
    perror("socket");
    return 1;
  }
  int opt = 1;
  setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons((unsigned short)port);
  if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("bind");
    close(server_fd);
    return 1;
  }
  if (listen(server_fd, 16) < 0) {
    perror("listen");
    close(server_fd);
    return 1;
  }

  Client clients[MAX_CLIENTS];
  for (int i = 0; i < MAX_CLIENTS; i++) {
    clients[i].active = 0;
    clients[i].fd = -1;
  }

  srand((unsigned int)time(NULL));
  Book books[5];
  for (int i = 0; i < SYMBOL_COUNT; i++) {
    books[i].price = 100.0 + (i * 75.0) + rand_between(0.0, 50.0);
    books[i].spread = 0.02 + rand_between(0.0, 0.05);
  }
  Order orders[32];
  int order_count = 0;
  int order_id = 1000;
  int position = 0;
  double realized = 0.0;
  double unrealized = 0.0;

  long long next_book = now_ms();
  long long next_trade = now_ms();
  long long next_orders = now_ms();
  long long next_latency = now_ms();
  long long next_inventory = now_ms();
  long long next_system = now_ms();

  printf("HFT C websocket server on ws://localhost:%d%s\n", port, path);

  while (1) {
    fd_set read_fds;
    FD_ZERO(&read_fds);
    FD_SET(server_fd, &read_fds);
    int max_fd = server_fd;
    for (int i = 0; i < MAX_CLIENTS; i++) {
      if (clients[i].active) {
        FD_SET(clients[i].fd, &read_fds);
        if (clients[i].fd > max_fd) {
          max_fd = clients[i].fd;
        }
      }
    }

    long long now = now_ms();
    long long next_tick = next_book;
    if (next_trade < next_tick)
      next_tick = next_trade;
    if (next_orders < next_tick)
      next_tick = next_orders;
    if (next_latency < next_tick)
      next_tick = next_latency;
    if (next_inventory < next_tick)
      next_tick = next_inventory;
    if (next_system < next_tick)
      next_tick = next_system;
    long long wait_ms = next_tick > now ? next_tick - now : 0;

    struct timeval tv;
    tv.tv_sec = (int)(wait_ms / 1000);
    tv.tv_usec = (int)((wait_ms % 1000) * 1000);

    int ready = select(max_fd + 1, &read_fds, NULL, NULL, &tv);
    if (ready > 0) {
      if (FD_ISSET(server_fd, &read_fds)) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd >= 0) {
          if (handle_handshake(client_fd, path) == 0) {
            int added = 0;
            for (int i = 0; i < MAX_CLIENTS; i++) {
              if (!clients[i].active) {
                clients[i].fd = client_fd;
                clients[i].active = 1;
                added = 1;
                break;
              }
            }
            if (!added) {
              close(client_fd);
            }
          } else {
            close(client_fd);
          }
        }
      }

      for (int i = 0; i < MAX_CLIENTS; i++) {
        if (!clients[i].active) {
          continue;
        }
        if (FD_ISSET(clients[i].fd, &read_fds)) {
          char junk[256];
          ssize_t r = recv(clients[i].fd, junk, sizeof(junk), 0);
          if (r <= 0) {
            close(clients[i].fd);
            clients[i].active = 0;
          }
        }
      }
    }

    now = now_ms();
    if (now >= next_book) {
      for (int i = 0; i < SYMBOL_COUNT; i++) {
        char payload[WRITE_BUF_SIZE];
        build_order_book(payload, sizeof(payload), books, i);
        broadcast(clients, payload);
      }
      next_book = now + 200;
    }
    if (now >= next_trade) {
      char payload[WRITE_BUF_SIZE];
      int symbol_index = rand() % SYMBOL_COUNT;
      build_trade_tape(payload, sizeof(payload), books, symbol_index);
      broadcast(clients, payload);
      next_trade = now + 60;
    }
    if (now >= next_orders) {
      order_count = maybe_add_order(orders, order_count, &order_id, books);
      order_count = mutate_orders(orders, order_count);
      char payload[WRITE_BUF_SIZE];
      build_active_orders(payload, sizeof(payload), orders, order_count);
      broadcast(clients, payload);
      next_orders = now + 500;
    }
    if (now >= next_latency) {
      char payload[WRITE_BUF_SIZE];
      build_latency_race(payload, sizeof(payload));
      broadcast(clients, payload);
      next_latency = now + 80;
    }
    if (now >= next_inventory) {
      char payload[WRITE_BUF_SIZE];
      build_inventory_pnl(payload, sizeof(payload), &position, &realized,
                          &unrealized);
      broadcast(clients, payload);
      next_inventory = now + 1000;
    }
    if (now >= next_system) {
      char payload[WRITE_BUF_SIZE];
      build_system_health(payload, sizeof(payload));
      broadcast(clients, payload);
      next_system = now + 1000;
    }
  }

  close(server_fd);
  return 0;
}
