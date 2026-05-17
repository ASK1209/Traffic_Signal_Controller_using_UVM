# Traffic Signal Controller Verification using SystemVerilog UVM

## Project Overview

This project implements and verifies a **Traffic Signal Controller** using **SystemVerilog UVM methodology**.

Link : https://www.edaplayground.com/x/mDaS

The RTL design models a basic traffic light controller with three states:

- RED
- GREEN
- YELLOW

The controller changes states based on fixed timer values. A complete UVM-based verification environment is developed to verify reset behavior, enable behavior, state transitions, output correctness, and functional coverage.

The project includes:

- RTL design of Traffic Signal Controller
- SystemVerilog interface with clocking blocks
- UVM testbench architecture
- Configuration class
- Sequence item
- Directed and random sequences
- Driver
- Monitor
- Agent
- Environment
- Scoreboard
- Functional coverage
- Assertions
- Simulation result and coverage report

---

## DUT Description

The DUT is a finite state machine based traffic signal controller.

### States

| State | Encoding | Active Output |
|------|----------|---------------|
| RED | `2'b00` | `red = 1` |
| GREEN | `2'b01` | `green = 1` |
| YELLOW | `2'b10` | `yellow = 1` |

---

## DUT Interface Signals

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | Input | 1-bit | System clock |
| `rst_n` | Input | 1-bit | Active-low reset |
| `enable` | Input | 1-bit | Enables timer and state transition |
| `light` | Output | 2-bit | Encoded traffic light state |
| `red` | Output | 1-bit | RED light output |
| `green` | Output | 1-bit | GREEN light output |
| `yellow` | Output | 1-bit | YELLOW light output |

---

## State Timing

The traffic signal controller uses fixed timing values for each state.

| State | Duration |
|------|----------|
| RED | 30 clock cycles |
| GREEN | 25 clock cycles |
| YELLOW | 5 clock cycles |

Expected state transition flow:

```text
RED -> GREEN -> YELLOW -> RED
```

---

## RTL Design Features

The RTL design includes:

- FSM-based traffic light control
- Enumerated state encoding using `typedef enum`
- Timer-based state transition logic
- Active-low asynchronous reset
- Enable-controlled timer and state update
- Safe output logic using `unique case`
- Default output assignment to avoid unknown output values
- Separate logic blocks for:
  - Timer
  - Timer done generation
  - State register
  - Next-state logic
  - Output logic

---

## State Diagram

```text
             RED_TIME completed
        +-------------------------+
        |                         v
    +---+---+                 +---+-----+
    |  RED  |                 |  GREEN  |
    +---+---+                 +---+-----+
        ^                         |
        |                         |
        |                         | GREEN_TIME completed
        |                         v
    +---+------+            +-----+------+
    |  RED     | <----------|  YELLOW   |
    +----------+  YELLOW_TIME completed
```

Simplified flow:

```text
+-------+      +---------+      +----------+
| RED   | ---> | GREEN   | ---> | YELLOW   |
+-------+      +---------+      +----------+
    ^                              |
    |                              |
    +------------------------------+
```

---

## UVM Testbench Architecture

```text
+-----------------------------------------------------------+
|                         UVM Test                          |
|                                                           |
|  +-----------------------------------------------------+  |
|  |                    Full Sequence                    |  |
|  |-----------------------------------------------------|  |
|  | Reset Sequence                                      |  |
|  | Directed Sequence                                   |  |
|  | Enable Sequence                                     |  |
|  | Enable Coverage Sequence                            |  |
|  | Reset Coverage Sequence                             |  |
|  | Random Sequence                                     |  |
|  +--------------------------+--------------------------+  |
|                             |                             |
|                             v                             |
|                      +-------------+                      |
|                      | Sequencer   |                      |
|                      +------+------+                      |
|                             |                             |
|                             v                             |
|                      +-------------+                      |
|                      | Driver      |                      |
|                      +------+------+                      |
|                             |                             |
+-----------------------------|-----------------------------+
                              |
                              v
                      +---------------+
                      | Interface     |
                      +-------+-------+
                              |
                              v
                      +---------------+
                      | DUT           |
                      | Traffic Signal|
                      | Controller    |
                      +-------+-------+
                              |
                              v
                      +---------------+
                      | Monitor       |
                      +-------+-------+
                              |
                              v
                      +---------------+
                      | Scoreboard    |
                      | + Coverage    |
                      +---------------+
```

---

## UVM Components

### 1. Interface

The SystemVerilog interface connects the DUT and UVM testbench.

It contains:

- DUT input/output signals
- Driver clocking block
- Monitor clocking block
- Driver modport
- Monitor modport
- Assertions for protocol and output checking

---

### 2. Configuration Class

The configuration class stores testbench configuration information.

It includes:

- Active/passive agent setting
- Virtual interface handle
- RED timing value
- GREEN timing value
- YELLOW timing value

Example fields:

```systemverilog
uvm_active_passive_enum is_active;
virtual tsc_if vif;

int unsigned red_time;
int unsigned green_time;
int unsigned yellow_time;
```

---

### 3. Sequence Item

The sequence item represents one transaction driven to the DUT.

It contains:

```systemverilog
rand logic rst_n;
rand logic enable;

logic [1:0] light;
logic       red;
logic       green;
logic       yellow;
```

The driver uses `rst_n` and `enable`.

The monitor samples:

- `rst_n`
- `enable`
- `light`
- `red`
- `green`
- `yellow`

---

### 4. Sequences

The testbench includes multiple sequences to verify different scenarios.

#### Reset Sequence

Applies reset and brings the DUT to a known RED state.

#### Directed Sequence

Runs the DUT through normal traffic light operation.

Expected sequence:

```text
RED -> GREEN -> YELLOW -> RED
```

#### Enable Sequence

Checks the behavior when `enable` is toggled.

When `enable = 0`, the DUT should hold/freeze its current state.

#### Enable Coverage Sequence

Targets enable-related functional coverage by driving enable low in different traffic light states.

#### Reset Coverage Sequence

Applies reset in different states to improve reset cross coverage.

#### Random Sequence

Generates random reset and enable values to stress the DUT and improve coverage.

#### Full Sequence

The full sequence runs all major sequences together.

```text
Reset Sequence
      ↓
Directed Sequence
      ↓
Enable Sequence
      ↓
Enable Coverage Sequence
      ↓
Reset Coverage Sequence
      ↓
Random Sequence
```

---

## Driver

The driver receives sequence items from the sequencer and drives DUT inputs through the virtual interface.

The driver drives:

- `rst_n`
- `enable`

---

## Monitor

The monitor samples DUT input and output signals through the virtual interface.

The monitor observes:

- `rst_n`
- `enable`
- `light`
- `red`
- `green`
- `yellow`

The sampled transaction is sent to the scoreboard using an analysis port.

---

## Agent

The agent contains:

- Sequencer
- Driver
- Monitor

The agent is configured as an active agent using the configuration class.

---

## Environment

The environment contains:

- Agent
- Scoreboard

The monitor analysis port is connected to the scoreboard analysis FIFO.

```text
monitor.ap -> scoreboard.sb_fifo.analysis_export
```

---

## Scoreboard

The scoreboard performs functional checking and coverage collection.

### Scoreboard Checks

The scoreboard verifies:

- Reset behavior
- One-hot traffic light output
- Correct `light` encoding
- Correct RED output
- Correct GREEN output
- Correct YELLOW output
- Correct state transitions
- Correct enable behavior
- Illegal state detection
- X/Z filtering before checking
- State freeze behavior when enable is low

---

## Assertions

The interface includes assertions for additional checking.

Assertions include:

- One-hot traffic light output
- Valid `light` encoding
- `light` output matching `red`, `green`, and `yellow`
- No X/Z on `light` after reset
- State should freeze when `enable = 0`
- RED should transition to GREEN
- GREEN should transition to YELLOW
- YELLOW should transition to RED

---

## Functional Coverage

Functional coverage is collected inside the scoreboard.

### Covergroups

| Covergroup | Description |
|-----------|-------------|
| `cg_states` | Covers RED, GREEN, and YELLOW states |
| `cg_rst` | Covers reset asserted and deasserted |
| `cg_enable` | Covers enable high and enable low |
| `cg_transitions` | Covers RED→GREEN, GREEN→YELLOW, and YELLOW→RED transitions |
| `cg_state_x_enable` | Cross coverage between state and enable |
| `cg_state_x_rst` | Cross coverage between state and reset |
| `cg_rst_in_state` | Reset behavior in different state scenarios |
| `cg_enable_in_state` | Enable behavior in different state scenarios |

---

## Simulation Result

The final simulation completed successfully.

```text
==========================================
  SCOREBOARD SUMMARY
  PASS         : 459
  FAIL         : 0
  RESET COUNT  : 201
==========================================
*** ALL CHECKS PASSED ***
```

---

## Functional Coverage Result

The final functional coverage result reached 100% for all covergroups.

```text
==========================================
  FUNCTIONAL COVERAGE REPORT
  cg_states          : 100.00%
  cg_rst             : 100.00%
  cg_enable          : 100.00%
  cg_transitions     : 100.00%
  cg_state_x_enable  : 100.00%
  cg_state_x_rst     : 100.00%
  cg_rst_in_state    : 100.00%
  cg_enable_in_state : 100.00%
==========================================
```

---

## UVM Report Summary

```text
UVM_INFO    : 425
UVM_WARNING : 0
UVM_ERROR   : 0
UVM_FATAL   : 0
```

---

## Waveform

The testbench generates a VCD waveform file:

```text
tsc_tb.vcd
```

This waveform can be viewed using EPWave or any VCD-supported waveform viewer.

---

## Repository Structure

Suggested GitHub repository structure:

```text
traffic-signal-controller-uvm/
│
├── rtl/
│   └── traffic_signal_controller.sv
│
├── tb/
│   ├── tsc_if.sv
│   ├── tsc_config.sv
│   ├── tsc_item.sv
│   ├── tsc_sequences.sv
│   ├── tsc_driver.sv
│   ├── tsc_monitor.sv
│   ├── tsc_scoreboard.sv
│   ├── tsc_agent.sv
│   ├── tsc_env.sv
│   ├── tsc_test.sv
│   └── tsc_tb_top.sv
│
├── sim/
│   └── run.do
│
├── waveform/
│   └── tsc_tb.vcd
│
├── README.md
└── LICENSE
```

If using EDA Playground with single-file style:

```text
traffic-signal-controller-uvm/
│
├── design.sv
├── testbench.sv
├── README.md
└── LICENSE
```

---

## How to Run

### Option 1: Run on EDA Playground

1. Open EDA Playground.
2. Select SystemVerilog as the language.
3. Enable UVM library support.
4. Place RTL code in `design.sv`.
5. Place UVM testbench code in `testbench.sv`.
6. Select a simulator that supports SystemVerilog and UVM.
7. Run the simulation.
8. View the transcript and waveform.

Recommended simulators:

```text
Aldec Riviera-PRO
QuestaSim
Synopsys VCS
Cadence Xcelium
```

---

### Option 2: Run Locally

Example command format:

```bash
vlog design.sv testbench.sv
vsim tsc_tb_top
run -all
```

The exact command may vary depending on the simulator.

---

## Tools Used

- SystemVerilog
- UVM
- Functional Coverage
- SystemVerilog Assertions
- Scoreboard-based verification
- EDA Playground
- EPWave / VCD waveform viewer

---

## Key Verification Scenarios

The following scenarios are verified:

- Reset assertion
- Reset release
- Normal RED to GREEN transition
- Normal GREEN to YELLOW transition
- Normal YELLOW to RED transition
- Enable high operation
- Enable low state freeze behavior
- Reset during different states
- Enable behavior in different states
- Random reset and enable combinations
- Functional coverage closure
- Assertion-based protocol checking

---

## Key Concepts Demonstrated

This project demonstrates:

- FSM-based RTL design
- UVM testbench development
- Virtual interface usage
- UVM configuration database
- Active UVM agent
- Sequence and sequencer communication
- Driver and monitor implementation
- Analysis port communication
- Scoreboard-based checking
- Functional coverage and cross coverage
- Assertion-based verification
- Coverage-driven verification
- Debugging using simulation logs and waveforms

---

## Author

**Ahalya S Kumar**

Aspiring Design Verification Engineer  
Skills: SystemVerilog, UVM, SVA, Functional Coverage, RTL Verification

GitHub: https://github.com/ASK1209

---

## License

This project is open-source and available under the MIT License.
