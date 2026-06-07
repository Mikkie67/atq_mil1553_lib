--
-- VHDL Architecture mil1553_tb.mil1553_cpu_registers_testctrl.rtl

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

library mil1553_tb;
context mil1553_tb.mil1553_context;

entity mil1553_cpu_registers_testctrl is
  port (
    DiscretesIn                 : out   CoreDiscretesIn_type;
    DiscretesOut                : in    CoreDiscretesOut_type;
    Bus1Intr                    : in    std_logic;
    Bus2Intr                    : in    std_logic;
    port_reg_24                 : in    std_logic_vector(15 downto 0);
    port_reg_25                 : in    std_logic_vector(15 downto 0);
    port_reg_26                 : in    std_logic_vector(15 downto 0);
    port_reg_27                 : in    std_logic_vector(15 downto 0);
    port_reg_28                 : in    std_logic_vector(15 downto 0);
    port_reg_29                 : in    std_logic_vector(15 downto 0);
    port_reg_40                 : in    std_logic_vector(15 downto 0);
    port_reg_41                 : in    std_logic_vector(15 downto 0);
    port_reg_42                 : in    std_logic_vector(15 downto 0);
    port_reg_43                 : in    std_logic_vector(15 downto 0);
    port_reg_44                 : in    std_logic_vector(15 downto 0);
    port_reg_45                 : in    std_logic_vector(15 downto 0);
    port_reg_bit                : in    std_logic_vector(15 downto 0);
    port_reg_bus1_mask          : in    std_logic_vector(15 downto 0);
    port_reg_bus2_mask          : in    std_logic_vector(15 downto 0);
    port_reg_clear_bits         : in    std_logic_vector(15 downto 0);
    port_reg_cmd_proc_length1   : in    std_logic_vector(15 downto 0);
    port_reg_cmd_proc_length2   : in    std_logic_vector(15 downto 0);
    port_reg_cmd_proc_start1    : in    std_logic_vector(15 downto 0);
    port_reg_cmd_proc_start2    : in    std_logic_vector(15 downto 0);
    port_reg_err_inj_data       : in    std_logic_vector(15 downto 0);
    port_reg_fw_version         : in    std_logic_vector(15 downto 0);
    port_reg_gID                : in    std_logic_vector(15 downto 0);
    port_reg_intr_mask          : in    std_logic_vector(15 downto 0);
    port_reg_legal_brdcst_mode1 : in    std_logic_vector(15 downto 0);
    port_reg_legal_brdcst_mode2 : in    std_logic_vector(15 downto 0);
    port_reg_legal_rx_mode1     : in    std_logic_vector(15 downto 0);
    port_reg_legal_rx_mode2     : in    std_logic_vector(15 downto 0);
    port_reg_legal_subaddr1     : in    std_logic_vector(15 downto 0);
    port_reg_legal_subaddr2     : in    std_logic_vector(15 downto 0);
    port_reg_legal_tx_mode1     : in    std_logic_vector(15 downto 0);
    port_reg_legal_tx_mode2     : in    std_logic_vector(15 downto 0);
    port_reg_node_control       : in    std_logic_vector(15 downto 0);
    port_reg_repeat_rate        : in    std_logic_vector(15 downto 0);
    port_reg_sw_rtaddr          : in    std_logic_vector(15 downto 0);
    port_reg_tmr_1us            : in    std_logic_vector(15 downto 0);
    port_reg_tmr_GAP            : in    std_logic_vector(15 downto 0);
    port_reg_tmr_NRP            : in    std_logic_vector(15 downto 0);
    port_reg_tmr_REP            : in    std_logic_vector(15 downto 0);
    port_reg_tmr_SAF            : in    std_logic_vector(15 downto 0);
    port_reg_tx_control1        : in    std_logic_vector(15 downto 0);
    port_reg_tx_control2        : in    std_logic_vector(15 downto 0);
    port_reg_vectorword         : in    std_logic_vector(15 downto 0);
    port_reg_wrap_subaddr       : in    std_logic_vector(15 downto 0);
    MyRtAddr                    : out   std_logic_vector(4 downto 0);
    MyRtAddrParity              : out   std_logic;
    TimeStamp                   : out   std_logic_vector(63 downto 0);
    clk                         : out   std_logic;
    nReset                      : out   std_logic;
    nResetCpu                   : out   std_logic;
    port_reg_bus1_status        : out   std_logic_vector(15 downto 0);
    port_reg_bus2_status        : out   std_logic_vector(15 downto 0);
    port_reg_cmd_rxed1          : out   std_logic_vector(15 downto 0);
    port_reg_cmd_rxed2          : out   std_logic_vector(15 downto 0);
    port_reg_mode_cmd_rxed1     : out   std_logic_vector(15 downto 0);
    port_reg_mode_cmd_rxed2     : out   std_logic_vector(15 downto 0);
    port_reg_mode_data_rxed1    : out   std_logic_vector(15 downto 0);
    port_reg_mode_data_rxed2    : out   std_logic_vector(15 downto 0);
    port_reg_rt_addr            : out   std_logic_vector(15 downto 0);
    port_reg_rx_cmd1            : out   std_logic_vector(15 downto 0);
    port_reg_rx_cmd2            : out   std_logic_vector(15 downto 0);
    port_reg_status             : out   std_logic_vector(15 downto 0);
    port_reg_status_rxed1       : out   std_logic_vector(15 downto 0);
    port_reg_status_rxed2       : out   std_logic_vector(15 downto 0);
    -- Address bus transaction interface
    cpu_bus                     : inout AddressBus16Type
  );

  -- Declarations
  constant OSVVM_RESULTS_DIR : string := "";

end entity;

