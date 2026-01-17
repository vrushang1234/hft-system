import type { BlotterRow } from "../types";

export const blotterData: BlotterRow[] = [
	{ id: 1, time: "09:59:58", side: "BUY", price: "189.10", qty: 100, status: "FILLED" },
	{
		id: 2,
		time: "09:59:59",
		side: "SELL",
		price: "189.15",
		qty: 250,
		status: "FILLED",
	},
	{ id: 3, time: "10:00:01", side: "BUY", price: "189.14", qty: 50, status: "PARTIAL" },
	{ id: 4, time: "10:00:05", side: "SELL", price: "412.91", qty: 75, status: "NEW" },
	{ id: 5, time: "10:00:08", side: "BUY", price: "147.06", qty: 300, status: "FILLED" },
	{
		id: 6,
		time: "10:00:12",
		side: "SELL",
		price: "242.48",
		qty: 120,
		status: "FILLED",
	},
	{ id: 7, time: "10:00:15", side: "BUY", price: "903.25", qty: 200, status: "NEW" },
	{ id: 8, time: "10:00:17", side: "SELL", price: "903.26", qty: 50, status: "FILLED" },
	{ id: 9, time: "10:00:20", side: "BUY", price: "412.92", qty: 90, status: "FILLED" },
	{
		id: 10,
		time: "10:00:25",
		side: "SELL",
		price: "147.08",
		qty: 130,
		status: "PARTIAL",
	},
];
