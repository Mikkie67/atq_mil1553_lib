-- VHDL Entity mil1553_tb.manchester_decoder_tb.symbol


ENTITY manchester_decoder_tb IS
   GENERIC( 
      gBitFreq    : natural := 1000000;
      gClkInFreq  : natural := 100000000;
      gOverSample : natural := 4
   );
-- Declarations

END manchester_decoder_tb ;

--------------------------------------------------------------------------------------------------
-- VHDL Architecture mil1553_tb.manchester_decoder_tb.struct
--------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY mil1553_lib;
LIBRARY mil1553_tb;

ARCHITECTURE struct OF manchester_decoder_tb IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL Clk          : std_logic;
   SIGNAL ClrNoiseErr  : std_logic;
   SIGNAL ClrParityErr : std_logic;
   SIGNAL CmdEdge      : std_logic;
   SIGNAL Cmd_nData    : std_logic;
   SIGNAL Err_Noise    : integer;
   SIGNAL Err_Parity   : integer;
   SIGNAL InN          : std_logic;
   SIGNAL InP          : std_logic;
   SIGNAL NewWord      : std_logic;
   SIGNAL OutWord      : std_logic_vector(15 DOWNTO 0);
   SIGNAL nReset       : std_logic;


   -- Component Declarations
   COMPONENT manchester_decoder
   GENERIC (
      gBitFreq    : natural := 1000000;
      gClkInFreq  : natural := 100000000;
      gOverSample : natural := 4
   );
   PORT (
      Clk          : IN     std_logic ;
      ClrNoiseErr  : IN     std_logic ;
      ClrParityErr : IN     std_logic ;
      InN          : IN     std_logic ;
      InP          : IN     std_logic ;
      nReset       : IN     std_logic ;
      CmdEdge      : OUT    std_logic ;
      Cmd_nData    : OUT    std_logic ;
      Err_Noise    : OUT    integer ;
      Err_Parity   : OUT    integer ;
      NewWord      : OUT    std_logic ;
      OutWord      : OUT    std_logic_vector (15 DOWNTO 0)
   );
   END COMPONENT;
   COMPONENT manchester_decoder_tester
   PORT (
      NewWord : IN     std_logic ;
      OutWord : IN     std_logic_vector (15 DOWNTO 0);
      InN     : OUT    std_logic ;
      InP     : OUT    std_logic ;
      Clk     : BUFFER std_logic ;
      nReset  : BUFFER std_logic 
   );
   END COMPONENT;

   -- Optional embedded configurations
   -- pragma synthesis_off
   FOR ALL : manchester_decoder USE ENTITY mil1553_lib.manchester_decoder;
   FOR ALL : manchester_decoder_tester USE ENTITY mil1553_tb.manchester_decoder_tester;
   -- pragma synthesis_on


BEGIN

   -- Instance port mappings.
   U_0 : manchester_decoder
      GENERIC MAP (
         gBitFreq    => 1000000,
         gClkInFreq  => 100000000,
         gOverSample => 4
      )
      PORT MAP (
         Clk          => Clk,
         ClrNoiseErr  => ClrNoiseErr,
         ClrParityErr => ClrParityErr,
         InN          => InN,
         InP          => InP,
         nReset       => nReset,
         CmdEdge      => CmdEdge,
         Cmd_nData    => Cmd_nData,
         Err_Noise    => Err_Noise,
         Err_Parity   => Err_Parity,
         NewWord      => NewWord,
         OutWord      => OutWord
      );
   U_1 : manchester_decoder_tester
      PORT MAP (
         NewWord => NewWord,
         OutWord => OutWord,
         InN     => InN,
         InP     => InP,
         Clk     => Clk,
         nReset  => nReset
      );

END struct;
