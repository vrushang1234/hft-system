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
const DEFAULT_MOCK_URL = "/hft_stream.json";
const DEFAULT_UI_TICK_MS = 100;
const DEFAULT_MOCK_TICK_MS = 80;
const MAX_TRADE_TAPE = 200;
const MAX_LATENCY_POINTS = 240;
const MAX_BUFFERED_MESSAGES = 5000;
const MAX_BATCH_PROCESS = 1200;

type ConnectionStatus = "connecting" | "open" | "closed" | "error";

type StreamState = {
	orderBooks: Record<string, OrderBookSnapshot>;
	activeOrders: ActiveOrder[];
	inventory: InventoryPnl | null;
	systemHealth: SystemHealth | null;
	connection: ConnectionStatus;
	lastMessageAt: number | null;
	tradeTapeVersion: number;
	latencyVersion: number;
};

const initialState: StreamState = {
	orderBooks: {},
	activeOrders: [],
	inventory: null,
	systemHealth: null,
	connection: "connecting",
	lastMessageAt: null,
	tradeTapeVersion: 0,
	latencyVersion: 0,
};

type Options = {
	url?: string;
	mockUrl?: string;
	uiTickMs?: number;
	source?: "ws" | "mock";
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

type RingBuffer<T> = {
	data: T[];
	start: number;
	size: number;
	capacity: number;
};

function createRingBuffer<T>(capacity: number): RingBuffer<T> {
	return { data: new Array<T>(capacity), start: 0, size: 0, capacity };
}

function ringPush<T>(buffer: RingBuffer<T>, value: T) {
	const index = (buffer.start + buffer.size) % buffer.capacity;
	buffer.data[index] = value;
	if (buffer.size < buffer.capacity) {
		buffer.size += 1;
	} else {
		buffer.start = (buffer.start + 1) % buffer.capacity;
	}
}

function ringToArrayChrono<T>(buffer: RingBuffer<T>): T[] {
	const result = new Array<T>(buffer.size);
	for (let i = 0; i < buffer.size; i += 1) {
		const index = (buffer.start + i) % buffer.capacity;
		result[i] = buffer.data[index];
	}
	return result;
}

function ringToArrayNewestFirst<T>(buffer: RingBuffer<T>): T[] {
	const result = new Array<T>(buffer.size);
	for (let i = 0; i < buffer.size; i += 1) {
		const index =
			(buffer.start + buffer.size - 1 - i + buffer.capacity) % buffer.capacity;
		result[i] = buffer.data[index];
	}
	return result;
}

function applyMessages(
	prev: StreamState,
	batch: HftMessage[],
	startTs: number,
	tradeTapeBuffer: RingBuffer<TradeTape>,
	latencyBuffer: RingBuffer<TelemetryPoint>,
): StreamState {
	let nextOrderBooks = prev.orderBooks;
	let nextActiveOrders = prev.activeOrders;
	let nextInventory = prev.inventory;
	let nextSystemHealth = prev.systemHealth;
	let tradeTapeVersion = prev.tradeTapeVersion;
	let latencyVersion = prev.latencyVersion;
	let touched = false;

	for (const message of batch) {
		switch (message.type) {
			case "order_book_snapshot": {
				if (nextOrderBooks === prev.orderBooks) {
					nextOrderBooks = { ...prev.orderBooks };
				}
				nextOrderBooks[message.data.symbol] = message.data;
				touched = true;
				break;
			}
			case "active_orders": {
				nextActiveOrders = message.data.slice();
				touched = true;
				break;
			}
			case "trade_tape": {
				ringPush(tradeTapeBuffer, message.data);
				tradeTapeVersion += 1;
				touched = true;
				break;
			}
			case "latency_race": {
				ringPush(latencyBuffer, toTelemetryPoint(message.data, nowSeconds(startTs)));
				latencyVersion += 1;
				touched = true;
				break;
			}
			case "inventory_pnl": {
				nextInventory = message.data;
				touched = true;
				break;
			}
			case "system_health": {
				nextSystemHealth = message.data;
				touched = true;
				break;
			}
			default:
				break;
		}
	}

	if (!touched) {
		return prev;
	}

	return {
		...prev,
		orderBooks: nextOrderBooks,
		activeOrders: nextActiveOrders,
		inventory: nextInventory,
		systemHealth: nextSystemHealth,
		lastMessageAt: Date.now(),
		tradeTapeVersion,
		latencyVersion,
	};
}

export function useHftStream(options: Options = {}) {
	const url = options.url ?? import.meta.env.VITE_HFT_WS_URL ?? DEFAULT_WS_URL;
	const mockUrl =
		options.mockUrl ?? import.meta.env.VITE_HFT_MOCK_URL ?? DEFAULT_MOCK_URL;
	const uiTickMs = options.uiTickMs ?? DEFAULT_UI_TICK_MS;
	const source = options.source ?? (options.url ? "ws" : "mock");
	const [state, setState] = useState<StreamState>(initialState);
	const bufferRef = useRef<HftMessage[]>([]);
	const socketRef = useRef<WebSocket | null>(null);
	const replayRef = useRef<number | null>(null);
	const replayIndexRef = useRef(0);
	const replayDataRef = useRef<HftMessage[]>([]);
	const tradeTapeRef = useRef<RingBuffer<TradeTape>>(
		createRingBuffer<TradeTape>(MAX_TRADE_TAPE),
	);
	const latencyRef = useRef<RingBuffer<TelemetryPoint>>(
		createRingBuffer<TelemetryPoint>(MAX_LATENCY_POINTS),
	);
	const startRef = useRef<number>(Date.now());

	useEffect(() => {
		startRef.current = Date.now();
		bufferRef.current = [];
		replayIndexRef.current = 0;
		replayDataRef.current = [];
		tradeTapeRef.current = createRingBuffer<TradeTape>(MAX_TRADE_TAPE);
		latencyRef.current = createRingBuffer<TelemetryPoint>(MAX_LATENCY_POINTS);
		setState((prev) => ({ ...prev, connection: "connecting" }));
		let active = true;

		if (replayRef.current) {
			window.clearInterval(replayRef.current);
			replayRef.current = null;
		}

		if (source === "ws") {
			const socket = new WebSocket(url);
			socketRef.current = socket;

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
						const buffer = bufferRef.current;
						buffer.push(parsed);
						if (buffer.length > MAX_BUFFERED_MESSAGES) {
							buffer.splice(0, buffer.length - MAX_BUFFERED_MESSAGES);
						}
					}
				} catch {
					return;
				}
			};
		} else {
			socketRef.current = null;
			fetch(mockUrl)
				.then((response) => response.json())
				.then((payload) => {
					if (!active) {
						return;
					}
					if (!Array.isArray(payload)) {
						throw new Error("Invalid mock payload");
					}
					replayDataRef.current = payload as HftMessage[];
					setState((prev) => ({ ...prev, connection: "open" }));
					replayRef.current = window.setInterval(() => {
						const stream = replayDataRef.current;
						if (stream.length === 0) {
							return;
						}
						const next = stream[replayIndexRef.current];
						replayIndexRef.current =
							(replayIndexRef.current + 1) % stream.length;
						const buffer = bufferRef.current;
						buffer.push(next);
						if (buffer.length > MAX_BUFFERED_MESSAGES) {
							buffer.splice(0, buffer.length - MAX_BUFFERED_MESSAGES);
						}
					}, DEFAULT_MOCK_TICK_MS);
				})
				.catch(() => {
					if (!active) {
						return;
					}
					setState((prev) => ({ ...prev, connection: "error" }));
				});
		}

		return () => {
			active = false;
			if (socketRef.current) {
				socketRef.current.close();
			}
			socketRef.current = null;
			if (replayRef.current) {
				window.clearInterval(replayRef.current);
				replayRef.current = null;
			}
		};
	}, [mockUrl, source, url]);

	useEffect(() => {
		const handle = window.setInterval(() => {
			const buffer = bufferRef.current;
			if (buffer.length === 0) {
				return;
			}
			if (buffer.length > MAX_BATCH_PROCESS) {
				buffer.splice(0, buffer.length - MAX_BATCH_PROCESS);
			}
			const batch = buffer.splice(0, buffer.length);
			setState((prev) =>
				applyMessages(
					prev,
					batch,
					startRef.current,
					tradeTapeRef.current,
					latencyRef.current,
				),
			);
		}, uiTickMs);
		return () => window.clearInterval(handle);
	}, [uiTickMs]);

	const derived = useMemo(() => {
		const orderBookList = Object.values(state.orderBooks);
		const tradeTape = ringToArrayNewestFirst(tradeTapeRef.current);
		const latencySeries = ringToArrayChrono(latencyRef.current);
		const lastTrade = tradeTape[0];
		const lastLatency = latencySeries[latencySeries.length - 1] ?? null;
		return { orderBookList, tradeTape, latencySeries, lastTrade, lastLatency };
	}, [state.orderBooks, state.tradeTapeVersion, state.latencyVersion]);

	return {
		...state,
		...derived,
	};
}
