-- VHDL Entity mil1553_tb.manchester_decoder_tester.interface
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY manchester_decoder_tester IS
   PORT( 
      NewWord : IN     std_logic;
      OutWord : IN     std_logic_vector (15 DOWNTO 0);
      InN     : OUT    std_logic;
      InP     : OUT    std_logic;
      Clk     : BUFFER std_logic;
      nReset  : BUFFER std_logic
   );

-- Declarations

END manchester_decoder_tester ;

--------------------------------------------------------------------------------------------------
-- VHDL Architecture mil1553_tb.manchester_decoder_tester.struct
--------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY barij_lib;
LIBRARY mil1553_tb;
LIBRARY testbenches;

ARCHITECTURE struct OF manchester_decoder_tester IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL MessageError : std_logic;
   SIGNAL StreamOut    : std_logic_vector(0 TO 1);
   SIGNAL TxWord       : std_logic_vector(16 DOWNTO 0);


   -- Component Declarations
   COMPONENT clock_source
   GENERIC (
      PhaseDelay   : delay_length := 20 ns;
      ClockPeriod  : delay_length := 40 ns;
      gJitterOn    : boolean      := true;
      gJitterDelay : real         := 7.0;
      gJitter_ps   : real         := 10.0
   );
   PORT (
      clk : BUFFER std_logic 
   );
   END COMPONENT;
   COMPONENT power_on_reset
   GENERIC (
      DelayLength : integer := 10
   );
   PORT (
      Clk    : IN     std_logic ;
      nReset : OUT    std_logic 
   );
   END COMPONENT;
   COMPONENT manchester_encoder_tb
   GENERIC (
      gClkInFreq : integer := 100000000;
      gBitFreq   : integer := 1000000
   );
   PORT (
      OutEn : OUT    std_logic ;
      OutN  : OUT    std_logic ;
      OutP  : OUT    std_logic 
   );
   END COMPONENT;
   COMPONENT bitstream_sender_bits
   GENERIC (
      gInputFile : string := "bitstream_error.txt"
   );
   PORT (
      clk       : IN     std_logic ;
      nReset    : IN     std_logic ;
      StreamOut : OUT    std_logic_vector (0 TO 1)
   );
   END COMPONENT;

   -- Optional embedded configurations
   -- pragma synthesis_off
   FOR ALL : bitstream_sender_bits USE ENTITY testbenches.bitstream_sender_bits;
   FOR ALL : clock_source USE ENTITY barij_lib.clock_source;
   FOR ALL : manchester_encoder_tb USE ENTITY mil1553_tb.manchester_encoder_tb;
   FOR ALL : power_on_reset USE ENTITY barij_lib.power_on_reset;
   -- pragma synthesis_on


BEGIN
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 eb1
   -- eb1 1 
   InP <= StreamOut(0);
   InN <= StreamOut(1);                                       


   -- Instance port mappings.
   U_1 : clock_source
      GENERIC MAP (
         PhaseDelay   => 2 ns,
         ClockPeriod  => 5 ns,
         gJitterOn    => false,
         gJitterDelay => 7.0,
         gJitter_ps   => 10.0
      )
      PORT MAP (
         clk => Clk
      );
   U_2 : power_on_reset
      GENERIC MAP (
         DelayLength => 10
      )
      PORT MAP (
         Clk    => Clk,
         nReset => nReset
      );
   U_0 : manchester_encoder_tb
      GENERIC MAP (
         gClkInFreq => 100000000,
         gBitFreq   => 1000000
      )
      PORT MAP (
         OutEn => OPEN,
         OutN  => OPEN,
         OutP  => OPEN
      );
   U_3 : bitstream_sender_bits
      GENERIC MAP (
         gInputFile => "stp_mil1553_bitdecoder_eersteReg.txt"
      )
      PORT MAP (
         clk       => Clk,
         nReset    => nReset,
         StreamOut => StreamOut
      );

END struct;
