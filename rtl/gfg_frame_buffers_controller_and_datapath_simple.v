// This module lays out both the datapath and control logic of the frame
// buffer system of the GFG-MCU
// While one frame is being rasterized, the previous completed frame is 
// available.
// The goal is to abstract the frame buffer control logic from the
// rasterization process and the modules that deliver a frame to displays
// Internally, there are two frame buffers. When one a frame is finished and
// enough time has passed, the frame buffers will trade places.

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

module gfg_frame_buffers_controller_and_datapath_simple #(
  parameter VERT_RESOLUTION  =  37, // TODO: Change to 640 for board synthesis
            HORIZ_RESOLUTION =  37, // TODO: Change to 480 for board synthesis
            COLOR_DEPTH      =  12,
            Z_DEPTH          =   4,
            NUM_RASTERIZERS  =   1, // TODO: Should be higher eventually
            VIVADO_ENV       =   0
) (
// general inputs
  input clk,
  input rst_n,
// input from the shape and image pools
  input drawing_pools_empty,
// inputs from rasterizers
  input [NUM_RASTERIZERS-1:0] rasterizers_write_reservation_request_flags,
  input [NUM_RASTERIZERS-1:0] rasterizers_finished_flags,
  input [NUM_RASTERIZERS*$clog2(VERT_RESOLUTION)-1:0]  rasterizers_vert_write_addrs,
  input [NUM_RASTERIZERS*$clog2(HORIZ_RESOLUTION)-1:0] rasterizers_horiz_write_addrs,
  input [NUM_RASTERIZERS-1:0] rasterizers_write_en_flags,
  input [NUM_RASTERIZERS*(COLOR_DEPTH+Z_DEPTH)-1:0] rasterizers_write_pixel_data,
  input [NUM_RASTERIZERS*$clog2(VERT_RESOLUTION)-1:0]  rasterizers_vert_read_addrs,
  input [NUM_RASTERIZERS*$clog2(HORIZ_RESOLUTION)-1:0] rasterizers_horiz_read_addrs,
// inputs from display output
  input vga_clk,
  input new_frame_requested,
  input [$clog2(VERT_RESOLUTION)-1:0]  vga_vert_read_addr,
  input [$clog2(HORIZ_RESOLUTION)-1:0] vga_horiz_read_addr,
// outputs to rasterizers
  output [NUM_RASTERIZERS-1:0] rasterizers_write_reservation_granted_flags,
  output [NUM_RASTERIZERS*(COLOR_DEPTH+Z_DEPTH)-1:0] rasterizers_read_pixel_data,
  output reg new_frame_initiated,
// output to display output
  output [(COLOR_DEPTH+Z_DEPTH)-1:0] vga_read_pixel_data
  );

  localparam FRAME_BUFFER_WIDTH = COLOR_DEPTH + Z_DEPTH;

  wire [$clog2(HORIZ_RESOLUTION)-1:0] rasterizers_horiz_write_addrs_array [NUM_RASTERIZERS-1:0];
  wire [$clog2(VERT_RESOLUTION)-1:0]  rasterizers_vert_write_addrs_array  [NUM_RASTERIZERS-1:0];
  wire [FRAME_BUFFER_WIDTH-1:0]       rasterizers_write_pixel_data_array [NUM_RASTERIZERS-1:0];

  wire [$clog2(HORIZ_RESOLUTION)-1:0] rasterizers_horiz_read_addrs_array [NUM_RASTERIZERS-1:0];
  wire [$clog2(VERT_RESOLUTION)-1:0]  rasterizers_vert_read_addrs_array  [NUM_RASTERIZERS-1:0];

  wire [FRAME_BUFFER_WIDTH-1:0] rasterizers_read_pixel_data_array [NUM_RASTERIZERS-1:0];

  // genvar used in generate block for-loops
  genvar i;

  generate

  if (NUM_RASTERIZERS == 1) begin
    assign rasterizers_horiz_write_addrs_array[0] =
      rasterizers_horiz_write_addrs[0 +: `CLOG2(HORIZ_RESOLUTION)];

    assign rasterizers_vert_write_addrs_array[0] =
      rasterizers_vert_write_addrs[0 +: `CLOG2(VERT_RESOLUTION)];

    assign rasterizers_write_pixel_data_array[0] =
      rasterizers_write_pixel_data[0 +: FRAME_BUFFER_WIDTH];

    assign rasterizers_horiz_read_addrs_array[0] =
      rasterizers_horiz_read_addrs[0 +: `CLOG2(HORIZ_RESOLUTION)];

    assign rasterizers_vert_read_addrs_array[0] =
      rasterizers_vert_read_addrs[0 +: `CLOG2(VERT_RESOLUTION)];

    assign rasterizers_read_pixel_data[0 +: FRAME_BUFFER_WIDTH] =
      rasterizers_read_pixel_data_array[i];

  end else if (NUM_RASTERIZERS > 1) begin
    for(i=0; i<NUM_RASTERIZERS; i=i+1) begin
      assign rasterizers_horiz_write_addrs_array[i] =
        rasterizers_horiz_write_addrs[i*`CLOG2(HORIZ_RESOLUTION) +: `CLOG2(HORIZ_RESOLUTION)];

      assign rasterizers_vert_write_addrs_array[i] =
        rasterizers_vert_write_addrs[i*`CLOG2(VERT_RESOLUTION) +: `CLOG2(VERT_RESOLUTION)];

      assign rasterizers_write_pixel_data_array[i] =
        rasterizers_write_pixel_data[i*FRAME_BUFFER_WIDTH +: FRAME_BUFFER_WIDTH];

      assign rasterizers_horiz_read_addrs_array[i] =
        rasterizers_horiz_read_addrs[i*`CLOG2(HORIZ_RESOLUTION) +: `CLOG2(HORIZ_RESOLUTION)];

      assign rasterizers_vert_read_addrs_array[i] =
        rasterizers_vert_read_addrs[i*`CLOG2(VERT_RESOLUTION) +: `CLOG2(VERT_RESOLUTION)];

      assign rasterizers_read_pixel_data[i*FRAME_BUFFER_WIDTH +: FRAME_BUFFER_WIDTH] =
        rasterizers_read_pixel_data_array[i];
    end
  end
  endgenerate

  // TODO: replace this with reservation units
  reg reservation_granted_temp_to_replaced;
  always @(posedge clk) begin
    reservation_granted_temp_to_replaced <= 
      rasterizers_write_reservation_request_flags;
  end
  assign rasterizers_write_reservation_granted_flags = 
    reservation_granted_temp_to_replaced;

  // latch used to indicate that the rasterizers have begun drawing to
  // a frame buffer
  reg frame_started_drawing_latch = 0;
  reg frame_started_drawing_latch_clr = 0;

  // The condition that triggers the frame_started_drawing_latch is a new
  // frame having been initiated and rasterizers beginning to make requests
  // for write reservations
  always @(posedge clk) begin
    if(rst_n == 0) begin
      frame_started_drawing_latch <= 1'b0;
    end else begin
      if(frame_started_drawing_latch_clr) begin
        frame_started_drawing_latch <= 1'b0;
      end else if(new_frame_initiated && 
                  rasterizers_write_reservation_request_flags) begin
        frame_started_drawing_latch <= 1'b1;
      end
    end
  end

  // latch used to indicate that the rasterizers have finished drawing to
  // a frame buffer
  reg frame_finished_drawing_latch = 0;
  reg frame_finished_drawing_latch_clr = 0;

  // The condition that triggers the frame_finished_drawing_latch is the
  // drawing pools being empty and the rasterizers indicating they are
  // finished drawing
  always @(posedge clk) begin
    if(rst_n == 1'b0) begin
      frame_finished_drawing_latch <= 1'b0;
    end else begin
      if(frame_finished_drawing_latch_clr) begin
        frame_finished_drawing_latch <= 1'b0;
      end else if(drawing_pools_empty && rasterizers_finished_flags) begin
        frame_finished_drawing_latch <= 1'b1;
      end
    end
  end

  // Specifies which frame buffer rasterization is being performed on. The
  // other frame buffer will be used for the display output.
  // This state machine uses gray coding for transitioning between states.
  reg rasterization_target = 1'b0;

  reg [1:0] rasterization_target_controller_state = 2'b00;

  always @(posedge clk) begin
    new_frame_initiated <= 1'b0;
    frame_started_drawing_latch_clr <= 1'b0;
    frame_finished_drawing_latch_clr <= 1'b0;

    if (rst_n == 0) begin
      rasterization_target_controller_state <= 2'b00;
      rasterization_target         <= 1'b0;
      new_frame_initiated          <= 1'b0;
      frame_started_drawing_latch_clr  <= 1'b0; // the latch itself is reset elsewhere
      frame_finished_drawing_latch_clr <= 1'b0; // the latch itself is reset elsewhere

    end else begin
      case (rasterization_target_controller_state)
        // initial state
        // waiting for the rasterization units to start drawing the frame, as
        // signaled by frame_started_drawing_latch
        2'b00 : begin
          new_frame_initiated <= 1'b1;
          frame_finished_drawing_latch_clr <= 1'b1;
          
          if(frame_started_drawing_latch == 1'b1)
            rasterization_target_controller_state <= 2'b01;
          else
            rasterization_target_controller_state <= 2'b00;
        end

        // waiting for new_frame_requested to return to 0
        // (this avoids swapping quickly-drawn frames multiple times before
        // the output is ready)
        // TODO: Is this state really necessary?
        2'b01 : begin
          if(new_frame_requested == 1'b0)
            rasterization_target_controller_state <= 2'b11;
          else
            rasterization_target_controller_state <= 2'b01;
        end

        // waiting for the frame to finished drawing, as signaled by 
        // frame_finished_drawing_latch 
        2'b11 : begin
          if(frame_finished_drawing_latch == 1'b1) begin
            frame_started_drawing_latch_clr <= 1'b0;
            rasterization_target_controller_state <= 2'b10;
          end else begin
            rasterization_target_controller_state <= 2'b11;
          end
        end

        // waiting for the now-finished frame to be requested
        // once it's finished, the rasterization_target will be flipped, the
        // frame_finished_drawing_latch will be reset to 0, and the state
        // machine will return to the initial state
        2'b10 : begin
          if(new_frame_requested == 1'b1) begin
            // swap which frame buffer is being rasterized
            rasterization_target <= !rasterization_target;
            rasterization_target_controller_state <= 2'b00;
          end else begin
            rasterization_target_controller_state <= 2'b10;
          end
        end

        default : begin
          // return to the initial state
          rasterization_target_controller_state <= 2'b00;
        end
      endcase
    end
  end


// Frame Buffer connections 
// Connections will depend on the current rasterization_target value
  wire rasterizing_frame_buffer_write_clk;
  wire rasterizing_frame_buffer_write_en;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] rasterizing_frame_buffer_vert_write_addr;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] rasterizing_frame_buffer_horiz_write_addr;
  wire [FRAME_BUFFER_WIDTH-1:0]       rasterizing_frame_buffer_data_in;

  wire rasterizing_frame_buffer_read_clk;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] rasterizing_frame_buffer_vert_read_addr;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] rasterizing_frame_buffer_horiz_read_addr;
  wire [FRAME_BUFFER_WIDTH-1:0]       rasterizing_frame_buffer_data_out;

  wire ready_frame_buffer_read_clk;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] ready_frame_buffer_vert_read_addr;
  wire [$clog2(HORIZ_RESOLUTION)-1:0] ready_frame_buffer_horiz_read_addr;
  wire [FRAME_BUFFER_WIDTH-1:0]       ready_frame_buffer_data_out;

// TODO: Add support for multiple rasterizers
  // Connections to rasterizers
  assign rasterizing_frame_buffer_write_clk = clk;
  assign rasterizing_frame_buffer_write_en = rasterizers_write_en_flags[0];
  assign rasterizing_frame_buffer_vert_write_addr = 
    rasterizers_vert_write_addrs_array[0];
  assign rasterizing_frame_buffer_horiz_write_addr = 
    rasterizers_horiz_write_addrs_array[0];

  // TODO: put this back
  // assign rasterizing_frame_buffer_data_in = rasterizers_write_pixel_data_array[0];
  reg [COLOR_DEPTH-1:0] pixel_data_counter = 0;
  always @(posedge clk)
    pixel_data_counter <= pixel_data_counter + 1;

  assign rasterizing_frame_buffer_data_in = pixel_data_counter;

  assign rasterizing_frame_buffer_read_clk = clk;
  assign rasterizing_frame_buffer_vert_read_addr = 
    rasterizers_vert_read_addrs_array[0];
  assign rasterizing_frame_buffer_horiz_read_addr = 
    rasterizers_horiz_read_addrs_array[0];

  assign rasterizers_read_pixel_data_array[0] = 
    rasterizing_frame_buffer_data_out;

  // Connections to VGA output module
  assign ready_frame_buffer_read_clk = vga_clk;

  reg vga_vert_read_addr_reg;
  always @(posedge vga_clk)
    vga_vert_read_addr_reg <= vga_vert_read_addr;
  assign ready_frame_buffer_vert_read_addr  = vga_vert_read_addr_reg;

  reg vga_horiz_read_addr_reg;
  always @(posedge vga_clk)
    vga_horiz_read_addr_reg <= vga_horiz_read_addr;
  assign ready_frame_buffer_horiz_read_addr = vga_horiz_read_addr_reg;

  assign vga_read_pixel_data = ready_frame_buffer_data_out;


// Frame Buffer 0 setup
  wire frame_buffer_0_write_clk;
  wire frame_buffer_0_write_en;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_0_write_addr;
  wire [FRAME_BUFFER_WIDTH-1:0] frame_buffer_0_data_in;

  wire frame_buffer_0_read_clk;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_0_read_addr;
  wire [FRAME_BUFFER_WIDTH-1:0] frame_buffer_0_data_out;

  ram_dual_port frame_buffer_0 (
    .write_clk(frame_buffer_0_write_clk),
    .write_en(frame_buffer_0_write_en),
    .write_addr(frame_buffer_0_write_addr),
    .data_in(frame_buffer_0_data_in),

    .read_clk(frame_buffer_0_read_clk),
    .read_addr(frame_buffer_0_read_addr),
    .data_out(frame_buffer_0_data_out));

  defparam frame_buffer_0.DEPTH = VERT_RESOLUTION * HORIZ_RESOLUTION;
  defparam frame_buffer_0.WIDTH = FRAME_BUFFER_WIDTH;

// Frame Buffer 1 setup
  wire frame_buffer_1_write_clk;
  wire frame_buffer_1_write_en;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_1_write_addr;
  wire [FRAME_BUFFER_WIDTH-1:0]     frame_buffer_1_data_in;

  wire frame_buffer_1_read_clk;
  wire [$clog2(VERT_RESOLUTION*HORIZ_RESOLUTION)-1:0] frame_buffer_1_read_addr;
  wire [FRAME_BUFFER_WIDTH-1:0]     frame_buffer_1_data_out;

  ram_dual_port frame_buffer_1 (
    .write_clk(frame_buffer_1_write_clk),
    .write_en(frame_buffer_1_write_en),
    .write_addr(frame_buffer_1_write_addr),
    .data_in(frame_buffer_1_data_in),

    .read_clk(frame_buffer_1_read_clk),
    .read_addr(frame_buffer_1_read_addr),
    .data_out(frame_buffer_1_data_out));

  defparam frame_buffer_1.DEPTH = VERT_RESOLUTION * HORIZ_RESOLUTION;
  defparam frame_buffer_1.WIDTH = FRAME_BUFFER_WIDTH;

// IMPORTANT NOTE: When reading the code below, pay attention to whether the
// rasterization_target value is being checked to be 1'b0 or 1'b1
// TODO: Add support for multiple rasterizers
  // The frame buffer write clk values can be tied to the rasterizer write
  // clk, at least for now

  // additional reg to help compensate for timing issues in read address selection
  reg read_addr_rasterization_target_reg;
  always @(posedge clk)
    read_addr_rasterization_target_reg <= rasterization_target;
  
  // frame_buffer_0 input connections
  assign frame_buffer_0_write_clk = 
    rasterizing_frame_buffer_write_clk;
  assign frame_buffer_0_write_en = 
    (rasterization_target == 1'b0) ? 
      rasterizing_frame_buffer_write_en : 1'b0;
  assign frame_buffer_0_write_addr = 
    (HORIZ_RESOLUTION*rasterizing_frame_buffer_vert_write_addr) + 
      rasterizing_frame_buffer_horiz_write_addr;
  assign frame_buffer_0_data_in = 
    rasterizing_frame_buffer_data_in;

  assign frame_buffer_0_read_clk = 
    (read_addr_rasterization_target_reg == 1'b0) ? 
      clk : vga_clk;
  assign frame_buffer_0_read_addr = 
    (read_addr_rasterization_target_reg == 1'b0) ? 
      (HORIZ_RESOLUTION*rasterizing_frame_buffer_vert_read_addr) + 
        rasterizing_frame_buffer_horiz_read_addr : 
      (HORIZ_RESOLUTION*ready_frame_buffer_vert_read_addr) + 
        ready_frame_buffer_horiz_read_addr;

  // frame_buffer_1 input connections
  assign frame_buffer_1_write_clk = 
    rasterizing_frame_buffer_write_clk;
  assign frame_buffer_1_write_en = 
    (rasterization_target == 1'b1) ? 
      rasterizing_frame_buffer_write_en : 1'b0;
  assign frame_buffer_1_write_addr = 
    (HORIZ_RESOLUTION*rasterizing_frame_buffer_vert_write_addr) + 
      rasterizing_frame_buffer_horiz_write_addr;
  assign frame_buffer_1_data_in = 
    rasterizing_frame_buffer_data_in;

  assign frame_buffer_1_read_clk = 
    (read_addr_rasterization_target_reg == 1'b1) ? 
      clk : vga_clk;
  assign frame_buffer_1_read_addr = 
    (read_addr_rasterization_target_reg == 1'b1) ? 
      (HORIZ_RESOLUTION*rasterizing_frame_buffer_vert_read_addr) + 
        rasterizing_frame_buffer_horiz_read_addr : 
      (HORIZ_RESOLUTION*ready_frame_buffer_vert_read_addr) + 
        ready_frame_buffer_horiz_read_addr;

  // frame buffer data output connections
  assign rasterizing_frame_buffer_data_out = 
    (rasterization_target == 1'b0) ? 
      frame_buffer_0_data_out : 
      frame_buffer_1_data_out;

  assign ready_frame_buffer_data_out =
    (read_addr_rasterization_target_reg == 1'b1) ? 
      frame_buffer_0_data_out : 
      frame_buffer_1_data_out;

endmodule
