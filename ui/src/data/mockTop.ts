import type { TopRow } from "../types";

export function mockTopRow(
	symbol: string,
	bidPx: number,
	bidSz: number,
	askPx: number,
	askSz: number,
	lastPx: number,
	lastSz: number,
): TopRow {
	const mid = (bidPx + askPx) / 2;
	const spreadBp = ((askPx - bidPx) / mid) * 10_000;
	const imb = bidSz + askSz > 0 ? bidSz / (bidSz + askSz) : 0;
	return {
		id: Math.random(),
		symbol,
		bidPx: +bidPx.toFixed(2),
		bidSz,
		askPx: +askPx.toFixed(2),
		askSz,
		spreadBp: +spreadBp.toFixed(1),
		mid: +mid.toFixed(2),
		imbalancePct: (imb * 100).toFixed(0) + "%",
		lastPx: +lastPx.toFixed(2),
		lastSz,
		lastTime: new Date().toLocaleTimeString(undefined, { hour12: false }),
	};
}

export const topOfBookData: TopRow[] = [
	mockTopRow("AAPL", 189.12, 1200, 189.14, 950, 189.13, 300),
	mockTopRow("MSFT", 412.88, 600, 412.91, 500, 412.89, 200),
	mockTopRow("AMZN", 147.05, 2200, 147.07, 2100, 147.06, 800),
	mockTopRow("TSLA", 242.45, 1800, 242.48, 1700, 242.47, 500),
	mockTopRow("NVDA", 903.22, 900, 903.25, 850, 903.24, 300),
];
