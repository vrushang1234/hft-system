export type BlotterRow = {
	id: number;
	time: string;
	side: "BUY" | "SELL";
	price: string;
	qty: number;
	status: "NEW" | "PARTIAL" | "FILLED";
};

export type TopRow = {
	id: number;
	symbol: string;
	bidPx: number;
	bidSz: number;
	askPx: number;
	askSz: number;
	spreadBp: number;
	mid: number;
	imbalancePct: string;
	lastPx: number;
	lastSz: number;
	lastTime: string;
};

export type TelemetryPoint = {
	t: number;
	chA: number;
	chB: number;
	state?: "nominal" | "unstable" | "anomaly";
};

export type TelemetryEvent = {
	t: number;
	label: string;
};

export type TelemetryWindow = {
	start: number;
	end: number;
	label: string;
	kind: "unstable" | "anomaly" | "nominal";
};
