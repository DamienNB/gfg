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
  input wire [3:0] i_triangle_color_red,
  input wire [3:0] i_triangle_color_green,
  input wire [3:0] i_triangle_color_blue,

  output reg [$clog2(VERT_RESOLUTION)-1:0]  o_vert_write_addr  = 0,
  output reg [$clog2(HORIZ_RESOLUTION)-1:0] o_horiz_write_addr = 0,

  output reg [3:0] o_red,
  output reg [3:0] o_green,
  output reg [3:0] o_blue,
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

  reg load_triangle = 1'b0;

  reg [$clog2(HORIZ_RESOLUTION)-1:0] horiz_target_addr = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  vert_target_addr  = 0;
  reg valid_target = 1'b0;

  wire triangle_loaded;
  wire point_inside_triangle;

  localparam DELAY_LENGTH = 4;

  reg [$clog2(HORIZ_RESOLUTION)-1:0] horiz_target_addr_delay [DELAY_LENGTH-1:0];
  reg [$clog2(VERT_RESOLUTION)-1:0]  vert_target_addr_delay  [DELAY_LENGTH-1:0];
  reg valid_target_delay [DELAY_LENGTH-1:0];

  localparam WAIT = 3'b001, LOAD_TRIANGLE = 3'b010, RASTERIZE = 3'b100; 
  reg [2:0] state = WAIT;

  rasterizer_triangle_intersection_detector #(
    .VERT_RESOLUTION(VERT_RESOLUTION),
    .HORIZ_RESOLUTION(HORIZ_RESOLUTION)
  ) rtid (
    .i_clk(i_clk),
    .i_srst_n(i_srst_n),
    .i_load_triangle(load_triangle),
    .i_current_point_x(horiz_target_addr),
    .i_current_point_y(vert_target_addr),
    .i_triangle_point_0_x(triangle_point_0_x_register),
    .i_triangle_point_0_y(triangle_point_0_y_register),
    .i_triangle_point_1_x(triangle_point_1_x_register),
    .i_triangle_point_1_y(triangle_point_1_y_register),
    .i_triangle_point_2_x(triangle_point_2_x_register),
    .i_triangle_point_2_y(triangle_point_2_y_register),
    .i_slack(8'h00), // TODO: Change this
    .o_triangle_loaded(triangle_loaded),
    .o_point_inside_triangle(point_inside_triangle)
  );

  integer i;
  generate
  always @(posedge i_clk) begin
    for(i=DELAY_LENGTH-1; i>0; i=i-1) begin
      vert_target_addr_delay[i]  <= vert_target_addr_delay[i-1];
      horiz_target_addr_delay[i] <= horiz_target_addr_delay[i-1];
      valid_target_delay[i]      <= valid_target_delay[i-1];
    end
    vert_target_addr_delay[0]  <= vert_target_addr;
    horiz_target_addr_delay[0] <= horiz_target_addr;
    valid_target_delay[0]      <= valid_target;
  end
  endgenerate

  always @(posedge i_clk) begin
    go_register <= i_go;

    o_vert_write_addr  <= vert_target_addr_delay[DELAY_LENGTH-1];
    o_horiz_write_addr <= horiz_target_addr_delay[DELAY_LENGTH-1];

    /*
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
    */

    if(i_srst_n == 1'b0) begin
      load_triangle    <= 1'b0;
      vert_target_addr   <= 0;
      horiz_target_addr  <= 0;
      valid_target       <= 1'b0;
      state              <= WAIT;
      o_write_en         <= 1'b0;
      o_done             <= 1'b0;
    end else begin
      // defaults to be overridden by state behaviors
      load_triangle    <= 1'b0;
      vert_target_addr   <= 0;
      horiz_target_addr  <= 0;
      valid_target       <= 1'b0;
      state              <= WAIT;
      o_write_en         <= 1'b0;
      o_done             <= 1'b0;

      triangle_point_0_x_register <= triangle_point_0_x_register;
      triangle_point_0_y_register <= triangle_point_0_y_register;
      triangle_point_1_x_register <= triangle_point_1_x_register;
      triangle_point_1_y_register <= triangle_point_1_y_register;
      triangle_point_2_x_register <= triangle_point_2_x_register;
      triangle_point_2_y_register <= triangle_point_2_y_register;

      case(state)
        WAIT          : begin
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
            state <= LOAD_TRIANGLE;
            load_triangle <= 1'b1;
          end else begin
            state <= WAIT;
            load_triangle <= 1'b0;
          end
        end

        LOAD_TRIANGLE : begin
          load_triangle <= 1'b0;
          if(triangle_loaded) begin
            vert_target_addr  <= 0;
            horiz_target_addr <= 0;
            valid_target <= 1'b1;
            state <= RASTERIZE;
          end else begin
            state <= LOAD_TRIANGLE;
          end
        end

        RASTERIZE     : begin
          valid_target <= 1'b1;
          state        <= RASTERIZE;

          o_write_en <= 1'b0;
          o_done     <= 1'b0;

          if(horiz_target_addr < HORIZ_RESOLUTION-1) begin
            horiz_target_addr <= horiz_target_addr + 1;
            vert_target_addr  <= vert_target_addr;
          end else begin
            horiz_target_addr <= 0;
            if(vert_target_addr < VERT_RESOLUTION-1) begin
              vert_target_addr <= vert_target_addr + 1;
            end else begin
              valid_target <= 1'b0;
              horiz_target_addr <= horiz_target_addr;
              vert_target_addr  <= vert_target_addr;
            end
          end

          // Due to the way the delays are set up, this will match up with the
          // values of o_vert_write_addr and o_horiz_write_addr at the output
          if(valid_target_delay[DELAY_LENGTH-1]) begin
            o_write_en <= 1'b1;
            if(point_inside_triangle) begin
              o_red   <= i_triangle_color_red;
              o_green <= i_triangle_color_green;
              o_blue  <= i_triangle_color_blue;
            end else begin
              o_red   <= 4'h0;
              o_green <= 4'h0;
              o_blue  <= 4'h0;
            end
          end else begin
            o_write_en <= 1'b0;
          end

          if(o_vert_write_addr >= VERT_RESOLUTION-1) begin
            if(o_horiz_write_addr >= HORIZ_RESOLUTION-1) begin
              state <= WAIT;
              o_done <= 1'b1;
            end
          end
        end

        default       : begin
          state <= WAIT;
        end
      endcase
    end
  end
endmodule
