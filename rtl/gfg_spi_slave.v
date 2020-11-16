module gfg_spi_slave #(
  parameter NUM_REGISTERS  = 32,
            REGISTER_WIDTH = 32
) (
  input wire i_sys_clk,
  input wire i_srst_n,

  input wire i_spi_clk,
  output reg o_spi_miso,
  input wire i_spi_mosi,
  input wire i_spi_ss,

  output reg [$clog2(NUM_REGISTERS)-1:0]  o_reg_addr,
  output reg [$clog2(REGISTER_WIDTH)-1:0] o_reg_write_data,
  output reg                              o_reg_write_en,
  input wire [$clog2(REGISTER_WIDTH)-1:0] i_reg_read_data
);
  // SPI commands
  localparam CMD_NOP       = 8'b0000_0000,
             CMD_READ_REG  = 8'b0000_0001,
             CMD_WRITE_REG = 8'b0000_0010;

  reg spi_clk_reg = 1'b0;
  reg spi_clk_reg_delayed = 1'b0;

  reg spi_mosi_reg = 1'b0;
  reg spi_ss_reg   = 1'b0;

  reg [7:0] spi_mosi_shift_register = 0;
  reg [7:0] spi_miso_shift_register = 0;

  localparam STATE_INITIAL       = 4'b0001,
             STATE_RECEIVE_CMD   = 4'b0010,
             STATE_RECEIVE_DATA  = 4'b0100,
             STATE_TRANSMIT_DATA = 4'b1000;

  reg [3:0] state = STATE_INITIAL;

  always @(posedge i_sys_clk) begin
    // This is always read and is not reset,
    spi_clk_reg <= i_spi_clk;
    spi_clk_reg_delayed <= spi_clk_reg;

    if(i_srst_n == 1'b0) begin
      state <= STATE_INITIAL;
      spi_mosi_shift_register <= 0;
      spi_miso_shift_register <= 0;
      o_spi_miso <= 1'b0;
    end else begin
    end


endmodule
