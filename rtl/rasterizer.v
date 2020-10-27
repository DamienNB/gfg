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

module rasterizer #(
  parameter VERT_RESOLUTION  = 60,
            HORIZ_RESOLUTION = 80 // TODO: Add more parameters
) (
  input wire i_clk,
  input wire i_srst_n,
  input wire i_go,

  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_0_x,
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_0_y,
  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_1_x,
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_1_y,
  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_2_x,
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_2_y,

  output reg [$clog2(VERT_RESOLUTION)-1:0]  o_vert_write_addr  = 0,
  output reg [$clog2(HORIZ_RESOLUTION)-1:0] o_horiz_write_addr = 0,

  output wire [3:0] o_red,
  output wire [3:0] o_green,
  output wire [3:0] o_blue,
  output reg o_write_en = 1'b0,
  output reg o_done =     1'b0
  );

  reg go_register;

  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_0_x_register;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_0_y_register;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_1_x_register;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_1_y_register;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_2_x_register;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_2_y_register;

  reg [$clog2(VERT_RESOLUTION)-1:0]  top_y;
  reg [$clog2(VERT_RESOLUTION)-1:0]  bottom_y;

  reg[31:0] color_counter = 0;

  localparam WAIT = 2'b01, RASTERIZE = 2'b10; 
  reg [1:0] state = WAIT;

  /*
  assign o_red   = 
    (o_horiz_write_addr == HORIZ_RESOLUTION-1) || (o_vert_write_addr == VERT_RESOLUTION-1) ?
    4'hf : 0; //(o_vert_write_addr/4) : 0;
    */
  assign o_red   = color_counter[31 -: 4];
  assign o_green = color_counter[31 -: 4];
  assign o_blue  = color_counter[31 -: 4];

  always @(posedge i_clk) begin
    go_register <= i_go;

    if(triangle_point_0_y_register >= triangle_point_1_y_register)
      if(triangle_point_0_y_register >= triangle_point_2_y_register)
        top_y <= triangle_point_0_y_register;
      else // if(triangle_point_2_y_register > triangle_point_0_y_register)
        top_y <= triangle_point_2_y_register;
    else // if(triangle_point_1_y_register > triangle_point_0_y_register)
      if(triangle_point_1_y_register >= triangle_point_2_y_register)
        top_y <= triangle_point_1_y_register;
      else // if(triangle_point_2_y_register > triangle_point_1_y_register)
        top_y <= triangle_point_2_y_register;

    if(triangle_point_0_y_register <= triangle_point_1_y_register)
      if(triangle_point_0_y_register <= triangle_point_2_y_register)
        bottom_y <= triangle_point_0_y_register;
      else // if(triangle_point_2_y_register < triangle_point_0_y_register)
        bottom_y <= triangle_point_2_y_register;
    else // if(triangle_point_1_y_register < triangle_point_0_y_register)
      if(triangle_point_1_y_register <= triangle_point_2_y_register)
        bottom_y <= triangle_point_1_y_register;
      else // if(triangle_point_2_y_register < triangle_point_1_y_register)
        bottom_y <= triangle_point_2_y_register;

    if(i_srst_n == 1'b0) begin
      state              <= WAIT;
      o_vert_write_addr  <= 0;
      o_horiz_write_addr <= 0;
      o_write_en         <= 1'b0;
      o_done             <= 1'b0;
      color_counter      <= 0;
    end else begin
      color_counter      <= color_counter+1;

      // defaults to be overridden by state behaviors
      state              <= WAIT;
      o_vert_write_addr  <= 0;
      o_horiz_write_addr <= 0;
      o_write_en         <= 1'b0;
      o_done             <= 1'b0;

      triangle_point_0_x_register <= triangle_point_0_x_register;
      triangle_point_0_y_register <= triangle_point_0_y_register;
      triangle_point_1_x_register <= triangle_point_1_x_register;
      triangle_point_1_y_register <= triangle_point_1_y_register;
      triangle_point_2_x_register <= triangle_point_2_x_register;
      triangle_point_2_y_register <= triangle_point_2_y_register;

      case(state)
        WAIT      : begin
          o_vert_write_addr  <= 0;
          o_horiz_write_addr <= 0;
          o_done <= o_done;

          // uses i_go instead of go_register so that the values will be
          // available once the go_register goes true
          if(i_go) begin
            triangle_point_0_x_register <= i_triangle_point_0_x;
            triangle_point_0_y_register <= i_triangle_point_0_y;
            triangle_point_1_x_register <= i_triangle_point_1_x;
            triangle_point_1_y_register <= i_triangle_point_1_y;
            triangle_point_2_x_register <= i_triangle_point_2_x;
            triangle_point_2_y_register <= i_triangle_point_2_y;
          end

          if(go_register) begin
            state <= RASTERIZE;
            o_write_en <= 1'b1;
          end else begin
            state <= WAIT;
            o_write_en <= 1'b0;
          end
        end

        RASTERIZE : begin
          state      <= RASTERIZE;
          o_write_en <= 1'b1;
          o_done     <= 1'b0;

          if(o_horiz_write_addr < HORIZ_RESOLUTION-1) begin
            o_horiz_write_addr <= o_horiz_write_addr + 1;
            o_vert_write_addr  <= o_vert_write_addr;
          end else begin
            o_horiz_write_addr <= 0;
            if(o_vert_write_addr < VERT_RESOLUTION-1) begin
              o_vert_write_addr <= o_vert_write_addr + 1;
            end else begin
              o_vert_write_addr <= 0;
              state      <= WAIT;
              o_write_en <= 1'b0;
              o_done     <= 1'b1;
            end
          end
        end
        default  : begin
          state <= WAIT;
        end
      endcase
    end
  end
endmodule
