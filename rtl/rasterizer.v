module rasterizer #(
  parameter VERT_RESOLUTION  = 60,
            HORIZ_RESOLUTION = 80 // TODO: Add more parameters
) (
  input wire i_clk,
  input wire i_srst_n,
  input wire i_go,

  output reg [$clog2(VERT_RESOLUTION)-1:0]  o_vert_write_addr  = 0,
  output reg [$clog2(HORIZ_RESOLUTION)-1:0] o_horiz_write_addr = 0,

  output wire [3:0] o_red,
  output wire [3:0] o_green,
  output wire [3:0] o_blue,
  output reg o_write_en = 1'b0,
  output reg o_done =     1'b0
  );

  localparam WAIT = 2'b01, RASTERIZE = 2'b10; 
  reg [1:0] state = WAIT;

  wire [11:0] color_wire;
  assign o_red   = (o_vert_write_addr/4);
  assign o_green = 0;
  assign o_blue  = 0;

  always @(posedge i_clk) begin
    if(i_srst_n == 1'b0) begin
      state              <= WAIT;
      o_vert_write_addr  <= 0;
      o_horiz_write_addr <= 0;
      o_write_en         <= 1'b0;
      o_done             <= 1'b0;
    end else begin
      // defaults to be overridden by state behaviors
      state              <= WAIT;
      o_vert_write_addr  <= 0;
      o_horiz_write_addr <= 0;
      o_write_en         <= 1'b0;
      o_done             <= 1'b0;

      case(state)
        WAIT      : begin
          o_vert_write_addr  <= 0;
          o_horiz_write_addr <= 0;
          o_done <= o_done;

          if(i_go) begin
            state <= RASTERIZE;
            o_write_en <= 1'b1;
          end else begin
            state <= WAIT;
            o_write_en <= 1'b0;
          end
        end

        RASTERIZE : begin
          state      <= RASTERIZE;
          o_write_en <= 1'b1;
          o_done     <= 1'b0;

          if(o_horiz_write_addr < HORIZ_RESOLUTION-1) begin
            o_horiz_write_addr <= o_horiz_write_addr + 1;
            o_vert_write_addr  <= o_vert_write_addr;
          end else begin
            o_horiz_write_addr <= 0;
            if(o_vert_write_addr < VERT_RESOLUTION-1) begin
              o_vert_write_addr <= o_vert_write_addr + 1;
            end else begin
              o_vert_write_addr <= 0;
              state      <= WAIT;
              o_write_en <= 1'b0;
              o_done     <= 1'b1;
            end
          end
        end
        default  : begin
          state <= WAIT;
        end
      endcase
    end
  end
endmodule
