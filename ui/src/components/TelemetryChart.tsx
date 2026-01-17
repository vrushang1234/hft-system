import { useId, useMemo } from "react";
import type { TelemetryEvent, TelemetryPoint, TelemetryWindow } from "../types";

type Props = {
	series: TelemetryPoint[];
	events?: TelemetryEvent[];
	windows?: TelemetryWindow[];
	height?: number;
	units?: string;
	title?: string;
};

const WIDTH = 820;
const HEIGHT = 320;
const PADDING = { top: 26, right: 28, bottom: 26, left: 48 };

export default function TelemetryChart({
	series,
	events = [],
	windows = [],
	height,
	units = "us",
	title = "Latency + Flow Telemetry",
}: Props) {
	const clipId = useId();

	const domain = useMemo(() => {
		if (series.length === 0) {
			return {
				tMin: 0,
				tMax: 1,
				yMin: 0,
				yMax: 1,
			};
		}

		let tMin = series[0].t;
		let tMax = series[0].t;
		let yMin = Math.min(series[0].chA, series[0].chB);
		let yMax = Math.max(series[0].chA, series[0].chB);

		for (const point of series) {
			tMin = Math.min(tMin, point.t);
			tMax = Math.max(tMax, point.t);
			yMin = Math.min(yMin, point.chA, point.chB);
			yMax = Math.max(yMax, point.chA, point.chB);
		}

		const padding = (yMax - yMin) * 0.08 || 1;
		return { tMin, tMax, yMin: yMin - padding, yMax: yMax + padding };
	}, [series]);

	const chartHeight = height ?? HEIGHT;
	const plotWidth = WIDTH - PADDING.left - PADDING.right;
	const plotHeight = chartHeight - PADDING.top - PADDING.bottom;

	const scaleX = (t: number) =>
		PADDING.left + ((t - domain.tMin) / (domain.tMax - domain.tMin || 1)) * plotWidth;
	const scaleY = (v: number) =>
		PADDING.top + (1 - (v - domain.yMin) / (domain.yMax - domain.yMin || 1)) * plotHeight;

	const linePath = (key: "chA" | "chB") =>
		series
			.map((point, index) => {
				const command = index === 0 ? "M" : "L";
				return `${command} ${scaleX(point.t)} ${scaleY(point[key])}`;
			})
			.join(" ");

	const yTicks = 6;
	const xTicks = 7;

	const yTickValues = Array.from({ length: yTicks }, (_, i) => {
		return domain.yMin + (i / (yTicks - 1)) * (domain.yMax - domain.yMin || 1);
	});

	const xTickValues = Array.from({ length: xTicks }, (_, i) => {
		return domain.tMin + (i / (xTicks - 1)) * (domain.tMax - domain.tMin || 1);
	});

	return (
		<div className="panel telemetry-panel">
			<div className="telemetry-header">
				<div>
					<div className="telemetry-title">{title}</div>
					<div className="telemetry-subtitle">Order flow + latency scan (read-only)</div>
				</div>
				<div className="telemetry-legend">
					<span className="legend-item">
						<span className="legend-swatch ch-a" />
						Channel A
					</span>
					<span className="legend-item">
						<span className="legend-swatch ch-b" />
						Channel B
					</span>
					<span className="legend-item">
						<span className="legend-swatch state" />
						Anomaly/Unstable
					</span>
				</div>
			</div>
			<div className="telemetry-body">
				<svg
					className="telemetry-svg"
					viewBox={`0 0 ${WIDTH} ${chartHeight}`}
					role="img"
					aria-label="Telemetry chart"
				>
					<rect
						className="telemetry-plot"
						x={PADDING.left}
						y={PADDING.top}
						width={plotWidth}
						height={plotHeight}
					/>
					{windows.map((window) => {
						const xStart = scaleX(window.start);
						const xEnd = scaleX(window.end);
						return (
							<rect
								key={`${window.label}-${window.start}`}
								x={xStart}
								y={PADDING.top}
								width={Math.max(1, xEnd - xStart)}
								height={plotHeight}
								className={`telemetry-window window-${window.kind}`}
							/>
						);
					})}
					{yTickValues.map((value) => (
						<line
							key={`y-grid-${value}`}
							x1={PADDING.left}
							y1={scaleY(value)}
							x2={WIDTH - PADDING.right}
							y2={scaleY(value)}
							className="telemetry-grid"
						/>
					))}
					{xTickValues.map((value) => (
						<line
							key={`x-grid-${value}`}
							x1={scaleX(value)}
							y1={PADDING.top}
							x2={scaleX(value)}
							y2={chartHeight - PADDING.bottom}
							className="telemetry-grid"
						/>
					))}
					<g clipPath={`url(#${clipId})`}>
						<path d={linePath("chA")} className="telemetry-line ch-a" />
						<path d={linePath("chB")} className="telemetry-line ch-b" />
						{series
							.filter((point) => point.state === "anomaly")
							.map((point) => (
								<circle
									key={`anom-${point.t}`}
									cx={scaleX(point.t)}
									cy={scaleY(point.chA)}
									r={2.2}
									className="telemetry-anomaly"
								/>
							))}
					</g>
					{events.map((event) => (
						<g key={`${event.label}-${event.t}`}>
							<line
								x1={scaleX(event.t)}
								y1={PADDING.top}
								x2={scaleX(event.t)}
								y2={chartHeight - PADDING.bottom}
								className="telemetry-event-line"
							/>
							<text
								x={scaleX(event.t) + 4}
								y={PADDING.top + 10}
								className="telemetry-event-label"
							>
								{event.label}
							</text>
						</g>
					))}
					{yTickValues.map((value) => (
						<text
							key={`y-label-${value}`}
							x={PADDING.left - 8}
							y={scaleY(value) + 3}
							className="telemetry-axis"
							textAnchor="end"
						>
							{value.toFixed(1)}
						</text>
					))}
					{xTickValues.map((value) => (
						<text
							key={`x-label-${value}`}
							x={scaleX(value)}
							y={chartHeight - PADDING.bottom + 16}
							className="telemetry-axis"
							textAnchor="middle"
						>
							{value.toFixed(0)}
						</text>
					))}
					<text
						x={PADDING.left}
						y={PADDING.top - 8}
						className="telemetry-axis telemetry-axis-title"
					>
						{`Latency (${units})`}
					</text>
					<text
						x={WIDTH - PADDING.right}
						y={chartHeight - 6}
						className="telemetry-axis telemetry-axis-title"
						textAnchor="end"
					>
						Time (s)
					</text>
					<defs>
						<clipPath id={clipId}>
							<rect
								x={PADDING.left}
								y={PADDING.top}
								width={plotWidth}
								height={plotHeight}
							/>
						</clipPath>
					</defs>
				</svg>
			</div>
		</div>
	);
}
