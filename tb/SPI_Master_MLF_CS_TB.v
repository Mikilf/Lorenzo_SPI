//Model original: https:github.com/nandland/spi-master/blob/master/Verilog/sim/SPI_Master_With_Single_CS_TB.sv
//el model que es presenta a continuació és una modificació del model original amb els requeriments establerts pels professors

module SPI_MASTER_MLF_CS_TB();

    //Configurem els paràmetres en funció de la configuració que volguem aplicar al nostre test
    parameter SPI_MODE = 0;                                                   
    parameter CLKS_PER_HALF_BIT = 2;
    parameter MAIN_CLK_DELAY = 2;
    parameter MAX_BYTES_PER_CS = 2;
    parameter CS_INACTIVE_CLKS = 3;

    //Determinem els registres i wires que trobem al nostre test

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

    // Determinem la freüència del nostre rellotge

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
      .i_SPI_MISO(w_SPI_MOSI),                                                  //Senyals MISO y MOSI curtcircuitades per generar un echo
      .o_SPI_MOSI(w_SPI_MOSI),
      .o_SPI_CS_n(w_SPI_CS_n)
    );

    //Creem una tasca per enviar només un bit, utilitzarem un input de 8 bits el qual anomenem dades, d'aquesta manera podem enviar el byte que volguem (0x00 - 0xFF)

    task EnviaUnByte(input [7:0] dades);
    begin 
        @(posedge r_clk);
        r_Master_TX_Byte <= dades;                                              //Carreguem el byte al registre TX byte
        r_Master_TX_DV <= 1'b1;                                                 //Activem el bit DV 1 cicle de rellotge, el qual indica que les dàdes s'han carregat al registre
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
            r_rst_n = 1'b0;                                                     //Reset inicial per configurar els valors inicials correctament
            repeat(10) @(posedge r_clk);
            r_rst_n = 1'b1;
            //envem dos bytes
            EnviaUnByte(8'h78);                                                 //Enviem un byte
            $display("He enviat el byte 0x78, Rebut 0x%X", w_Master_RX_Byte);   //Per consola comprovarem si s'ha enviat i rebut correctament
            #50
            EnviaUnByte(8'h9A);
            $display("He envial el byte 0x9A, Rebut 0x%X", w_Master_RX_Byte);

            repeat(100) @(posedge r_clk);
            $stop();       
        end
endmodule

