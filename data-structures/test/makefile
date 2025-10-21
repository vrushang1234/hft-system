CC = gcc
CFLAGS = -I$(IDIR) -Wall -Wextra -pedantic -Wunused -Wshadow -Werror=return-type -Wwrite-strings -g3

IDIR = ../include
ODIR = ../obj
SDIR = ../src

TARGET = test.exe

SRCS = $(wildcard $(SDIR)/*.c) $(wildcard ./*.c)
OBJS = $(patsubst $(SDIR)/%.c, $(ODIR)/%.o, $(SRCS))

.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^

$(ODIR)/%.o: $(SDIR)/%.c
	@if not exist $(ODIR) mkdir $(ODIR)
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	@if exist $(TARGET) del /Q $(TARGET)
	@if exist $(ODIR) rmdir /S /Q $(ODIR)
