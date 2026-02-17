import { memo, useEffect, useMemo, useRef, useState } from "react";
import type { UIEvent } from "react";

export type Column<T> = {
	key: keyof T;
	header: string;
	width?: number | string;
	align?: "left" | "right" | "center";
};

type DataRow = { id: string | number; [key: string]: string | number };

type Props = {
	columns: Column<any>[];
	rows: DataRow[];
	height?: number;
	rowHeight?: number;
};

function DataTable({
	columns,
	rows,
	height,
 	rowHeight = 28,
}: Props) {
	const bodyRef = useRef<HTMLDivElement | null>(null);
	const [scrollTop, setScrollTop] = useState(0);
	const [bodyHeight, setBodyHeight] = useState(0);

	useEffect(() => {
		const el = bodyRef.current;
		if (!el) {
			return;
		}
		const observer = new ResizeObserver((entries) => {
			for (const entry of entries) {
				setBodyHeight(entry.contentRect.height);
			}
		});
		observer.observe(el);
		return () => observer.disconnect();
	}, []);

	const totalRows = rows.length;
	const totalHeight = totalRows * rowHeight;
	const overscan = 6;
	const visibleCount = bodyHeight > 0 ? Math.ceil(bodyHeight / rowHeight) : totalRows;
	const startIndex = Math.max(0, Math.floor(scrollTop / rowHeight) - overscan);
	const endIndex = Math.min(
		totalRows,
		startIndex + visibleCount + overscan * 2,
	);

	const visibleRows = useMemo(
		() => rows.slice(startIndex, endIndex),
		[rows, startIndex, endIndex],
	);

	return (
		<div className="panel table" style={height != null ? { height } : undefined}>
			<div className="tbl-head">
				{columns.map((col) => (
					<div
						key={String(col.key)}
						className="cell head"
						style={{ width: col.width ?? "auto", textAlign: col.align ?? "left" }}
					>
						{col.header}
					</div>
				))}
			</div>
			<div
				className="tbl-body"
				ref={bodyRef}
				onScroll={(event: UIEvent<HTMLDivElement>) =>
					setScrollTop(event.currentTarget.scrollTop)
				}
			>
				<div className="tbl-spacer" style={{ height: totalHeight }}>
					<div
						className="tbl-window"
						style={{ transform: `translateY(${startIndex * rowHeight}px)` }}
					>
						{visibleRows.map((r, offset) => {
							const rowIndex = startIndex + offset;
							const background = rowIndex % 2 === 1 ? "#f7f9fb" : "transparent";
							return (
							<div
								className="row"
								key={r.id}
								style={{ height: rowHeight, background }}
							>
								{columns.map((col) => (
									(() => {
										const key = String(col.key);
										const value = (r as Record<string, string | number>)[key];
										return (
										<div
										key={key}
										className="cell"
										style={{
											width: col.width ?? "auto",
											textAlign: col.align ?? "left",
										}}
										title={String(value)}
									>
										{String(value)}
									</div>
									);
									})()
								))}
							</div>
						);
						})}
					</div>
				</div>
			</div>
		</div>
	);
}

const MemoDataTable = memo(DataTable as any, (prev: Props, next: Props) => {
	return (
		prev.rows === next.rows &&
		prev.columns === next.columns &&
		prev.height === next.height &&
		prev.rowHeight === next.rowHeight
	);
}) as typeof DataTable;

export default MemoDataTable;
