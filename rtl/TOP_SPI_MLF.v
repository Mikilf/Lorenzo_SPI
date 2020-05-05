module TOP_SPI_MLF(

    input I_RST_N,
    input I_CLK,
    input I_SPI_MISO,
    output O_SPI_MOSI,
    output O_SPI_CS_N,
    output O_SPI_CLK,

    output [7:0] OUT
);

reg i_TX_DV;
reg[7:0] i_TX_byte;
reg [1:0] reg_TX_Count = 2'b10;
wire [7:0] o_RX_byte;







SPI_Master_MaquinaEstats_MLF(
  I
)

 (
//Senyals de control
     input                                          i_rst_n,
     input                                          i_clk,
//Senyals de TX (MOSI)
     input [$clog2(MAX_BYTES_PER_CS+1)-1:0]         i_TX_count,         //Variable que ens indicarà el numero de bytes que s'envien per TX
     input [7:0]                                    i_TX_byte,
     input                                          i_TX_DV,
     output                                         o_TX_Ready,
//Senyals de RX (MISO)
     output reg [$clog2(MAX_BYTES_PER_CS+1)-1:0]    o_RX_count,         //Varialbe que ens idexiona les entrades de MISO en l'ordre correcte
     output                                         o_RX_DV,
     output [7:0] o_RX_byte,
//Senyals a top
     output                                         o_SPI_clk,
     input                                          i_SPI_MISO,
     output                                         o_SPI_MOSI,
     output                                         o_SPI_CS_n          //Sortida del CS cap a codi de mes alt nivell (TOP)
 );