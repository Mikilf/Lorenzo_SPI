//Model original: https:github.com/nandland/spi-master/blob/master/Verilog/sim/SPI_Master_TB.sv
//el model que es presenta a continuació és una modificació del model original amb els requeriments establerts pels professors

module SPI_Master_MLF_TB();

    parameter SPI_MODE = 0;
    parameter CLKS_PER_HALF_BIT = 2;
    parameter MAIN_CLK_DELAY = 2;

    reg r_rst_n = 1'b0;
    reg r_clk = 1'b0;
    wire w_SPI_clk;
    wire w_SPI_MOSI;

    //Master Specific
    reg [7:0] r_master_TX_byte = 0;   
    reg r_master_TX_DV = 1'b0;
    
    wire w_master_RX_DV;
    wire w_master_TX_ready;
    wire [7:0] w_master_RX_byte;

    //Generacio del clk
    always #(MAIN_CLK_DELAY) r_clk = ~r_clk;

    //Instantiate UUT
    SPI_Master_MLF
    #(.SPI_MODE(SPI_MODE),
      .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)) SPI_Master_MLF_UUT
    (
        .i_rst_n(r_rst_n),
        .i_clk(r_clk),

        .i_TX_Byte(r_master_TX_byte),
        .i_TX_DV(r_master_TX_DV),
        .o_TX_Ready(w_master_TX_ready),
        
        .o_RX_DV(w_master_RX_DV),
        .o_RX_Byte(w_master_RX_byte),
        
        .o_SPI_clk(w_SPI_clk),
        .i_SPI_MISO(w_SPI_MOSI),
        .o_SPI_MOSI(w_SPI_MOSI)
        );

    task EnviaUnByte(input [7:0] data); begin
        @(posedge r_clk);
        r_master_TX_byte <= data;
        r_master_TX_DV <= 1'b1;
        @(posedge r_clk);
        r_master_TX_DV <= 1'b0;
        @(posedge w_master_TX_ready); end
    endtask

    initial
     begin
        // Required for EDA Playground
        $dumpfile("dump.vcd"); 
        $dumpvars;
      
        repeat(10) @(posedge r_clk);
        r_rst_n = 1'b0;
        repeat(10) @(posedge r_clk);
        r_rst_n = 1'b1;

        //test un byte
        EnviaUnByte(8'h9A);
        $display("He enviat 0x9A, rebo 0x%X", w_master_RX_byte);
        #50
        //test dos bytes
        EnviaUnByte(8'h99);
        $display("He enviat 0x99, rebo 0x%X", w_master_RX_byte);
        #50
        EnviaUnByte(8'h77);
        $display("He enviat 0x77, rebo 0x%X", w_master_RX_byte);
        #50
        repeat(10) @(posedge r_clk);
        $stop();
     end

endmodule

