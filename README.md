# Raw SDRAM Controller Project for DE10-Lite

This project mirrors the structure of the GitHub SDRAM controller project the user studied:

- `sdram_controller.sv` — raw SDRAM controller FSM
- `comprehensive_tb.sv` — top-level memory test/demo
- `debounce_explicit.sv` — button debounce helper
- `bin2bcd.sv` — binary-to-BCD converter for error display
- `LED_mux.sv` — six-digit 7-segment output formatter
- `constraints/de10_lite_raw_sdram.qsf` — Quartus pin assignments
- `constraints/de10_lite_raw_sdram.sdc` — 50 MHz clock constraint

## Project concept

This project implements a **raw SDRAM controller** in SystemVerilog on the DE10-Lite board.
It performs:

1. SDRAM initialization after reset
2. periodic SDRAM refresh
3. ACTIVATE / READ / WRITE / PRECHARGE sequencing
4. a deterministic full-memory write test
5. a deterministic full-memory read-and-verify test
6. error counting displayed on the six onboard 7-segment displays

## Top-level usage

- `SW[9]` = global run/reset enable
  - `1` => run
  - `0` => reset controller/tester
- `KEY[0]` = start full-memory WRITE test
- `KEY[1]` = start full-memory READ/VERIFY test
- `SW[0]` = inject intentional errors into two pages during write test

## LEDs

- `LEDR[9]` = controller ready
- `LEDR[8]` = debounced KEY0 level
- `LEDR[7]` = debounced KEY1 level
- `LEDR[6]` = write test active
- `LEDR[5]` = read test active
- `LEDR[4]` = error flag (nonzero error count)
- `LEDR[3:0]` = low bits of current page index

## Important engineering note

This is a raw controller project intended for learning and project/resume use.
It is structured for DE10-Lite and Quartus, but the exact SDRAM clock relationship may still need tuning on real hardware.
The current version uses a conservative direct 50 MHz SDRAM clock path to maximize bring-up simplicity.

## Quartus steps

1. Create a Quartus project for device `10M50DAF484C7G`
2. Add all RTL files under `rtl/`
3. Import or include `constraints/de10_lite_raw_sdram.qsf`
4. Add `constraints/de10_lite_raw_sdram.sdc`
5. Set top-level entity to `comprehensive_tb`
6. Compile
7. Program `.sof` over JTAG

## Resume wording suggestion

**Raw SDRAM Controller and Memory Tester — SystemVerilog, Intel MAX 10, Quartus**
- Designed a raw SDRAM controller for the DE10-Lite FPGA board implementing initialization, refresh scheduling, and ACTIVATE/READ/WRITE/PRECHARGE command sequencing.
- Built a top-level full-memory test engine that writes deterministic patterns, reads them back, verifies correctness, and displays error counts on onboard 7-segment displays.
- Integrated board-level push-button control, status LEDs, and DE10-Lite SDRAM pin constraints in Quartus for hardware bring-up.
