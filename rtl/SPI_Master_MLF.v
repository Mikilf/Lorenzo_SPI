//model original: https://github.com/nandland/spi-master/tree/master/Verilog
// el model que es presenta a continuació és una modificació del model original amb els requeriments establerts pels professors

module SPI_Master
    #(parameter SPI_MODE = 0,                                           //Determina quin model SPI utilitzem CPOL,CPHA: 0=00, 1=01, 2=10, 3=11
    parameter CLKS_PER_HALF_BIT = 3)                                    //Donada la freq de l'entrada (i_clk) determinem quants pulsos hi ha en mig bit (SPI_clk = 25MHz, i_clk= 100MHz; 100MHz/25MHz = 4 polsos / 2 = 2)
    (
        //Senyals de control
        input                   i_rst_n,                                //senyal de reset negada
        input                   i_clk,                                  //senyal del clock d'entrada

        //Senyals de TX (MOSI)
        input [7:0]             i_TX_Byte,                              //Byte que volem enviar des del SPI master   
        input                   i_TX_DV,                                //Pols d'un bit d'amplada que li diu al Master que miri i_TX_Byte i l'envii pel SPI TOP 
        output reg              o_TX_Ready,                             //Senyal que li diu al codi a mes alt nivell que esta preparat per una nova dada (i_TX_DV fa de trgger) converteix el byte de paralel a serie

        //Senyals de RX (MISO)
        output reg              o_RX_DV,                                //Pols d'un bit que fa de trigger per enviar les dades per o_RX_Byte un cop siguin valides (r_RX_bit_count = 3'b000)
        output reg              o_RX_Byte,                              //Dada convertida en paralel a partir de les dades en serie que arriben per MISO, indexat per r_RX_bit_Count

        //Senyals a TOP
        output reg              o_SPI_clk,                              //clock del nostre sistema SPI, es genera a partir de i_clk i s'ompla per r_SPI_clk
        input                   i_SPI_MISO,                             //senyal MISO que arriba en serie, la convertirem en un byte en paralel i l'enviarem per o_RX_Byte[7:0], o_RX_byte[r_RX_bit_count]
        output reg              o_SPI_MOSI                              //senyal MOSI que enviem a partir de o_TX_Ready, es controla a partir de r_TX_Byte[r_TX_bit_count]
    );      

    wire    w_CPOL;                                                     //Polaritat del clk
    wire    w_CPHA;                                                     //Fase del clk

    reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_SPI_clk_count;              //Conta per calcular el clock spi
    reg r_SPI_clk;                                                      //Registre on guardem el valor del clock spi
    reg [4:0] r_SPI_Clk_Edges;                                          //Numero de flancs en un byte (sempre 16, 1byte = 8bits; 1bit = 2 edges; 8bits = 16 edges)
    reg r_Leading_Edge;                                                 //registre on es guarda el flanc de pujada
    reg r_Trailing_Edge;                                                //registre on es guarda el flanc de baixada
    reg r_TX_DV;                                                        //registre on es guarda el valor de i_TX_DV
    reg [7:0] r_TX_Byte;                                                //registre on es guarda la dada de i__TX_byte i quan i_TX_DV s'activa l'envia

    reg[2:0] r_RX_Bit_Count;                                            //Registre que ens indica quin bit estem del byte Rx (111 -> 000)
    reg[2:0] r_TX_Bit_Count;                                            //registre que ens indica a quin bit estem del byte Tx (111 -> 000) 

    assign w_CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);                  //Donem valor a la polaritat en funcio del mode que s'activa
    assign w_CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);                  //Donem valor a la fase en funció del mode que s'activa

//Proposit: Generar el clock SPI el nombre correcte de cops

always @(posedge i_clk or i_rst_n)
begin
    if(~i_rst_n)                                                        //en cas de reset tornem totes les variables a 0
    begin
        o_TX_Ready <= 1'b0;
        r_SPI_Clk_Edges <= 0;
        r_Leading_Edge <= 1'b0;
        r_Trailing_Edge <= 1'b0;
        r_SPI_clk <= w_CPOL;                                            //donem el valor de la polaritat per iniciar correctament
        r_SPI_clk_count <= 0; 
    end
    else
        begin
            r_Leading_Edge <= 1'b0;
            r_Trailing_Edge <= 1'b0;

            if (i_TX_DV)                                                    //Quan activem el trigger
            begin
                o_TX_Ready <= 1'b0;                                         //posem el bit a 0 per seguretat
                r_SPI_Clk_Edges <= 16;                                      //Posem 16 per generar 8 polsos de clk
            end
            else if (r_SPI_Clk_Edges > 0)                                   //Comencem a contar flancs per poder generar el clk de forma correcta
            begin
                o_TX_Ready <= 1'b0;                                     

                if(r_SPI_clk_count == CLKS_PER_HALF_BIT*2-1)                //flanc de pujada
                begin
                    r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
                    r_Trailing_Edge <= 1'b1;                            
                    r_SPI_clk_count <= 0;
                    r_SPI_clk <= ~r_SPI_clk;
                end
                else if (r_SPI_clk_count == CLKS_PER_HALF_BIT-1)            //flanc de baixada
                begin
                    r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
                    r_Leading_Edge <= 1'b1;
                    r_SPI_clk_count <= 0;
                    r_SPI_clk <= ~r_SPI_clk;
                end
                else
                begin
                    r_SPI_clk_count <= r_SPI_clk_count + 1;                 //Un cop hem acabat la operació haurem generat un pols, per tant afegim 1 a la compta del clk
                end
            end
        else
        begin
            o_TX_Ready <= 1'b1;
        end
    end
end

//Proposit: Registra i_TX_Byte un cop DV s'activa, també guardem les dades de forma local en cas es canviin les dades al TOP
always @(posedge i_clk or negedge i_rst_n)
begin
    if(~i_rst_n)
    begin
        r_TX_Byte <= 8'h00; 
        r_TX_DV <= 1'b0;
    end
    else
    begin
        r_TX_DV <= i_TX_DV;                                             //delay d'un clock
        if(i_TX_DV)
        begin
            r_TX_DV <= i_TX_DV;                                         //utilitzem la dada que ens arriba des del TOP i la registrem localment
        end
    end
end

//Proposit: Generar les dades MOSI, funciona amb ambdues opcions de CPHA= 0 i CPHA = 1

always @(posedge i_clk or negedge i_rst_n)
begin
    if (~i_rst_n)                                                       //En el cas que s'activi el reset
    begin
        o_SPI_MOSI <= 1'b0;                                             //Posarem un 0 a la sortida
        r_TX_Bit_Count <= 3'b111;                                       //Donarem el valor maxim a tx count per enviar una nova dada correctament i en ordre
    end
    else
    begin
        if(o_TX_Ready)                                                  //En el cas que o tx ready estigui activa, el que significa que enviarem una trama
        begin
            r_TX_Bit_Count <= 3'b111;                                   //Li donem el valor maxim al comptador (conta de 111 -> 000)
        end

        else if (r_TX_DV & ~w_CPHA)                                     //Quan s'activi el trigger i estiguem en ordre amb el CPHA 
        begin
            o_SPI_MOSI <= r_TX_Byte[3'b111];                            //Enviem el primer byte per MOSI
            r_TX_Bit_Count <=3'b110;                                    //Disminuim el comptador
        end
        else if ((r_Leading_Edge & w_CPHA) | (r_Trailing_Edge & ~w_CPHA))   //Un cop alineat ja podem enviar tots els bits
        begin
            r_TX_Bit_Count <= r_TX_Bit_Count - 1;                       
            o_SPI_MOSI <= r_TX_Byte[r_TX_Bit_Count];
        end
    end 
end

//Proposit: Llegir les dades MISO

always @(posedge i_clk or negedge i_rst_n)
begin
    if(~i_rst_n)                                                        //Si activem el reset
    begin
        o_RX_Byte <= 8'h00;                                             //RX byte torna a 0
        o_RX_DV <= 1'b0;                                                //Desactivem el trigger de rebuda
        r_RX_Bit_Count <= 3'b111;                                       //La conta torna al valor inicial
    end
    else
    begin
        o_RX_DV <= 1'b0;                                                //Mantenim el RX desactivat fins que acaem les operacions
        if(o_TX_Ready)                                                  //Si tenim les dades preparades
        begin
            r_RX_Bit_Count  <= 3'b111;                                  //La conta es posa al valor maxim
        end
        else if ((r_Leading_Edge & ~w_CPHA) | (r_Trailing_Edge & w_CPHA))   //Si estem alineats amb CPHA
        begin
            o_RX_Byte[r_RX_Bit_Count] <= i_SPI_MISO;                    //Comencem a rebre bits per MISO
            r_RX_Bit_Count <= r_RX_Bit_Count - 1;                       //Disminuim la compta per indexar-ho de forma correcta
            if(r_RX_Bit_Count == 3'b000)                                //Un cop la compta ha acabat i vol dir que tot s'ha rebut amb exit
            begin
                o_RX_DV <= 1'b1;                                        //Activem el trigger
            end
        end
    end 
end

//Proposit: Afegir un delay al clock per poder alinear correctament les senyals

always @(posedge i_clk or negedge i_rst_n)
begin
    if(~i_rst_n)
    begin
        o_SPI_clk <= w_CPOL; 
    end
    else
    begin
        o_SPI_clk <= r_SPI_clk;
    end
end

endmodule