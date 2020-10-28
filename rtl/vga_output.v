module vga_output #(
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

            OUTPUT_DELAY_COUNT = 2
  ) (
    input pixel_clk, // If running with default values, expects 25 MHz
    input rst_n,
    input [3:0] red_in,
    input [3:0] green_in,
    input [3:0] blue_in,
    output reg frame_buffer_swap_allowed,
    output [$clog2(HORIZ_RESOLUTION)-1:0] horiz_addr,
    output [$clog2(VERT_RESOLUTION)-1:0] vert_addr,
    output horiz_sync,
    output vert_sync,
    output [3:0] red_out,
    output [3:0] green_out,
    output [3:0] blue_out
  );

  localparam HORIZ_TOTAL = HORIZ_RESOLUTION  + 
    HORIZ_FRONT_PORCH + 
    HORIZ_SYNC_PULSE  + 
    HORIZ_BACK_PORCH;

  localparam VERT_TOTAL = VERT_RESOLUTION  + 
    VERT_FRONT_PORCH + 
    VERT_SYNC_PULSE  + 
    VERT_BACK_PORCH;

  wire currently_drawing_screen;

  // location (0,0) is the upper-left most pixel
  // the horiz_counter increases the further right the position is
  // the vert_counter increases the further down the position is
  // the delayed version are responsible for logic related to the vga_output,
  // since the point is to provide enough of a read-ahead to deliver the pixel
  // data in time
  reg [$clog2(HORIZ_TOTAL)-1:0] horiz_counter = 0;
  reg [$clog2(VERT_TOTAL)-1:0]  vert_counter  = 0;
  wire [$clog2(HORIZ_TOTAL)-1:0] horiz_counter_delayed;
  wire [$clog2(VERT_TOTAL)-1:0]  vert_counter_delayed;

  generate
  // case of no delay
  if(OUTPUT_DELAY_COUNT == 0) begin
    assign horiz_counter_delayed = horiz_counter;
    assign vert_counter_delayed = vert_counter;

  // case of one clock cycle delay
  end else if (OUTPUT_DELAY_COUNT == 1) begin
    reg [$clog2(HORIZ_TOTAL)-1:0] horiz_counter_delay_reg;
    reg [$clog2(VERT_TOTAL)-1:0]  vert_counter_delay_reg;

    always @(posedge pixel_clk) begin
      if (rst_n == 1'b0) begin
        horiz_counter_delay_reg = 0;
        vert_counter_delay_reg  = 0;
      end else begin
        horiz_counter_delay_reg <= horiz_counter;
        vert_counter_delay_reg  <= vert_counter;
      end
    end

    assign horiz_counter_delayed = horiz_counter_delay_reg;
    assign vert_counter_delayed  = vert_counter_delay_reg;

  // case of multiple clock cycle delay
  end else begin
    reg [$clog2(HORIZ_TOTAL)-1:0] horiz_counter_delay_reg [OUTPUT_DELAY_COUNT-1:0];
    reg [$clog2(VERT_TOTAL)-1:0]  vert_counter_delay_reg  [OUTPUT_DELAY_COUNT-1:0];

    integer i;
    always @(posedge pixel_clk) begin
      if (rst_n == 1'b0) begin
        for(i=0; i<OUTPUT_DELAY_COUNT; i=i+1) begin
          horiz_counter_delay_reg[i] = 0;
          vert_counter_delay_reg[i]  = 0;
        end
      end else begin
        for(i=OUTPUT_DELAY_COUNT-1; i>0; i=i-1) begin
          horiz_counter_delay_reg[i] <= horiz_counter_delay_reg[i-1];
          vert_counter_delay_reg[i]  <= vert_counter_delay_reg[i-1];
        end
        horiz_counter_delay_reg[0] <= horiz_counter;
        vert_counter_delay_reg[0]  <= vert_counter;
      end
    end

    assign horiz_counter_delayed = horiz_counter_delay_reg [OUTPUT_DELAY_COUNT-1];
    assign vert_counter_delayed  = vert_counter_delay_reg  [OUTPUT_DELAY_COUNT-1];
  end
  endgenerate

  // This is similar to vert_counter, except it only keeps count up to the
  // vertical resolution, and increments at the start of the front porch
  // rather than at the end of the back porch
  // This is done for addressing, so the next needed line of the frame can be
  // requested in the vert_addr before the line is actually finished
  reg [$clog2(VERT_RESOLUTION)-1:0] horiz_lines_drawn_counter = 0;

  always @(posedge pixel_clk) begin
    if (rst_n == 0) begin
      horiz_counter             <= 0;
      horiz_lines_drawn_counter <= 0;
      vert_counter              <= 0;
      frame_buffer_swap_allowed <= 0;

    end else begin
      // These value boundaries are conservative. There is additional time on
      // each side that could also be included, but it would involve more
      // complex logic that monitors the horizontal counter. This could be
      // implemented, but it's currently unnecessary and may introduce
      // problems 
      frame_buffer_swap_allowed <= (vert_counter >= VERT_RESOLUTION) && 
                                   (vert_counter < VERT_TOTAL-1);

      if (horiz_counter < HORIZ_TOTAL-1) begin
        horiz_counter <= horiz_counter + 1;

        // increment horiz_lines_drawn when the visible portion of
        // a visible horizontal line is finished being counted by
        // horiz_counter
        if ((horiz_counter == HORIZ_RESOLUTION - 1) && 
            (vert_counter < VERT_RESOLUTION)) begin
          if (horiz_lines_drawn_counter < VERT_RESOLUTION-1) begin
            horiz_lines_drawn_counter <= horiz_lines_drawn_counter + 1;
          end else begin
            horiz_lines_drawn_counter <= 0;
          end
        end else begin
          horiz_lines_drawn_counter <= horiz_lines_drawn_counter;
        end

        vert_counter <= vert_counter;

      end else begin
        horiz_counter <= 0;

        horiz_lines_drawn_counter <= horiz_lines_drawn_counter;

        if (vert_counter < VERT_TOTAL-1) begin
          vert_counter <= vert_counter + 1;
        end else begin
          vert_counter <= 0;
        end

      end
    end
  end

  assign horiz_addr = ((horiz_counter < HORIZ_RESOLUTION) &&
                       (vert_counter < VERT_RESOLUTION)) ? 
                      horiz_counter : 0;

  assign vert_addr = (horiz_lines_drawn_counter < VERT_RESOLUTION) ? 
                      horiz_lines_drawn_counter : 0;

  assign horiz_sync = !((horiz_counter_delayed >= (HORIZ_RESOLUTION + 
                                                   HORIZ_FRONT_PORCH)) &&
                        (horiz_counter_delayed < (HORIZ_TOTAL - 
                                                  HORIZ_BACK_PORCH)));

  assign vert_sync = !((vert_counter_delayed >= (VERT_RESOLUTION + 
                                                 VERT_FRONT_PORCH)) &&
                       (vert_counter_delayed < (VERT_TOTAL - 
                                                VERT_BACK_PORCH)));

  /*
  assign red_out   = red_in;
  assign green_out = green_in;
  assign blue_out  = blue_in;
  */
  assign currently_drawing_screen = ((horiz_counter_delayed < HORIZ_RESOLUTION) && 
                                     (vert_counter_delayed < VERT_RESOLUTION));

  assign red_out   = currently_drawing_screen ? red_in   : 0;
  assign green_out = currently_drawing_screen ? green_in : 0;
  assign blue_out  = currently_drawing_screen ? blue_in  : 0;

/*
  always @(vert_counter) begin
    vert_sync = vert_counter < VERT_SYNC_PULSE;

    if ((vert_addr > (VERT_SYNC_PULSE + VERT_BACK_PORCH)) &&
        (vert_addr < VERT_TOTAL - VERT_FRONT_PORCH)) begin
      vert_addr = vert_counter - VERT_SYNC_PULSE - VERT_BACK_PORCH;
    end else begin
      vert_addr = 0;
    end
  end
*/
endmodule
