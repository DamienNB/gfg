module ram_dual_port #(
  parameter DEPTH = 80*60,
            WIDTH =    12,

            VIVADO_ENV = 1
) (
    input  write_clk,
    input  write_en,
    input  [$clog2(DEPTH)-1:0] write_addr,
    input  [WIDTH-1:0] data_in,

    input  read_clk,
    input  [$clog2(DEPTH)-1:0] read_addr,
    output [WIDTH-1:0] data_out
  );

  if(VIVADO_ENV) begin
    blk_mem_gen_frame_buffer inst (
      .clka(write_clk),
      .wea(write_en),
      .addra(write_addr),
      .dina(data_in),

      .clkb(read_clk),
      .addrb(read_addr),
      .doutb(data_out)
    );

  end else begin

    reg [WIDTH-1:0] memory[DEPTH-1:0];
    
    reg [WIDTH-1:0] data_out_reg = 0;
    assign data_out = data_out_reg;

    always @(posedge write_clk) begin
      if (write_en == 1) begin
        if(write_addr < DEPTH) begin
          memory[write_addr] <= data_in;
        end
      end
    end

    always @(posedge read_clk) begin
      if(read_addr < DEPTH) begin
        data_out_reg <= memory[read_addr];
      end else begin
        // assign don't cares for access attempts greater than the allowed depth
        data_out_reg <= {WIDTH{1'bx}};
      end
    end

  end

endmodule
