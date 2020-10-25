`timescale 1 ns/100 ps

module frame_buffers_swapping_controller_tb ();

  reg i_clk = 0;
  reg i_srst_n = 1;

  reg i_raster_in_progress = 0;
  reg i_frame_buffer_swap_allowed = 0;

  wire o_new_frame;
  wire o_rasterization_target;
  
  frame_buffers_swapping_controller UUT (
    .i_clk(i_clk),
    .i_srst_n(i_srst_n),
    .i_raster_in_progress(i_raster_in_progress),
    .i_frame_buffer_swap_allowed(i_frame_buffer_swap_allowed),
    .o_new_frame(o_new_frame),
    .o_rasterization_target(o_rasterization_target)
  );

  /*
  localparam FRAME_READY = UUT.FRAME_READY;
  localparam RASTER_IN_PROGRESS = UUT.RASTER_IN_PROGRESS;
  localparam FRAME_FINISHED = UUT.FRAME_FINISHED;
  */

  always #1 i_clk <= ~i_clk;

  integer i;
  initial begin
    i_clk <= 1'b0;
    i_srst_n <= 1'b1;
    i_raster_in_progress <= 1'b0;
    i_frame_buffer_swap_allowed <= 1'b0;

    // Checking initial state
    for(i=0; i<10; i=i+1) begin
      if(UUT.state != UUT.FRAME_READY) begin
        $display("%t ERROR: state is %03b, should be %03b initially",
          $time, UUT.state, UUT.FRAME_READY);
      end
      if(o_new_frame != 1'b1) begin
        $display("%t ERROR: o_new_frame value is %01b, should be 1 initially",
          $time, o_new_frame);
      end
      if(o_rasterization_target != 1'b0) begin
        $display("%t ERROR: o_new_frame value is %01b, should be 1 initially",
          $time, o_rasterization_target);
      end
      #1 ;
    end

    // doing a reset
    i_srst_n <= 1'b0;
    for(i=0; i<10; i=i+1) begin
      if(UUT.state != UUT.FRAME_READY) begin
        $display("%t ERROR: state is %03b, should be %03b during reset",
          $time, UUT.state, UUT.FRAME_READY);
      end
      if(o_new_frame != 1'b1) begin
        $display("%t ERROR: o_new_frame value is %01b, should be during reset",
          $time, o_new_frame);
      end
      if(o_rasterization_target != 1'b0) begin
        $display("%t ERROR: o_new_frame value is %01b, should be during reset",
          $time, o_rasterization_target);
      end
      #1 ;
    end

    // testing state transitions with rasterization finished before
    // i_frame_buffer_swap_allowed changes to 1'b1
    i_srst_n <= 1'b1;
    for(i=0; i<4; i=i+1) begin
      if(UUT.state != UUT.FRAME_READY) begin
        $display("%t ERROR: state is %03b, should be %03b",
          $time, UUT.state, UUT.FRAME_READY);
      end
      if(o_new_frame != 1'b1) begin
        $display("%t ERROR: o_new_frame value is %01b, should be 1",
          $time, o_new_frame);
      end
      if(o_rasterization_target != 1'b0) begin
        $display("%t ERROR: o_new_frame value is %01b, should be 0",
          $time, o_rasterization_target);
      end
      #1 ;
    end
  // transition to RASTER_IN_PROGRESS state
    i_raster_in_progress <= 1'b1;
    // doesn't change until next rising clk edge
    if(UUT.state != UUT.FRAME_READY) begin
      $display("%t ERROR: state is %03b, should be %03b",
        $time, UUT.state, UUT.FRAME_READY);
    end
    if(o_new_frame != 1'b1) begin
      $display("%t ERROR: o_new_frame value is %01b, should be 1",
        $time, o_new_frame);
    end
    if(o_rasterization_target != 1'b0) begin
      $display("%t ERROR: o_new_frame value is %01b, should be 0",
        $time, o_rasterization_target);
    end
    #2 ;
    // verifying change
    for(i=0; i<2; i=i+1) begin
      if(UUT.state != UUT.RASTER_IN_PROGRESS) begin
        $display("%t ERROR: state is %03b, should be %03b",
          $time, UUT.state, UUT.RASTER_IN_PROGRESS);
      end
      if(o_new_frame != 1'b0) begin
        $display("%t ERROR: o_new_frame value is %01b, should be 0",
          $time, o_new_frame);
      end
      if(o_rasterization_target != 1'b0) begin
        $display("%t ERROR: o_new_frame value is %01b, should be 0",
          $time, o_rasterization_target);
      end
      #2 ;
    end
  // change i_raster_in_progress to 1'b0
    i_raster_in_progress <= 1'b0;

    #10 ;

    i_frame_buffer_swap_allowed <= 1'b1;

    #10 ;

  // trying reset in RASTER_IN_PROGRESS state
    $display("%t: trying reset in RASTER_IN_PROGRESS state", $time);
    i_raster_in_progress <= 1'b1;

    #10 ;

    i_srst_n <= 1'b0;

    #10 ;

    i_srst_n <= 1'b1;
    // change i_raster_in_progress to 1'b0
    i_raster_in_progress <= 1'b0;

    #10 ;

  // trying reset in FRAME_FINISHED state
    $display("%t: trying reset in FRAME_FINISHED state", $time);
    i_frame_buffer_swap_allowed <= 1'b0;
    i_raster_in_progress <= 1'b1;

    #10 ;

    i_raster_in_progress <= 1'b0;

    #10 ;

    i_srst_n <= 1'b0;

    #10 ;

    i_srst_n <= 1'b1;

    #10 ;

    #2 $finish;
  end

  initial begin
    $dumpfile("frame_buffers_swapping_controller_tb.lxt");
    $dumpvars(0,
              i_clk,i_srst_n,
              i_raster_in_progress,
              i_frame_buffer_swap_allowed,
              o_new_frame,
              o_rasterization_target,
              UUT.state);
  end
endmodule
