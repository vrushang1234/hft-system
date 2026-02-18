FROM alpine:latest

RUN apk add --no-cache build-base

WORKDIR /app

COPY . .

RUN make ws-server

EXPOSE 8080

CMD ["./bin/hft_ws_server"]
