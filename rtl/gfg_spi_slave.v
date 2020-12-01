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

module gfg_spi_slave #(
  parameter NUM_REGISTERS  = 32,
            REGISTER_WIDTH = 32
) (
  input wire i_sys_clk,
  input wire i_srst_n,

  input wire i_spi_clk,
  output reg o_spi_miso = 1'b0,
  input wire i_spi_mosi,
  input wire i_spi_ss_n,

  output reg  [$clog2(NUM_REGISTERS)-1:0] o_reg_addr       = 0,
  output wire [REGISTER_WIDTH-1:0]        o_reg_write_data,
  output reg                              o_reg_write_en   = 1'b0,
  input wire  [REGISTER_WIDTH-1:0]        i_reg_read_data,

  output wire [5:0] o_state
);
  // SPI commands
  localparam COMMAND_WIDTH = 2;
  localparam CMD_NO_OP     = 2'b00,
             CMD_READ_REG  = 2'b01,
             CMD_WRITE_REG = 2'b10;

  // code based on example from https://electronics.stackexchange.com/a/71226
  /*
  generate
  if ($clog2(NUM_REGISTERS) + COMMAND_WIDTH > 8) begin
    illegal_param_condition_triggered_will_instantiate non_existing_module();
  end
  if (REGISTER_WIDTH < 8) begin
    illegal_param_condition_triggered_will_instantiate non_existing_module();
  end
  endgenerate
  */

  reg spi_clk_reg         = 1'b1;
  reg spi_clk_reg_delayed = 1'b1;

  reg spi_ss_n_reg = 1'b0;

  reg [7:0] spi_mosi_shift_register = 0;
  reg [$clog2(REGISTER_WIDTH):0] shift_register_tracker  = 0;

  reg [REGISTER_WIDTH-1:0] register_local_copy = 0;
  assign o_reg_write_data = register_local_copy;

  localparam real REGISTER_WIDTH_FLOAT = REGISTER_WIDTH;

  localparam STATE_INITIAL                 = 6'b000001,
             STATE_RECEIVE_CMD             = 6'b000010,
             STATE_LOAD_DATA_TO_TRANSMIT   = 6'b000100,
             STATE_TRANSMIT_DATA           = 6'b001000,
             STATE_RECEIVE_DATA            = 6'b010000,
             STATE_STORE_RECEIVED_DATA     = 6'b100000;

  reg [5:0] state = STATE_INITIAL;
  assign o_state = state;

  always @(posedge i_sys_clk) begin
    // This is always read and is not reset,
    spi_clk_reg         <= i_spi_clk;
    spi_clk_reg_delayed <= spi_clk_reg;

    spi_ss_n_reg <= i_spi_ss_n;

    if(i_srst_n == 1'b0) begin
      state <= STATE_INITIAL;
      spi_mosi_shift_register <= 0;
      o_spi_miso <= 1'b0;

      register_local_copy <= 0;

      o_reg_addr       <= 0;
      o_reg_write_en   <= 1'b0;
    end else begin
      state <= state;
      register_local_copy <= register_local_copy;
      o_reg_addr          <= o_reg_addr;

      o_spi_miso <= 1'b0;

      o_reg_write_en   <= 1'b0;

      case(state)
        STATE_INITIAL : begin
          // hold onto the last transmitted bit on miso to give time for the
          // last bit of a slave-to-master transmission to be read
          o_spi_miso <= o_spi_miso;

          if(spi_ss_n_reg == 1'b0) begin
            if(spi_clk_reg == 1'b0) begin
              spi_mosi_shift_register <= 0;
              shift_register_tracker  <= 0;
              state <= STATE_RECEIVE_CMD;
            end
          end else begin
            state <= STATE_INITIAL;
          end
        end
        STATE_RECEIVE_CMD : begin
          if(spi_ss_n_reg == 1'b0) begin
            if(shift_register_tracker < 8) begin
              // shift in command on rising spi_clk edge
              if((spi_clk_reg == 1'b1) && (spi_clk_reg_delayed == 1'b0)) begin
                spi_mosi_shift_register    <= spi_mosi_shift_register << 1;
                spi_mosi_shift_register[0] <= i_spi_mosi;

                shift_register_tracker <= shift_register_tracker + 1;
              end
            end else begin
              case(spi_mosi_shift_register[7 -: COMMAND_WIDTH])
                CMD_NO_OP     : begin
                  state <= STATE_INITIAL;
                end
                CMD_READ_REG  : begin
                  o_reg_addr <= 
                    spi_mosi_shift_register[0 +: `CLOG2(NUM_REGISTERS)];
                  shift_register_tracker  <= 0;
                  state <= STATE_LOAD_DATA_TO_TRANSMIT;
                end
                CMD_WRITE_REG : begin
                  o_reg_addr <= 
                    spi_mosi_shift_register[0 +: `CLOG2(NUM_REGISTERS)];
                  shift_register_tracker  <= 0;
                  state <= STATE_RECEIVE_DATA;

                end
                // default should be the same as CMD_NO_OP
                default       : begin
                  state <= STATE_INITIAL;
                end
              endcase
            end
          /*
          end else if(shift_register_tracker%8 != 0) begin
            // return to initial state if SS is interrupt mid-byte
            state <= STATE_INITIAL;
          */
          end else begin
            state <= STATE_INITIAL;
          end
        end
        STATE_LOAD_DATA_TO_TRANSMIT : begin
          o_reg_addr            <= o_reg_addr;
          register_local_copy   <= i_reg_read_data;
          state <= STATE_TRANSMIT_DATA;
        end
        STATE_TRANSMIT_DATA : begin
          o_reg_addr            <= o_reg_addr;
          shift_register_tracker <= shift_register_tracker;
          o_spi_miso <= o_spi_miso;
          if(spi_ss_n_reg == 1'b0) begin
            // shift out data on falling edge
            if((spi_clk_reg == 1'b0) && (spi_clk_reg_delayed == 1'b1)) begin
              if(shift_register_tracker < REGISTER_WIDTH) begin
                // shift out register data
                o_spi_miso          <= register_local_copy[REGISTER_WIDTH-1];
                register_local_copy <= register_local_copy << 1;

                shift_register_tracker <= shift_register_tracker + 1;

              // accounting for register widths not divisible by 8 by
              // bit-padding with 0's
              end else if (shift_register_tracker%8 != 0) begin
                o_spi_miso <= 1'b0;
                shift_register_tracker <= shift_register_tracker + 1;
              end else begin
                state <= STATE_INITIAL;
              end
            end
          end else if(shift_register_tracker%8 != 0) begin
            // return to initial state if SS goes high mid-byte
            state <= STATE_INITIAL;
          end else if(shift_register_tracker >= REGISTER_WIDTH) begin
            // return to initial state if SS is high after the transmission is
            // complete
            state <= STATE_INITIAL;
          end else begin
            state <= STATE_TRANSMIT_DATA;
          end
        end
        STATE_RECEIVE_DATA : begin
          register_local_copy    <= register_local_copy;
          shift_register_tracker <= shift_register_tracker;

          o_reg_addr <= o_reg_addr;

          if(spi_ss_n_reg == 1'b0) begin
            // shift in data on rising edge
            if((spi_clk_reg == 1'b1) && (spi_clk_reg_delayed == 1'b0)) begin
              if(shift_register_tracker < REGISTER_WIDTH) begin
                // shift in register data
                register_local_copy    <= register_local_copy << 1;
                register_local_copy[0] <= i_spi_mosi;
            
                shift_register_tracker <= shift_register_tracker + 1;

              // accounting for register widths not divisible by 8 by
              // ignoring the bottom-most bits transmitted
              end else if (shift_register_tracker%8 != 0) begin
                shift_register_tracker <= shift_register_tracker + 1;
              end else begin
                state <= STATE_STORE_RECEIVED_DATA;
              end
            end
          end else if(shift_register_tracker%8 != 0) begin
            // return to initial state if SS goes high mid-byte
            state <= STATE_INITIAL;
          end else if(shift_register_tracker >= REGISTER_WIDTH) begin
            // return to initial state if SS is high after the transmission is
            // complete
            state <= STATE_STORE_RECEIVED_DATA;
          end else begin
            state <= STATE_RECEIVE_DATA;
          end
        end
        STATE_STORE_RECEIVED_DATA : begin
          register_local_copy <= register_local_copy;

          o_reg_addr     <= o_reg_addr;
          o_reg_write_en <= 1'b1;

          state <= STATE_INITIAL;
        end
        default                     : begin
          state <= STATE_INITIAL;
        end
      endcase
    end
  end
endmodule
