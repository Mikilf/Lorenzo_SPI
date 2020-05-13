//https:github.com/nandland/spi-master/blob/master/Verilog/sim/SPI_Master_With_Single_CS_TB.sv

module SPI_MASTER_MLF_CS_TB();

    parameter SPI_MODE = 0;
    parameter CLKS_PER_HALF_BIT = 2;
    parameter MAIN_CLK_DELAY = 2;
    parameter MAX_BYTES_PER_CS = 2;
    parameter CS_INACTIVE_CLKS = 1;

    reg             r_rst_n = 1'b0;
    reg             r_clk = 1'b0;
    reg             r_SPI_en = 1'b0;
    wire            w_SPI_clk;
    wire            w_SPI_CS_n;
    wire            w_SPI_MOSI;
    //wire            w_SPI_MISO;

    //Senyals especifiques del master

    reg[7:0]                                r_Master_TX_Byte = 0;
    reg                                     r_Master_TX_DV = 1'b0;
    wire                                    w_Master_TX_ready;
    wire                                    w_Master_RX_DV;
    wire[7:0]                               w_Master_RX_Byte;
    wire [2:0]                              w_Master_RX_count = 2'b10;
    wire [2:0]                              r_Master_TX_count = 2'b10;

    always #(MAIN_CLK_DELAY) r_clk = ~r_clk;

    SPI_Master_MaquinaEstats_MLF
    #(.SPI_MODE(SPI_MODE),
      .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
      .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS),
      .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS)
      ) UUT
    (
    
    //Senyals de control
      .i_rst_n(r_rst_n),
      .i_clk(r_clk),
    //Senyals TX(MOSI)
      .i_TX_count(r_Master_TX_count),
      .i_TX_Byte(r_Master_TX_Byte),
      .i_TX_DV(r_Master_TX_DV),
      .o_TX_Ready(w_Master_TX_ready),
    //Senyals RX(MISO)
      .o_RX_count(w_Master_RX_count),
      .o_RX_DV(w_Master_RX_DV),
      .o_RX_Byte(w_Master_RX_Byte),
    //Interficie SPI
      .o_SPI_clk(w_SPI_clk),
      .i_SPI_MISO(w_SPI_MOSI),
      .o_SPI_MOSI(w_SPI_MOSI),
      .o_SPI_CS_n(w_SPI_CS_n)
    );

    task EnviaUnByte(input [7:0] dades);
    begin 
        @(posedge r_clk);
        r_Master_TX_Byte <= dades;
        r_Master_TX_DV <= 1'b1;
        @(posedge r_clk);
        r_Master_TX_DV <= 1'b0;
        @(posedge r_clk);
        @(posedge w_Master_TX_ready);
    end
    endtask

    initial
        begin
            $dumpfile("dump.vcd");
            $dumpvars;

            repeat(10) @(posedge r_clk);
            r_rst_n = 1'b0;
            repeat(10) @(posedge r_clk);
            r_rst_n = 1'b1;
            //envem dos bytes
            EnviaUnByte(8'hFF);
            $display("He enviat el byte 0xFF, Rebut 0x%X", w_Master_RX_Byte);
            EnviaUnByte(8'h88);
            $display("He envial el byte 0x88, Rebut 0x%X", w_Master_RX_Byte);

            repeat(100) @(posedge r_clk);
            $stop();       
        end
endmodule

