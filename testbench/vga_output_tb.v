`timescale 1 ns/100 ps

module vga_output_tb;
  // Default vals taken from Digilent's Pmod VGA Reference Manual on 2020-09-29
  // https://reference.digilentinc.com/reference/pmod/pmodvga/reference-manual
  parameter HORIZ_RESOLUTION  = 640,
            HORIZ_FRONT_PORCH =  16,
            HORIZ_SYNC_PULSE  =  96,
            HORIZ_BACK_PORCH  =  48,

            VERT_RESOLUTION  = 480,
            VERT_FRONT_PORCH =  10,
            VERT_SYNC_PULSE  =   2,
            VERT_BACK_PORCH  =  29,

            OUTPUT_DELAY_COUNT = 1;

  localparam HORIZ_TOTAL = HORIZ_RESOLUTION  + 
                           HORIZ_FRONT_PORCH + 
                           HORIZ_SYNC_PULSE  + 
                           HORIZ_BACK_PORCH;

  localparam VERT_TOTAL = VERT_RESOLUTION  + 
                          VERT_FRONT_PORCH + 
                          VERT_SYNC_PULSE  + 
                          VERT_BACK_PORCH;
  reg pixel_clk;
  reg rst_n;

  wire frame_buffer_swap_allowed;

  wire horizontal_sync;
  wire [9:0] horizontal_addr;

  wire vertical_sync;
  wire [8:0] vertical_addr;

  integer i;

  vga_output UUT (
    .pixel_clk(pixel_clk),
    .rst_n(rst_n),
    .frame_buffer_swap_allowed(frame_buffer_swap_allowed),
    .horiz_sync(horizontal_sync),
    .horiz_addr(horizontal_addr),
    .vert_sync(vertical_sync),
    .vert_addr(vertical_addr));
  defparam UUT.HORIZ_RESOLUTION   = HORIZ_RESOLUTION;
  defparam UUT.HORIZ_FRONT_PORCH  = HORIZ_FRONT_PORCH;
  defparam UUT.HORIZ_SYNC_PULSE   = HORIZ_SYNC_PULSE;
  defparam UUT.HORIZ_BACK_PORCH   = HORIZ_BACK_PORCH;
  defparam UUT.VERT_RESOLUTION    = VERT_RESOLUTION;
  defparam UUT.VERT_FRONT_PORCH   = VERT_FRONT_PORCH;
  defparam UUT.VERT_SYNC_PULSE    = VERT_SYNC_PULSE;
  defparam UUT.VERT_BACK_PORCH    = VERT_BACK_PORCH;
  defparam UUT.OUTPUT_DELAY_COUNT = OUTPUT_DELAY_COUNT;

  always begin
    pixel_clk = 1'b0;
    #1;

    pixel_clk = 1'b1;
    #1;
  end

  initial begin
    for (i=0; i<2*(HORIZ_TOTAL*VERT_TOTAL); i=i+1) begin
      if (i <= 9) begin
        rst_n = 0;
      end else begin
        rst_n = 1;
      end
      #2;
    end
    #2 $finish;
  end

  initial begin
    $dumpfile("vga_output_tb.lxt");
    $dumpvars(0,
      pixel_clk,rst_n,
      frame_buffer_swap_allowed,
      horizontal_sync,vertical_sync,
      horizontal_addr,vertical_addr,
      UUT.horiz_counter,UUT.vert_counter,
      UUT.horiz_counter_delayed,UUT.vert_counter_delayed,
      UUT.currently_drawing_screen
    );
  end
endmodule
