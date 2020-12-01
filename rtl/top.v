`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Damien Nikola Bobrek
// 
// Create Date: 10/14/2020 10:36:56 AM
// Design Name: top
// Module Name: top
// Project Name: gfg
// Target Devices: Arty A7-100
// Tool Versions: Vivado 2017.2
// Description: Top-level file for gfg project
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
    input i_clk,
    input i_arst_n,
    input [3:0] i_sw,

    input  i_spi_clk,
    output o_spi_miso,
    input  i_spi_mosi,
    input  i_spi_ss_n,

    output o_vga_hs,
    output o_vga_vs,
    output [3:0] o_vga_red,
    output [3:0] o_vga_green,
    output [3:0] o_vga_blue,
    output reg [7:0] o_led = 0
    );
  parameter HORIZ_RESOLUTION =  80,
            VERT_RESOLUTION  =  60,
            VGA_HORIZ_RES    = 640,
            VGA_VERT_RES     = 480,
            COLOR_DEPTH      =  12,
            Z_DEPTH          =   0,
            VIVADO_ENV       =   1;

  localparam FRAME_BUFFER_WIDTH = COLOR_DEPTH + Z_DEPTH;

  reg srst_n;
  wire srst;
  assign srst = !srst_n;

  wire pixel_clk;
  wire pixel_clk_locked;

  clk_wiz_100MHz_to_25MHz clk_wiz_inst
  (
  // inputs
    // control signals
    .resetn(srst_n), 
    // Clock in port
    .clk_in1(i_clk),
  // outputs
    // Clock out port
    .clk_out1(pixel_clk),
    // status signal
    .locked(pixel_clk_locked)
  );

  wire raster_in_progress;

  wire frame_buffer_swap_allowed;

  //assign o_led[1:0] = {2{frame_buffer_swap_allowed}};
  //assign o_led[3:2] = {2{rasterizer_done}};

  wire new_frame;
  wire rasterization_target;

  frame_buffers_swapping_controller frame_buffers_swapping_controller_inst (
    .i_clk(i_clk),
    .i_srst_n(srst_n),
    .i_raster_in_progress(raster_in_progress),
    .i_frame_buffer_swap_allowed(frame_buffer_swap_allowed),
    .o_new_frame(new_frame),
    .o_rasterization_target(rasterization_target)
  );

  wire [$clog2(VERT_RESOLUTION)-1:0]  rasterizer_vert_write_addr;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] rasterizer_horiz_write_addr;
  wire                                rasterizer_write_en;
  wire [FRAME_BUFFER_WIDTH-1:0]       rasterizer_write_pixel_data;
  // TODO: Replace with actual reading eventually
  reg [$clog2(VERT_RESOLUTION)-1:0]  rasterizer_vert_read_addr   = 0;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] rasterizer_horiz_read_addr  = 0;

  wire [$clog2(VGA_VERT_RES)-1:0]  vga_vert_read_addr;
  wire [$clog2(VGA_HORIZ_RES)-1:0] vga_horiz_read_addr;

  wire [$clog2(VGA_VERT_RES)-1:0]  vga_vert_read_addr_crossed;
  wire [$clog2(VGA_HORIZ_RES)-1:0] vga_horiz_read_addr_crossed;

  wire [FRAME_BUFFER_WIDTH-1:0] rasterizer_read_pixel_data;

  wire [COLOR_DEPTH-1:0] vga_read_pixel_data;

  frame_buffers_datapath #(
    .VERT_RESOLUTION (VERT_RESOLUTION),
    .HORIZ_RESOLUTION(HORIZ_RESOLUTION),
    .COLOR_DEPTH     (COLOR_DEPTH),
    .Z_DEPTH         (Z_DEPTH),
    .VIVADO_ENV      (VIVADO_ENV)
  ) frame_buffers_datapath_inst (
  // general inputs
    .i_sys_clk(i_clk),
    .i_vga_clk(pixel_clk),
  // input from controller
    .i_rasterization_target(rasterization_target),
  // inputs from rasterizer
    .i_rasterizer_vert_write_addr (rasterizer_vert_write_addr),
    .i_rasterizer_horiz_write_addr(rasterizer_horiz_write_addr),
    .i_rasterizer_write_en        (rasterizer_write_en),
    .i_rasterizer_write_pixel_data(rasterizer_write_pixel_data),
    .i_rasterizer_vert_read_addr  (rasterizer_vert_read_addr),
    .i_rasterizer_horiz_read_addr (rasterizer_horiz_read_addr),
  // inputs from display output
    .i_vga_vert_read_addr (vga_vert_read_addr_crossed[8:3]),
    .i_vga_horiz_read_addr(vga_horiz_read_addr_crossed[9:3]),
  // outputs to rasterizer
    .o_rasterizer_read_pixel_data(rasterizer_read_pixel_data),
  // output to display output
    .o_vga_read_pixel_data(vga_read_pixel_data)
  );

  wire [5:0]  spi_slave_regs_addr;
  wire [31:0] spi_slave_regs_read_data;
  wire        spi_slave_regs_write_en;
  wire [31:0] spi_slave_regs_write_data;

  wire [5:0] spi_slave_state;

  gfg_spi_slave #(
    .NUM_REGISTERS(32),
    .REGISTER_WIDTH(32)
  ) spi_slave_inst (
    .i_sys_clk(i_clk),
    .i_srst_n(srst_n),

    .i_spi_clk(i_spi_clk),
    .o_spi_miso(o_spi_miso),
    .i_spi_mosi(i_spi_mosi),
    .i_spi_ss_n(i_spi_ss_n),

    .o_reg_addr(spi_slave_regs_addr),
    .i_reg_read_data(spi_slave_regs_read_data),
    .o_reg_write_en(spi_slave_regs_write_en),
    .o_reg_write_data(spi_slave_regs_write_data),
    
    .o_state(spi_slave_state)
  );

  /*
  reg         spi_regs_write_en   = 1'b0;
  reg   [5:0] spi_regs_addr       = 0;
  wire [31:0] spi_regs_read_data;
  reg  [31:0] spi_regs_write_data = 0;
  */

  reg [31:0] spi_slave_regs [31:0];

  /*
  blk_mem_spi_slave_regs spi_slave_regs (
    .clka(i_clk),
    .wea(spi_slave_regs_write_en),
    .addra(spi_slave_regs_addr),
    .dina(spi_slave_regs_write_data),
    .douta(spi_slave_regs_read_data),

    .clkb(i_clk),
    .web(spi_regs_write_en),
    .addrb(spi_regs_addr),
    .dinb(spi_regs_write_data),
    .doutb(spi_regs_read_data)
  );
  */
  /*
  dist_mem_spi_slave_regs spi_slave_regs (
    .clk(i_clk),
    .we(spi_slave_regs_write_en),
    .a(spi_slave_regs_addr),
    .d(spi_slave_regs_write_data),
    .qspo(spi_slave_regs_read_data),

    .dpra(spi_regs_addr),
    .qdpo(spi_regs_read_data)
  );
  */

  wire rasterizer_done;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_0_x = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_0_y = 0;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_1_x = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_1_y = 0;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_2_x = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_2_y = 0;
  reg [3:0] triangle_color_red   = 0;
  reg [3:0] triangle_color_green = 0;
  reg [3:0] triangle_color_blue  = 0;

  rasterizer #(
    .VERT_RESOLUTION (VERT_RESOLUTION),
    .HORIZ_RESOLUTION(HORIZ_RESOLUTION)
  ) rasterizer_inst (
    .i_clk(i_clk),
    .i_srst_n(srst_n),
    .i_go(new_frame),

    .i_triangle_point_0_x(triangle_point_0_x),
    .i_triangle_point_0_y(triangle_point_0_x),
    .i_triangle_point_1_x(triangle_point_1_x),
    .i_triangle_point_1_y(triangle_point_1_y),
    .i_triangle_point_2_x(triangle_point_2_x),
    .i_triangle_point_2_y(triangle_point_2_y),
    .i_triangle_color_red(triangle_color_red),
    .i_triangle_color_green(triangle_color_green),
    .i_triangle_color_blue(triangle_color_blue),

    .o_vert_write_addr(rasterizer_vert_write_addr),
    .o_horiz_write_addr(rasterizer_horiz_write_addr),

    .o_red(rasterizer_write_pixel_data[8 +: 4]),
    .o_green(rasterizer_write_pixel_data[4 +: 4]),
    .o_blue(rasterizer_write_pixel_data[0 +: 4]),
    .o_write_en(rasterizer_write_en),
    // TODO: Come up with something more elegant
    .o_done(rasterizer_done)
  );
  assign raster_in_progress = !rasterizer_done;

  vga_output #(
    .OUTPUT_DELAY_COUNT(2)
  ) vga_output_inst (
    .pixel_clk(pixel_clk),
    .rst_n(srst_n),
    .red_in(vga_read_pixel_data[8 +: 4]),
    .green_in(vga_read_pixel_data[4 +: 4]),
    .blue_in(vga_read_pixel_data[0 +: 4]),

    .frame_buffer_swap_allowed(frame_buffer_swap_allowed),

    .horiz_addr(vga_horiz_read_addr),
    .vert_addr(vga_vert_read_addr),

    .horiz_sync(o_vga_hs),
    .vert_sync(o_vga_vs),
    .red_out(o_vga_red),
    .green_out(o_vga_green),
    .blue_out(o_vga_blue)
  );

  blk_mem_addr_clk_domain_cross vert_inst
  (
    .clka(pixel_clk),
    .wea(1'b1),
    .addra(0),
    .dina(vga_vert_read_addr),

    .clkb(pixel_clk),
    .addrb(0),
    .doutb(vga_vert_read_addr_crossed)
  );

  blk_mem_addr_clk_domain_cross horiz_inst
  (
    .clka(pixel_clk),
    .wea(1'b1),
    .addra(0),
    .dina(vga_horiz_read_addr),

    .clkb(pixel_clk),
    .addrb(0),
    .doutb(vga_horiz_read_addr_crossed)
  );

  integer i;

  generate
  always @(posedge i_clk) begin
    // TODO: Add debouncing to rst
    srst_n <= i_arst_n;

    if(srst_n == 1'b0) begin
      triangle_point_0_x <= 0;
      triangle_point_0_y <= 0;
      triangle_point_1_x <= 0;
      triangle_point_1_y <= 0;
      triangle_point_2_x <= 0;
      triangle_point_2_y <= 0;

      //spi_regs_write_en   <= 1'b0;
      //spi_regs_write_data <= 0;
      //spi_regs_addr <= 0;


      for (i = 0; i < 32; i = i+1) begin
        spi_slave_regs[i] = 0;
      end

      o_led <= 0;
    end else begin
      for (i = 0; i < 32; i = i+1) begin
        spi_slave_regs[i] <= spi_slave_regs[i];
      end
      if(spi_slave_regs_write_en) begin
        spi_slave_regs[spi_slave_regs_addr] <= spi_slave_regs_write_data;
      end

      triangle_point_0_x <= spi_slave_regs[0];
      triangle_point_0_y <= spi_slave_regs[1];
      triangle_point_1_x <= spi_slave_regs[2];
      triangle_point_1_y <= spi_slave_regs[3];
      triangle_point_2_x <= spi_slave_regs[4];
      triangle_point_2_y <= spi_slave_regs[5];

      triangle_color_red   <= spi_slave_regs[6][11:8];
      triangle_color_green <= spi_slave_regs[6][7:4];
      triangle_color_blue  <= spi_slave_regs[6][3:0];

      //spi_regs_write_en   <= 1'b0;
      //spi_regs_write_data <= 0;
      
      /*
      triangle_point_0_x <= triangle_point_0_x;
      triangle_point_0_y <= triangle_point_0_y;
      triangle_point_1_x <= triangle_point_1_x;
      triangle_point_1_y <= triangle_point_1_y;
      triangle_point_2_x <= triangle_point_2_x;
      triangle_point_2_y <= triangle_point_2_y;

      if(spi_slave_regs_write_en) begin
        case(spi_regs_addr)
          0 : begin
            triangle_point_0_x <= spi_slave_regs_write_data;
          end
          1 : begin
            triangle_point_0_y <= spi_slave_regs_write_data;
          end
          2 : begin
            triangle_point_1_x <= spi_slave_regs_write_data;
          end
          3 : begin
            triangle_point_1_y <= spi_slave_regs_write_data;
          end
          4 : begin
            triangle_point_2_x <= spi_slave_regs_write_data;
          end
          5 : begin
            triangle_point_2_y <= spi_slave_regs_write_data;
          end
        endcase
      end
      */

      /*
      //data <= spi_regs_read_data;
      triangle_point_0_x <= triangle_point_0_x;

      if(spi_slave_state == 6'b000100) begin
        triangle_point_0_x <= spi_slave_regs_read_data;
      end

      //case(spi_regs_read_data[1:0])
      case(i_sw[1:0])
        2'b00   : begin
          triangle_point_0_x <= 10;
          triangle_point_0_y <= 10;
          triangle_point_1_x <= 10;
          triangle_point_1_y <= 50;
          triangle_point_2_x <= 50;
          triangle_point_2_y <= 25;
        end
        2'b01   : begin
          triangle_point_0_x <= HORIZ_RESOLUTION/2;
          triangle_point_0_y <= 5;
          triangle_point_1_x <= 5;
          triangle_point_1_y <= VERT_RESOLUTION-5;
          triangle_point_2_x <= HORIZ_RESOLUTION-5;
          triangle_point_2_y <= VERT_RESOLUTION-5;
        end
        2'b10   : begin
          triangle_point_0_x <= 0;
          triangle_point_0_y <= 0;
          triangle_point_1_x <= 0;
          triangle_point_1_y <= 0;
          triangle_point_2_x <= 0;
          triangle_point_2_y <= 0;
        end
        2'b11   : begin
          triangle_point_0_x <= 10;
          triangle_point_0_y <= 10;
          triangle_point_1_x <= 50;
          triangle_point_1_y <= 10;
          triangle_point_2_x <= 25;
          triangle_point_2_y <= 50;
        end
        default : begin
          triangle_point_0_x <= 10;
          triangle_point_0_y <= 10;
          triangle_point_1_x <= 50;
          triangle_point_1_y <= 10;
          triangle_point_2_x <= 25;
          triangle_point_2_y <= 50;
        end
      endcase
      */
    end
  end
  endgenerate

endmodule
