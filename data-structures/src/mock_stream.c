#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct {
	double price;
	double spread;
} Book;

static const char *SYMBOLS[] = {"AAPL", "MSFT", "AMZN", "TSLA", "NVDA"};
static const int SYMBOL_COUNT = 5;

static double rand_between(double min, double max) {
	return min + ((double)rand() / (double)RAND_MAX) * (max - min);
}

static long long now_ns_base(void) {
	return 1700000000000000000LL;
}

static void write_order_book(FILE *out, Book *books, int symbol_index, long long ts) {
	Book *book = &books[symbol_index];
	book->price += rand_between(-0.08, 0.08);
	if (book->price < 1.0) {
		book->price = 1.0;
	}
	book->spread += rand_between(-0.004, 0.004);
	if (book->spread < 0.01) {
		book->spread = 0.01;
	}

	double bid = book->price - book->spread / 2.0;
	double ask = book->price + book->spread / 2.0;
	int bid_size = (int)rand_between(100, 2500);
	int ask_size = (int)rand_between(100, 2500);

	fprintf(
		out,
		"{\"type\":\"order_book_snapshot\",\"data\":{\"ts\":%lld,\"symbol\":\"%s\",\"bids\":[{\"price\":%.2f,\"size\":%d},{\"price\":%.2f,\"size\":%d}],\"asks\":[{\"price\":%.2f,\"size\":%d},{\"price\":%.2f,\"size\":%d}]}}",
		ts,
		SYMBOLS[symbol_index],
		bid,
		bid_size,
		bid - 0.01,
		(int)(bid_size * 0.6),
		ask,
		ask_size,
		ask + 0.01,
		(int)(ask_size * 0.6));
}

static void write_trade_tape(FILE *out, Book *books, int symbol_index, long long ts) {
	Book *book = &books[symbol_index];
	double price = book->price + rand_between(-0.02, 0.02);
	int size = (int)rand_between(10, 700);
	const char *aggressor = rand_between(0, 1) > 0.5 ? "BUY" : "SELL";

	fprintf(
		out,
		"{\"type\":\"trade_tape\",\"data\":{\"ts\":%lld,\"price\":%.2f,\"size\":%d,\"aggressor\":\"%s\"}}",
		ts,
		price,
		size,
		aggressor);
}

static void write_latency_race(FILE *out) {
	int my_latency = (int)rand_between(90000, 230000);
	int fastest = (int)rand_between(70000, 200000);
	const char *outcome = my_latency <= fastest + 15000 ? "WON" : "LOST";
	double fill = rand_between(0.25, 0.95);

	fprintf(
		out,
		"{\"type\":\"latency_race\",\"data\":{\"my_latency_ns\":%d,\"fastest_competitor_ns\":%d,\"race_outcome\":\"%s\",\"fill_probability\":%.2f}}",
		my_latency,
		fastest,
		outcome,
		fill);
}

static void write_active_orders(FILE *out, int *order_id) {
	int first_id = (*order_id)++;
	int second_id = (*order_id)++;
	fprintf(
		out,
		"{\"type\":\"active_orders\",\"data\":[{\"order_id\":%d,\"side\":\"B\",\"price\":%.2f,\"size\":%d,\"queue_ahead\":%d,\"queue_behind\":%d,\"status\":\"ACTIVE\"},{\"order_id\":%d,\"side\":\"S\",\"price\":%.2f,\"size\":%d,\"queue_ahead\":%d,\"queue_behind\":%d,\"status\":\"ACTIVE\"}]}",
		first_id,
		rand_between(120, 520),
		(int)rand_between(50, 900),
		(int)rand_between(0, 3000),
		(int)rand_between(0, 3000),
		second_id,
		rand_between(120, 520),
		(int)rand_between(50, 900),
		(int)rand_between(0, 3000),
		(int)rand_between(0, 3000));
}

static void write_inventory_pnl(FILE *out, int *position, double *realized, double *unrealized) {
	*position += (int)rand_between(-12, 12);
	if (*position > 1000) {
		*position = 1000;
	}
	if (*position < -1000) {
		*position = -1000;
	}
	*realized += rand_between(-50, 65);
	*unrealized += rand_between(-30, 40);
	const char *skew = *position > 40 ? "LONG" : (*position < -40 ? "SHORT" : "FLAT");

	fprintf(
		out,
		"{\"type\":\"inventory_pnl\",\"data\":{\"position\":%d,\"realized_pnl\":%.2f,\"unrealized_pnl\":%.2f,\"inventory_skew\":\"%s\"}}",
		*position,
		*realized,
		*unrealized,
		skew);
}

static void write_system_health(FILE *out) {
	int event_rate = (int)rand_between(120000, 240000);
	int dropped = (int)rand_between(0, 20);
	double replay = rand_between(0.95, 1.08);

	fprintf(
		out,
		"{\"type\":\"system_health\",\"data\":{\"event_rate\":%d,\"dropped_events\":%d,\"replay_speed\":%.2f}}",
		event_rate,
		dropped,
		replay);
}

int main(int argc, char **argv) {
	const char *output_path = argc > 1 ? argv[1] : "mock-data/hft_stream.json";
	FILE *out = fopen(output_path, "w");
	if (!out) {
		return 1;
	}

	srand((unsigned int)time(NULL));
	Book books[5];
	for (int i = 0; i < SYMBOL_COUNT; i++) {
		books[i].price = 100.0 + (i * 75.0) + rand_between(0.0, 50.0);
		books[i].spread = 0.02 + rand_between(0.0, 0.05);
	}

	int order_id = 1000;
	int position = 0;
	double realized = 0.0;
	double unrealized = 0.0;
	long long base_ts = now_ns_base();
	int total = 240;

	fprintf(out, "[\n");
	for (int i = 0; i < total; i++) {
		if (i > 0) {
			fprintf(out, ",\n");
		}
		long long ts = base_ts + (long long)i * 50000000LL;
		int selector = i % 6;
		int symbol_index = i % SYMBOL_COUNT;

		switch (selector) {
			case 0:
				write_order_book(out, books, symbol_index, ts);
				break;
			case 1:
				write_trade_tape(out, books, symbol_index, ts);
				break;
			case 2:
				write_latency_race(out);
				break;
			case 3:
				write_active_orders(out, &order_id);
				break;
			case 4:
				write_inventory_pnl(out, &position, &realized, &unrealized);
				break;
			default:
				write_system_health(out);
				break;
		}
	}
	fprintf(out, "\n]\n");

	fclose(out);
	return 0;
}
