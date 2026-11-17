# Synchronous FIFO — RTL to GDSII Implementation

An end-to-end digital design project implementing a synchronous FIFO using SystemVerilog, followed by functional verification, logic synthesis, physical design, and GDSII generation using the SkyWater SKY130A open-source PDK and LibreLane.

## Project Overview

A First-In First-Out (FIFO) buffer is a sequential storage structure in which data is read in the same order in which it was written. FIFOs are commonly used for data buffering, clock-domain interfaces, processor pipelines, and communication systems.

This project implements an 8-bit-wide, 16-entry synchronous FIFO and takes the RTL through an RTL-to-GDSII implementation flow.

### Design Specifications

| Parameter | Description |
|---|---|
| Design | Synchronous FIFO |
| RTL Language | SystemVerilog |
| Data Width | 8 bits |
| FIFO Depth | 16 entries |
| Storage Capacity | 128 bits |
| Clocking | Single synchronous clock |
| Reset | Active-high synchronous reset |
| Full/Empty Detection | Occupancy counter |
| Read/Write Pointers | 4-bit pointers |
| Occupancy Counter | 5-bit counter |
| Target PDK | SkyWater SKY130A |
| Standard Cell Library | `sky130_fd_sc_hd` |

## FIFO Architecture

The FIFO contains:

- A 16 × 8-bit storage array.
- A write pointer to select the next storage location.
- A read pointer to select the next data location.
- An occupancy counter to track the number of stored entries.
- Full and empty status indicators.
- Overflow and underflow indicators.

### Functional Behaviour

- A write is accepted when `wr_en` is asserted and the FIFO is not full.
- A read is accepted when `rd_en` is asserted and the FIFO is not empty.
- The read and write pointers advance independently.
- The occupancy counter updates according to accepted read and write operations.
- Simultaneous read and write operations are supported.
- Pointer wraparound is handled for the 16-entry storage array.
- Reset clears the pointers, occupancy counter, output register, and error indicators.

The design uses registered output data and does not reset the storage array itself.

## Repository Structure

```text
SystemVerilog-FIFO-RTL-to-GDSII/
│
├── src/
│   └── FIFO.sv
│
├── verification/
│   ├── FIFO_testbench.sv
│   └── FIFO_testbench1.sv
│
├── config/
│   ├── config.json
│   └── config_optimized.json
│
├── synthesis/
│   ├── FIFO_generic.v
│   └── FIFO_generic.json
│
├── layout/
│   ├── FIFO.gds
│   ├── FIFO.magic.gds
│   ├── FIFO.def
│   └── FIFO.lef
│
├── reports/
│   ├── timing/
│   └── physical_design/
│
├── screenshots/
├── documentation/
├── .gitignore
└── README.md
```

The complete intermediate run directories are excluded from version control. The repository contains selected final design artifacts and reports.

## Verification

The FIFO RTL was verified using SystemVerilog testbenches.

Verification covered:

- Reset operation.
- Normal write and read operations.
- FIFO full and empty conditions.
- Overflow and underflow handling.
- Simultaneous read and write operations.
- Pointer wraparound.
- Directed and randomized transaction testing.
- Reference-model-based data checking.

The verification process also included assertion-based checks and coverage tracking.

## RTL-to-GDSII Flow

The design was implemented using the LibreLane RTL-to-GDSII flow with the SkyWater SKY130A PDK.

The major implementation stages were:

1. RTL input and configuration.
2. Logic synthesis.
3. Floorplanning.
4. Power distribution network generation.
5. Standard-cell placement.
6. Clock-tree synthesis.
7. Global routing.
8. Detailed routing.
9. Parasitic extraction and timing analysis.
10. Physical verification.
11. GDSII generation.

### Implementation Tools

| Tool | Purpose |
|---|---|
| SystemVerilog | RTL design |
| XSim | RTL simulation |
| Yosys | Logic synthesis |
| LibreLane | RTL-to-GDSII automation |
| SkyWater SKY130A | Process design kit |
| OpenROAD | Physical design |
| Magic | Layout inspection and DRC |
| KLayout | GDSII visualization |
| Netgen | LVS verification |

## Physical Verification Results

The optimized implementation was checked using the generated physical-design reports.

| Check | Result |
|---|---|
| Magic DRC | 0 violations |
| LVS | Circuits match uniquely |
| Antenna Check | No violations reported |
| Setup Violations | 0 |
| Hold Violations | 0 |
| Maximum Capacitance Violations | 0 |
| Maximum Slew Violations | 83 |

**Timing qualification:** Setup and hold checks pass at the reported corners. However, maximum-slew violations remain and are disclosed rather than treated as a clean timing signoff.

## Physical Design Metrics

### Optimized Implementation

| Metric | Result |
|---|---:|
| Standard-cell area | 10,403.7 µm² |
| Total instance area | 16,642.2 µm² |
| Standard-cell count | 992 |
| Total instance count | 2,858 |
| Worst setup slack | +9.0122 ns |
| Worst hold slack | +0.1188 ns |
| Routed wirelength | 17,405 µm |
| Estimated power | 1.496 mW |

The power value is an implementation-flow estimate, not a measured silicon power result.

The timing analysis used an exploratory 20 ns clock-period target. It should not be interpreted as a measured maximum operating frequency.

## Baseline vs Optimized Implementation

Two physical-design configurations were evaluated.

| Metric | Baseline | Optimized |
|---|---:|---:|
| Standard-cell area | 10,438.8 µm² | 10,403.7 µm² |
| Standard-cell count | 990 | 992 |
| Total instance count | 2,846 | 2,858 |
| Worst setup slack | +8.5916 ns | +9.0122 ns |
| Worst hold slack | +0.1209 ns | +0.1188 ns |
| Routed wirelength | 17,427 µm | 17,405 µm |
| Estimated power | 1.497 mW | 1.496 mW |
| Maximum-slew violations (max SS) | 116 | 83 |

The optimized configuration reduced maximum-slew violations at the max-SS corner from 116 to 83, approximately a 28.4% reduction.

It also produced a small reduction in standard-cell area and routed wirelength, alongside an improvement in worst setup slack.

However, the optimized implementation still has maximum-slew violations, and some other timing corners also report slew violations. Therefore, this comparison represents an improvement in selected metrics, not complete timing closure.

## Design Artifacts

The repository includes:

- SystemVerilog RTL source.
- Verification testbenches.
- Generic synthesis netlist and synthesis statistics.
- GDSII layout.
- DEF physical-design database.
- LEF abstract.
- Magic-compatible GDSII.
- Timing and physical-verification reports.

## Learning Outcomes

This project provided practical experience with:

- Synchronous digital design using SystemVerilog.
- FIFO architecture and pointer management.
- Functional verification and reference-model checking.
- Logic synthesis and standard-cell mapping.
- Floorplanning, placement, clock-tree synthesis, and routing.
- Static timing analysis.
- Design Rule Checking (DRC).
- Layout Versus Schematic (LVS) verification.
- GDSII generation and layout inspection.

## Future Improvements

- Investigate and reduce remaining maximum-slew violations.
- Explore memory-macro-based FIFO implementation.
- Improve area and timing through RTL and physical-design optimization.
- Evaluate additional implementation constraints and configurations.

## Acknowledgements

This project uses the open-source SkyWater SKY130A PDK and the LibreLane/OpenROAD ecosystem.

The implementation is intended for educational and engineering-learning purposes. It is not a claim of commercial foundry signoff.
