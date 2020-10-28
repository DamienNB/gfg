`timescale 1 ns/100 ps

module rasterizer_tb ();

  parameter VERT_RESOLUTION  = 60,
            HORIZ_RESOLUTION = 80; // TODO: Add more parameters

  reg i_clk = 1'b0;
  reg i_srst_n = 1'b1;
  reg i_go = 1'b0;

  wire [$clog2(VERT_RESOLUTION)-1:0]  o_vert_write_addr;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] o_horiz_write_addr;

  wire [3:0] o_red;
  wire [3:0] o_green;
  wire [3:0] o_blue;
  wire o_write_en;
  wire o_done;

  rasterizer #(
    .VERT_RESOLUTION(VERT_RESOLUTION),
    .HORIZ_RESOLUTION(HORIZ_RESOLUTION)
  ) UUT (
    .i_clk(i_clk),
    .i_srst_n(i_srst_n),
    .i_go(i_go),

    .i_triangle_point_0_x(10),
    .i_triangle_point_0_y(10),
    .i_triangle_point_1_x(10),
    .i_triangle_point_1_y(70),
    .i_triangle_point_2_x(70),
    .i_triangle_point_2_y(30),

    .o_vert_write_addr(o_vert_write_addr),
    .o_horiz_write_addr(o_horiz_write_addr),
    .o_red(o_red),
    .o_green(o_green),
    .o_blue(o_blue),
    .o_write_en(o_write_en),
    .o_done(o_done)
  );

  always #1 i_clk <= ~i_clk;

  integer i;
  initial begin
    #10 i_go <= 1'b1;

    #10 i_go <= 1'b0;

    for(i=0; i<4*VERT_RESOLUTION*HORIZ_RESOLUTION; i=i+1) begin
      #1 ;
    end

    $finish;
  end

  initial begin
    $dumpfile("rasterizer_tb.lxt");
    $dumpvars(0,
              i_clk,i_srst_n,
              i_go,
              o_vert_write_addr,
              o_horiz_write_addr,
              o_red,
              o_green,
              o_blue,
              o_write_en,
              o_done,
              UUT.state);
  end
endmodule
