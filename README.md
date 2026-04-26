# 💾 Raw SDRAM Controller and Memory Tester (DE10-Lite)

## 📌 Overview

This project implements a **raw SDRAM controller** and **hardware memory test system** on the **DE10-Lite FPGA board** using **SystemVerilog**.

Instead of relying on vendor-generated memory IP, this design directly interfaces with the onboard SDRAM and handles the actual SDRAM protocol in hardware, including initialization, refresh operations, burst transfers, and low-level command sequencing.

The project is built as a modular FPGA system that combines:

- low-level SDRAM control  
- top-level memory testing and verification  
- push-button input handling  
- LED status monitoring  
- seven-segment error display  

This makes the project more than just a memory demo — it acts as a reusable **external memory subsystem** for larger FPGA applications that need buffering or temporary storage.

---

## 🚀 Features

- Raw SDRAM controller written in SystemVerilog  
- SDRAM initialization after reset  
- Periodic SDRAM refresh scheduling  
- ACTIVATE / READ / WRITE / PRECHARGE / REFRESH command sequencing  
- Burst-based read and write transfers  
- Full-memory write test  
- Full-memory readback and verification test  
- Error counting in hardware  
- Error display on six onboard 7-segment displays  
- Push-button controlled test execution  
- LED-based live status monitoring  
- Optional fault injection for validation testing  

---

## 🏗️ System Architecture

The design is divided into two major parts:

### 1. 💡 SDRAM Controller
This is the low-level memory interface engine. It translates simple FPGA-side read/write requests into the strict command and timing behavior required by SDRAM.

It handles:

- power-up wait timing  
- startup precharge sequence  
- initialization refresh cycles  
- mode register loading  
- runtime refresh operations  
- row activation and bank selection  
- burst read and burst write transactions  
- bidirectional SDRAM data bus control  

---

### 2. 🧪 Memory Test and Verification Engine
This is the top-level system that tests the SDRAM controller in hardware.

It performs:

- deterministic full-memory write testing  
- deterministic full-memory readback verification  
- mismatch/error detection  
- page-by-page burst transfers  
- LED and display-based hardware reporting  

This layer turns the SDRAM controller into a complete **hardware bring-up and debugging platform**.

---

## 📂 Project Files

- `sdram_controller.sv` — raw SDRAM controller implemented as an FSM  
- `comprehensive_tb.sv` — top-level memory test and verification system  
- `debounce_explicit.sv` — push-button debounce logic  
- `bin2bcd.sv` — binary-to-BCD converter for decimal error display  
- `LED_mux.sv` — six-digit 7-segment display driver  
- `constraints/de10_lite_raw_sdram.qsf` — Quartus pin assignments  
- `constraints/de10_lite_raw_sdram.sdc` — 50 MHz timing constraints  

---

## 🎛️ Board Controls

### Switches
- `SW[9]` → Global run/reset control  
  - `1` = run  
  - `0` = reset  

- `SW[0]` → Inject intentional write errors into selected pages  

### Push Buttons
- `KEY[0]` → Start full-memory **WRITE** test  
- `KEY[1]` → Start full-memory **READ / VERIFY** test  

---

## 💡 LED Status Indicators

- `LEDR[9]` → SDRAM controller ready  
- `LEDR[8]` → Debounced `KEY[0]` level  
- `LEDR[7]` → Debounced `KEY[1]` level  
- `LEDR[6]` → Write test active  
- `LEDR[5]` → Read/verify test active  
- `LEDR[4]` → Error flag (`error_count != 0`)  
- `LEDR[3:0]` → Low bits of current memory page  

---

## 🔢 7-Segment Display

The six onboard 7-segment displays show the current **memory error count** in decimal.

This makes it easy to check whether the memory test passed or failed directly on hardware without needing external debugging tools.

---

## 🧠 Why This Project Matters

Most FPGA projects begin with small on-chip memories, but real systems often need much more storage.

This project solves that by creating a reusable **external memory controller** that can support larger systems such as:

- 🎥 video frame buffers  
- 📷 image and vision pipelines  
- 📡 streaming DSP systems  
- 📊 sensor-data capture and logging  
- ⚡ FPGA accelerators that need larger temporary storage  

So while this project includes a built-in tester, the controller itself can also serve as a foundation for real FPGA systems that need high-capacity off-chip memory.

---

## 🛠️ Quartus Setup

1. Create a Quartus project targeting device `10M50DAF484C7G`  
2. Add all RTL files from the `rtl/` directory  
3. Include `constraints/de10_lite_raw_sdram.qsf`  
4. Add `constraints/de10_lite_raw_sdram.sdc`  
5. Set the top-level entity to `comprehensive_tb`  
6. Compile the design  
7. Program the `.sof` file over JTAG  

---

## ⚠️ Engineering Notes

- This project uses a **raw SDRAM-controller approach** instead of vendor IP  
- The focus is on understanding and implementing the actual SDRAM protocol directly  
- The current design uses a **conservative 50 MHz direct SDRAM clock path** for simpler bring-up  
- Depending on real hardware timing margins, SDRAM clock tuning may still be needed for more robust operation  

---

## 🔮 Possible Extensions

This project can be extended into larger FPGA systems such as:

- VGA framebuffer engine  
- image buffer for computer vision  
- sensor sample logger  
- external working memory for DSP pipelines  
- memory subsystem for FPGA accelerators  

---

