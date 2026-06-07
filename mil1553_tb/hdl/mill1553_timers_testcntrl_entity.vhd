--
-- VHDL Architecture mil1553_tb.mill1553_timers_testcntrl.test1
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
  use ieee.numeric_std_unsigned.all;
  use ieee.math_real.all;

library osvvm;
context osvvm.osvvmcontext;
use osvvm.ScoreboardPkg_slv.all;

library mil1553_tb;
context mil1553_tb.mil1553_context;
ENTITY mill1553_timers_testcntrl IS
   PORT( 
      tmr_1us         : IN     std_logic;
      tmr_25us        : IN     std_logic;
      tmr_Blank       : IN     std_logic;
      tmr_ERP         : IN     std_logic;
      tmr_GAP         : IN     std_logic;
      tmr_NRP         : IN     std_logic;
      tmr_REP         : IN     std_logic;
      tmr_SAF         : IN     std_logic;
      SyncPosEdge     : OUT    std_logic;
      clk             : OUT    std_logic;
      nReset          : OUT    std_logic;
      reg_tmr_1us     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_ERP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_GAP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_NRP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_REP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_SAF     : OUT    std_logic_vector (15 DOWNTO 0);
      tmr_1us_Start   : OUT    std_logic;
      tmr_1us_Stop    : OUT    std_logic;
      tmr_25us_Start  : OUT    std_logic;
      tmr_25us_Stop   : OUT    std_logic;
      tmr_Blank_Start : OUT    std_logic;
      tmr_Blank_Stop  : OUT    std_logic;
      tmr_ERP_Reset   : OUT    std_logic;
      tmr_ERP_Stop    : OUT    std_logic;
      tmr_ERP_enable  : OUT    std_logic;
      tmr_GAP_Start   : OUT    std_logic;
      tmr_GAP_Stop    : OUT    std_logic;
      tmr_NRP_Start   : OUT    std_logic;
      tmr_NRP_Stop    : OUT    std_logic;
      tmr_REP_Start   : OUT    std_logic;
      tmr_REP_Stop    : OUT    std_logic;
      tmr_SAF_Start   : OUT    std_logic;
      tmr_SAF_Stop    : OUT    std_logic
   );

  -- Declarations
  constant OSVVM_RESULTS_DIR : string := "";
END ENTITY mill1553_timers_testcntrl ;


