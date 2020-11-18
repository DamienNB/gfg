`timescale 1 ns/100 ps

module gfg_spi_slave_tb ();

  parameter NUM_REGISTERS  = 32,
            REGISTER_WIDTH = 32;

  reg i_sys_clk = 1'b0;
  reg i_srst_n  = 1'b1;

  reg i_spi_clk  = 1'b1;
  wire o_spi_miso;
  reg i_spi_mosi = 1'b0;
  reg i_spi_ss_n = 1'b1;

  wire [$clog2(NUM_REGISTERS)-1:0] o_reg_addr;
  wire [REGISTER_WIDTH-1:0] o_reg_write_data;
  wire o_reg_write_en;
  wire [REGISTER_WIDTH-1:0] i_reg_read_data;

  gfg_spi_slave #(
    .NUM_REGISTERS(NUM_REGISTERS),
    .REGISTER_WIDTH(REGISTER_WIDTH)
  ) UUT (
    .i_sys_clk(i_sys_clk),
    .i_srst_n(i_srst_n),
    .i_spi_clk(i_spi_clk),
    .o_spi_miso(o_spi_miso),
    .i_spi_mosi(i_spi_mosi),
    .i_spi_ss_n(i_spi_ss_n),
    .o_reg_addr(o_reg_addr),
    .o_reg_write_data(o_reg_write_data),
    .o_reg_write_en(o_reg_write_en),
    .i_reg_read_data(i_reg_read_data)
  );

  ram_dual_port #(
    .DEPTH(NUM_REGISTERS),
    .WIDTH(REGISTER_WIDTH),
    .VIVADO_ENV(0)
  ) REGISTERS (
    .write_clk(i_sys_clk),
    .write_en(o_reg_write_en),
    .write_addr(o_reg_addr),
    .data_in(o_reg_write_data),
    .read_clk(i_sys_clk),
    .read_addr(o_reg_addr),
    .data_out(i_reg_read_data)
  );

  reg [7:0] spi_mosi_val;

  always #1 i_sys_clk <= ~i_sys_clk;

  integer i, j;
  initial begin
    i_sys_clk <= 1'b0;

    for(i=0; i<30; i=i+1) begin
      #1 ;
    end

  // write test with slave select going high between bytes
    spi_mosi_val <= 8'b10_0_11111;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    spi_mosi_val <= 8'b0000_0001;
    i_spi_ss_n <= 1'b0;

    for(i=3; i>=0; i=i-1) begin
      #20 i_spi_ss_n <= 1'b0;
      for(j=7; j>=0; j=j-1) begin
        #10 i_spi_clk  <= 1'b0;
        i_spi_mosi <= spi_mosi_val[j];

        #10 i_spi_clk <= 1'b1;
      end
      spi_mosi_val <= spi_mosi_val + 1;
      #20 i_spi_ss_n <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    #20 ;

  // write test with slave select staying low between bytes
    spi_mosi_val <= 8'b10_0_00000;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 ;

    spi_mosi_val <= 8'b0000_0100;

    for(i=3; i>=0; i=i-1) begin
      #20 ;
      for(j=7; j>=0; j=j-1) begin
        #10 i_spi_clk  <= 1'b0;
        i_spi_mosi <= spi_mosi_val[j];

        #10 i_spi_clk <= 1'b1;
      end
      spi_mosi_val <= spi_mosi_val - 1;
      #20 ;
    end

    #20 i_spi_ss_n <= 1'b1;

  // write test with slave select stopping operation by going high
    spi_mosi_val <= 8'b10_0_01010;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 ;

    spi_mosi_val <= 8'b0000_0001;

    #20 ;
    for(j=7; j>=3; j=j-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[j];

      #10 i_spi_clk <= 1'b1;
    end
    spi_mosi_val <= spi_mosi_val + 1;
    #20 ;

    #20 i_spi_ss_n <= 1'b1;

    #40 ;

  // read test with slave select going high between bytes
    //i_reg_read_data <= 32'h89ABCDEF;
    spi_mosi_val <= 8'b01_0_11111;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    spi_mosi_val <= 8'b1111_1111;
    i_spi_ss_n <= 1'b0;

    for(i=3; i>=0; i=i-1) begin
      #20 i_spi_ss_n <= 1'b0;
      for(j=7; j>=0; j=j-1) begin
        #10 i_spi_clk  <= 1'b0;
        i_spi_mosi <= spi_mosi_val[j];

        #10 i_spi_clk <= 1'b1;
      end
      spi_mosi_val <= spi_mosi_val + 1;
      #20 i_spi_ss_n <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    #40 ;

  // read test with slave select staying low between bytes
    // i_reg_read_data <= 32'hFEDCBA98;
    spi_mosi_val <= 8'b01_0_00000;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 ;

    spi_mosi_val <= 8'b1111_1111;

    for(i=3; i>=0; i=i-1) begin
      #20 ;
      for(j=7; j>=0; j=j-1) begin
        #10 i_spi_clk  <= 1'b0;
        i_spi_mosi <= spi_mosi_val[j];

        #10 i_spi_clk <= 1'b1;
      end
      spi_mosi_val <= spi_mosi_val + 1;
      #20 ;
    end

    #20 i_spi_ss_n <= 1'b1;

    #40 ;

  // read test with slave select stopping operation by going high
    // i_reg_read_data <= 32'hFEDCBA98;
    spi_mosi_val <= 8'b01_0_00000;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 ;

    spi_mosi_val <= 8'b1111_1111;

    #20 ;
    for(j=32; j>=18; j=j-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[j%8];

      #10 i_spi_clk <= 1'b1;
    end
    #20 ;

    #20 i_spi_ss_n <= 1'b1;
    // i_reg_read_data <= 0;

    #40 ;

  // no op test
    spi_mosi_val <= 8'b00_0_00000;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    #40 ;

  // no op test with a different reg address
    spi_mosi_val <= 8'b00_0_11111;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    #40 ;

  // invalid command test, should act like a no op
    spi_mosi_val <= 8'b11_0_11111;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    #40 ;

  // command test with slave select stopping command by going high
    spi_mosi_val <= 8'b10_0_00000;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=1; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    #40 ;

  // reset test with reset occurring during command
    spi_mosi_val <= 8'b10_0_10101;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      if(i <= 2)
        i_srst_n <= 1'b0;
      else
        i_srst_n <= 1'b1;

      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;
    i_srst_n <= 1'b1;

    #40 ;

  // write test after reset finished, with slave select going high between bytes
    spi_mosi_val <= 8'b10_0_11111;
    i_spi_ss_n <= 1'b0;

    for(i=7; i>=0; i=i-1) begin
      #10 i_spi_clk  <= 1'b0;
      i_spi_mosi <= spi_mosi_val[i];

      #10 i_spi_clk <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    spi_mosi_val <= 37;
    i_spi_ss_n <= 1'b0;

    for(i=3; i>=0; i=i-1) begin
      #20 i_spi_ss_n <= 1'b0;
      for(j=7; j>=0; j=j-1) begin
        #10 i_spi_clk  <= 1'b0;
        i_spi_mosi <= spi_mosi_val[j];

        #10 i_spi_clk <= 1'b1;
      end
      spi_mosi_val <= spi_mosi_val + 1;
      #20 i_spi_ss_n <= 1'b1;
    end

    #20 i_spi_ss_n <= 1'b1;

    #20 ;

    #2 $finish;

  end

  initial begin
    $dumpfile("gfg_spi_slave_tb.lxt");
    $dumpvars(0,
              i_sys_clk,
              i_srst_n,
              spi_mosi_val,
              i_spi_clk,
              o_spi_miso,
              i_spi_mosi,
              i_spi_ss_n,
              o_reg_addr,
              o_reg_write_data,
              o_reg_write_en,
              i_reg_read_data,
              UUT.state,
              UUT.spi_mosi_shift_register,
              UUT.shift_register_tracker);
  end
endmodule
