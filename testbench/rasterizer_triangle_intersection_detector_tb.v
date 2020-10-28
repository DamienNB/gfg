`timescale 1 ns/100 ps

module rasterizer_triangle_intersection_detector_tb ();
  parameter VERT_RESOLUTION  = 60,
            HORIZ_RESOLUTION = 80;
  
  reg i_clk = 0;
  reg i_srst_n = 0;
  reg i_load_triangle = 0;

  reg [(2*$clog2(HORIZ_RESOLUTION))-1:0] i_current_point_x = 0;
  reg [(2*$clog2(VERT_RESOLUTION))-1:0]  i_current_point_y = 0;

  reg [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_0_x = 10;
  reg [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_0_y = 10;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_1_x = 10;
  reg [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_1_y = 50;
  reg [$clog2(HORIZ_RESOLUTION)-1:0] i_triangle_point_2_x = 50;
  reg [$clog2(VERT_RESOLUTION)-1:0]  i_triangle_point_2_y = 25;

  reg signed [7:0] i_slack = 0;

  wire unsigned [63:0] triangle_areas_sum;

  wire o_triangle_loaded;
  wire o_point_inside_triangle;

  rasterizer_triangle_intersection_detector #(
    .VERT_RESOLUTION(VERT_RESOLUTION),
    .HORIZ_RESOLUTION(HORIZ_RESOLUTION)
  ) UUT (
    .i_clk(i_clk),
    .i_srst_n(i_srst_n),
    .i_load_triangle(i_load_triangle),
    .i_current_point_x(i_current_point_x),
    .i_current_point_y(i_current_point_y),
    .i_triangle_point_0_x(i_triangle_point_0_x),
    .i_triangle_point_0_y(i_triangle_point_0_y),
    .i_triangle_point_1_x(i_triangle_point_1_x),
    .i_triangle_point_1_y(i_triangle_point_1_y),
    .i_triangle_point_2_x(i_triangle_point_2_x),
    .i_triangle_point_2_y(i_triangle_point_2_y),
    .i_slack(i_slack),
    .o_triangle_loaded(o_triangle_loaded),
    .o_point_inside_triangle(o_point_inside_triangle)
  );
  assign triangle_areas_sum = UUT.triangle_area[0] + UUT.triangle_area[1] + UUT.triangle_area[2];

  always #1 i_clk <= ~i_clk;

  integer i, j;
  initial begin
    i_clk <= 1'b0;
    i_srst_n <= 1'b1;
    i_load_triangle <= 1'b0;

    #6 ;

    i_srst_n <= 1'b0;

    #6 ;

    i_srst_n <= 1'b1;

    #6 ;

    i_load_triangle <= 1'b1;

    #2 ;

    i_load_triangle <= 1'b0;

    #8 ;

    for(i=0; i<VERT_RESOLUTION; i=i+1) begin
      for(j=0; j<HORIZ_RESOLUTION; j=j+1) begin
        i_current_point_x = j;
        i_current_point_y = i;

        #8 ;

        if(o_point_inside_triangle)
          $write("*");
        else
          $write(".");
      end
      $write("\n");
    end
    
    #6 $finish;
  end

  initial begin
    $dumpfile("rasterizer_triangle_intersection_detector_tb.lxt");
    $dumpvars(0,
              i_clk,i_srst_n,
              i_load_triangle,
              i_current_point_x,
              i_current_point_y,
              i_triangle_point_0_x,
              i_triangle_point_0_y,
              i_triangle_point_1_x,
              i_triangle_point_1_y,
              i_triangle_point_2_x,
              i_triangle_point_2_y,
              i_slack,
              o_triangle_loaded,
              o_point_inside_triangle,
              UUT.state,
              UUT.triangle_point_0_x_register,
              UUT.triangle_point_0_y_register,
              UUT.triangle_point_1_x_register,
              UUT.triangle_point_1_y_register,
              UUT.triangle_point_2_x_register,
              UUT.triangle_point_2_y_register,
              UUT.cross_product_input_a[0],
              UUT.cross_product_input_b[0],
              UUT.cross_product_input_c[0],
              UUT.cross_product_input_d[0],
              UUT.cross_product[0],
              UUT.cross_product_absolute_value[0],
              UUT.principle_triangle_area,
              UUT.triangle_area[0],
              UUT.triangle_area[1],
              UUT.triangle_area[2],
              triangle_areas_sum
    );
  end
endmodule
