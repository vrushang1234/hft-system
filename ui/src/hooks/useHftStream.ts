import { useEffect, useMemo, useRef, useState } from "react";
import type {
	ActiveOrder,
	HftMessage,
	InventoryPnl,
	LatencyRace,
	OrderBookSnapshot,
	SystemHealth,
	TelemetryPoint,
	TradeTape,
} from "../types";

const DEFAULT_WS_URL = "ws://localhost:8080/ws";
const DEFAULT_UI_TICK_MS = 100;
const MAX_TRADE_TAPE = 200;
const MAX_LATENCY_POINTS = 240;

type ConnectionStatus = "connecting" | "open" | "closed" | "error";

type StreamState = {
	orderBooks: Record<string, OrderBookSnapshot>;
	activeOrders: ActiveOrder[];
	tradeTape: TradeTape[];
	latencySeries: TelemetryPoint[];
	inventory: InventoryPnl | null;
	systemHealth: SystemHealth | null;
	connection: ConnectionStatus;
	lastMessageAt: number | null;
};

const initialState: StreamState = {
	orderBooks: {},
	activeOrders: [],
	tradeTape: [],
	latencySeries: [],
	inventory: null,
	systemHealth: null,
	connection: "connecting",
	lastMessageAt: null,
};

type Options = {
	url?: string;
	uiTickMs?: number;
};

function nowSeconds(start: number) {
	return (Date.now() - start) / 1000;
}

function toTelemetryPoint(sample: LatencyRace, t: number): TelemetryPoint {
	const state =
		sample.race_outcome === "LOST"
			? "anomaly"
			: sample.fill_probability < 0.4
				? "unstable"
				: undefined;
	return {
		t,
		chA: sample.my_latency_ns,
		chB: sample.fastest_competitor_ns,
		state,
	};
}

function applyMessages(
	prev: StreamState,
	batch: HftMessage[],
	startTs: number,
): StreamState {
	let nextOrderBooks = prev.orderBooks;
	let nextActiveOrders = prev.activeOrders;
	let nextTradeTape = prev.tradeTape;
	let nextLatency = prev.latencySeries;
	let nextInventory = prev.inventory;
	let nextSystemHealth = prev.systemHealth;

	for (const message of batch) {
		switch (message.type) {
			case "order_book_snapshot": {
				if (nextOrderBooks === prev.orderBooks) {
					nextOrderBooks = { ...prev.orderBooks };
				}
				nextOrderBooks[message.data.symbol] = message.data;
				break;
			}
			case "active_orders": {
				nextActiveOrders = message.data.slice();
				break;
			}
			case "trade_tape": {
				if (nextTradeTape === prev.tradeTape) {
					nextTradeTape = prev.tradeTape.slice();
				}
				nextTradeTape.unshift(message.data);
				if (nextTradeTape.length > MAX_TRADE_TAPE) {
					nextTradeTape.length = MAX_TRADE_TAPE;
				}
				break;
			}
			case "latency_race": {
				if (nextLatency === prev.latencySeries) {
					nextLatency = prev.latencySeries.slice();
				}
				nextLatency.push(toTelemetryPoint(message.data, nowSeconds(startTs)));
				if (nextLatency.length > MAX_LATENCY_POINTS) {
					nextLatency.splice(0, nextLatency.length - MAX_LATENCY_POINTS);
				}
				break;
			}
			case "inventory_pnl": {
				nextInventory = message.data;
				break;
			}
			case "system_health": {
				nextSystemHealth = message.data;
				break;
			}
			default:
				break;
		}
	}

	return {
		...prev,
		orderBooks: nextOrderBooks,
		activeOrders: nextActiveOrders,
		tradeTape: nextTradeTape,
		latencySeries: nextLatency,
		inventory: nextInventory,
		systemHealth: nextSystemHealth,
		lastMessageAt: Date.now(),
	};
}

export function useHftStream(options: Options = {}) {
	const url = options.url ?? import.meta.env.VITE_HFT_WS_URL ?? DEFAULT_WS_URL;
	const uiTickMs = options.uiTickMs ?? DEFAULT_UI_TICK_MS;
	const [state, setState] = useState<StreamState>(initialState);
	const bufferRef = useRef<HftMessage[]>([]);
	const socketRef = useRef<WebSocket | null>(null);
	const startRef = useRef<number>(Date.now());

	useEffect(() => {
		startRef.current = Date.now();
		const socket = new WebSocket(url);
		socketRef.current = socket;
		setState((prev) => ({ ...prev, connection: "connecting" }));

		socket.onopen = () => {
			setState((prev) => ({ ...prev, connection: "open" }));
		};

		socket.onclose = () => {
			setState((prev) => ({ ...prev, connection: "closed" }));
		};

		socket.onerror = () => {
			setState((prev) => ({ ...prev, connection: "error" }));
		};

		socket.onmessage = (event) => {
			try {
				const parsed = JSON.parse(event.data) as HftMessage;
				if (parsed && typeof parsed === "object" && "type" in parsed) {
					bufferRef.current.push(parsed);
				}
			} catch {
				return;
			}
		};

		return () => {
			socketRef.current = null;
			socket.close();
		};
	}, [url]);

	useEffect(() => {
		const handle = window.setInterval(() => {
			if (bufferRef.current.length === 0) {
				return;
			}
			const batch = bufferRef.current.splice(0, bufferRef.current.length);
			setState((prev) => applyMessages(prev, batch, startRef.current));
		}, uiTickMs);
		return () => window.clearInterval(handle);
	}, [uiTickMs]);

	const derived = useMemo(() => {
		const orderBookList = Object.values(state.orderBooks);
		const lastTrade = state.tradeTape[0];
		return { orderBookList, lastTrade };
	}, [state.orderBooks, state.tradeTape]);

	return {
		...state,
		...derived,
	};
}
