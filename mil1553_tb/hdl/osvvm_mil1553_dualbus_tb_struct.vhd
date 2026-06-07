-- VHDL Entity mil1553_tb.osvvm_Mil1553_dualbus_tb.symbol
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

library mil1553_tb;
context mil1553_tb.mil1553_context;

entity osvvm_Mil1553_dualbus_tb is
  -- Declarations
end entity;

--
-- VHDL Architecture mil1553_tb.osvvm_Mil1553_dualbus_tb.struct
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library mil1553_lib;
use mil1553_lib.mil1553.all;

library osvvm;
context osvvm.OsvvmContext;

architecture struct of osvvm_mil1553_dualbus_tb is

  -- Architecture declarations

  -- Internal signal declarations
  signal Addr_BC              : std_logic_vector(15 downto 0);
  signal Addr_RT1             : std_logic_vector(15 downto 0);
  signal Addr_RT2             : std_logic_vector(15 downto 0);
  signal BitWord_BC           : std_logic_vector(15 downto 0);
  signal BitWord_RT1          : std_logic_vector(15 downto 0);
  signal BitWord_RT2          : std_logic_vector(15 downto 0);
  signal Clk_BC               : std_logic;
  signal Clk_RT1              : std_logic;
  signal Clk_RT2              : std_logic;
  signal Cs_BC                : std_logic;
  signal Cs_RT1               : std_logic;
  signal Cs_RT2               : std_logic;
  signal DataIn_BC            : std_logic_vector(15 downto 0);
  signal DataIn_RT1           : std_logic_vector(15 downto 0);
  signal DataIn_RT2           : std_logic_vector(15 downto 0);
  signal DataOut_BC           : std_logic_vector(15 downto 0);
  signal DataOut_RT1          : std_logic_vector(15 downto 0);
  signal DataOut_RT2          : std_logic_vector(15 downto 0);
  signal DataValid_BC         : std_logic;
  signal DataValid_RT1        : std_logic;
  signal DataValid_RT2        : std_logic;
  signal InN1_BC              : std_logic;
  signal InN1_RT1             : std_logic;
  signal InN1_RT2             : std_logic;
  signal InN2_BC              : std_logic;
  signal InN2_RT1             : std_logic;
  signal InN2_RT2             : std_logic;
  signal InP1_BC              : std_logic;
  signal InP1_RT1             : std_logic;
  signal InP1_RT2             : std_logic;
  signal InP2_BC              : std_logic;
  signal InP2_RT1             : std_logic;
  signal InP2_RT2             : std_logic;
  signal Intr_BC              : std_logic;
  signal Intr_RT1             : std_logic;
  signal Intr_RT2             : std_logic;
  signal MyRtAddrParity_BC    : std_logic;
  signal MyRtAddrParity_RT1   : std_logic;
  signal MyRtAddrParity_RT2   : std_logic;
  signal MyRtAddr_BC          : std_logic_vector(4 downto 0);
  signal MyRtAddr_RT1         : std_logic_vector(4 downto 0);
  signal MyRtAddr_RT2         : std_logic_vector(4 downto 0);
  signal OutEn1_BC            : std_logic;
  signal OutEn1_RT1           : std_logic;
  signal OutEn1_RT2           : std_logic;
  signal OutEn2_BC            : std_logic;
  signal OutEn2_RT1           : std_logic;
  signal OutEn2_RT2           : std_logic;
  signal OutN1_BC             : std_logic;
  signal OutN1_RT1            : std_logic;
  signal OutN1_RT2            : std_logic;
  signal OutN2_BC             : std_logic;
  signal OutN2_RT1            : std_logic;
  signal OutN2_RT2            : std_logic;
  signal OutP1_BC             : std_logic;
  signal OutP1_RT1            : std_logic;
  signal OutP1_RT2            : std_logic;
  signal OutP2_BC             : std_logic;
  signal OutP2_RT1            : std_logic;
  signal OutP2_RT2            : std_logic;
  signal Rd_BC                : std_logic;
  signal Rd_RT1               : std_logic;
  signal Rd_RT2               : std_logic;
  signal ServiceReqVector_BC  : std_logic_vector(15 downto 0);
  signal ServiceReqVector_RT1 : std_logic_vector(15 downto 0);
  signal ServiceReqVector_RT2 : std_logic_vector(15 downto 0);
  signal ServiceRequest_BC    : std_logic;
  signal ServiceRequest_RT1   : std_logic;
  signal ServiceRequest_RT2   : std_logic;
  signal Strobe1_BC           : std_logic;
  signal Strobe1_RT1          : std_logic;
  signal Strobe1_RT2          : std_logic;
  signal Strobe2_BC           : std_logic;
  signal Strobe2_RT1          : std_logic;
  signal Strobe2_RT2          : std_logic;
  signal SubsystemFlag_BC     : std_logic;
  signal SubsystemFlag_RT1    : std_logic;
  signal SubsystemFlag_RT2    : std_logic;
  signal VC_Clk               : std_logic;
  signal VC_nReset            : std_logic;
  signal Wr_BC                : std_logic;
  signal Wr_RT1               : std_logic;
  signal Wr_RT2               : std_logic;
  signal nResetIn_BC          : std_logic;
  signal nResetIn_RT1         : std_logic;
  signal nResetIn_RT2         : std_logic;

  signal MonBusP1 : std_logic;
  signal MonBusN1 : std_logic;

  signal BC_cpu_bus       : AddressBus16Type;
  signal RT1_cpu_bus      : AddressBus16Type;
  signal RT2_cpu_bus      : AddressBus16Type;
  signal BC1_DiscretesIn  : CoreDiscretesIn_type;
  signal RT1_DiscretesIn  : CoreDiscretesIn_type;
  signal RT2_DiscretesIn  : CoreDiscretesIn_type;
  signal BC1_DiscretesOut : CoreDiscretesOut_type;
  signal RT1_DiscretesOut : CoreDiscretesOut_type;
  signal RT2_DiscretesOut : CoreDiscretesOut_type;

  -- Internal signal declarations
    signal BC_BusMonitorRecs : BusMonitorRec_type;
    signal RT1_BusMonitorRecs : BusMonitorRec_type;
    signal RT2_BusMonitorRecs : BusMonitorRec_type;

  -- Component Declarations
  component osvvm_Mil1553_dualbus_testctrl is
    port (
      -- Global Signal Interface
      nReset           : in    std_logic;
      Clk              : in    std_logic;
      -- Transaction Interfaces
      RT1_cpu_bus      : inout AddressBus16Type;
      RT2_cpu_bus      : inout AddressBus16Type;
      BC_cpu_bus       : inout AddressBus16Type;
      BC1_DiscretesOut : in    CoreDiscretesOut_type;
      RT1_DiscretesOut : in    CoreDiscretesOut_type;
      RT2_DiscretesOut : in    CoreDiscretesOut_type;
      BC1_DiscretesIn  : out   CoreDiscretesIn_type;
      RT1_DiscretesIn  : out   CoreDiscretesIn_type;
      RT2_DiscretesIn  : out   CoreDiscretesIn_type;
      BC_BusMonitorRec : in    BusMonitorRec_type;
      RT1_BusMonitorRec : in    BusMonitorRec_type;
      RT2_BusMonitorRec : in    BusMonitorRec_type
    );
  end component;

  component Mil1553_dualbus is
    generic (
      CoreMode : core_mode_t := BCRT_MODE
    );
    port (
      Addr             : in     std_logic_vector (15 downto 0);
      BitWord          : in     std_logic_vector (15 downto 0);
      Cs               : in     std_logic;
      DataIn           : in     std_logic_vector (15 downto 0);
      InN1             : in     std_logic;
      InN2             : in     std_logic;
      InP1             : in     std_logic;
      InP2             : in     std_logic;
      MyRtAddr         : in     std_logic_vector (4 downto 0);
      MyRtAddrParity   : in     std_logic;
      Rd               : in     std_logic;
      ServiceReqVector : in     std_logic_vector (15 downto 0);
      ServiceRequest   : in     std_logic;
      SubsystemFlag    : in     std_logic;
      Wr               : in     std_logic;
      clk              : in     std_logic;
      nResetIn         : in     std_logic;
      DataOut          : out    std_logic_vector (15 downto 0);
      DataValid        : out    std_logic;
      Intr             : out    std_logic;
      OutEn1           : out    std_logic;
      OutEn2           : out    std_logic;
      OutN1            : out    std_logic;
      OutN2            : out    std_logic;
      OutP1            : out    std_logic;
      OutP2            : out    std_logic;
      Strobe1          : out    std_logic;
      Strobe2          : out    std_logic
    );
  end component;

  -- Optional embedded configurations
  -- pragma synthesis_off
  --  FOR ALL : mil1553_core_vc  USE ENTITY mil1553_tb.mil1553_core_vc;
  for BC1: Mil1553_dualbus use entity mil1553_lib.mill1553_dualbus(struct);
  for RT1: Mil1553_dualbus use entity mil1553_lib.mill1553_dualbus(struct);
  for RT2: Mil1553_dualbus use entity mil1553_lib.mill1553_dualbus(struct);
        --  FOR ALL : osvvm_Mil1553_dualbus_testctrl USE ENTITY mil1553_tb.osvvm_Mil1553_dualbus_testctrl;
        -- pragma synthesis_on

      begin
        Init_Proc: process
        begin
          wait;
        end process;
        -- -- Architecture concurrent statements
        -- create Clock
        Osvvm.ClockResetPkg.CreateClock(
          Clk    => VC_Clk,
          Period => 10 ns
        );

        -- create nReset
        Osvvm.ClockResetPkg.CreateReset(
          Reset       => VC_nReset,
          ResetActive => '0',
          Clk         => VC_Clk,
          Period      => 70 * 10 ns,
          tpd         => 1 ns
        );
        -- HDL Embedded Text Block 1 Tristatebus        -- v4p formatting off
        -- Tristatebus
        InP1_RT1 <=  OutP1_BC when OutEn1_BC = '1' else
                     OutP1_RT2 when OutEn1_RT2 = '1' else
                     'Z';--OutP1_RT1;
        InN1_RT1 <=  OutN1_BC when OutEn1_BC = '1' else
                     OutN1_RT2 when OutEn1_RT2 = '1' else
                     'Z';--OutN1_RT1;
        
        InP1_RT2 <=  OutP1_BC when OutEn1_BC = '1' else
                     OutP1_RT1 when OutEn1_RT1 = '1' else
                     'Z';--OutP1_RT2;
        InN1_RT2 <= OutN1_BC when OutEn1_BC = '1' else
                     OutN1_RT1 when OutEn1_RT1 = '1' else
                     'Z';--OutN1_RT2;

        InP1_BC <=   OutP1_RT1 when OutEn1_RT1 = '1' else
                     OutP1_RT2 when OutEn1_RT2 = '1' else
                     'Z';--OutP1_BC;
        InN1_BC <=   OutN1_RT1 when OutEn1_RT1 = '1' else
                     OutN1_RT2 when OutEn1_RT2 = '1' else
                     'Z';--OutN1_BC;

        InP2_RT1 <=  OutP2_BC when OutEn2_BC = '1' else
                     OutP2_RT2 when OutEn2_RT2 = '1' else
                     'Z';--OutP2_RT1;
        InN2_RT1 <=  OutN2_BC when OutEn2_BC = '1' else
                     OutN2_RT2 when OutEn2_RT2 = '1' else
                     'Z';--OutN2_RT1;  
        
        InP2_RT2 <=  OutP2_BC when OutEn2_BC = '1' else
                     OutP2_RT1 when OutEn2_RT1 = '1' else
                     'Z';--OutP2_RT2;
        InN2_RT2 <=  OutN2_BC when OutEn2_BC = '1' else
                     OutN2_RT1 when OutEn2_RT1 = '1' else
                     'Z';--OutN2_RT2;

        InP2_BC <=   OutP2_RT1 when OutEn2_RT1 = '1' else
                     OutP2_RT2 when OutEn2_RT2 = '1' else
                     'Z';--OutP2_BC;
        InN2_BC <=   OutN2_RT1 when OutEn2_RT1 = '1' else
                     OutN2_RT2 when OutEn2_RT2 = '1' else
                     'Z';--OutN2_BC;

        MonBusP1 <=  OutP1_BC when OutEn1_BC = '1' else
                     OutP1_RT1 when OutEn1_RT1 = '1' else
                     OutP1_RT2 when OutEn1_RT2 = '1' else
                     'Z'; 
        MonBusN1 <=  OutN1_BC when OutEn1_BC = '1' else
                     OutN1_RT1 when OutEn1_RT1 = '1' else
                     OutN1_RT2 when OutEn1_RT2 = '1' else
                     'Z';
         -- v4p formatting on

        -- Instance port mappings.
        BC1: Mil1553_dualbus
        generic map (
            CoreMode => BC_MODE
        )
        port map (
            Addr             => Addr_BC,
            BitWord          => BitWord_BC,
            Cs               => Cs_BC,
            DataIn           => DataIn_BC,
            InN1             => InN1_BC,
            InN2             => InN2_BC,
            InP1             => InP1_BC,
            InP2             => InP2_BC,
            MyRtAddr         => MyRtAddr_BC,
            MyRtAddrParity   => MyRtAddrParity_BC,
            Rd               => Rd_BC,
            ServiceReqVector => ServiceReqVector_BC,
            ServiceRequest   => ServiceRequest_BC,
            SubsystemFlag    => SubsystemFlag_BC,
            Wr               => Wr_BC,
            clk              => Clk_BC,
            nResetIn         => nResetIn_BC,
            DataOut          => DataOut_BC,
            DataValid        => DataValid_BC,
            Intr             => Intr_BC,
            OutEn1           => OutEn1_BC,
            OutEn2           => OutEn2_BC,
            OutN1            => OutN1_BC,
            OutN2            => OutN2_BC,
            OutP1            => OutP1_BC,
            OutP2            => OutP2_BC,
            Strobe1          => Strobe1_BC,
            Strobe2          => Strobe2_BC
        );
        RT1: Mil1553_dualbus
        generic map (
            CoreMode => BCRT_MODE
        )
        port map (
            Addr             => Addr_RT1,
            BitWord          => BitWord_RT1,
            Cs               => Cs_RT1,
            DataIn           => DataIn_RT1,
            InN1             => InN1_RT1,
            InN2             => InN2_RT1,
            InP1             => InP1_RT1,
            InP2             => InP2_RT1,
            MyRtAddr         => MyRtAddr_RT1,
            MyRtAddrParity   => MyRtAddrParity_RT1,
            Rd               => Rd_RT1,
            ServiceReqVector => ServiceReqVector_RT1,
            ServiceRequest   => ServiceRequest_RT1,
            SubsystemFlag    => SubsystemFlag_RT1,
            Wr               => Wr_RT1,
            clk              => Clk_RT1,
            nResetIn         => nResetIn_RT1,
            DataOut          => DataOut_RT1,
            DataValid        => DataValid_RT1,
            Intr             => Intr_RT1,
            OutEn1           => OutEn1_RT1,
            OutEn2           => OutEn2_RT1,
            OutN1            => OutN1_RT1,
            OutN2            => OutN2_RT1,
            OutP1            => OutP1_RT1,
            OutP2            => OutP2_RT1,
            Strobe1          => Strobe1_RT1,
            Strobe2          => Strobe2_RT1
        );
        RT2: Mil1553_dualbus
        generic map (
            CoreMode => RT_MODE
        )
        port map (
            Addr             => Addr_RT2,
            BitWord          => BitWord_RT2,
            Cs               => Cs_RT2,
            DataIn           => DataIn_RT2,
            InN1             => InN1_RT2,
            InN2             => InN2_RT2,
            InP1             => InP1_RT2,
            InP2             => InP2_RT2,
            MyRtAddr         => MyRtAddr_RT2,
            MyRtAddrParity   => MyRtAddrParity_RT2,
            Rd               => Rd_RT2,
            ServiceReqVector => ServiceReqVector_RT2,
            ServiceRequest   => ServiceRequest_RT2,
            SubsystemFlag    => SubsystemFlag_RT2,
            Wr               => Wr_RT2,
            clk              => Clk_RT2,
            nResetIn         => nResetIn_RT2,
            DataOut          => DataOut_RT2,
            DataValid        => DataValid_RT2,
            Intr             => Intr_RT2,
            OutEn1           => OutEn1_RT2,
            OutEn2           => OutEn2_RT2,
            OutN1            => OutN1_RT2,
            OutN2            => OutN2_RT2,
            OutP1            => OutP1_RT2,
            OutP2            => OutP2_RT2,
            Strobe1          => Strobe1_RT2,
            Strobe2          => Strobe2_RT2
        );

        test_man_dec_bc: test_man_dec
        generic map (
            gBitFreq    => 1000000,
            gClkInFreq  => 100000000,
            gOverSample => 4
        )
        port map (
            Clk               => VC_Clk,
            InN               => MonBusN1, 
            InP               => MonBusP1,
            nReset            => VC_nReset,
            BusMonitorRec     => BC_BusMonitorRecs
        );

        test_man_decRT1: test_man_dec
        generic map (
            gBitFreq    => 1000000,
            gClkInFreq  => 100000000,
            gOverSample => 4
        )
        port map (
            Clk               => VC_Clk,
            InN               => OutN2_RT1, 
            InP               => OutP2_RT1,
            nReset            => VC_nReset,
            BusMonitorRec     => RT1_BusMonitorRecs
        );

      test_man_decRT2: test_man_dec
        generic map (
            gBitFreq    => 1000000,
            gClkInFreq  => 100000000,
            gOverSample => 4
        )
        port map (
            Clk               => VC_Clk,
            InN               => OutN2_RT2, 
            InP               => OutP2_RT2,
            nReset            => VC_nReset,
            BusMonitorRec     => RT2_BusMonitorRecs
        );

        BC_VC: mil1553_core_vc
        generic map (
            MODEL_ID_NAME   => "MIL1553_VC_BC",
            tperiod_Clk     => 10 ns,
            DEFAULT_DELAY   => 1 ns,
            tpd_Clk_Address => 1 ns,
            tpd_Clk_Write   => 1 ns,
            tpd_Clk_DataIn  => 1 ns
        )
        port map (
            nReset           => VC_nReset,
            Clk              => VC_Clk,
            DataOut          => DataOut_BC,
            DataValid        => DataValid_BC,
            Intr             => Intr_BC,
            Addr             => Addr_BC,
            Cs               => Cs_BC,
            DataIn           => DataIn_BC,
            Rd               => Rd_BC,
            Wr               => Wr_BC,
            cpu_bus          => BC_cpu_bus,
            DiscretesIn      => BC1_DiscretesIn,
            DiscretesOut     => BC1_DiscretesOut,
            OutEn1           => OutEn1_BC,
            Strobe1          => Strobe1_BC,
            OutEn2           => OutEn2_BC,
            Strobe2          => Strobe2_BC,
            MyRtAddr         => MyRtAddr_BC,
            MyRtAddrParity   => MyRtAddrParity_BC,
            BitWord          => BitWord_BC,
            ServiceReqVector => ServiceReqVector_BC,
            ServiceRequest   => ServiceRequest_BC,
            SubsystemFlag    => SubsystemFlag_BC,
            ClkOut           => Clk_BC,
            nResetOut        => nResetIn_BC
        );
        RT1_VC: mil1553_core_vc
        generic map (
            MODEL_ID_NAME   => "MIL1553_VC_RT1",
            tperiod_Clk     => 10 ns,
            DEFAULT_DELAY   => 1 ns,
            tpd_Clk_Address => 1 ns,
            tpd_Clk_Write   => 1 ns,
            tpd_Clk_DataIn  => 1 ns
        )
        port map (
            nReset           => VC_nReset,
            Clk              => VC_Clk,
            DataOut          => DataOut_RT1,
            DataValid        => DataValid_RT1,
            Intr             => Intr_RT1,
            Addr             => Addr_RT1,
            Cs               => Cs_RT1,
            DataIn           => DataIn_RT1,
            Rd               => Rd_RT1,
            Wr               => Wr_RT1,
            cpu_bus          => RT1_cpu_bus,
            DiscretesIn      => RT1_DiscretesIn,
            DiscretesOut     => RT1_DiscretesOut,
            OutEn1           => OutEn1_RT1,
            Strobe1          => Strobe1_RT1,
            OutEn2           => OutEn2_RT1,
            Strobe2          => Strobe2_RT1,
            MyRtAddr         => MyRtAddr_RT1,
            MyRtAddrParity   => MyRtAddrParity_RT1,
            BitWord          => BitWord_RT1,
            ServiceReqVector => ServiceReqVector_RT1,
            ServiceRequest   => ServiceRequest_RT1,
            SubsystemFlag    => SubsystemFlag_RT1,
            ClkOut           => Clk_RT1,
            nResetOut        => nResetIn_RT1
        );
        RT2_VC: mil1553_core_vc
        generic map (
            MODEL_ID_NAME   => "MIL1553_VC_RT2",
            tperiod_Clk     => 10 ns,
            DEFAULT_DELAY   => 1 ns,
            tpd_Clk_Address => 1 ns,
            tpd_Clk_Write   => 1 ns,
            tpd_Clk_DataIn  => 1 ns
        )
        port map (
            nReset           => VC_nReset,
            Clk              => VC_Clk,
            DataOut          => DataOut_RT2,
            DataValid        => DataValid_RT2,
            Intr             => Intr_RT2,
            Addr             => Addr_RT2,
            Cs               => Cs_RT2,
            DataIn           => DataIn_RT2,
            Rd               => Rd_RT2,
            Wr               => Wr_RT2,
            cpu_bus          => RT2_cpu_bus,
            DiscretesIn      => RT2_DiscretesIn,
            DiscretesOut     => RT2_DiscretesOut,
            OutEn1           => OutEn1_RT2,
            Strobe1          => Strobe1_RT2,
            OutEn2           => OutEn2_RT2,
            Strobe2          => Strobe2_RT2,
            MyRtAddr         => MyRtAddr_RT2,
            MyRtAddrParity   => MyRtAddrParity_RT2,
            BitWord          => BitWord_RT2,
            ServiceReqVector => ServiceReqVector_RT2,
            ServiceRequest   => ServiceRequest_RT2,
            SubsystemFlag    => SubsystemFlag_RT2,
            ClkOut           => Clk_RT2,
            nResetOut        => nResetIn_RT2
        );
        TestCntrl_1: osvvm_Mil1553_dualbus_testctrl
        port map (
            nReset           => VC_nReset,
            Clk              => VC_Clk,
            RT1_cpu_bus      => RT1_cpu_bus,
            RT2_cpu_bus      => RT2_cpu_bus,
            BC_cpu_bus       => BC_cpu_bus,
            BC1_DiscretesOut => BC1_DiscretesOut,
            RT1_DiscretesOut => RT1_DiscretesOut,
            RT2_DiscretesOut => RT2_DiscretesOut,
            BC1_DiscretesIn  => BC1_DiscretesIn,
            RT1_DiscretesIn  => RT1_DiscretesIn,
            RT2_DiscretesIn  => RT2_DiscretesIn,
            BC_BusMonitorRec  => BC_BusMonitorRecs,
            RT1_BusMonitorRec => RT1_BusMonitorRecs,
            RT2_BusMonitorRec => RT2_BusMonitorRecs
        );

      end architecture;

      configuration osvvm_Mil1553_dualbus_tb_struct of osvvm_Mil1553_dualbus_tb is
        for struct
        end for;
      end configuration;
