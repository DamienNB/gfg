// This module lays out both the datapath and control logic of the frame
// buffer system of the GFG-MCU
// While one frame is being rasterized, the previous completed frame is 
// available.
// The goal is to abstract the frame buffer control logic from the
// rasterization process and the modules that deliver a frame to displays
// Internally, there are two frame buffers. When one a frame is finished and
// enough time has passed, the frame buffers will trade places.
// The frame buffer swap is controlled externally by another module which
// provides the i_rasterization_target signal

`define CLOG2(x) \
((x <= 1) || (x > 16777216)) ? 0 : \
(x <= 2) ? 1 : \
(x <= 4) ? 2 : \
(x <= 8) ? 3 : \
(x <= 16) ? 4 : \
(x <= 32) ? 5 : \
(x <= 64) ? 6 : \
(x <= 128) ? 7 : \
(x <= 256) ? 8 : \
(x <= 512) ? 9 : \
(x <= 1024) ? 10 : \
(x <= 2048) ? 11 : \
(x <= 4096) ? 12 : \
(x <= 8192) ? 13 : \
(x <= 16384) ? 14 : \
(x <= 32768) ? 15 : \
(x <= 65536) ? 16 : \
(x <= 131072) ? 17 : \
(x <= 262144) ? 18 : \
(x <= 1048576) ? 20 : \
(x <= 2097152) ? 21 : \
(x <= 4194304) ? 22 : \
(x <= 8388608) ? 23 : \
(x <= 16777216) ? 24 : 0

module frame_buffers_datapath #(
  parameter VERT_RESOLUTION  = 60,
            HORIZ_RESOLUTION = 80,
            COLOR_DEPTH      = 12,
            Z_DEPTH          =  2,
            VIVADO_ENV       =  0
) (
// general inputs
  input wire i_sys_clk,
  input wire i_vga_clk,
// input from controller
  input wire i_rasterization_target,
// inputs from rasterizer
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_rasterizer_vert_write_addr,
  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_rasterizer_horiz_write_addr,
  input wire                                i_rasterizer_write_en,
  input wire [(COLOR_DEPTH+Z_DEPTH)-1:0]    i_rasterizer_write_pixel_data,
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_rasterizer_vert_read_addr,
  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_rasterizer_horiz_read_addr,
// inputs from display output
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_vga_vert_read_addr,
  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_vga_horiz_read_addr,
// outputs to rasterizer
  output wire [(COLOR_DEPTH+Z_DEPTH)-1:0] o_rasterizer_read_pixel_data,
// output to display output
  output wire [(COLOR_DEPTH+Z_DEPTH)-1:0] o_vga_read_pixel_data
  );

  localparam FRAME_BUFFER_WIDTH = COLOR_DEPTH + Z_DEPTH;

// Frame Buffer 0 setup
  wire frame_buffer_0_write_clk;
  wire frame_buffer_0_write_en;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_0_write_addr;
  wire [FRAME_BUFFER_WIDTH-1:0] frame_buffer_0_data_in;

  wire frame_buffer_0_read_clk;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_0_read_addr;
  wire [FRAME_BUFFER_WIDTH-1:0] frame_buffer_0_data_out;

  ram_dual_port #(
    .DEPTH(VERT_RESOLUTION*HORIZ_RESOLUTION),
    .WIDTH(FRAME_BUFFER_WIDTH),
    .VIVADO_ENV(VIVADO_ENV)
  ) frame_buffer_0 (
    .write_clk(frame_buffer_0_write_clk),
    .write_en(frame_buffer_0_write_en),
    .write_addr(frame_buffer_0_write_addr),
    .data_in(frame_buffer_0_data_in),

    .read_clk(frame_buffer_0_read_clk),
    .read_addr(frame_buffer_0_read_addr),
    .data_out(frame_buffer_0_data_out)
  );

// Frame Buffer 1 setup
  wire frame_buffer_1_write_clk;
  wire frame_buffer_1_write_en;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_1_write_addr;
  wire [FRAME_BUFFER_WIDTH-1:0]     frame_buffer_1_data_in;

  wire frame_buffer_1_read_clk;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_1_read_addr;
  wire [FRAME_BUFFER_WIDTH-1:0]     frame_buffer_1_data_out;

  ram_dual_port #(
    .DEPTH(VERT_RESOLUTION*HORIZ_RESOLUTION),
    .WIDTH(FRAME_BUFFER_WIDTH),
    .VIVADO_ENV(VIVADO_ENV)
  ) frame_buffer_1 (
    .write_clk(frame_buffer_1_write_clk),
    .write_en(frame_buffer_1_write_en),
    .write_addr(frame_buffer_1_write_addr),
    .data_in(frame_buffer_1_data_in),

    .read_clk(frame_buffer_1_read_clk),
    .read_addr(frame_buffer_1_read_addr),
    .data_out(frame_buffer_1_data_out)
  );

// IMPORTANT NOTE: When reading the code below, pay attention to whether the
// rasterization_target value is being checked to be 1'b0 or 1'b1

  // frame_buffer_0 input connections
  assign frame_buffer_0_write_clk = 
    i_sys_clk;
  assign frame_buffer_0_write_en = 
    (i_rasterization_target == 1'b0) ? 
      i_rasterizer_write_en : 1'b0;
  assign frame_buffer_0_write_addr = 
    (HORIZ_RESOLUTION*i_rasterizer_vert_write_addr) + 
      i_rasterizer_horiz_write_addr;
  assign frame_buffer_0_data_in = 
    i_rasterizer_write_pixel_data;

  assign frame_buffer_0_read_clk = 
    (i_rasterization_target == 1'b0) ? 
      i_sys_clk : i_vga_clk;
  assign frame_buffer_0_read_addr = 
    (i_rasterization_target == 1'b0) ? 
      (HORIZ_RESOLUTION*i_rasterizer_vert_write_addr) + 
        i_rasterizer_horiz_write_addr : 
      (HORIZ_RESOLUTION*i_vga_vert_read_addr) + 
        i_vga_horiz_read_addr;

  // frame_buffer_1 input connections
  assign frame_buffer_1_write_clk = 
    i_sys_clk;
  assign frame_buffer_1_write_en = 
    (i_rasterization_target == 1'b1) ? 
      i_rasterizer_write_en : 1'b0;
  assign frame_buffer_1_write_addr = 
    (HORIZ_RESOLUTION*i_rasterizer_vert_write_addr) + 
      i_rasterizer_horiz_write_addr;
  assign frame_buffer_1_data_in = 
    i_rasterizer_write_pixel_data;

  assign frame_buffer_1_read_clk = 
    (i_rasterization_target == 1'b1) ? 
      i_sys_clk : i_vga_clk;
  assign frame_buffer_1_read_addr = 
    (i_rasterization_target == 1'b1) ? 
      (HORIZ_RESOLUTION*i_rasterizer_vert_write_addr) + 
        i_rasterizer_horiz_write_addr : 
      (HORIZ_RESOLUTION*i_vga_vert_read_addr) + 
        i_vga_horiz_read_addr;

  // frame buffer data output connections
  assign o_vga_read_pixel_data = 
    (i_rasterization_target == 1'b0) ? 
      frame_buffer_0_data_out : 
      frame_buffer_1_data_out;

  assign o_vga_read_pixel_data =
    (i_rasterization_target == 1'b1) ? 
      frame_buffer_0_data_out : 
      frame_buffer_1_data_out;

endmodule
