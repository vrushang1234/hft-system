export type Column<T> = {
	key: keyof T;
	header: string;
	width?: number | string;
	align?: "left" | "right" | "center";
};

type Props<T extends { id: string | number }> = {
	columns: Column<T>[];
	rows: T[];
	height?: number;
};

export default function DataTable<T extends { id: string | number }>({
	columns,
	rows,
	height,
}: Props<T>) {
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
			<div className="tbl-body">
				{rows.map((r) => (
					<div className="row" key={r.id}>
						{columns.map((col) => (
							<div
								key={String(col.key)}
								className="cell"
								style={{ width: col.width ?? "auto", textAlign: col.align ?? "left" }}
								title={String(r[col.key])}
							>
								{String(r[col.key])}
							</div>
						))}
					</div>
				))}
			</div>
		</div>
	);
}
