-- VHDL Entity mil1553_tb.manchester_encoder_tb.symbol
--
ENTITY manchester_encoder_tb IS
   GENERIC( 
      gClkInFreq : natural := 100000000;
      gBitFreq   : natural := 1000000
   );
-- Declarations

END ENTITY manchester_encoder_tb ;

--
-- VHDL Architecture mil1553_tb.manchester_encoder_tb.struct
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY mil1553_lib;
LIBRARY mil1553_tb;

ARCHITECTURE struct OF manchester_encoder_tb IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL BlankStart    : std_logic;
   SIGNAL BlankStop     : std_logic;
   SIGNAL Clk           : std_logic;
   SIGNAL Cmd_nData     : std_logic;
   SIGNAL Data          : std_logic_vector(15 DOWNTO 0);
   SIGNAL Done          : std_logic;
   SIGNAL Err_inj       : std_logic_vector(15 DOWNTO 0);
   SIGNAL Go            : std_logic;
   SIGNAL LastBitEdge   : std_logic;
   SIGNAL OutEn         : std_logic;
   SIGNAL OutN          : std_logic;
   SIGNAL OutP          : std_logic;
   SIGNAL PulseBit      : std_logic;
   SIGNAL PulseWord     : std_logic;
   SIGNAL nReset        : std_logic;
   SIGNAL tmr_Blank     : std_logic;
   SIGNAL tmr_ERP_Reset : std_logic;


   -- Component Declarations
   COMPONENT manchester_encoder
   GENERIC (
      gClkInFreq : natural := 100000000;
      gBitFreq   : natural := 1000000
   );
   PORT (
      Clk           : IN     std_logic ;
      Cmd_nData     : IN     std_logic ;
      Data          : IN     std_logic_vector (15 DOWNTO 0);
      Err_inj       : IN     std_logic_vector (15 DOWNTO 0);
      Go            : IN     std_logic ;
      nReset        : IN     std_logic ;
      tmr_Blank     : IN     std_logic ;
      BlankStart    : OUT    std_logic ;
      BlankStop     : OUT    std_logic ;
      Done          : OUT    std_logic ;
      LastBitEdge   : OUT    std_logic ;
      OutEn         : OUT    std_logic ;
      OutN          : OUT    std_logic ;
      OutP          : OUT    std_logic ;
      PulseBit      : OUT    std_logic ;
      PulseWord     : OUT    std_logic ;
      tmr_ERP_Reset : OUT    std_logic 
   );
   END COMPONENT manchester_encoder;
   COMPONENT manchester_encoder_testcntrl
   PORT (
      BlankStart    : IN     std_logic;
      BlankStop     : IN     std_logic;
      Done          : IN     std_logic;
      LastBitEdge   : IN     std_logic;
      OutEn         : IN     std_logic;
      OutN          : IN     std_logic;
      OutP          : IN     std_logic;
      PulseBit      : IN     std_logic;
      PulseWord     : IN     std_logic;
      tmr_ERP_Reset : IN     std_logic;
      Clk           : OUT    std_logic;
      Cmd_nData     : OUT    std_logic;
      Data          : OUT    std_logic_vector (15 DOWNTO 0);
      Err_inj       : OUT    std_logic_vector (15 DOWNTO 0);
      Go            : OUT    std_logic;
      nReset        : OUT    std_logic;
      tmr_Blank     : OUT    std_logic
   );
   END COMPONENT manchester_encoder_testcntrl;

   -- Optional embedded configurations
   -- pragma synthesis_off
   FOR ALL : manchester_encoder USE ENTITY mil1553_lib.manchester_encoder;
   -- pragma synthesis_on


BEGIN

   -- Instance port mappings.
   encoder1 : manchester_encoder
      GENERIC MAP (
         gClkInFreq => 100000000,
         gBitFreq   => 1000000
      )
      PORT MAP (
         Clk           => Clk,
         Cmd_nData     => Cmd_nData,
         Data          => Data,
         Err_inj       => Err_inj,
         Go            => Go,
         nReset        => nReset,
         tmr_Blank     => tmr_Blank,
         BlankStart    => BlankStart,
         BlankStop     => BlankStop,
         Done          => Done,
         LastBitEdge   => LastBitEdge,
         OutEn         => OutEn,
         OutN          => OutN,
         OutP          => OutP,
         PulseBit      => PulseBit,
         PulseWord     => PulseWord,
         tmr_ERP_Reset => tmr_ERP_Reset
      );
   testcntrl1 : manchester_encoder_testcntrl
      PORT MAP (
         BlankStart    => BlankStart,
         BlankStop     => BlankStop,
         Done          => Done,
         LastBitEdge   => LastBitEdge,
         OutEn         => OutEn,
         OutN          => OutN,
         OutP          => OutP,
         PulseBit      => PulseBit,
         PulseWord     => PulseWord,
         tmr_ERP_Reset => tmr_ERP_Reset,
         Clk           => Clk,
         Cmd_nData     => Cmd_nData,
         Data          => Data,
         Err_inj       => Err_inj,
         Go            => Go,
         nReset        => nReset,
         tmr_Blank     => tmr_Blank
      );

END ARCHITECTURE struct;
      configuration manchester_encoder_tb_struct of manchester_encoder_tb is
        for struct
        end for;
      end configuration;
