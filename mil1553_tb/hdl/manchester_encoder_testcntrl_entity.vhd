--
-- VHDL Architecture mil1553_tb.manchester_encoder_testctntrl.Enc_Test1
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
  use ieee.numeric_std_unsigned.all;
  use ieee.math_real.all;

library osvvm;
context osvvm.osvvmcontext;
use osvvm.ScoreboardPkg_slv.all;

library mil1553_tb;
ENTITY manchester_encoder_testcntrl IS
   PORT( 
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

-- Declarations
  constant OSVVM_RESULTS_DIR : string := "";
END ENTITY manchester_encoder_testcntrl ;

