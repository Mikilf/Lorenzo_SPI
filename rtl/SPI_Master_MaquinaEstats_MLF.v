//model original: https://github.com/nandland/spi-master/tree/master/Verilog
// el model que es presenta a continuació és una modificació del model original amb els requeriments establerts pels professors

module SPI_Master_MaquinaEstats_MLF
 #(parameter SPI_MODE = 0,                                              //Determina quin model SPI utilitzem CPOL,CPHA: 0=00, 1=01, 2=10, 3=11
 parameter CLKS_PER_HALF_BIT = 2,                                       //Donada la freq de l'entrada (i_clk) determinem quants pulsos hi ha en mig bit (SPI_clk = 25MHz, i_clk= 100MHz; 100MHz/25MHz = 4 polsos / 2 = 2)
 parameter MAX_BYTES_PER_CS = 2,                                        //Numero de bytes que enviarem cada cop que s'activi el chip select
 parameter CS_INACTIVE_CLKS = 1)                                        //Determina el numero de cicles que ens mantindrem inactius un cop acabada la transmissio (necessari per alguns moduls)
 (
//Senyals de control
     input                                          i_rst_n,
     input                                          i_clk,
//Senyals de TX (MOSI)
     input [2:0]                                    i_TX_count,         //Variable que ens indicarà el numero de bytes que s'envien per TX
     input [7:0]                                    i_TX_Byte,
     input                                          i_TX_DV,
     output                                         o_TX_Ready,
//Senyals de RX (MISO)
     output reg [2:0]                               o_RX_count,         //Varialbe que ens idexiona les entrades de MISO en l'ordre correcte
     output                                         o_RX_DV,
     output [7:0]                                   o_RX_Byte,
//Senyals a top
     output                                         o_SPI_clk,
     input                                          i_SPI_MISO,
     output                                         o_SPI_MOSI,
     output                                         o_SPI_CS_n          //Sortida del CS cap a codi de mes alt nivell (TOP)
 );
//Definim els tres estats mitjançant un parametres local
 localparam                             IDLE = 2'b00;
 localparam                             TRANSFER = 2'b01;
 localparam                             CS_INACTIVE = 2'b10;
 
 reg[1:0]                               r_MaquinaEstats;                //En aquest registre guardarem l'estat en el qual ens trobem dins de la maquina d'estats
 reg                                    r_CS_n;                         //En aquest registre guardarem de forma local el vaor del CS
 reg [1:0]                              r_CS_Inactive_Count;            //Utilitzarem aquest registre per determinar els cicles que ens hem de mantindre amb CS inactius
 reg [2:0]                              r_TX_count;                     //Utilitzarem aquest registre per contar les dades que enviem per MOSI
 wire                                   w_Master_Ready;                 //Utilitzarem aquest wire per indicar quan el master està preparat per rebre una nova dada

 SPI_Master_MLF                                                         //Cridem el Master del SPI 
  #(.SPI_MODE(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
    ) SPI_Master_Inst
(
    //Senyals de control
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    //Senyals de TX(MOSI)
    .i_TX_Byte(i_TX_Byte),
    .i_TX_DV(i_TX_DV),
    .o_TX_Ready(w_Master_Ready),
    //Senyals de RX(MISO)
    .o_RX_DV(o_RX_DV),
    .o_RX_Byte(o_RX_Byte),
    //Interficie SPI
    .o_SPI_clk(o_SPI_clk),
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_MOSI(o_SPI_MOSI)
);

//Proposit: Controlar la senyal del CS a partir d'una maquina d'estats
 
always @(posedge i_clk or negedge i_rst_n)
begin
    if(~i_rst_n)                                                        //Si s'activa el reset 
    begin
        r_MaquinaEstats <= IDLE;                                        //Ens possisionem al estat incial IDLE
        r_CS_n <= 1'b1;                                                 //Desactivem el chip select
        r_TX_count <= 0;                                                //Reiniciem la compta de TX
        r_CS_Inactive_Count <= 2'b01;                        //Donem el valor que haguem determinat al temps que haurem d'estar inacius
    end
    else
    begin
        case(r_MaquinaEstats)
        IDLE:                                                           //Estat inicial, esperem preparats per rebre una trama
            begin
               if(r_CS_n & i_TX_DV)                                     //Quan s'activa TX DV vol dir que alguna cosa arriba
               begin
                  r_TX_count <= i_TX_count -3'b001;                          //Comencem a contar enrere
                  r_CS_n <= 1'b0;                                       //Activem el Chip Select
                  r_MaquinaEstats <= TRANSFER;                          //Pasem al estat de transfer perque ja estem preparats per enviar
               end 
            end
        TRANSFER:                                                       //Estat de transferencia, ens trobem aqui quan estiguem enviant dades
            begin
               if(w_Master_Ready)                                       //En el cas que el master estigui preparat
               begin
                    if(r_TX_count > 0)                                  //Si la conta de TX es mes gran que 0
                    begin
                        if(i_TX_DV)                                     //I el trigger esta activat
                        begin
                        r_TX_count <= r_TX_count - 3'b001;                   //Descontem un a la conta per passar a la seguent posicio
                        end
                    end
                    else
                    begin
                        r_CS_n <= 1'b1;                                 //Un cop TX count sigui 0, tornem a activar el CS
                        r_CS_Inactive_Count <= 2'b01;        //Donem el valor maxim al temps que hem d'estar inactius
                        r_MaquinaEstats <= CS_INACTIVE;                 //Pasem al estat d'inactivitat
                    end
                end 
            end
        CS_INACTIVE:                                                    //Estat d'inactivitat, ens hem de trobar qui sempre i quan el modul que utilitzem requereixi d'un delay
            begin
                if(r_CS_Inactive_Count > 0)                             //Si el delay no es 0
                begin
                    r_CS_Inactive_Count <= r_CS_Inactive_Count - 1'b1;  //El fem decreixer fins arribar a 0
                end
                else
                begin
                    r_MaquinaEstats <= IDLE;                            //Un cop sigui 0 tornem a IDLE
                end
            end
        default:                                                        //En el cas d'error desactivarem el CS i tornarem a IDLE
            begin
               r_CS_n <= 1'b1;
               r_MaquinaEstats <=IDLE; 
            end
        endcase
    
    end 
end

//Proposit: Mantindre controla RX count per poder indexar be les entrades 

always @(posedge i_clk)
begin
   begin
        if(r_CS_n)                                                      //En el cas que CS estigui actiu
        begin
        o_RX_count <= 0;                                                //Mantindrem la conta a 0 perque no arriba res
        end
        else if (o_RX_DV)                                               //Si s'activa el trigger d'entrada
        begin
            o_RX_count <= o_RX_count + 1'b1;                            //Incrementem el valor ja que ens estaran arribant nomes dades que depsres haurem d'indexar
        end
    end
end

 assign o_SPI_CS_n = r_CS_n;
 assign o_TX_Ready = ((r_MaquinaEstats == IDLE) | (r_MaquinaEstats == TRANSFER && w_Master_Ready == 1'b1 && r_TX_count > 0)) & ~i_TX_DV;


endmodule