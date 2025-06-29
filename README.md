# sobel-filter-verilog
This project implements an 4-direction Sobel edge detection filter using Verilog HDL, supporting grayscale BMP image input/output.


## Overview


This project implements a complete image processing pipeline in Verilog featuring:

Line Buffer Management: Circular buffer system for streaming image data

4-Direction Sobel Edge Detection: Enhanced edge detection using 0°, 45°, 90°, and 135° kernels


Pipelined Architecture: Multi-stage pipeline for high-throughput processing



## Key Components

imageControl: Manages line buffers and generates 3x3 pixel windows.


lineBuffer: Stores image lines and outputs 3-pixel windows.


sobel_4direction: Performs 4-direction Sobel convolution with pipelining.


imageProcessTop: Top-level module with AXI4-Stream output buffering.


outputBuffer: AXI4-Stream FIFO providing flow control and standard interface.


## Technical Specifications

Input: 8-bit grayscale pixels.

Output: Binary edge map (8-bit values: 0x00 or 0xFF).

Image Width: 512 pixels per line.

Processing Window: 3x3 pixel neighborhood.

Clock Domain: Single clock design.



## Module Description

### imageControl

Manages 4 line buffers in circular fashion

Generates 72-bit output containing 3x3 pixel window

Implements state machine for buffer management

Provides interrupt signaling for processing completion

### sobel_4direction

Implements 4 different Sobel kernels for comprehensive edge detection

4-stage pipeline: Multiplication → Summation → Absolute Value → Maximum Selection

Configurable threshold for edge/non-edge classification
Outputs binary edge map

### lineBuffer

Stores 512 pixels per line
Provides 3 consecutive pixels for window generation
Dual-port operation with independent read/write pointers
