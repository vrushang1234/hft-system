const WebSocket = require("ws");

const PORT = Number(process.env.PORT || 8080);
const PATH = process.env.WS_PATH || "/ws";

const SYMBOLS = ["AAPL", "MSFT", "AMZN", "TSLA", "NVDA"];

const STATE = {
	books: Object.fromEntries(
		SYMBOLS.map((symbol) => [
			symbol,
			{
				price: 100 + Math.random() * 500,
				spread: 0.02 + Math.random() * 0.05,
			},
		]),
	),
	activeOrders: [],
	orderId: 1000,
	position: 0,
	realized: 0,
	unrealized: 0,
};

function nowNs() {
	return Math.floor(Date.now() * 1_000_000);
}

function randBetween(min, max) {
	return min + Math.random() * (max - min);
}

function nextPrice(symbol) {
	const book = STATE.books[symbol];
	const drift = randBetween(-0.08, 0.08);
	book.price = Math.max(1, book.price + drift);
	book.spread = Math.max(0.01, book.spread + randBetween(-0.003, 0.003));
	return book;
}

function orderBookSnapshot(symbol) {
	const book = nextPrice(symbol);
	const bid = +(book.price - book.spread / 2).toFixed(2);
	const ask = +(book.price + book.spread / 2).toFixed(2);
	const bidSize = Math.floor(randBetween(100, 2500));
	const askSize = Math.floor(randBetween(100, 2500));
	return {
		ts: nowNs(),
		symbol,
		bids: [
			{ price: bid, size: bidSize },
			{ price: +(bid - 0.01).toFixed(2), size: Math.floor(bidSize * 0.6) },
		],
		asks: [
			{ price: ask, size: askSize },
			{ price: +(ask + 0.01).toFixed(2), size: Math.floor(askSize * 0.6) },
		],
	};
}

function tradeTape(symbol) {
	const book = STATE.books[symbol];
	const price = +(book.price + randBetween(-0.02, 0.02)).toFixed(2);
	const size = Math.floor(randBetween(10, 600));
	const aggressor = Math.random() > 0.5 ? "BUY" : "SELL";
	return {
		ts: nowNs(),
		price,
		size,
		aggressor,
	};
}

function maybeAddOrder() {
	if (STATE.activeOrders.length > 20) {
		return;
	}
	if (Math.random() < 0.4) {
		const symbol = SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)];
		const book = STATE.books[symbol];
		const side = Math.random() > 0.5 ? "B" : "S";
		const price = +(book.price + (side === "B" ? -0.01 : 0.01)).toFixed(2);
		STATE.activeOrders.push({
			order_id: STATE.orderId++,
			side,
			price,
			size: Math.floor(randBetween(50, 800)),
			queue_ahead: Math.floor(randBetween(0, 3000)),
			queue_behind: Math.floor(randBetween(0, 3000)),
			status: "ACTIVE",
		});
	}
}

function mutateOrders() {
	for (const order of STATE.activeOrders) {
		if (order.status !== "ACTIVE") {
			continue;
		}
		if (Math.random() < 0.1) {
			order.status = Math.random() > 0.5 ? "FILLED" : "CANCELED";
		}
		order.queue_ahead = Math.max(0, order.queue_ahead - Math.floor(randBetween(0, 80)));
		order.queue_behind = Math.max(0, order.queue_behind + Math.floor(randBetween(-40, 40)));
	}
	STATE.activeOrders = STATE.activeOrders.filter((order) => order.status === "ACTIVE");
}

function latencyRace() {
	const myLatency = Math.floor(randBetween(90_000, 230_000));
	const fastest = Math.floor(randBetween(70_000, 200_000));
	const raceWon = myLatency <= fastest + 15_000;
	return {
		my_latency_ns: myLatency,
		fastest_competitor_ns: fastest,
		race_outcome: raceWon ? "WON" : "LOST",
		fill_probability: Math.max(0, Math.min(1, randBetween(0.25, 0.95))),
	};
}

function inventoryPnl() {
	STATE.position += Math.floor(randBetween(-12, 12));
	STATE.position = Math.max(-1000, Math.min(1000, STATE.position));
	STATE.realized += randBetween(-50, 65);
	STATE.unrealized += randBetween(-30, 40);
	const skew = STATE.position > 40 ? "LONG" : STATE.position < -40 ? "SHORT" : "FLAT";
	return {
		position: STATE.position,
		realized_pnl: +STATE.realized.toFixed(2),
		unrealized_pnl: +STATE.unrealized.toFixed(2),
		inventory_skew: skew,
	};
}

function systemHealth() {
	return {
		event_rate: Math.floor(randBetween(120_000, 240_000)),
		dropped_events: Math.floor(randBetween(0, 20)),
		replay_speed: +randBetween(0.95, 1.08).toFixed(2),
	};
}

const server = new WebSocket.Server({ port: PORT, path: PATH });
const clients = new Set();

server.on("connection", (socket) => {
	clients.add(socket);

	socket.on("close", () => {
		clients.delete(socket);
	});
});

function broadcast(payload) {
	const message = JSON.stringify(payload);
	for (const client of clients) {
		if (client.readyState === WebSocket.OPEN) {
			client.send(message);
		}
	}
}

function publish(type, data) {
	broadcast({ type, data });
}

setInterval(() => {
	for (const symbol of SYMBOLS) {
		publish("order_book_snapshot", orderBookSnapshot(symbol));
	}
}, 200);

setInterval(() => {
	const symbol = SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)];
	publish("trade_tape", tradeTape(symbol));
}, 60);

setInterval(() => {
	maybeAddOrder();
	mutateOrders();
	publish("active_orders", STATE.activeOrders);
}, 500);

setInterval(() => {
	publish("latency_race", latencyRace());
}, 80);

setInterval(() => {
	publish("inventory_pnl", inventoryPnl());
}, 1000);

setInterval(() => {
	publish("system_health", systemHealth());
}, 1000);

console.log(`Mock HFT websocket server running on ws://localhost:${PORT}${PATH}`);
