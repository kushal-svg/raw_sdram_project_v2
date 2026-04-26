Raw SDRAM Controller and Memory Tester for DE10-Lite

This project is a custom raw SDRAM controller and hardware memory test system built in SystemVerilog for the Terasic DE10-Lite FPGA board. The design interfaces directly with the onboard SDRAM without using vendor memory IP, and includes the control, verification, and display logic needed to test memory behavior on hardware.

Project overview

The goal of this project is to design and integrate a working SDRAM subsystem on FPGA, including both the low-level memory controller and a top-level test engine. The controller handles SDRAM initialization, refresh timing, and command sequencing, while the top-level logic performs repeatable write and read/verify tests across memory and reports results through onboard LEDs and 7-segment displays.

Project files
sdram_controller.sv — raw SDRAM controller implemented as an FSM
comprehensive_tb.sv — top-level memory test and verification system
debounce_explicit.sv — push-button debouncing logic
bin2bcd.sv — binary-to-BCD conversion for decimal error display
LED_mux.sv — six-digit 7-segment display driver
constraints/de10_lite_raw_sdram.qsf — Quartus pin assignments for DE10-Lite
constraints/de10_lite_raw_sdram.sdc — timing constraints for 50 MHz operation
Features

This project implements:

SDRAM initialization after reset
periodic refresh scheduling
raw SDRAM command sequencing using:
ACTIVATE
READ
WRITE
PRECHARGE
REFRESH
deterministic full-memory write testing
deterministic full-memory readback and verification
error counting and display on the six onboard 7-segment displays
button-controlled test execution and LED-based hardware status monitoring
How it works

The system is divided into two main parts:

1. SDRAM controller

The SDRAM controller translates simple FPGA-side requests into the low-level command and timing behavior required by SDRAM. It manages:

power-up initialization
mode register loading
periodic refresh operations
row activation and precharge timing
burst read and burst write transactions
bidirectional SDRAM data bus control
2. Top-level memory tester

The top-level tester drives the controller through a full-memory test flow. It:

starts write or read/verify tests using push buttons
generates deterministic test patterns based on page and burst index
compares readback data against expected values
counts mismatches
displays error totals and live status using LEDs and 7-segment displays
Board controls
Switches
SW[9] — global run/reset control
1 = run
0 = reset
SW[0] — optional error injection during write test
Push buttons
KEY[0] — start full-memory write test
KEY[1] — start full-memory read/verify test
LED status indicators
LEDR[9] — SDRAM controller ready
LEDR[8] — debounced KEY[0] level
LEDR[7] — debounced KEY[1] level
LEDR[6] — write test active
LEDR[5] — read/verify test active
LEDR[4] — error flag (error_count != 0)
LEDR[3:0] — low bits of current memory page
Engineering notes

This project was built as a raw memory-controller design rather than an IP-based memory interface. The focus was on understanding and implementing the actual SDRAM protocol and integrating it into a complete FPGA test system.

The current version is structured for Quartus and the DE10-Lite, using a conservative 50 MHz direct SDRAM clock path for simpler bring-up. Depending on board behavior and timing closure, the SDRAM clock relationship may still need tuning for fully robust hardware operation.

Quartus setup
Create a Quartus project targeting device 10M50DAF484C7G
Add all RTL files from the rtl/ directory
Include constraints/de10_lite_raw_sdram.qsf
Add constraints/de10_lite_raw_sdram.sdc
Set the top-level entity to comprehensive_tb
Compile the project
Program the .sof file over JTAG
What this project demonstrates

This project demonstrates:

FPGA-based memory-controller design
finite state machine implementation
timing-aware external memory interfacing
board-level system integration in Quartus
hardware test and verification methodology
real-time debugging using LEDs and 7-segment displays
