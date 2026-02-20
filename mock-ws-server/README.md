# Mock HFT WebSocket Server

Simulates the HFT engine stream using the terminal data spec.

## Setup

```bash
cd mock-ws-server
npm install
npm run start
```

Defaults to `ws://localhost:8080/ws`.

## Environment

- `PORT` (default `8080`)
- `WS_PATH` (default `/ws`)

## Payloads

Each websocket message is a JSON object:

```json
{ "type": "order_book_snapshot", "data": { "ts": 0, "symbol": "AAPL", "bids": [], "asks": [] } }
```

The server emits the following message types:

- `order_book_snapshot`
- `active_orders`
- `trade_tape`
- `latency_race`
- `inventory_pnl`
- `system_health`
