--
-- VHDL Entity mil1553_tb.man_dec_testctrl.test1
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.numeric_std_unsigned.all;
  use ieee.math_real.all;

library osvvm;
context osvvm.osvvmcontext;
use osvvm.ScoreboardPkg_slv.all;

library mil1553_tb;
context mil1553_tb.mil1553_context;

entity man_dec_testctrl is
  port (
    BusMonitorRec : inout BusMonitorRec_type;
    man_dec_bus   : inout ManchesterDecRecType
  );

  -- Declarations
  constant OSVVM_RESULTS_DIR : string := "";

end entity;
