Raw SDRAM Controller and Buffering Subsystem for DE10-Lite

Overview

This project implements a custom raw SDRAM controller and hardware memory test platform in SystemVerilog for the Terasic DE10-Lite FPGA board. Instead of relying on vendor memory IP, this design directly interfaces with the onboard SDRAM and manages the low-level protocol required for external memory operation.

At its core, this project is not just a memory test. It is an external-memory subsystem that can serve as the foundation for FPGA systems that need more storage than on-chip memory can provide. In real designs, this type of controller can be used as a buffering and temporary storage layer for data-intensive applications such as video pipelines, sensor capture systems, signal-processing hardware, embedded display systems, and streaming accelerators.

Why This Project Matters

Most FPGA designs start with small internal memories, but real systems quickly outgrow them. When an application needs to store large amounts of temporary data — such as image frames, ADC samples, communication packets, or intermediate processing results — external memory becomes necessary.

This project solves that problem by providing a raw SDRAM interface that allows custom FPGA logic to:

- write large blocks of data into external memory
- read large blocks of data back
- maintain SDRAM contents through periodic refresh
- control burst transfers efficiently
- verify memory correctness directly on hardware

In practical terms, this controller can act as the memory backbone for:

- frame buffers in VGA or display systems
- image and video buffering in vision pipelines
- burst-data storage in sensor logging systems
- working memory for FPGA accelerators
- temporary storage in streaming DSP and communication systems

Project Goals

The goal of this project is to design and integrate a complete external-memory subsystem on FPGA, including both the low-level SDRAM controller and a board-level hardware verification environment.

This project includes:

- a raw SDRAM controller implemented as a finite state machine
- SDRAM initialization and mode register programming
- refresh scheduling and maintenance logic
- ACTIVATE / READ / WRITE / PRECHARGE / REFRESH command sequencing
- burst-based memory access
- a top-level memory verification engine
- visible hardware debug through LEDs and 7-segment displays

Project Structure

- sdram_controller.sv  
  Raw SDRAM controller implemented as an FSM. Handles initialization, refresh timing, command generation, burst transfers, and bidirectional SDRAM data bus control.

- comprehensive_tb.sv  
  Top-level memory test and verification system. Starts write/read tests, generates known data patterns, compares readback results, and reports errors.

- debounce_explicit.sv  
  Debounces push-button inputs for reliable user control.

- bin2bcd.sv  
  Converts the binary error counter into decimal digits for display.

- LED_mux.sv  
  Drives the six onboard 7-segment displays.

- constraints/de10_lite_raw_sdram.qsf  
  Quartus pin assignments for the DE10-Lite board.

- constraints/de10_lite_raw_sdram.sdc  
  Clock and timing constraints for 50 MHz operation.

System Architecture

The design is divided into two major layers:

1. Raw SDRAM Controller

The SDRAM controller translates simple FPGA-side requests into the exact low-level command and timing behavior expected by the SDRAM device. It manages:

- startup delay and initialization sequence
- PRECHARGE-ALL at startup
- initialization refresh cycles
- mode register loading
- periodic runtime refresh
- row activation and timing delays
- burst read transactions
- burst write transactions
- bidirectional control of the SDRAM data bus

This block is the reusable external-memory engine of the project.

2. Memory Test and Verification Layer

The top-level tester uses the controller to perform full-memory write and readback verification. It:

- launches write and read tests from board buttons
- writes deterministic page-based data patterns into SDRAM
- reads them back and compares each word against the expected pattern
- counts mismatches
- reports test progress and results through LEDs and 7-segment displays

This layer turns the memory controller into a complete hardware bring-up and validation system.

Real-World Use Cases

Although this project includes a built-in memory tester, the controller itself is meant to be reusable in larger systems. In real FPGA development, a subsystem like this would typically sit between custom logic and off-chip memory.

Examples of how this design can be extended into real applications include:

Video and Display Buffering
A VGA or display engine can use SDRAM as a frame buffer, storing image data in external memory and reading it back continuously for display output.

Sensor and Data Logging
A sensor capture block can write incoming samples into SDRAM for later processing, compression, or transfer.

Streaming DSP Systems
Digital signal-processing hardware can store intermediate data in SDRAM when the working set is too large for block RAM.

Image and Vision Pipelines
Image-processing stages can use SDRAM to hold frames, tiles, feature maps, or temporary results.

FPGA Accelerators
Custom compute hardware can use SDRAM as external working memory for bulk input/output storage.

Board Controls

Switches
- SW[9] = global run/reset control  
  - 1 = run
  - 0 = reset
- SW[0] = inject intentional write errors into selected pages for validation testing

Push Buttons
- KEY[0] = start full-memory write test
- KEY[1] = start full-memory read/verify test

LED Indicators
- LEDR[9] = SDRAM controller ready
- LEDR[8] = debounced KEY[0] level
- LEDR[7] = debounced KEY[1] level
- LEDR[6] = write test active
- LEDR[5] = read/verify test active
- LEDR[4] = error flag
- LEDR[3:0] = low bits of current memory page

7-Segment Display
- Displays the memory error count in decimal

Engineering Notes

This project intentionally uses a raw memory-controller approach rather than vendor-provided IP. The objective is to understand and implement the SDRAM protocol directly, including timing management, refresh scheduling, burst transfers, and external-bus control.

The current version is structured for Quartus and the DE10-Lite board using a conservative 50 MHz direct SDRAM clock path to simplify initial bring-up and debugging. Depending on real hardware timing margins, SDRAM clock phase alignment may require further tuning for more robust operation.

What This Project Demonstrates

This project demonstrates practical FPGA design skills in:

- external memory-controller design
- finite state machine implementation
- timing-aware hardware sequencing
- integration of custom logic with off-chip SDRAM
- burst-based data movement
- board-level verification and debugging
- hardware test methodology
- building reusable memory infrastructure for larger systems

Quartus Setup

1. Create a Quartus project targeting device 10M50DAF484C7G
2. Add all RTL files from the rtl/ directory
3. Include constraints/de10_lite_raw_sdram.qsf
4. Add constraints/de10_lite_raw_sdram.sdc
5. Set the top-level entity to comprehensive_tb
6. Compile the design
7. Program the .sof file over JTAG

Resume-Friendly Project Summary

Raw SDRAM Controller and Buffering Subsystem — SystemVerilog, Quartus, Intel MAX 10 (DE10-Lite)

Designed a custom raw SDRAM controller for the DE10-Lite FPGA board implementing initialization, refresh scheduling, and ACTIVATE/READ/WRITE/PRECHARGE command sequencing without vendor memory IP. Built a top-level verification platform that writes deterministic patterns to external memory, reads them back, detects mismatches, and displays live results on onboard LEDs and 7-segment displays. Structured the design as a reusable external-memory subsystem suitable for data buffering in video, sensor, DSP, and accelerator-based FPGA systems.
