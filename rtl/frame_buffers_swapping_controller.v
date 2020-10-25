module frame_buffers_swapping_controller
(
  input i_clk,
  input i_srst_n,

  input i_raster_in_progress,
  input i_frame_buffer_swap_allowed,

  output reg o_new_frame = 1'b1,
  output reg o_rasterization_target = 1'b0
);

// one-hot state machine
localparam FRAME_READY = 3'b001, RASTER_IN_PROGRESS = 3'b010, FRAME_FINISHED = 3'b100;
reg [2:0] state = FRAME_READY; // initial state is FRAME_READY

always @(posedge i_clk) begin
  if(i_srst_n == 1'b0) begin
    o_new_frame <= 1'b1;
    state <= FRAME_READY; // return to FRAME_READY

    // keep the rasterization target the same
    // no need for reset logic
    o_rasterization_target <= o_rasterization_target;

  end else begin
    o_new_frame <= 1'b0;
    state <= FRAME_READY;
    o_rasterization_target <= o_rasterization_target;

    case(state)
      FRAME_READY        : begin
        if(i_raster_in_progress) begin
          o_new_frame <= 1'b0;
          state <= RASTER_IN_PROGRESS;
        end else begin
          o_new_frame <= 1'b1;
          state <= FRAME_READY;
        end
      end

      RASTER_IN_PROGRESS : begin
        o_new_frame <= 1'b0;
        if(i_raster_in_progress)
          state <= RASTER_IN_PROGRESS;
        else
          state <= FRAME_FINISHED;
      end

      FRAME_FINISHED     : begin
        if(i_frame_buffer_swap_allowed) begin
          o_rasterization_target <= !o_rasterization_target;
          o_new_frame <= 1'b1;
          state <= FRAME_READY;
        end else begin
          o_new_frame <= 1'b0;
          state <= FRAME_FINISHED;
        end
      end

      default            : begin
        state <= FRAME_READY;
      end
    endcase
  end
end
endmodule
