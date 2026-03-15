# High Frequency Trading System

A hardware-accelerated high-frequency trading system built on FPGAs, combining a custom Tensor Processing Unit for neural network inference, a high-throughput order matching engine, and a software backend for large-scale order management. The system is designed around the idea that latency-critical decisions should never leave the chip.

---

## What It Does

The system takes incoming market orders, decides which ones are most profitable using a neural network running directly on hardware, caches the highest-priority orders in on-chip memory, and matches them deterministically in two clock cycles. Everything from inference to trade matching runs without CPU involvement in the critical path.

A web-based terminal displays the live order book, active positions, and real-time price data for operator visibility.

---

## System Architecture

The system is split across three components: a host machine running the software infrastructure, and two FPGAs — one dedicated to the TPU and one to order matching. They communicate over parallel SPI.

```
Host Computer (Red-Black Tree, 100k+ orders)
        |
        | SPI
       / \
      /   \
TPU FPGA   Order Matching FPGA
(neural net inference)  (MultiQueue + CAM)
```

### Host Computer

The host stores the full order book using lock-free Red-Black Trees, which guarantee O(log n) insertion, search, and deletion across concurrent strategy threads. Orders are ranked using a formula that weighs trading frequency against a "nice value" assigned by the RL agent:

```
Rank = (Frequency * C) / Nice Value Weight
```

The top-ranked orders are promoted to FPGA BRAM for ultra-low-latency access. Everything else stays in software.

---

### TPU FPGA — Decision Engine

The TPU runs a lightweight neural network entirely in hardware to determine which orders are worth caching. No order book data is sent to the CPU for inference.

**Compute pipeline:** `MatMul -> Tanh -> MatMul -> Softmax`

The network is implemented as a systolic array — a grid of MAC units that process matrix chunks in parallel. Tanh and Softmax are approximated with on-chip Look-Up Tables to avoid floating-point logic entirely.

**Precision:** 32-bit fixed-point arithmetic (Q2.29 format), which keeps integer throughput high while maintaining enough range for financial math.

**Clock:** 200 MHz (5 ns per stage). The 4-stage pipeline produces a decision every 20 ns.

---

### Order Matching FPGA — MultiQueue Engine

Incoming orders are matched entirely in on-chip BRAM. The architecture is a MultiQueue: a set of priority queues backed by BRAM blocks, organized as Sorting Cells that push lower-priority items back on insert.

**Memory:** The Artix-7 XC7A35T has 100 blocks of 18 Kb BRAM, supporting up to 512 symbols each with a 24-order deep Min-Queue. Read and write both complete in 2 clock cycles.

**Dynamic Indexing:** A Content-Addressable Memory (CAM) controller acts as a lookup table that maps stock symbols to their queue location. When the table is full, it evicts the oldest symbol automatically — no software intervention needed.

**Pipelining:** CAM lookup, order matching, and MultiQueue read/write are fully overlapped. An incoming order is deterministically matched within 2 clock cycles.

**Clock:** Up to 150 MHz synthesis, supporting 75 million orders per second throughput.

---

### Reinforcement Learning

A Proximal Policy Optimization (PPO) agent assigns a "nice value" in the range [-10, 10] to each order. The policy takes three inputs: trade frequency, share volume, and the buy/sell ratio. Its output weights are used to compute the rank that determines whether an order gets promoted to FPGA memory.

The reward function is higher when a matched order was already resident in FPGA memory, which trains the agent to predict which trades are worth caching ahead of time.

---

### User Terminal

A React front end connects over WebSocket for live two-way communication with the FPGA backend. It displays real-time stock prices, a live order book showing market depth, position tracking, and buy/sell controls with live P&L.

---

## Hardware

- 2x Digilent Cmod A7-35T (Artix-7 XC7A35T FPGA)
- One FPGA for the TPU, one for the Order Matching Engine
- Host machine connected via parallel SPI

## Software Stack

- Verilog — RTL design (Xilinx Vivado 2023.1)
- C (GCC 13.2.0) — host-side order management
- Python 3.13 — RL training (PyTorch 2.2.0, Stable-Baselines3, Gymnasium)
- React + WebSocket — user terminal
- Docker Engine 29.1.2
