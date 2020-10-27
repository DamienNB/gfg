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
    $clog2(HORIZ_RESOLUTION) : $clog2(VERT_RESOLUTION);

  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_0_x_register = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_0_y_register = 0;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_1_x_register = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_1_y_register = 0;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] triangle_point_2_x_register = 0;
  reg [$clog2(VERT_RESOLUTION)-1:0]  triangle_point_2_y_register = 0;

  reg [(2*$clog2(HORIZ_RESOLUTION))-1:0] current_point_x_register;
  reg [(2*$clog2(VERT_RESOLUTION))-1:0]  current_point_y_register;

  reg signed [7:0] slack_register;

  reg calculating_triangle_area = 1'b0;

  wire signed [COORD_WIDTH-1:0] cross_product_input_a [2:0];
  wire signed [COORD_WIDTH-1:0] cross_product_input_b [2:0];
  wire signed [COORD_WIDTH-1:0] cross_product_input_c [2:0];
  wire signed [COORD_WIDTH-1:0] cross_product_input_d [2:0];

  wire signed [(2*COORD_WIDTH)-1:0] cross_product [2:0];

  wire unsigned [(2*COORD_WIDTH)-1:0] cross_product_absolute_value [2:0];

  wire unsigned [(2*COORD_WIDTH)-1:0] triangle_area [2:0];

  // area of the triangle defined by triangle points 0 to 2
  reg unsigned [(2*COORD_WIDTH)-1:0] principle_triangle_area;

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

  assign cross_product_input_a[0] = (calculating_triangle_area) ?
    ($signed(triangle_point_1_x_register) - $signed(triangle_point_0_x_register)) :
    ($signed(triangle_point_1_x_register) - $signed(current_point_x_register));
  assign cross_product_input_b[0] = (calculating_triangle_area) ?
    ($signed(triangle_point_1_y_register) - $signed(triangle_point_0_y_register)) :
    ($signed(triangle_point_1_y_register) - $signed(current_point_y_register));
  assign cross_product_input_c[0] = (calculating_triangle_area) ?
    ($signed(triangle_point_2_x_register) - $signed(triangle_point_0_x_register)) :
    ($signed(triangle_point_2_x_register) - $signed(current_point_x_register));
  assign cross_product_input_d[0] = (calculating_triangle_area) ?
    ($signed(triangle_point_2_y_register) - $signed(triangle_point_0_y_register)) :
    ($signed(triangle_point_2_y_register) - $signed(current_point_y_register));

  assign cross_product_input_a[1] = 
    $signed(triangle_point_0_x_register) - $signed(current_point_x_register);
  assign cross_product_input_b[1] = 
    $signed(triangle_point_0_y_register) - $signed(current_point_y_register);
  assign cross_product_input_c[1] = 
    $signed(triangle_point_2_x_register) - $signed(current_point_x_register);
  assign cross_product_input_d[1] = 
    $signed(triangle_point_2_y_register) - $signed(current_point_y_register);

  assign cross_product_input_a[2] = 
    $signed(triangle_point_0_x_register) - $signed(current_point_x_register);
  assign cross_product_input_b[2] = 
    $signed(triangle_point_0_y_register) - $signed(current_point_y_register);
  assign cross_product_input_c[2] = 
    $signed(triangle_point_1_x_register) - $signed(current_point_x_register);
  assign cross_product_input_d[2] = 
    $signed(triangle_point_1_y_register) - $signed(current_point_y_register);


  localparam POINT_CALCULATION = 2'b01, LOADING_TRIANGLE = 2'b10;
  reg [1:0] state = POINT_CALCULATION;


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

      calculating_triangle_area <= 1'b0;
      principle_triangle_area   <= 0;

      o_triangle_loaded <= 1'b0;
    end else begin
      if(calculating_triangle_area) begin
        principle_triangle_area <= triangle_area[0];
      end else begin
        principle_triangle_area <= principle_triangle_area;
      end

      current_point_x_register <= i_current_point_x;
      current_point_y_register <= i_current_point_y;

      triangle_point_0_x_register <= i_triangle_point_0_x;
      triangle_point_0_y_register <= i_triangle_point_0_y;
      triangle_point_1_x_register <= i_triangle_point_1_x;
      triangle_point_1_y_register <= i_triangle_point_1_y;
      triangle_point_2_x_register <= i_triangle_point_2_x;
      triangle_point_2_y_register <= i_triangle_point_2_y;

      slack_register <= i_slack;

      /*
      triangle_point_0_x_register <= triangle_point_0_x_register;
      triangle_point_0_y_register <= triangle_point_0_y_register;
      triangle_point_1_x_register <= triangle_point_1_x_register;
      triangle_point_1_y_register <= triangle_point_1_y_register;
      triangle_point_2_x_register <= triangle_point_2_x_register;
      triangle_point_2_y_register <= triangle_point_2_y_register;
      */

      calculating_triangle_area <= 1'b0;

      o_triangle_loaded <= 1'b0;

      case(state)
        POINT_CALCULATION : begin
          o_triangle_loaded       <= o_triangle_loaded;
          o_point_inside_triangle <= 1'b0;
          state <= POINT_CALCULATION;

          if(i_load_triangle) begin
            o_triangle_loaded         <= 1'b0;
            calculating_triangle_area <= 1'b0;

            /*
            triangle_point_0_x_register <= i_triangle_point_0_x;
            triangle_point_0_y_register <= i_triangle_point_0_y;
            triangle_point_1_x_register <= i_triangle_point_1_x;
            triangle_point_1_y_register <= i_triangle_point_1_y;
            triangle_point_2_x_register <= i_triangle_point_2_x;
            triangle_point_2_y_register <= i_triangle_point_2_y;
            */

            calculating_triangle_area <= 1'b0;
            state <= LOADING_TRIANGLE;
          end else if (calculating_triangle_area) begin
            calculating_triangle_area <= 1'b0;
            o_triangle_loaded         <= 1'b1;
            state <= POINT_CALCULATION;
          end else if (o_triangle_loaded) begin
            if($signed(triangle_area[0]+triangle_area[1]+triangle_area[2]) <=
                ($signed(principle_triangle_area) + slack_register)) begin
              o_point_inside_triangle <= 1'b1;
            end else begin
              o_point_inside_triangle <= 1'b0;
            end
          end
        end
        LOADING_TRIANGLE  : begin
          calculating_triangle_area <= 1'b1;
          o_triangle_loaded         <= 1'b0;
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
