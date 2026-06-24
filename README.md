# FIFO Design and Verification

## Overview

This project implements and verifies both **Synchronous FIFO** and **Asynchronous FIFO** using Verilog/SystemVerilog.

- **Synchronous FIFO** operates with a single clock for both read and write operations.
- **Asynchronous FIFO** operates with independent write and read clocks, making it suitable for Clock Domain Crossing (CDC) applications.

Both designs are verified using dedicated SystemVerilog testbenches. The asynchronous FIFO is verified using a class-based verification environment with constrained random stimulus.

---

## Project Features

### Synchronous FIFO
- Single clock operation
- 8-bit data width
- FIFO depth of 8
- Full and Empty flag generation
- Write and Read operations
- Functional verification using a SystemVerilog testbench

### Asynchronous FIFO
- Independent write and read clocks
- Binary and Gray code pointers
- Two-stage synchronizers for clock domain crossing
- Full and Empty flag generation
- Class-based verification environment
- Mailbox communication
- Constrained random testing
- Scoreboard-based data checking

---

## Project Structure

```
FIFO-Design-and-Verification/
│
├── sync_fifo.v
├── sync_fifo_tb.sv
│
├── async_fifo.v
├── async_fifo_tb.sv
│
├── README.md
│
├── Waveforms/
│   ├── sync_fifo_waveform.png
│   └── async_fifo_waveform.png
│
└── Output/
    ├── sync_fifo_output.txt
    └── async_fifo_output.txt
```

---

## Verification Components (Asynchronous FIFO)

- Interface
- Transaction
- Generator
- Driver
- Monitor
- Scoreboard
- Mailboxes

The scoreboard stores all written data in a reference queue and compares it with the data read from the FIFO to ensure correct FIFO behavior.

---

## Test Cases Performed

### Synchronous FIFO
- Reset Operation
- Write Operation
- Read Operation
- FIFO Full Condition
- FIFO Empty Condition
- Data Integrity Check

### Asynchronous FIFO
- Reset Operation
- Multiple Write Operations
- Multiple Read Operations
- Random Read/Write Transactions
- FIFO Full Condition
- FIFO Empty Condition
- Data Integrity Verification using Scoreboard

---

## Simulation Results

The asynchronous FIFO verification reports successful comparisons between expected and actual data.

Example:

```
[Scoreboard] Stored 163
[Scoreboard] PASS Expected=163 Actual=163

[Scoreboard] Stored 168
[Scoreboard] PASS Expected=168 Actual=168

[Scoreboard] Stored 195
[Scoreboard] PASS Expected=195 Actual=195
```

---

## Waveforms

The simulation waveforms demonstrate:

### Synchronous FIFO
- Write operations
- Read operations
- Full and Empty flags

### Asynchronous FIFO
- Independent write and read clocks
- Pointer synchronization
- Gray code pointer updates
- Full and Empty flags
- Correct FIFO ordering

---

## Tools Used

- Verilog
- SystemVerilog
- Vivado
- EDA Playground

---

## Author

**Megha**
