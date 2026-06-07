--
-- VHDL Entity mil1553_tb.osvvm_Mil1553_dualbus_testctrl.arch_name
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.numeric_std_unsigned.all;
  use ieee.math_real.all;

library OSVVM;
context OSVVM.OsvvmContext;
use osvvm.ScoreboardPkg_slv.all;

library mil1553_tb;
context mil1553_tb.mil1553_context;

entity osvvm_Mil1553_dualbus_testctrl is
  port (
    -- Global Signal Interface
    nReset            : in    std_logic;
    Clk               : in    std_logic;
    -- Transaction Interfaces
    RT1_cpu_bus       : inout AddressBus16Type;
    RT2_cpu_bus       : inout AddressBus16Type;
    BC_cpu_bus        : inout AddressBus16Type;
    BC1_DiscretesOut  : in    CoreDiscretesOut_type;
    RT1_DiscretesOut  : in    CoreDiscretesOut_type;
    RT2_DiscretesOut  : in    CoreDiscretesOut_type;
    BC1_DiscretesIn   : out   CoreDiscretesIn_type;
    RT1_DiscretesIn   : out   CoreDiscretesIn_type;
    RT2_DiscretesIn   : out   CoreDiscretesIn_type;
    BC_BusMonitorRec  : in    BusMonitorRec_type;
    RT1_BusMonitorRec : in    BusMonitorRec_type;
    RT2_BusMonitorRec : in    BusMonitorRec_type
  );

  -- Declarations
  constant OSVVM_RESULTS_DIR : string := "";

end entity;

