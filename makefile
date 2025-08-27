CC = gcc
CFLAGS = -I$(IDIR) -Wall -Wextra -pedantic -Wunused -Wshadow -Werror=return-type -Wwrite-strings -g3

IDIR = include
ODIR = obj
SDIR = src

TARGET = main.exe

SRCS = $(wildcard $(SDIR)/*.c)
OBJS = $(patsubst $(SDIR)/%.c, $(ODIR)/%.o, $(SRCS))

.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^

$(ODIR)/%.o: $(SDIR)/%.c
	@mkdir -p $(ODIR)
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	-rm -f $(TARGET)
	-rm -rf $(ODIR)

