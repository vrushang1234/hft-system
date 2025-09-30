import { useMemo, useState } from "react";
import DataTable, { type Column } from "./components/DataTable";
import { type TopRow, type BlotterRow } from "./types";
import { topOfBookData } from "./data/mockTop";
import { blotterData } from "./data/mockBlotter";

export default function App() {
	const [topRows] = useState<TopRow[]>(topOfBookData);
	const [blotter] = useState<BlotterRow[]>(blotterData);

	const topCols: Column<TopRow>[] = useMemo(
		() => [
			{ key: "symbol", header: "Sym", width: 70 },
			{ key: "bidPx", header: "Bid", width: 80, align: "right" },
			{ key: "bidSz", header: "BidSz", width: 70, align: "right" },
			{ key: "askPx", header: "Ask", width: 80, align: "right" },
			{ key: "askSz", header: "AskSz", width: 70, align: "right" },
			{ key: "spreadBp", header: "Spr(bp)", width: 80, align: "right" },
			{ key: "mid", header: "Mid", width: 80, align: "right" },
			{ key: "imbalancePct", header: "Imb%", width: 70, align: "right" },
			{ key: "lastPx", header: "Last", width: 80, align: "right" },
			{ key: "lastSz", header: "Lsz", width: 60, align: "right" },
			{ key: "lastTime", header: "Last Time", width: 110 },
		],
		[],
	);

	const blotterCols: Column<BlotterRow>[] = useMemo(
		() => [
			{ key: "time", header: "Time", width: 120 },
			{ key: "side", header: "Side", width: 70, align: "center" },
			{ key: "price", header: "Price", width: 90, align: "right" },
			{ key: "qty", header: "Qty", width: 70, align: "right" },
			{ key: "status", header: "Status", width: 90, align: "center" },
		],
		[],
	);

	return (
		<div className="shell">
			<div className="workspace">
				<div className="panel table" style={{ flex: "0 0 50%" }}>
					<DataTable columns={topCols} rows={topRows} />
				</div>
				<div className="panel table" style={{ flex: 1, marginLeft: 12 }}>
					<DataTable columns={blotterCols} rows={blotter} />
				</div>
			</div>
		</div>
	);
}
