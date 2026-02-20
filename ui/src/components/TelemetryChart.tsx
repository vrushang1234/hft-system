import { useEffect, useMemo, useRef, useState } from "react";
import type { TelemetryPoint } from "../types";

type Props = {
	series: TelemetryPoint[];
	height?: number;
	units?: string;
	title?: string;
};

const DEFAULT_HEIGHT = 320;
const PADDING = { top: 26, right: 28, bottom: 26, left: 48 };
const MAX_POINTS = 900;

export default function TelemetryChart({
	series,
	height,
	units = "us",
	title = "Latency + Flow Telemetry",
}: Props) {
	const containerRef = useRef<HTMLDivElement | null>(null);
	const canvasRef = useRef<HTMLCanvasElement | null>(null);
	const frameRef = useRef<number | null>(null);
	const latestRef = useRef({ series, units });
	const [size, setSize] = useState({ width: 820, height: height ?? DEFAULT_HEIGHT });

	useEffect(() => {
		latestRef.current = { series, units };
		if (frameRef.current != null) {
			return;
		}
		frameRef.current = window.requestAnimationFrame(() => {
			frameRef.current = null;
			drawChart();
		});
	}, [series, units]);

	useEffect(() => {
		const el = containerRef.current;
		if (!el) {
			return;
		}
		const observer = new ResizeObserver((entries) => {
			for (const entry of entries) {
				const nextWidth = Math.max(320, entry.contentRect.width);
				setSize({ width: nextWidth, height: height ?? DEFAULT_HEIGHT });
			}
		});
		observer.observe(el);
		return () => observer.disconnect();
	}, [height]);

	const domain = useMemo(() => {
		if (series.length === 0) {
			return { tMin: 0, tMax: 1, yMin: 0, yMax: 1 };
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

	const drawChart = () => {
		const canvas = canvasRef.current;
		if (!canvas) {
			return;
		}
		const ctx = canvas.getContext("2d");
		if (!ctx) {
			return;
		}

		const { width, height: chartHeight } = size;
		const dpr = window.devicePixelRatio || 1;
		canvas.width = Math.floor(width * dpr);
		canvas.height = Math.floor(chartHeight * dpr);
		canvas.style.width = `${width}px`;
		canvas.style.height = `${chartHeight}px`;
		ctx.scale(dpr, dpr);
		ctx.clearRect(0, 0, width, chartHeight);

		ctx.fillStyle = "#ffffff";
		ctx.fillRect(0, 0, width, chartHeight);

		const plotWidth = width - PADDING.left - PADDING.right;
		const plotHeight = chartHeight - PADDING.top - PADDING.bottom;
		const scaleX = (t: number) =>
			PADDING.left + ((t - domain.tMin) / (domain.tMax - domain.tMin || 1)) * plotWidth;
		const scaleY = (v: number) =>
			PADDING.top + (1 - (v - domain.yMin) / (domain.yMax - domain.yMin || 1)) * plotHeight;

		ctx.strokeStyle = "#e6eaf0";
		ctx.lineWidth = 1;
		const yTicks = 6;
		const xTicks = 7;
		for (let i = 0; i < yTicks; i += 1) {
			const value = domain.yMin + (i / (yTicks - 1)) * (domain.yMax - domain.yMin || 1);
			const y = scaleY(value);
			ctx.beginPath();
			ctx.moveTo(PADDING.left, y);
			ctx.lineTo(width - PADDING.right, y);
			ctx.stroke();
		}
		for (let i = 0; i < xTicks; i += 1) {
			const value = domain.tMin + (i / (xTicks - 1)) * (domain.tMax - domain.tMin || 1);
			const x = scaleX(value);
			ctx.beginPath();
			ctx.moveTo(x, PADDING.top);
			ctx.lineTo(x, chartHeight - PADDING.bottom);
			ctx.stroke();
		}

		const points = latestRef.current.series;
		const stride = points.length > MAX_POINTS ? Math.ceil(points.length / MAX_POINTS) : 1;
		const drawLine = (key: "chA" | "chB", color: string) => {
			ctx.strokeStyle = color;
			ctx.lineWidth = 1.5;
			ctx.beginPath();
			let started = false;
			for (let i = 0; i < points.length; i += stride) {
				const point = points[i];
				const x = scaleX(point.t);
				const y = scaleY(point[key]);
				if (!started) {
					ctx.moveTo(x, y);
					started = true;
				} else {
					ctx.lineTo(x, y);
				}
			}
			ctx.stroke();
		};

		drawLine("chA", "#1d4ed8");
		drawLine("chB", "#6d28d9");

		ctx.fillStyle = "#4b5563";
		ctx.font = "10px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
		ctx.textAlign = "right";
		ctx.textBaseline = "middle";
		for (let i = 0; i < yTicks; i += 1) {
			const value = domain.yMin + (i / (yTicks - 1)) * (domain.yMax - domain.yMin || 1);
			const y = scaleY(value);
			ctx.fillText(value.toFixed(1), PADDING.left - 8, y);
		}
		ctx.textAlign = "center";
		ctx.textBaseline = "top";
		for (let i = 0; i < xTicks; i += 1) {
			const value = domain.tMin + (i / (xTicks - 1)) * (domain.tMax - domain.tMin || 1);
			const x = scaleX(value);
			ctx.fillText(value.toFixed(0), x, chartHeight - PADDING.bottom + 6);
		}

		ctx.fillStyle = "#6b7280";
		ctx.textAlign = "left";
		ctx.textBaseline = "bottom";
		ctx.fillText(`Latency (${latestRef.current.units})`, PADDING.left, PADDING.top - 6);
		ctx.textAlign = "right";
		ctx.textBaseline = "bottom";
		ctx.fillText("Time (s)", width - PADDING.right, chartHeight - 6);
	};

	useEffect(() => {
		drawChart();
		return () => {
			if (frameRef.current != null) {
				window.cancelAnimationFrame(frameRef.current);
				frameRef.current = null;
			}
		};
	}, [domain, size]);

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
				</div>
			</div>
			<div className="telemetry-body" ref={containerRef}>
				<canvas className="telemetry-canvas" ref={canvasRef} />
			</div>
		</div>
	);
}
