CC = gcc
CFLAGS = -I$(IDIR) -Wall -Wextra -pedantic -Wshadow -Werror=return-type -Wwrite-strings -g3

IDIR = include
SDIR = src
BDIR = bin

WS_SERVER = $(BDIR)/hft_ws_server
MOCK_STREAM = $(BDIR)/mock_stream

.PHONY: all ws-server run-ws mock-stream clean
all: ws-server

$(WS_SERVER): $(SDIR)/hft_ws_server.c
	@mkdir -p $(BDIR)
	$(CC) $(CFLAGS) -o $@ $^

ws-server: $(WS_SERVER)

run-ws: ws-server
	$(WS_SERVER)

$(MOCK_STREAM): $(SDIR)/mock_stream.c
	@mkdir -p $(BDIR)
	$(CC) $(CFLAGS) -o $@ $^

mock-stream: $(MOCK_STREAM)

clean:
	-rm -rf $(BDIR)
