import { useMemo, useState } from "react";
import DataTable, { type Column } from "./components/DataTable";
import {
	type ActiveOrderRow,
	type TopOfBookRow,
	type TradeTapeRow,
} from "./types";
import TelemetryChart from "./components/TelemetryChart";
import { useHftStream } from "./hooks/useHftStream";

function formatNsTimestamp(ns: number | null) {
	if (!ns) {
		return "--";
	}
	const date = new Date(ns / 1_000_000);
	return date.toLocaleTimeString(undefined, {
		hour12: false,
		minute: "2-digit",
		second: "2-digit",
		fractionalSecondDigits: 3,
	});
}

function formatNumber(value: number | null, digits = 2) {
	if (value == null || Number.isNaN(value)) {
		return "--";
	}
	return value.toFixed(digits);
}

function formatSpreadBp(value: number | null) {
	if (value == null || Number.isNaN(value)) {
		return "--";
	}
	return value.toFixed(1);
}

function formatLatency(value: number | null) {
	if (value == null || Number.isNaN(value)) {
		return "--";
	}
	const micros = value / 1000;
	if (micros >= 1000) {
		return `${(micros / 1000).toFixed(2)} ms`;
	}
	return `${micros.toFixed(1)} us`;
}

export default function App() {
	const {
		orderBookList,
		activeOrders,
		tradeTape,
		latencySeries,
		inventory,
		systemHealth,
		connection,
		lastMessageAt,
		lastTrade,
		lastLatency,
	} = useHftStream({ source: "ws" });

	const topRows = useMemo<TopOfBookRow[]>(() => {
		return orderBookList.map((snapshot) => {
			const bestBid = snapshot.bids[0] ?? null;
			const bestAsk = snapshot.asks[0] ?? null;
			const mid =
				bestBid && bestAsk ? (bestBid.price + bestAsk.price) / 2 : null;
			const spreadBp =
				bestBid && bestAsk && mid
					? ((bestAsk.price - bestBid.price) / mid) * 10_000
					: null;
			const imbalance =
				bestBid && bestAsk
					? bestBid.size / Math.max(bestBid.size + bestAsk.size, 1)
					: null;
			return {
				id: snapshot.symbol,
				symbol: snapshot.symbol,
				bidPx: formatNumber(bestBid?.price ?? null, 2),
				bidSz: bestBid ? String(bestBid.size) : "--",
				askPx: formatNumber(bestAsk?.price ?? null, 2),
				askSz: bestAsk ? String(bestAsk.size) : "--",
				spreadBp: formatSpreadBp(spreadBp),
				mid: formatNumber(mid, 2),
				lastTradePx: formatNumber(lastTrade?.price ?? null, 2),
				lastTradeSz: lastTrade ? String(lastTrade.size) : "--",
				lastTradeTs: formatNsTimestamp(lastTrade?.ts ?? null),
				imbalancePct: imbalance == null ? "--" : `${(imbalance * 100).toFixed(0)}%`,
			};
		});
	}, [orderBookList, lastTrade]);

	const activeOrderRows = useMemo<ActiveOrderRow[]>(() => {
		return activeOrders.map((order) => ({
			id: order.order_id,
			orderId: order.order_id,
			side: order.side,
			price: formatNumber(order.price, 2),
			size: order.size,
			queueAhead: order.queue_ahead,
			queueBehind: order.queue_behind,
			status: order.status,
		}));
	}, [activeOrders]);

	const tradeTapeRows = useMemo<TradeTapeRow[]>(() => {
		return tradeTape.map((trade, index) => ({
			id: `${trade.ts}-${index}`,
			ts: formatNsTimestamp(trade.ts),
			price: formatNumber(trade.price, 2),
			size: trade.size,
			aggressor: trade.aggressor,
		}));
	}, [tradeTape]);

	const topCols: Column<TopOfBookRow>[] = useMemo(
		() => [
			{ key: "symbol", header: "Sym", width: 70 },
			{ key: "bidPx", header: "Bid", width: 80, align: "right" },
			{ key: "bidSz", header: "BidSz", width: 70, align: "right" },
			{ key: "askPx", header: "Ask", width: 80, align: "right" },
			{ key: "askSz", header: "AskSz", width: 70, align: "right" },
			{ key: "spreadBp", header: "Spr(bp)", width: 80, align: "right" },
			{ key: "mid", header: "Mid", width: 80, align: "right" },
			{ key: "imbalancePct", header: "Imb%", width: 70, align: "right" },
			{ key: "lastTradePx", header: "Last", width: 80, align: "right" },
			{ key: "lastTradeSz", header: "Lsz", width: 60, align: "right" },
			{ key: "lastTradeTs", header: "Last Time", width: 110 },
		],
		[],
	);

	const activeOrderCols: Column<ActiveOrderRow>[] = useMemo(
		() => [
			{ key: "orderId", header: "Order", width: 90, align: "right" },
			{ key: "side", header: "Side", width: 60, align: "center" },
			{ key: "price", header: "Price", width: 90, align: "right" },
			{ key: "size", header: "Size", width: 70, align: "right" },
			{ key: "queueAhead", header: "Q Ahead", width: 90, align: "right" },
			{ key: "queueBehind", header: "Q Behind", width: 90, align: "right" },
			{ key: "status", header: "Status", width: 90, align: "center" },
		],
		[],
	);

	const tradeTapeCols: Column<TradeTapeRow>[] = useMemo(
		() => [
			{ key: "ts", header: "Time", width: 120 },
			{ key: "price", header: "Price", width: 90, align: "right" },
			{ key: "size", header: "Size", width: 70, align: "right" },
			{ key: "aggressor", header: "Agg", width: 70, align: "center" },
		],
		[],
	);

	const [panels, setPanels] = useState({
		topOfBook: true,
		activeOrders: true,
		tradeTape: true,
		telemetry: true,
	});

	const togglePanel = (
		key: "topOfBook" | "activeOrders" | "tradeTape" | "telemetry",
	) => {
		setPanels((prev) => {
			const next = { ...prev, [key]: !prev[key] };
			const enabled = Object.values(next).filter(Boolean).length;
			return enabled === 0 ? prev : next;
		});
	};

	const panelCount = Object.values(panels).filter(Boolean).length;

	return (
		<div className="shell">
			<aside className="rail">
				<button
					className={`rail-btn ${panels.telemetry ? "active" : ""}`}
					aria-pressed={panels.telemetry}
					aria-label="Telemetry"
					onClick={() => togglePanel("telemetry")}
				>
					<i className="fa-thin fa-chart-area" aria-hidden="true" />
				</button>
				<button
					className={`rail-btn ${panels.topOfBook ? "active" : ""}`}
					aria-pressed={panels.topOfBook}
					aria-label="Top of Book"
					onClick={() => togglePanel("topOfBook")}
				>
					<i className="fa-thin fa-table" aria-hidden="true" />
				</button>
				<button
					className={`rail-btn ${panels.activeOrders ? "active" : ""}`}
					aria-pressed={panels.activeOrders}
					aria-label="Active Orders"
					onClick={() => togglePanel("activeOrders")}
				>
					<i className="fa-thin fa-wave-square" aria-hidden="true" />
				</button>
				<button
					className={`rail-btn ${panels.tradeTape ? "active" : ""}`}
					aria-pressed={panels.tradeTape}
					aria-label="Trade Tape"
					onClick={() => togglePanel("tradeTape")}
				>
					<i className="fa-thin fa-chart-line" aria-hidden="true" />
				</button>
				<div className="rail-spacer" />
				<button className="rail-btn" aria-label="Settings">
					CFG
				</button>
			</aside>
			<div className="main">
				<header className="topbar">
					<div className="title-block">
						<div className="title">Realtime Market Monitor</div>
						<div className="subtitle">Top of Book + Orders + Tape</div>
					</div>
					<div className="status-row">
						<span
							className={`status chip ${connection === "open" ? "ok" : "warn"}`}
						>
							WS {connection.toUpperCase()}
						</span>
						<span className="status chip">
							POS {inventory ? `${inventory.position} ${inventory.inventory_skew}` : "--"}
						</span>
						<span className="status chip">
							PNL {inventory ? formatNumber(inventory.realized_pnl + inventory.unrealized_pnl, 2) : "--"}
						</span>
						<span className="status chip">
							EVT {systemHealth ? `${systemHealth.event_rate}/s` : "--"}
						</span>
						<span className="status chip">
							DROP {systemHealth ? systemHealth.dropped_events : "--"}
						</span>
						<span className="status chip">
							LAT {formatLatency(lastLatency?.chA ?? null)}
						</span>
						<span className="status chip">
							LAST {lastMessageAt ? new Date(lastMessageAt).toLocaleTimeString() : "--"}
						</span>
					</div>
				</header>
				<div className={`workspace layout-${panelCount || 1}`}>
					{panelCount === 1 && panels.telemetry ? (
						<TelemetryChart
							series={latencySeries}
							height={420}
							units="ns"
							title="Latency Race Diagnostics"
						/>
					) : null}
					{panelCount === 1 && panels.topOfBook ? (
						<div className="panel table">
							<DataTable columns={topCols} rows={topRows} />
						</div>
					) : null}
					{panelCount === 1 && panels.activeOrders ? (
						<div className="panel table">
							<DataTable columns={activeOrderCols} rows={activeOrderRows} />
						</div>
					) : null}
					{panelCount === 1 && panels.tradeTape ? (
						<div className="panel table">
							<DataTable columns={tradeTapeCols} rows={tradeTapeRows} />
						</div>
					) : null}
					{panelCount > 1 && panels.telemetry ? (
						<TelemetryChart
							series={latencySeries}
							units="ns"
							title="Latency Race Diagnostics"
						/>
					) : null}
					{panelCount > 1 && panels.topOfBook ? (
						<div className="panel table">
							<DataTable columns={topCols} rows={topRows} />
						</div>
					) : null}
					{panelCount > 1 && panels.activeOrders ? (
						<div className="panel table">
							<DataTable columns={activeOrderCols} rows={activeOrderRows} />
						</div>
					) : null}
					{panelCount > 1 && panels.tradeTape ? (
						<div className="panel table">
							<DataTable columns={tradeTapeCols} rows={tradeTapeRows} />
						</div>
					) : null}
				</div>
			</div>
		</div>
	);
}
