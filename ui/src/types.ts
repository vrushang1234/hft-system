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
