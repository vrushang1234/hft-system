export type OrderBookLevel = {
	price: number;
	size: number;
};

export type OrderBookSnapshot = {
	ts: number;
	symbol: string;
	bids: OrderBookLevel[];
	asks: OrderBookLevel[];
};

export type ActiveOrder = {
	order_id: number;
	side: "B" | "S";
	price: number;
	size: number;
	queue_ahead: number;
	queue_behind: number;
	status: "ACTIVE" | "FILLED" | "CANCELED";
};

export type TradeTape = {
	ts: number;
	price: number;
	size: number;
	aggressor: "BUY" | "SELL";
};

export type LatencyRace = {
	my_latency_ns: number;
	fastest_competitor_ns: number;
	race_outcome: "WON" | "LOST";
	fill_probability: number;
};

export type InventoryPnl = {
	position: number;
	realized_pnl: number;
	unrealized_pnl: number;
	inventory_skew: "LONG" | "SHORT" | "FLAT";
};

export type SystemHealth = {
	event_rate: number;
	dropped_events: number;
	replay_speed: number;
};

export type HftMessage =
	| { type: "order_book_snapshot"; data: OrderBookSnapshot }
	| { type: "active_orders"; data: ActiveOrder[] }
	| { type: "trade_tape"; data: TradeTape }
	| { type: "latency_race"; data: LatencyRace }
	| { type: "inventory_pnl"; data: InventoryPnl }
	| { type: "system_health"; data: SystemHealth };

export type TopOfBookRow = {
	id: string;
	symbol: string;
	bidPx: string;
	bidSz: string;
	askPx: string;
	askSz: string;
	spreadBp: string;
	mid: string;
	imbalancePct: string;
	lastTradePx: string;
	lastTradeSz: string;
	lastTradeTs: string;
};

export type ActiveOrderRow = {
	id: number;
	orderId: number;
	side: "B" | "S";
	price: string;
	size: number;
	queueAhead: number;
	queueBehind: number;
	status: "ACTIVE" | "FILLED" | "CANCELED";
};

export type TradeTapeRow = {
	id: string;
	ts: string;
	price: string;
	size: number;
	aggressor: "BUY" | "SELL";
};

export type TelemetryPoint = {
	t: number;
	chA: number;
	chB: number;
	state?: "nominal" | "unstable" | "anomaly";
};
