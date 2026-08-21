# UART-SPI Communication Peripheral

A modular **UART-to-SPI communication peripheral** implemented in synthesizable SystemVerilog. The design receives commands over UART, performs an SPI transaction, and sends the SPI response back through UART.

## Features

* Parameterized system clock, UART baud rate, and SPI clock frequency
* UART TX/RX with **8N1** configuration
* UART baud-rate generation
* SPI Master supporting **Mode 0 (CPOL=0, CPHA=0)**
* 8-bit **MSB-first** SPI transfers
* FSM-based UART-SPI control logic
* Self-checking simulation testbenches
* Synthesizable RTL verified using Vivado

## Project Structure

```text
UART-SPI-Peripheral/
│
├── rtl/
│   ├── baud_generator.sv
│   ├── uart_tx.sv
│   ├── uart_rx.sv
│   ├── spi_master.sv
│   ├── uart_spi_controller.sv
│   └── uart_spi_top.sv
│
├── tb/
│   ├── baud_generator_tb.sv
│   ├── uart_tx_tb.sv
│   ├── uart_rx_tb.sv
│   ├── spi_master_tb.sv
│   ├── uart_spi_controller_tb.sv
│   └── uart_spi_top_tb.sv
│
├── constraints/
│   └── uart_spi_top.xdc
│
├── waveforms/
├── spi_master_waveform.png
│   ├── top_level_integration.png
│   ├── top_level_integration_detailed.png
│   ├── uart_rx_waveform.png
│   ├── uart_spi_controller_waveform.png
│   └── uart_tx_waveform.png
│
├── README.md
└── .gitignore
```

## Architecture

```text
                UART
                  │
          ┌───────┴───────┐
          │               │
       UART RX         UART TX
          │               ▲
          ▼               │
   UART-SPI Controller ───┘
          │
          ▼
      SPI Master
          │
    ┌─────┼─────┐
    │     │     │
   MOSI  MISO  SCLK
          │
         CS
```

## Communication Flow

The peripheral uses a simple command format:

```text
[COMMAND] [SPI DATA]
```

Currently, command `0x01` triggers a single SPI transfer: the controller sends the given data byte over SPI, captures the response, and transmits it back over UART.

## Protocol Configuration

### UART

```text
Baud Rate : 115200
Format    : 8N1
Data Bits : 8
Parity    : None
Stop Bits : 1
```

### SPI

```text
Mode      : 0
CPOL      : 0
CPHA      : 0
Frequency : 1 MHz
Width     : 8-bit
Order     : MSB first
```

## Synthesis Results

Target FPGA:

```text
Xilinx Artix-7 XC7A35T
Device: xc7a35tcpg236-1
```

Synthesis results:

| Resource   | Usage |
| ---------- | ----: |
| LUTs       |   185 |
| Flip-Flops |   196 |
| BRAM       |     0 |
| DSP        |     0 |
| I/O        |     8 |

### Timing

The design was constrained for a **100 MHz system clock (10 ns period)**.

```text
Worst Negative Slack (WNS) : +5.321 ns
Total Negative Slack (TNS)  : 0.000 ns
Worst Hold Slack (WHS)     : +0.142 ns
Total Hold Slack (THS)     : 0.000 ns
Failing Endpoints           : 0
```

All specified timing constraints were met.

## Tools

* SystemVerilog
* Xilinx Vivado 2017.4
* Vivado XSim
