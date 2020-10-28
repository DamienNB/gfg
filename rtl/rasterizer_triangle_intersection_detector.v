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

module rasterizer_triangle_intersection_detector #(
  parameter VERT_RESOLUTION  = 60,
            HORIZ_RESOLUTION = 80 // TODO: Add more parameters
) (
  input wire i_clk,
  input wire i_srst_n,
  input wire i_load_triangle,

  input wire [(2*$clog2(HORIZ_RESOLUTION))-1:0] i_current_point_x,
  input wire [(2*$clog2(VERT_RESOLUTION))-1:0]  i_current_point_y,

  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_0_x,
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_0_y,
  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_1_x,
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_1_y,
  input wire [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_2_x,
  input wire [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_2_y,

  input wire signed [7:0] i_slack,

  output reg o_triangle_loaded = 1'b0,
  output reg o_point_inside_triangle = 1'b0
  );

  // COORD_WIDTH is the CLOG2 of the larger of the two resolution parameters
  localparam COORD_WIDTH = (HORIZ_RESOLUTION > VERT_RESOLUTION) ?
    `CLOG2(HORIZ_RESOLUTION) : `CLOG2(VERT_RESOLUTION);

  reg signed [COORD_WIDTH:0] triangle_point_0_x_register = 0;
  reg signed [COORD_WIDTH:0]  triangle_point_0_y_register = 0;
  reg signed [COORD_WIDTH:0] triangle_point_1_x_register = 0;
  reg signed [COORD_WIDTH:0]  triangle_point_1_y_register = 0;
  reg signed [COORD_WIDTH:0] triangle_point_2_x_register = 0;
  reg signed [COORD_WIDTH:0]  triangle_point_2_y_register = 0;

  reg [(2*$clog2(HORIZ_RESOLUTION))-1:0] current_point_x_register;
  reg [(2*$clog2(VERT_RESOLUTION))-1:0]  current_point_y_register;

  //reg signed [7:0] slack_register;

  reg calculating_triangle_area = 1'b0;

  reg signed [COORD_WIDTH:0] cross_product_input_a [2:0];
  reg signed [COORD_WIDTH:0] cross_product_input_b [2:0];
  reg signed [COORD_WIDTH:0] cross_product_input_c [2:0];
  reg signed [COORD_WIDTH:0] cross_product_input_d [2:0];

  wire signed [(3*COORD_WIDTH)-1:0] cross_product [2:0];

  wire unsigned [(3*COORD_WIDTH):0] cross_product_absolute_value [2:0];

  wire unsigned [(3*COORD_WIDTH):0] triangle_area [2:0];

  reg unsigned [(4*COORD_WIDTH):0] triangle_areas_sum = 0;

  // area of the triangle defined by triangle points 0 to 2
  reg unsigned [(3*COORD_WIDTH):0] principle_triangle_area = 0;
  //reg unsigned [(3*COORD_WIDTH):0] principle_triangle_area_plus_slack = 0;

  genvar i;
  generate
    for(i=0; i<=2; i=i+1) begin
      assign cross_product[i] =
        (cross_product_input_a[i] * cross_product_input_d[i]) -
        (cross_product_input_b[i] * cross_product_input_c[i]);
      assign cross_product_absolute_value[i] = (cross_product[i] < 0) ?
        -cross_product[i] : cross_product[i];
      assign triangle_area[i] = (cross_product_absolute_value[i])/2;
    end
  endgenerate

  localparam POINT_CALCULATION = 3'b001, LOADING_TRIANGLE_0 = 3'b010,
    LOADING_TRIANGLE_1 = 3'b100;
  reg [2:0] state = POINT_CALCULATION;

  always @(posedge i_clk) begin
    if(i_srst_n == 1'b0) begin
      triangle_point_0_x_register <= 0;
      triangle_point_0_y_register <= 0;
      triangle_point_1_x_register <= 0;
      triangle_point_1_y_register <= 0;
      triangle_point_2_x_register <= 0;
      triangle_point_2_y_register <= 0;

      current_point_x_register <= 0;
      current_point_y_register <= 0;

      //slack_register <= 0;

      calculating_triangle_area <= 1'b0;

      triangle_areas_sum <= 0;

      principle_triangle_area <= 0;
      //principle_triangle_area_plus_slack <= 0;

      o_triangle_loaded <= 1'b0;
    end else begin
      principle_triangle_area <= principle_triangle_area;
      //principle_triangle_area_plus_slack <= principle_triangle_area + slack_register;

      current_point_x_register <= i_current_point_x;
      current_point_y_register <= i_current_point_y;

      triangle_point_0_x_register <= i_triangle_point_0_x;
      triangle_point_0_y_register <= i_triangle_point_0_y;
      triangle_point_1_x_register <= i_triangle_point_1_x;
      triangle_point_1_y_register <= i_triangle_point_1_y;
      triangle_point_2_x_register <= i_triangle_point_2_x;
      triangle_point_2_y_register <= i_triangle_point_2_y;

      //slack_register <= i_slack;

      cross_product_input_a[0] <= (calculating_triangle_area) ?
        ($signed(triangle_point_1_x_register) - $signed(triangle_point_0_x_register)) :
        ($signed(triangle_point_1_x_register) - $signed(current_point_x_register));
      cross_product_input_b[0] <= (calculating_triangle_area) ?
        ($signed(triangle_point_1_y_register) - $signed(triangle_point_0_y_register)) :
        ($signed(triangle_point_1_y_register) - $signed(current_point_y_register));
      cross_product_input_c[0] <= (calculating_triangle_area) ?
        ($signed(triangle_point_2_x_register) - $signed(triangle_point_0_x_register)) :
        ($signed(triangle_point_2_x_register) - $signed(current_point_x_register));
      cross_product_input_d[0] <= (calculating_triangle_area) ?
        ($signed(triangle_point_2_y_register) - $signed(triangle_point_0_y_register)) :
        ($signed(triangle_point_2_y_register) - $signed(current_point_y_register));

      cross_product_input_a[1] <= 
        $signed(triangle_point_0_x_register) - $signed(current_point_x_register);
      cross_product_input_b[1] <= 
        $signed(triangle_point_0_y_register) - $signed(current_point_y_register);
      cross_product_input_c[1] <= 
        $signed(triangle_point_2_x_register) - $signed(current_point_x_register);
      cross_product_input_d[1] <= 
        $signed(triangle_point_2_y_register) - $signed(current_point_y_register);

      cross_product_input_a[2] <= 
        $signed(triangle_point_0_x_register) - $signed(current_point_x_register);
      cross_product_input_b[2] <= 
        $signed(triangle_point_0_y_register) - $signed(current_point_y_register);
      cross_product_input_c[2] <= 
        $signed(triangle_point_1_x_register) - $signed(current_point_x_register);
      cross_product_input_d[2] <= 
        $signed(triangle_point_1_y_register) - $signed(current_point_y_register);

      calculating_triangle_area <= 1'b0;

      triangle_areas_sum <= triangle_area[0]+triangle_area[1]+triangle_area[2];

      o_triangle_loaded <= 1'b0;

      case(state)
        POINT_CALCULATION : begin
          o_triangle_loaded       <= o_triangle_loaded;
          o_point_inside_triangle <= 1'b0;
          state <= POINT_CALCULATION;

          if(i_load_triangle) begin
            o_triangle_loaded         <= 1'b0;
            calculating_triangle_area <= 1'b1;

            state <= LOADING_TRIANGLE_0;
          end else if (o_triangle_loaded) begin
            if(triangle_areas_sum <= principle_triangle_area) begin
              o_point_inside_triangle <= 1'b1;
            end else begin
              o_point_inside_triangle <= 1'b0;
            end
          end
        end
        LOADING_TRIANGLE_0  : begin
          state <= LOADING_TRIANGLE_1;
        end
        LOADING_TRIANGLE_1  : begin
          principle_triangle_area <= triangle_area[0];
          o_triangle_loaded <= 1'b1;
          state <= POINT_CALCULATION;
        end
        default            : begin
          calculating_triangle_area <= 1'b0;
          o_triangle_loaded         <= 1'b0;
          state <= POINT_CALCULATION;
        end
      endcase

      // TODO
      if(i_load_triangle) begin
        triangle_point_0_x_register <= i_triangle_point_0_x;
        triangle_point_0_y_register <= i_triangle_point_0_y;
        triangle_point_1_x_register <= i_triangle_point_1_x;
        triangle_point_1_y_register <= i_triangle_point_1_y;
        triangle_point_2_x_register <= i_triangle_point_2_x;
        triangle_point_2_y_register <= i_triangle_point_2_y;
      end
    end
  end
endmodule
