-- VHDL Entity mil1553_tb.osvvm_mil1553_cpu_registers_tb.symbol
--
entity osvvm_mil1553_cpu_registers_tb is
  -- Declarations
end entity;

--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_cpu_registers_tb.struct
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library mil1553_lib;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

library mil1553_tb;
context mil1553_tb.mil1553_context;

architecture struct of osvvm_mil1553_cpu_registers_tb is

  -- Architecture declarations

  -- Internal signal declarations
  signal Addr             : std_logic_vector(15 downto 0);
  signal BitWord          : std_logic_vector(15 downto 0);
  signal Bus1Intr         : std_logic;
  signal Bus2Intr         : std_logic;
  signal ClkOut           : std_logic;
  signal Cs               : std_logic;
  signal DataIn           : std_logic_vector(15 downto 0);
  signal DataOut          : std_logic_vector(15 downto 0);
  signal DataValid        : std_logic;
  signal DiscretesIn      : CoreDiscretesIn_type;
  signal DiscretesOut     : CoreDiscretesOut_type;
  signal Intr             : std_logic;
  signal MyRtAddr         : std_logic_vector(4 downto 0);
  signal MyRtAddrParity   : std_logic;
  signal OutEn1           : std_logic;
  signal OutEn2           : std_logic;
  signal Rd               : std_logic;
  signal ServiceReqVector : std_logic_vector(15 downto 0);
  signal ServiceRequest   : std_logic;
  signal Strobe1          : std_logic;
  signal Strobe2          : std_logic;
  signal SubsystemFlag    : std_logic;
  signal TimeStamp        : std_logic_vector(63 downto 0);
  signal Wr               : std_logic;
  signal clk              : std_logic;
  -- Address bus transaction interface
  signal cpu_bus                     : AddressBus16Type;
  signal nReset                      : std_logic;
  signal nResetOut                   : std_logic;
  signal nResetCpu                   : std_logic;
  signal port_reg_24                 : std_logic_vector(15 downto 0);
  signal port_reg_25                 : std_logic_vector(15 downto 0);
  signal port_reg_26                 : std_logic_vector(15 downto 0);
  signal port_reg_27                 : std_logic_vector(15 downto 0);
  signal port_reg_28                 : std_logic_vector(15 downto 0);
  signal port_reg_29                 : std_logic_vector(15 downto 0);
  signal port_reg_40                 : std_logic_vector(15 downto 0);
  signal port_reg_41                 : std_logic_vector(15 downto 0);
  signal port_reg_42                 : std_logic_vector(15 downto 0);
  signal port_reg_43                 : std_logic_vector(15 downto 0);
  signal port_reg_44                 : std_logic_vector(15 downto 0);
  signal port_reg_45                 : std_logic_vector(15 downto 0);
  signal port_reg_bit                : std_logic_vector(15 downto 0);
  signal port_reg_bus1_mask          : std_logic_vector(15 downto 0);
  signal port_reg_bus1_status        : std_logic_vector(15 downto 0);
  signal port_reg_bus2_mask          : std_logic_vector(15 downto 0);
  signal port_reg_bus2_status        : std_logic_vector(15 downto 0);
  signal port_reg_clear_bits         : std_logic_vector(15 downto 0);
  signal port_reg_cmd_proc_length1   : std_logic_vector(15 downto 0);
  signal port_reg_cmd_proc_length2   : std_logic_vector(15 downto 0);
  signal port_reg_cmd_proc_start1    : std_logic_vector(15 downto 0);
  signal port_reg_cmd_proc_start2    : std_logic_vector(15 downto 0);
  signal port_reg_cmd_rxed1          : std_logic_vector(15 downto 0);
  signal port_reg_cmd_rxed2          : std_logic_vector(15 downto 0);
  signal port_reg_err_inj_data       : std_logic_vector(15 downto 0);
  signal port_reg_fw_version         : std_logic_vector(15 downto 0);
  signal port_reg_gID                : std_logic_vector(15 downto 0);
  signal port_reg_intr_mask          : std_logic_vector(15 downto 0);
  signal port_reg_legal_brdcst_mode1 : std_logic_vector(15 downto 0);
  signal port_reg_legal_brdcst_mode2 : std_logic_vector(15 downto 0);
  signal port_reg_legal_rx_mode1     : std_logic_vector(15 downto 0);
  signal port_reg_legal_rx_mode2     : std_logic_vector(15 downto 0);
  signal port_reg_legal_subaddr1     : std_logic_vector(15 downto 0);
  signal port_reg_legal_subaddr2     : std_logic_vector(15 downto 0);
  signal port_reg_legal_tx_mode1     : std_logic_vector(15 downto 0);
  signal port_reg_legal_tx_mode2     : std_logic_vector(15 downto 0);
  signal port_reg_mode_cmd_rxed1     : std_logic_vector(15 downto 0);
  signal port_reg_mode_cmd_rxed2     : std_logic_vector(15 downto 0);
  signal port_reg_mode_data_rxed1    : std_logic_vector(15 downto 0);
  signal port_reg_mode_data_rxed2    : std_logic_vector(15 downto 0);
  signal port_reg_node_control       : std_logic_vector(15 downto 0);
  signal port_reg_repeat_rate        : std_logic_vector(15 downto 0);
  signal port_reg_rt_addr            : std_logic_vector(15 downto 0);
  signal port_reg_rx_cmd1            : std_logic_vector(15 downto 0);
  signal port_reg_rx_cmd2            : std_logic_vector(15 downto 0);
  signal port_reg_status             : std_logic_vector(15 downto 0);
  signal port_reg_status_rxed1       : std_logic_vector(15 downto 0);
  signal port_reg_status_rxed2       : std_logic_vector(15 downto 0);
  signal port_reg_sw_rtaddr          : std_logic_vector(15 downto 0);
  signal port_reg_tmr_1us            : std_logic_vector(15 downto 0);
  signal port_reg_tmr_GAP            : std_logic_vector(15 downto 0);
  signal port_reg_tmr_NRP            : std_logic_vector(15 downto 0);
  signal port_reg_tmr_REP            : std_logic_vector(15 downto 0);
  signal port_reg_tmr_SAF            : std_logic_vector(15 downto 0);
  signal port_reg_tx_control1        : std_logic_vector(15 downto 0);
  signal port_reg_tx_control2        : std_logic_vector(15 downto 0);
  signal port_reg_vectorword         : std_logic_vector(15 downto 0);
  signal port_reg_wrap_subaddr       : std_logic_vector(15 downto 0);

  -- Component Declarations
  component mil1553_cpu_registers
    generic (
      gID      : std_logic_vector(15 downto 0) := X"BEEF";
      gVersion : std_logic_vector(15 downto 0) := X"0203"
    );
    port (
      Addr                   : in     std_logic_vector(15 downto 0);
      Cs                     : in     std_logic;
      DataIn                 : in     std_logic_vector(15 downto 0);
      Rd                     : in     std_logic;
      Wr                     : in     std_logic;
      clk                    : in     std_logic;
      nReset                 : in     std_logic;
      DataOut                : out    std_logic_vector(15 downto 0);
      DataValid              : out    std_logic;
      Intr                   : out    std_logic;
      reg_tmr_SAF            : buffer std_logic_vector(15 downto 0);
      reg_intr_mask          : buffer std_logic_vector(15 downto 0);
      reg_legal_subaddr2     : buffer std_logic_vector(15 downto 0);
      reg_legal_subaddr1     : buffer std_logic_vector(15 downto 0);
      reg_tmr_REP            : buffer std_logic_vector(15 downto 0);
      reg_status_rxed1       : in     std_logic_vector(15 downto 0);
      reg_tmr_NRP            : buffer std_logic_vector(15 downto 0);
      reg_legal_rx_mode1     : buffer std_logic_vector(15 downto 0);
      reg_legal_rx_mode2     : buffer std_logic_vector(15 downto 0);
      reg_legal_tx_mode1     : buffer std_logic_vector(15 downto 0);
      reg_legal_tx_mode2     : buffer std_logic_vector(15 downto 0);
      reg_legal_brdcst_mode1 : buffer std_logic_vector(15 downto 0);
      reg_legal_brdcst_mode2 : buffer std_logic_vector(15 downto 0);
      reg_gID                : buffer std_logic_vector(15 downto 0);
      reg_mode_data_rxed1    : in     std_logic_vector(15 downto 0);
      reg_tmr_1us            : buffer std_logic_vector(15 downto 0);
      reg_tmr_GAP            : buffer std_logic_vector(15 downto 0);
      reg_fw_version         : buffer std_logic_vector(15 downto 0);
      reg_rt_addr            : in     std_logic_vector(15 downto 0);
      reg_mode_cmd_rxed1     : in     std_logic_vector(15 downto 0);
      reg_clear_bits         : buffer std_logic_vector(15 downto 0);
      reg_node_control       : buffer std_logic_vector(15 downto 0);
      reg_err_inj_data       : buffer std_logic_vector(15 downto 0);
      reg_status             : in     std_logic_vector(15 downto 0);
      reg_rx_cmd1            : in     std_logic_vector(15 downto 0);
      reg_tx_control1        : buffer std_logic_vector(15 downto 0);
      reg_cmd_proc_start1    : buffer std_logic_vector(15 downto 0);
      reg_cmd_proc_length1   : buffer std_logic_vector(15 downto 0);
      reg_cmd_rxed1          : in     std_logic_vector(15 downto 0);
      reg_24                 : buffer std_logic_vector(15 downto 0);
      reg_25                 : buffer std_logic_vector(15 downto 0);
      reg_26                 : buffer std_logic_vector(15 downto 0);
      reg_27                 : buffer std_logic_vector(15 downto 0);
      reg_28                 : buffer std_logic_vector(15 downto 0);
      reg_29                 : buffer std_logic_vector(15 downto 0);
      reg_bus1_status        : in     std_logic_vector(15 downto 0);
      reg_bus1_mask          : buffer std_logic_vector(15 downto 0);
      reg_status_rxed2       : in     std_logic_vector(15 downto 0);
      reg_mode_cmd_rxed2     : in     std_logic_vector(15 downto 0);
      reg_mode_data_rxed2    : in     std_logic_vector(15 downto 0);
      reg_rx_cmd2            : in     std_logic_vector(15 downto 0);
      reg_tx_control2        : buffer std_logic_vector(15 downto 0);
      reg_cmd_proc_start2    : buffer std_logic_vector(15 downto 0);
      reg_cmd_proc_length2   : buffer std_logic_vector(15 downto 0);
      reg_cmd_rxed2          : in     std_logic_vector(15 downto 0);
      reg_40                 : buffer std_logic_vector(15 downto 0);
      reg_41                 : buffer std_logic_vector(15 downto 0);
      reg_42                 : buffer std_logic_vector(15 downto 0);
      reg_43                 : buffer std_logic_vector(15 downto 0);
      reg_44                 : buffer std_logic_vector(15 downto 0);
      reg_45                 : buffer std_logic_vector(15 downto 0);
      reg_bus2_status        : in     std_logic_vector(15 downto 0);
      reg_bus2_mask          : buffer std_logic_vector(15 downto 0);
      reg_repeat_rate        : buffer std_logic_vector(15 downto 0);
      TimeStamp              : in     std_logic_vector(63 downto 0);
      reg_wrap_subaddr       : buffer std_logic_vector(15 downto 0);
      Bus1Intr               : buffer std_logic;
      Bus2Intr               : buffer std_logic;
      reg_vectorword         : buffer std_logic_vector(15 downto 0);
      reg_bit                : buffer std_logic_vector(15 downto 0);
      reg_sw_rtaddr          : buffer std_logic_vector(15 downto 0);
      MyRtAddrParity         : in     std_logic;
      MyRtAddr               : in     std_logic_vector(4 downto 0)
    );
  end component;
  component mil1553_core_vc
    generic (
      MODEL_ID_NAME   : string := "MIL1553_VC";
      tperiod_Clk     : time   := 10 ns;
      DEFAULT_DELAY   : time   := 1 ns;
      tpd_Clk_Address : time   := DEFAULT_DELAY;
      tpd_Clk_Write   : time   := DEFAULT_DELAY;
      tpd_Clk_DataIn  : time   := DEFAULT_DELAY
    );
    port (
      -- VC reset and clock signals
      nReset           : in    std_logic;
      Clk              : in    std_logic;
      -- cpu bus interface signals
      DataOut          : in    std_logic_vector(15 downto 0);
      DataValid        : in    std_logic;
      Intr             : in    std_logic;
      Addr             : out   std_logic_vector(15 downto 0);
      Cs               : out   std_logic;
      DataIn           : out   std_logic_vector(15 downto 0);
      Rd               : out   std_logic;
      Wr               : out   std_logic;
      -- Address bus transaction interface
      cpu_bus          : inout AddressBus16Type;
      DiscretesIn      : in    CoreDiscretesIn_type;
      DiscretesOut     : out   CoreDiscretesOut_type;
      OutEn1           : in    std_logic;
      Strobe1          : in    std_logic;
      OutEn2           : in    std_logic;
      Strobe2          : in    std_logic;
      MyRtAddr         : out   std_logic_vector(4 downto 0);
      MyRtAddrParity   : out   std_logic;
      BitWord          : out   std_logic_vector(15 downto 0);
      ServiceReqVector : out   std_logic_vector(15 downto 0);
      ServiceRequest   : out   std_logic;
      SubsystemFlag    : out   std_logic;
      ClkOut           : out   std_logic;
      nResetOut        : out   std_logic
    );
  end component;
  component mil1553_cpu_registers_testctrl
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
      cpu_bus                     : inout AddressBus16Type
    );
  end component;

  -- Optional embedded configurations
  -- pragma synthesis_off
  for all: mil1553_core_vc use entity mil1553_tb.mil1553_core_vc;
    for all: mil1553_cpu_registers use entity mil1553_lib.mil1553_cpu_registers;
      --- FOR ALL : mil1553_cpu_registers_testctrl USE ENTITY mil1553_tb.mil1553_cpu_registers_testctrl;
      -- pragma synthesis_on

    begin
      -- -- Architecture concurrent statements

      -- Instance port mappings.
      U_0: mil1553_cpu_registers
      generic map (
          gID      => X"BEEF",
          gVersion => X"0203"
      )
      port map (
          Addr                   => Addr,
          Cs                     => Cs,
          DataIn                 => DataIn,
          Rd                     => Rd,
          Wr                     => Wr,
          clk                    => Clk,
          nReset                 => nResetCpu,
          DataOut                => DataOut,
          DataValid              => DataValid,
          Intr                   => Intr,
          reg_tmr_SAF            => port_reg_tmr_SAF,
          reg_intr_mask          => port_reg_intr_mask,
          reg_legal_subaddr2     => port_reg_legal_subaddr2,
          reg_legal_subaddr1     => port_reg_legal_subaddr1,
          reg_tmr_REP            => port_reg_tmr_REP,
          reg_status_rxed1       => port_reg_status_rxed1,
          reg_tmr_NRP            => port_reg_tmr_NRP,
          reg_legal_rx_mode1     => port_reg_legal_rx_mode1,
          reg_legal_rx_mode2     => port_reg_legal_rx_mode2,
          reg_legal_tx_mode1     => port_reg_legal_tx_mode1,
          reg_legal_tx_mode2     => port_reg_legal_tx_mode2,
          reg_legal_brdcst_mode1 => port_reg_legal_brdcst_mode1,
          reg_legal_brdcst_mode2 => port_reg_legal_brdcst_mode2,
          reg_gID                => port_reg_gID,
          reg_mode_data_rxed1    => port_reg_mode_data_rxed1,
          reg_tmr_1us            => port_reg_tmr_1us,
          reg_tmr_GAP            => port_reg_tmr_GAP,
          reg_fw_version         => port_reg_fw_version,
          reg_rt_addr            => port_reg_rt_addr,
          reg_mode_cmd_rxed1     => port_reg_mode_cmd_rxed1,
          reg_clear_bits         => port_reg_clear_bits,
          reg_node_control       => port_reg_node_control,
          reg_err_inj_data       => port_reg_err_inj_data,
          reg_status             => port_reg_status,
          reg_rx_cmd1            => port_reg_rx_cmd1,
          reg_tx_control1        => port_reg_tx_control1,
          reg_cmd_proc_start1    => port_reg_cmd_proc_start1,
          reg_cmd_proc_length1   => port_reg_cmd_proc_length1,
          reg_cmd_rxed1          => port_reg_cmd_rxed1,
          reg_24                 => port_reg_24,
          reg_25                 => port_reg_25,
          reg_26                 => port_reg_26,
          reg_27                 => port_reg_27,
          reg_28                 => port_reg_28,
          reg_29                 => port_reg_29,
          reg_bus1_status        => port_reg_bus1_status,
          reg_bus1_mask          => port_reg_bus1_mask,
          reg_status_rxed2       => port_reg_status_rxed2,
          reg_mode_cmd_rxed2     => port_reg_mode_cmd_rxed2,
          reg_mode_data_rxed2    => port_reg_mode_data_rxed2,
          reg_rx_cmd2            => port_reg_rx_cmd2,
          reg_tx_control2        => port_reg_tx_control2,
          reg_cmd_proc_start2    => port_reg_cmd_proc_start2,
          reg_cmd_proc_length2   => port_reg_cmd_proc_length2,
          reg_cmd_rxed2          => port_reg_cmd_rxed2,
          reg_40                 => port_reg_40,
          reg_41                 => port_reg_41,
          reg_42                 => port_reg_42,
          reg_43                 => port_reg_43,
          reg_44                 => port_reg_44,
          reg_45                 => port_reg_45,
          reg_bus2_status        => port_reg_bus2_status,
          reg_bus2_mask          => port_reg_bus2_mask,
          reg_repeat_rate        => port_reg_repeat_rate,
          TimeStamp              => TimeStamp,
          reg_wrap_subaddr       => port_reg_wrap_subaddr,
          Bus1Intr               => Bus1Intr,
          Bus2Intr               => Bus2Intr,
          reg_vectorword         => port_reg_vectorword,
          reg_bit                => port_reg_bit,
          reg_sw_rtaddr          => port_reg_sw_rtaddr,
          MyRtAddrParity         => MyRtAddrParity,
          MyRtAddr               => MyRtAddr
      );
      U_2: mil1553_core_vc
      generic map (
          MODEL_ID_NAME   => "MIL1553_VC",
          tperiod_Clk     => 10 ns,
          DEFAULT_DELAY   => 1 ns,
          tpd_Clk_Address => 1 ns,
          tpd_Clk_Write   => 1 ns,
          tpd_Clk_DataIn  => 1 ns
      )
      port map (
          nReset           => nReset,
          Clk              => clk,
          DataOut          => DataOut,
          DataValid        => DataValid,
          Intr             => Intr,
          Addr             => Addr,
          Cs               => Cs,
          DataIn           => DataIn,
          Rd               => Rd,
          Wr               => Wr,
          cpu_bus          => cpu_bus,
          DiscretesIn      => DiscretesIn,
          DiscretesOut     => DiscretesOut,
          OutEn1           => OutEn1,
          Strobe1          => Strobe1,
          OutEn2           => OutEn2,
          Strobe2          => Strobe2,
          MyRtAddr         => open,
          MyRtAddrParity   => open,
          BitWord          => BitWord,
          ServiceReqVector => ServiceReqVector,
          ServiceRequest   => ServiceRequest,
          SubsystemFlag    => SubsystemFlag,
          ClkOut           => ClkOut,
          nResetOut        => nResetOut
      );
      TestCntrl_2: mil1553_cpu_registers_testctrl
      port map (
          DiscretesIn                 => DiscretesIn,
          DiscretesOut                => DiscretesOut,
          Bus1Intr                    => Bus1Intr,
          Bus2Intr                    => Bus2Intr,
          port_reg_24                 => port_reg_24,
          port_reg_25                 => port_reg_25,
          port_reg_26                 => port_reg_26,
          port_reg_27                 => port_reg_27,
          port_reg_28                 => port_reg_28,
          port_reg_29                 => port_reg_29,
          port_reg_40                 => port_reg_40,
          port_reg_41                 => port_reg_41,
          port_reg_42                 => port_reg_42,
          port_reg_43                 => port_reg_43,
          port_reg_44                 => port_reg_44,
          port_reg_45                 => port_reg_45,
          port_reg_bit                => port_reg_bit,
          port_reg_bus1_mask          => port_reg_bus1_mask,
          port_reg_bus2_mask          => port_reg_bus2_mask,
          port_reg_clear_bits         => port_reg_clear_bits,
          port_reg_cmd_proc_length1   => port_reg_cmd_proc_length1,
          port_reg_cmd_proc_length2   => port_reg_cmd_proc_length2,
          port_reg_cmd_proc_start1    => port_reg_cmd_proc_start1,
          port_reg_cmd_proc_start2    => port_reg_cmd_proc_start2,
          port_reg_err_inj_data       => port_reg_err_inj_data,
          port_reg_fw_version         => port_reg_fw_version,
          port_reg_gID                => port_reg_gID,
          port_reg_intr_mask          => port_reg_intr_mask,
          port_reg_legal_brdcst_mode1 => port_reg_legal_brdcst_mode1,
          port_reg_legal_brdcst_mode2 => port_reg_legal_brdcst_mode2,
          port_reg_legal_rx_mode1     => port_reg_legal_rx_mode1,
          port_reg_legal_rx_mode2     => port_reg_legal_rx_mode2,
          port_reg_legal_subaddr1     => port_reg_legal_subaddr1,
          port_reg_legal_subaddr2     => port_reg_legal_subaddr2,
          port_reg_legal_tx_mode1     => port_reg_legal_tx_mode1,
          port_reg_legal_tx_mode2     => port_reg_legal_tx_mode2,
          port_reg_node_control       => port_reg_node_control,
          port_reg_repeat_rate        => port_reg_repeat_rate,
          port_reg_sw_rtaddr          => port_reg_sw_rtaddr,
          port_reg_tmr_1us            => port_reg_tmr_1us,
          port_reg_tmr_GAP            => port_reg_tmr_GAP,
          port_reg_tmr_NRP            => port_reg_tmr_NRP,
          port_reg_tmr_REP            => port_reg_tmr_REP,
          port_reg_tmr_SAF            => port_reg_tmr_SAF,
          port_reg_tx_control1        => port_reg_tx_control1,
          port_reg_tx_control2        => port_reg_tx_control2,
          port_reg_vectorword         => port_reg_vectorword,
          port_reg_wrap_subaddr       => port_reg_wrap_subaddr,
          MyRtAddr                    => MyRtAddr,
          MyRtAddrParity              => MyRtAddrParity,
          TimeStamp                   => TimeStamp,
          clk                         => clk,
          nReset                      => nReset,
          nResetCpu                   => nResetCpu,
          port_reg_bus1_status        => port_reg_bus1_status,
          port_reg_bus2_status        => port_reg_bus2_status,
          port_reg_cmd_rxed1          => port_reg_cmd_rxed1,
          port_reg_cmd_rxed2          => port_reg_cmd_rxed2,
          port_reg_mode_cmd_rxed1     => port_reg_mode_cmd_rxed1,
          port_reg_mode_cmd_rxed2     => port_reg_mode_cmd_rxed2,
          port_reg_mode_data_rxed1    => port_reg_mode_data_rxed1,
          port_reg_mode_data_rxed2    => port_reg_mode_data_rxed2,
          port_reg_rt_addr            => port_reg_rt_addr,
          port_reg_rx_cmd1            => port_reg_rx_cmd1,
          port_reg_rx_cmd2            => port_reg_rx_cmd2,
          port_reg_status             => port_reg_status,
          port_reg_status_rxed1       => port_reg_status_rxed1,
          port_reg_status_rxed2       => port_reg_status_rxed2,
          cpu_bus                     => cpu_bus
      );

    end architecture;
    configuration osvvm_mil1553_cpu_registers_tb_struct of osvvm_mil1553_cpu_registers_tb is
      for struct
      end for;
    end configuration;
