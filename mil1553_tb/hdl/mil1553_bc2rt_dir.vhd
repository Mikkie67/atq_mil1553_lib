--
-- VHDL Architecture mil1553_tb.osvvm_Mil1553_dualbus_testctrl.mil1553_bc2rt_dir
-- Test focuses on BC2RT commands
-- Directed BC2RT (RT receive) command options
-- BC verifies correct responses from two RTs
-- RTs verify correct receipt of data when addresses match or broadcast command
-- BC also verifies correct NRP timeouts when command RTs not in the network
architecture mil1553_bc2rt_dir of osvvm_Mil1553_dualbus_testctrl is
  signal NEW_CMD_START                  : integer_barrier      := 1;
  signal BC_CMD_SEND_Done, RT_Done      : integer_barrier      := 1;
  signal TbID                           : AlertLogIDType;
  signal SB_RT1                         : ScoreboardIdType;
  signal SB_RT2                         : ScoreboardIdType;
  signal CmdWord                        : std_logic_vector(15 downto 0);
  signal MyRtAddr1, MyRtAddr2, MyBcAddr : integer;
  signal ActiveBus                      : integer range 1 to 2 := 1;
  signal BC_Done                        : bit                  := '0';
  -- #################################################################################################################
  -- #################################################################################################################
  -- #################################################################################################################
  -- #################################################################################################################
begin
  -- #################################################################################################################
  InitProc: process
  begin
    BC1_DiscretesIn.MyRtAddr <= "00000";
    BC1_DiscretesIn.MyRtAddrParity <= '1'; -- Odd parity
    BC1_DiscretesIn.BitWord <= X"AAAA";
    BC1_DiscretesIn.ServiceReqVector <= X"BBBB";
    BC1_DiscretesIn.ServiceRequest <= '0';
    BC1_DiscretesIn.SubsystemFlag <= '0';
    BC1_DiscretesIn.nReset <= '0';
    wait for 0 ns;
    MyBcAddr <= to_integer(unsigned(BC1_DiscretesIn.MyRtAddr));
    wait for 200 ns;
    BC1_DiscretesIn.nReset <= '1';
    wait for 0 ns;

    RT1_DiscretesIn.MyRtAddr <= "01111";
    RT1_DiscretesIn.MyRtAddrParity <= '1'; -- Odd parity
    RT1_DiscretesIn.BitWord <= X"CCCC";
    RT1_DiscretesIn.ServiceReqVector <= X"DDDD";
    RT1_DiscretesIn.ServiceRequest <= '0';
    RT1_DiscretesIn.SubsystemFlag <= '0';
    RT1_DiscretesIn.nReset <= '0';
    wait for 0 ns;
    MyRtAddr1 <= to_integer(unsigned(RT1_DiscretesIn.MyRtAddr));
    wait for 200 ns;
    RT1_DiscretesIn.nReset <= '1';
    wait for 0 ns;

    RT2_DiscretesIn.MyRtAddr <= "10000";
    RT2_DiscretesIn.MyRtAddrParity <= '0'; -- Odd parity
    RT2_DiscretesIn.BitWord <= X"EEEE";
    RT2_DiscretesIn.ServiceReqVector <= X"FFFF";
    RT2_DiscretesIn.ServiceRequest <= '0';
    RT2_DiscretesIn.SubsystemFlag <= '0';
    RT2_DiscretesIn.nReset <= '0';
    wait for 0 ns;
    MyRtAddr2 <= to_integer(unsigned(RT2_DiscretesIn.MyRtAddr));
    wait for 200 ns;
    RT2_DiscretesIn.nReset <= '1';
    wait for 0 ns; --to propagate the discretes before using them in next statements
    MyRtAddr1 <= to_integer(unsigned(RT1_DiscretesIn.MyRtAddr));
    MyRtAddr2 <= to_integer(unsigned(RT2_DiscretesIn.MyRtAddr));
    MyBcAddr <= to_integer(unsigned(BC1_DiscretesIn.MyRtAddr));
    wait for 0 ns;
    wait;
  end process;
  -- #################################################################################################################
  ControlProc: process
  begin
    SetTestName("mil1553_bc2rt_dir");
    log("mil1553_bc2rt_dir", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    SB_RT1 <= NewID("SB_RT1");
    SB_RT2 <= NewID("SB_RT2");
    TbID <= GetAlertLogID("TB");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_bc2rt_dir.txt");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 10 sec);
    AlertIf(now >= 10 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process;
  -- #################################################################################################################
  BcProc: process
    variable Manager1Id     : AlertLogIDType;
    variable CmdValues1     : int_array(0 to 100);
    variable CmdValue1_stdv : std_logic_vector(15 downto 0);
    variable RtAddr_i       : integer;
    variable SubAddr_i      : integer;
    variable Len_i          : integer;
    variable ArrayIndex     : integer := 0;
    variable RtAddrTemp1    : std_logic_vector(4 downto 0);
    variable SubAddrTemp    : std_logic_vector(4 downto 0);
    variable LenTemp        : std_logic_vector(4 downto 0);
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    -- Write the softwere RtAddr Register
    Write(BC_cpu_bus, reg_rt_addr, X"0001");
    -- Read the ID Regsister
    ReadCheck(BC_cpu_bus, reg_gID, X"FEEB");
    -- Set general RT control register
    Write(BC_cpu_bus, reg_node_control, X"4000");
    -- #################################################################################################################
    -- THIS LOOP DESIGN IS FOR DIRECTED COVERAGE OF BC TO RT RX COMMANDS, INCLUDING BROADCASTS
    -- 1. BC to RT1 (RtAddr = 15)
    -- 2. BC to RT2 (RtAddr = 16)
    -- 3. BC to broadcast (RtAddr = 31)
    -- 4. BC to RTX (RtAddr = 14)
    -- for each of above setups, the following additions are made
    -- 1. SubAddress 1,15,16,30 (excluding mode commands)
    -- 2. For each Sub address, do length of 0,1,31
    -- 3. For each above, do bus 1, bus 2
    -- I use an integer array to keep the command values in and then loop through this array
    ArrayIndex := 0;
    for RtAddrIndex in 1 to 4 loop
      case RtAddrIndex is
        when 1 =>
          RtAddrTemp1 := "01111";
        when 2 =>
          RtAddrTemp1 := "10000";
        when 3 =>
          RtAddrTemp1 := "11111";
        when 4 =>
          RtAddrTemp1 := "01110";
      end case;
      for SubaddrIndex in 0 to 3 loop
        case SubaddrIndex is
          when 0 =>
            SubAddrTemp := "00001"; -- subaddress 1
          when 1 =>
            SubAddrTemp := "01111"; -- subaddress 15
          when 2 =>
            SubAddrTemp := "10000"; -- subaddress 16
          when 3 =>
            SubAddrTemp := "11110"; -- subaddress 31
        end case;
        for LenIndex in 0 to 2 loop
          case LenIndex is
            when 0 =>
              LenTemp := "00000"; -- length 32 words
            when 1 =>
              LenTemp := "00001"; -- length 1
            when 2 =>
              LenTemp := "11111"; -- length 31
          end case;
          CmdValue1_stdv := RtAddrTemp1 & '0' & SubAddrTemp & LenTemp;
          CmdValues1(ArrayIndex) := to_integer(unsigned(CmdValue1_stdv));
          ArrayIndex := ArrayIndex + 1;
        end loop;
      end loop;
    end loop;
    -- #################################################################################################################
    for CmdValuesIndex in 0 to ArrayIndex - 1 loop -- loop through all Command values
      CmdValue1_stdv := std_logic_vector(to_unsigned(CmdValues1(CmdValuesIndex), 16));
      RtAddr_i := to_integer(unsigned(CmdValue1_stdv(15 downto 11)));
      SubAddr_i := to_integer(unsigned(CmdValue1_stdv(9 downto 5)));
      Len_i := to_integer(unsigned(CmdValue1_stdv(4 downto 0)));
      for ActiveBus in 1 to 2 loop -- loop for bus 1 or 2
        WaitForBarrier(NEW_CMD_START);
        BC_BC2RT(RtAddr_i, SubAddr_i, Len_i, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1, SB_RT2, Manager1Id);
        WaitForBarrier(BC_CMD_SEND_Done);
        WaitForBarrier(RT_Done);
        BC_BC2RT_Check(RtAddr_i, SubAddr_i, Len_i, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1, SB_RT2, Manager1Id);
        -- wait for the TxGAP before starting the next command
        wait for tGAP;
      end loop; -- Bus 1/2
    end loop; -- Command values
    log(Manager1Id, "################### BC DONE ###################", DEBUG);
    BC_done <= '1';
    WaitForBarrier(NEW_CMD_START);
    wait for 100 us;
    WaitForBarrier(TestDone);
  end process;
  -- #################################################################################################################
  RT1Proc: process
    variable Manager1Id : AlertLogIDType;
  begin
    wait until nReset = '1';
    WaitForClock(RT1_cpu_bus, 1);
    Manager1Id := NewID("RT1", TbID);
    Write(RT1_cpu_bus, reg_rt_addr, X"0001");
    Write(RT1_cpu_bus, reg_intr_mask, X"0003");
    ReadCheck(RT1_cpu_bus, reg_gID, X"FEEB");
    Write(RT1_cpu_bus, reg_node_control, X"4020");
    while (BC_Done = '0') loop
      WaitForBarrier(NEW_CMD_START);
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
      exit when BC_Done = '1';
      WaitForBarrier(BC_CMD_SEND_Done);
      exit when BC_Done = '1';
      RT_BC2RT(MyRtAddr1, CmdWord, RT1_cpu_bus, RT1_DiscretesOut, SB_RT1, Manager1Id);
      WaitForBarrier(RT_Done);
    end loop;
    WaitForBarrier(TestDone);
  end process;
  -- #################################################################################################################
  RT2Proc: process
    variable Manager1Id : AlertLogIDType;
  begin
    wait until nReset = '1';
    WaitForClock(RT2_cpu_bus, 1);
    Manager1Id := NewID("RT2", TbID);
    Write(RT2_cpu_bus, reg_rt_addr, X"0001");
    Write(RT2_cpu_bus, reg_intr_mask, X"0003");
    ReadCheck(RT2_cpu_bus, reg_gID, X"FEEB");
    Write(RT2_cpu_bus, reg_node_control, X"4020");
    while (BC_Done = '0') loop
      WaitForBarrier(NEW_CMD_START);
      ClearInterrupts(RT2_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT2_cpu_bus, 2, IrqMask, Manager1Id);
      exit when BC_Done = '1';
      WaitForBarrier(BC_CMD_SEND_Done);
      exit when BC_Done = '1';
      RT_BC2RT(MyRtAddr2, CmdWord, RT2_cpu_bus, RT2_DiscretesOut, SB_RT2, Manager1Id);
      WaitForBarrier(RT_Done);
    end loop;
    WaitForBarrier(TestDone);
  end process;
end architecture;
-- #################################################################################################################
configuration mil1553_bc2rt_dir_cfg of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(mil1553_bc2rt_dir);
    end for;
  end for;
end configuration;
