FROM alpine:latest

RUN apk add --no-cache build-base

# Set root working directory
WORKDIR /app

# Copy project files
COPY . .

# Change into test directory
WORKDIR /app/test

# Build, test, and clean
CMD sh -c "make && ./test && make clean"

