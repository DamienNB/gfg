`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2020 10:36:56 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

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

module top(
    input clk,
    input rst_n,
    input [3:0] sw,
    output vga_hs,
    output vga_vs,
    output [3:0] vga_red,
    output [3:0] vga_green,
    output [3:0] vga_blue,
    output [3:0] led
    );
  parameter HORIZ_RESOLUTION =  80,
            VERT_RESOLUTION  =  60,
            VGA_HORIZ_RES    = 640,
            VGA_VERT_RES     = 480,
            COLOR_DEPTH      =  12,
            Z_DEPTH          =   2,
            NUM_RASTERIZERS  =   1,
            VIVADO_ENV       =   1;

  localparam FRAME_BUFFER_WIDTH = COLOR_DEPTH + Z_DEPTH;

  assign led = 0;

  wire pixel_clk;
  wire pixel_clk_locked;

  clk_wiz_100MHz_to_25MHz clk_wiz_inst
  (
  // inputs
    // control signals
    .resetn(rst_n), 
    // Clock in port
    .clk_in1(clk),
  // outputs
    // Clock out port
    .clk_out1(pixel_clk),
    // status signal
    .locked(pixel_clk_locked)
  );

  reg drawing_pools_empty;

  reg rasterizers_write_reservation_request_flags;
  reg rasterizers_finished_flags;
  reg [$clog2(VERT_RESOLUTION)-1:0]  rasterizers_vert_write_addrs;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] rasterizers_horiz_write_addrs;
  reg rasterizers_write_en_flags;
  reg [FRAME_BUFFER_WIDTH-1:0] rasterizers_write_pixel_data = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  rasterizers_vert_read_addrs;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] rasterizers_horiz_read_addrs;

  reg new_frame_requested_reg;

  wire [$clog2(VGA_VERT_RES)-1:0]  vga_vert_read_addr;
  wire [$clog2(VGA_HORIZ_RES)-1:0] vga_horiz_read_addr;

  wire rasterizers_write_reservation_granted_flags;
  wire [FRAME_BUFFER_WIDTH-1:0] rasterizers_read_pixel_data;
  wire new_frame_initiated;

  wire [FRAME_BUFFER_WIDTH-1:0] vga_read_pixel_data;

  gfg_frame_buffers_controller_and_datapath_simple frame_buffers_inst (
    .clk(clk),
    .rst_n(rst_n),

    .drawing_pools_empty(drawing_pools_empty),

    .rasterizers_write_reservation_request_flags(rasterizers_write_reservation_request_flags),
    .rasterizers_finished_flags(rasterizers_finished_flags),
    .rasterizers_vert_write_addrs(rasterizers_vert_write_addrs),
    .rasterizers_horiz_write_addrs(rasterizers_horiz_write_addrs),
    .rasterizers_write_en_flags(rasterizers_write_en_flags),
    .rasterizers_write_pixel_data(rasterizers_write_pixel_data),
    .rasterizers_vert_read_addrs(rasterizers_vert_read_addrs),
    .rasterizers_horiz_read_addrs(rasterizers_horiz_read_addrs),

    .vga_clk(pixel_clk),
    .new_frame_requested(new_frame_requested_reg),
    // Only reading the data using the upper bits due to the reduced size of the frame buffer
    .vga_vert_read_addr(vga_vert_read_addr[(`CLOG2(VGA_VERT_RES))-1 :- `CLOG2(VERT_RESOLUTION)]),
    .vga_horiz_read_addr(vga_horiz_read_addr[(`CLOG2(VGA_HORIZ_RES))-1 :- `CLOG2(HORIZ_RESOLUTION)]),

    .rasterizers_write_reservation_granted_flags(rasterizers_write_reservation_granted_flags),
    .rasterizers_read_pixel_data(rasterizers_read_pixel_data),
    .new_frame_initiated(new_frame_initiated),

    .vga_read_pixel_data(vga_read_pixel_data)
  );
  defparam frame_buffers_inst.VERT_RESOLUTION  = VERT_RESOLUTION;
  defparam frame_buffers_inst.HORIZ_RESOLUTION = HORIZ_RESOLUTION;
  defparam frame_buffers_inst.COLOR_DEPTH      = COLOR_DEPTH;
  defparam frame_buffers_inst.Z_DEPTH          = Z_DEPTH;
  defparam frame_buffers_inst.NUM_RASTERIZERS  = NUM_RASTERIZERS;
  defparam frame_buffers_inst.VIVADO_ENV       = VIVADO_ENV;

  vga_output vga_output_inst (
    .pixel_clk(pixel_clk),
    .rst_n(rst_n),
    .red_in(rasterizers_read_pixel_data[8 +: 4]),
    .green_in(rasterizers_read_pixel_data[4 +: 4]),
    .blue_in(rasterizers_read_pixel_data[0 +: 4]),

    .horiz_addr(vga_horiz_read_addr),
    .vert_addr(vga_vert_read_addr),

    .horiz_sync(vga_hs),
    .vert_sync(vga_vs),
    .red_out(vga_red),
    .green_out(vga_green),
    .blue_out(vga_blue)
  );
  defparam vga_output_inst.OUTPUT_DELAY_COUNT = 2;

  always @(posedge clk) begin
    new_frame_requested_reg <= !new_frame_initiated && 
      (vga_horiz_read_addr == 0) && (vga_vert_read_addr == 0);
  end

  always @(posedge clk) begin
    rasterizers_write_pixel_data <= rasterizers_write_pixel_data + 37;
  end

  always @(posedge clk) begin
    if(rst_n == 1'b0) begin
      rasterizers_horiz_write_addrs <= 0;
    end else begin
      if(rasterizers_horiz_write_addrs < HORIZ_RESOLUTION)
        rasterizers_horiz_write_addrs <= rasterizers_horiz_write_addrs + 1;
      else
        rasterizers_horiz_write_addrs <= 0;
    end
  end
  always @(posedge clk) begin
    if(rst_n == 1'b0) begin
      rasterizers_horiz_write_addrs <= 0;
    end else if (rasterizers_horiz_write_addrs == HORIZ_RESOLUTION) begin
      if (rasterizers_vert_write_addrs < VERT_RESOLUTION)
        rasterizers_vert_write_addrs <= rasterizers_vert_write_addrs + 1;
      else
        rasterizers_vert_write_addrs <= 0;
    end
  end

  always @(posedge clk) begin
    if(new_frame_initiated && !rasterizers_write_reservation_request_flags) begin
      rasterizers_write_reservation_request_flags <= 1'b1;
    end else begin
      rasterizers_write_reservation_request_flags <= 1'b0;
    end
  end


/*
  always @(posedge clk) begin
    if(rst_n == 0) begin
      drawing_pools_empty <= 0;
      rasterizers_write_reservation_request_flags <= 0;
      rasterizers_vert_write_addrs <= 0;
      rasterizers_horiz_write_addrs <= 0;
      //rasterizers_write_pixel_data <= 0;
      rasterizers_vert_read_addrs <= 0;
      rasterizers_horiz_read_addrs <= 0;
    end else begin
      rasterizers_write_reservation_request_flags <= 0;

      if(rasterizers_horiz_write_addrs < HORIZ_RESOLUTION) begin
        rasterizers_write_reservation_request_flags <= 1;
        rasterizers_horiz_write_addrs <= rasterizers_horiz_write_addrs + 1;
      end else if(rasterizers_vert_write_addrs < VERT_RESOLUTION) begin
        rasterizers_write_reservation_request_flags <= 1;
        rasterizers_horiz_write_addrs <= 0;
        rasterizers_vert_write_addrs <= rasterizers_vert_write_addrs + 1;
      end else if(new_frame_initiated) begin
        rasterizers_write_reservation_request_flags <= 1;
        rasterizers_horiz_write_addrs <= 0;
        rasterizers_vert_write_addrs <= 0;
      end
    end

    if((rasterizers_vert_write_addrs < VERT_RESOLUTION)) begin
      if (rasterizers_horiz_write_addrs < HORIZ_RESOLUTION) begin
        rasterizers_write_en_flags <= 1;
        rasterizers_finished_flags <= 0;
        drawing_pools_empty <= 0;
        if((rasterizers_vert_write_addrs >= 10) && 
           (rasterizers_vert_write_addrs < 110)) begin
          if((rasterizers_horiz_write_addrs >= 10) && 
             (rasterizers_horiz_write_addrs < 110)) begin
            //rasterizers_write_pixel_data <= 12'hFFF;
          end else begin
            //rasterizers_write_pixel_data <= 12'h000;
          end
        end else begin
          //rasterizers_write_pixel_data <= 12'h000;
        end
      end else begin
        rasterizers_write_en_flags <= 0;
      end
    end else begin
      rasterizers_write_en_flags <= 0;
      rasterizers_finished_flags <= 1;
      drawing_pools_empty <= 1;
    end
  end
  */

endmodule
