import type { TelemetryEvent, TelemetryPoint, TelemetryWindow } from "../types";

const points: TelemetryPoint[] = [];
const total = 180;

for (let i = 0; i <= total; i += 1) {
	const base = Math.sin(i / 10) * 4 + Math.cos(i / 24) * 2;
	const chA = base + Math.sin(i / 4.2) * 1.6 + 32;
	const chB = base * 0.8 + Math.cos(i / 5.1) * 1.9 + 28;
	const state = i > 98 && i < 116 ? "unstable" : i > 132 && i < 140 ? "anomaly" : undefined;
	points.push({ t: i, chA, chB, state });
}

export const telemetrySeries = points;

export const telemetryEvents: TelemetryEvent[] = [
	{ t: 12, label: "Feed Sync" },
	{ t: 44, label: "Spread Widen" },
	{ t: 76, label: "Queue Burst" },
	{ t: 132, label: "Risk Gate" },
];

export const telemetryWindows: TelemetryWindow[] = [
	{ start: 100, end: 116, label: "Vol Spike", kind: "unstable" },
	{ start: 133, end: 140, label: "Limit Breach", kind: "anomaly" },
];
