--
-- VHDL Architecture mil1553_tb.osvvm_Mil1553_dualbus_testctrl.test1
-- Test focuses on RT2RT commands
-- A loop is used to generate all the one RT address
-- and a second loop is used to generate the second RT address
-- RTs verify correct receipt of data when addresses match or broadcast command
-- BC verfies correct receipt of data as well as receipt of CS from receiving RT (when not broadcast)
architecture mil1553_rt2rt_dir of osvvm_Mil1553_dualbus_testctrl is
  signal BC_CMD_SEND_Done, RT_Done      : integer_barrier := 1;
  signal TbID                           : AlertLogIDType;
  signal SB_RT                          : ScoreboardIdType;
  signal SB_BC                          : ScoreboardIdType;
  signal CmdWord1                       : std_logic_vector(15 downto 0);
  signal CmdWord2                       : std_logic_vector(15 downto 0);
  signal MyRtAddr1, MyRtAddr2, MyBcAddr : integer;
  signal BC_Done                        : bit             := '0';
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

    SetTestName("mil1553_rt2rt_dir");
    log("mil1553_rt2rt_dir", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    SB_RT <= NewID("SB_RT");
    SB_BC <= NewID("SB_BC");
    TbID <= GetAlertLogID("TB");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_rt2rt_dir.txt");
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
    variable CmdValues2     : int_array(0 to 100);
    variable CmdValue1_stdv : std_logic_vector(15 downto 0);
    variable CmdValue2_stdv : std_logic_vector(15 downto 0);
    variable RtAddr1_i      : integer;
    variable RtAddr2_i      : integer;
    variable SubAddr_i      : integer;
    variable Len_i          : integer;
    variable RtAddrTemp1    : std_logic_vector(4 downto 0);
    variable RtAddrTemp2    : std_logic_vector(4 downto 0);
    variable SubAddrTemp    : std_logic_vector(4 downto 0);
    variable LenTemp        : std_logic_vector(4 downto 0);
    variable ArrayIndex     : integer;
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    -- Write the softwere RtAddr Register
    Write(BC_cpu_bus, X"0038", X"0001");
    -- Read the ID Regsister
    ReadCheck(BC_cpu_bus, X"0036", X"FEEB");
    -- Set general RT control register
    Write(BC_cpu_bus, X"0034", X"4000");
    printImportantRegisters(BC_cpu_bus, "BC", Manager1Id);
    -- #################################################################################################################
    -- THIS DESIGN IS FOR DIRECTED COVERAGE OF RT TO RT COMMANDS
    -- 1. RT1 to RT2 
    -- 2. RT2 to RT1 
    -- 3. RT1 to RTX
    -- 4. RT2 to RTX
    -- 5. RTN to RT1
    -- 6. RTN to RT2
    -- 7. RTN to RTX
    -- for each of above setups, the following additions are made
    -- 1. SubAddress 1,15,16,30 (excluding mode commands)
    -- 2. For each Sub address, do length of 0,1,31
    -- 3. For each above, do bus 1, bus 2
    -- I use an integer array to keep the command values in and then loop through this array
    -- ##### RT1 to RT2 ################################################################################################
    ArrayIndex := 0;
    for RtAddrIndex in 1 to 7 loop
      case RtAddrIndex is
        when 1 =>
          RtAddrTemp2 := "01111";
          RtAddrTemp1 := "10000";
        when 2 =>
          RtAddrTemp2 := "10000";
          RtAddrTemp1 := "01111";
        when 3 =>
          RtAddrTemp2 := "01111";
          RtAddrTemp1 := "01110";
        when 4 =>
          RtAddrTemp2 := "10000";
          RtAddrTemp1 := "01110";
        when 5 =>
          RtAddrTemp1 := "11111";
          RtAddrTemp2 := "01111";
        when 6 =>
          RtAddrTemp1 := "11111";
          RtAddrTemp2 := "10000";
        when 7 =>
          RtAddrTemp1 := "11111";
          RtAddrTemp2 := "01110";
        when others =>
          RtAddrTemp1 := "01111";
          RtAddrTemp2 := "10000";
      end case;
      for SubaddrIndex in 0 to 2 loop
        case SubaddrIndex is
          when 0 =>
            SubAddrTemp := "00001"; -- subaddress 1
          when 1 =>
            SubAddrTemp := "01111"; -- subaddress 15
          when 2 =>
            SubAddrTemp := "10000"; -- subaddress 16
          when others =>
            SubAddrTemp := "00001"; -- subaddress 1
        end case;
        for LenIndex in 0 to 2 loop
          case LenIndex is
            when 0 =>
              LenTemp := "00000"; -- length 32 words
            when 1 =>
              LenTemp := "00001"; -- length 1
            when 2 =>
              LenTemp := "11111"; -- length 31
            when others =>
              LenTemp := "00000"; -- length 32
          end case;
          CmdValue1_stdv := RtAddrTemp1 & '0' & SubAddrTemp & LenTemp;
          CmdValues1(ArrayIndex) := to_integer(unsigned(CmdValue1_stdv));
          CmdValue2_stdv := RtAddrTemp2 & '1' & SubAddrTemp & LenTemp;
          CmdValues2(ArrayIndex) := to_integer(unsigned(CmdValue2_stdv));
          ArrayIndex := ArrayIndex + 1;
        end loop;
      end loop;
    end loop;

    -- #################################################################################################################
    for CmdValuesIndex in 0 to ArrayIndex - 1 loop -- loop through all Command values
      CmdValue1_stdv := std_logic_vector(to_unsigned(CmdValues1(CmdValuesIndex), 16));
      CmdValue2_stdv := std_logic_vector(to_unsigned(CmdValues2(CmdValuesIndex), 16));
      RtAddr1_i := to_integer(unsigned(CmdValue1_stdv(15 downto 11)));
      RtAddr2_i := to_integer(unsigned(CmdValue2_stdv(15 downto 11)));
      SubAddr_i := to_integer(unsigned(CmdValue1_stdv(9 downto 5)));
      Len_i := to_integer(unsigned(CmdValue1_stdv(4 downto 0)));
      -- #################################################################################################################
      log(Manager1Id, "RtAddr1_i " & to_string(RtAddr1_i) & " RtAddr2_i " & to_string(RtAddr2_i), ALWAYS);
      if (CmdValue1_stdv = CmdValue2_stdv) then -- Rx and Tx addresses cannot be the same
        Log(Manager1Id, "Skipping matching Addrs " & to_String(CmdValue1_stdv));
        exit;
      end if;
      for ActiveBus in 1 to 2 loop -- loop for bus 1 or 2
        CmdWord1 <= std_logic_vector(to_unsigned(CmdValues1(CmdValuesIndex), 16));
        CmdWord2 <= std_logic_vector(to_unsigned(CmdValues2(CmdValuesIndex), 16));
        wait for 0 ns;
        BC_RT2RT(RtAddr1_i, RtAddr2_i, SubAddr_i, Len_i, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord1, CmdWord2, BC_cpu_bus, BC1_DiscretesOut, SB_RT, SB_BC, Manager1Id);
        WaitForBarrier(BC_CMD_SEND_Done); --set the barrier for RTs
        ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
        Log(Manager1Id, "Waiting for RTs to complete", DEBUG);
        WaitForBarrier(RT_Done); -- set the barrier
        Log(Manager1Id, "RTs to compeleted", DEBUG);
        BC_RT2RT_Check(RtAddr1_i, RtAddr2_i, SubAddr_i, Len_i, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord1, CmdWord2, BC_cpu_bus, BC1_DiscretesOut, SB_RT, SB_BC, Manager1Id);
        -- ensure that after each test, the SB is empty again
        AlertIf(Manager1Id, not IsEmpty(SB_RT), "Error: SB_RT is not empty");
        AlertIf(Manager1Id, not IsEmpty(SB_BC), "Error: SB_BC is not empty");
        wait for tGAP; -- need to wait for the GAP timer before starting new transaction TODO: should the FSM not capture this and just start when the BC reaches IDLE after the GAP timer?
      end loop; -- Bus 1/2
    end loop; -- RT Rx Addresses
    -- #################################################################################################################
    -- This is just te reverse of the loops above (RT1 and RT2 is swapped)
    ArrayIndex := 0;
    for RtAddrIndex in 1 to 7 loop
      case RtAddrIndex is
        when 1 =>
          RtAddrTemp1 := "01111";
          RtAddrTemp2 := "10000";
        when 2 =>
          RtAddrTemp1 := "10000";
          RtAddrTemp2 := "01111";
        when 3 =>
          RtAddrTemp1 := "01111";
          RtAddrTemp2 := "01110";
        when 4 =>
          RtAddrTemp1 := "10000";
          RtAddrTemp2 := "01110";
        when 5 =>
          RtAddrTemp1 := "11111";
          RtAddrTemp2 := "01111";
        when 6 =>
          RtAddrTemp1 := "11111";
          RtAddrTemp2 := "10000";
        when 7 =>
          RtAddrTemp1 := "11111";
          RtAddrTemp2 := "01110";
        when others =>
          RtAddrTemp1 := "01111";
          RtAddrTemp2 := "10000";
      end case;
      for SubaddrIndex in 0 to 2 loop
        case SubaddrIndex is
          when 0 =>
            SubAddrTemp := "00001"; -- subaddress 1
          when 1 =>
            SubAddrTemp := "01111"; -- subaddress 15
          when 2 =>
            SubAddrTemp := "10000"; -- subaddress 16
          when others =>
            SubAddrTemp := "00001"; -- subaddress 1
        end case;
        for LenIndex in 0 to 2 loop
          case LenIndex is
            when 0 =>
              LenTemp := "00000"; -- length 32 words
            when 1 =>
              LenTemp := "00001"; -- length 1
            when 2 =>
              LenTemp := "11111"; -- length 31
            when others =>
              LenTemp := "00000"; -- length 32
          end case;
          CmdValue1_stdv := RtAddrTemp1 & '0' & SubAddrTemp & LenTemp;
          CmdValues1(ArrayIndex) := to_integer(unsigned(CmdValue1_stdv));
          CmdValue2_stdv := RtAddrTemp2 & '1' & SubAddrTemp & LenTemp;
          CmdValues2(ArrayIndex) := to_integer(unsigned(CmdValue2_stdv));
          ArrayIndex := ArrayIndex + 1;
        end loop;
      end loop;
    end loop;
    -- #################################################################################################################
    for CmdValuesIndex in 0 to ArrayIndex - 1 loop -- loop through all Command values
      CmdValue1_stdv := std_logic_vector(to_unsigned(CmdValues1(CmdValuesIndex), 16));
      CmdValue2_stdv := std_logic_vector(to_unsigned(CmdValues2(CmdValuesIndex), 16));
      RtAddr1_i := to_integer(unsigned(CmdValue1_stdv(15 downto 11)));
      RtAddr2_i := to_integer(unsigned(CmdValue2_stdv(15 downto 11)));
      SubAddr_i := to_integer(unsigned(CmdValue1_stdv(9 downto 5)));
      Len_i := to_integer(unsigned(CmdValue1_stdv(4 downto 0)));
      -- #################################################################################################################
      log(Manager1Id, "RtAddr1_i " & to_string(RtAddr1_i) & " RtAddr2_i " & to_string(RtAddr2_i), ALWAYS);
      if (CmdValue1_stdv = CmdValue2_stdv) then -- Rx and Tx addresses cannot be the same
        Log(Manager1Id, "Skipping matching Addrs " & to_String(CmdValue1_stdv));
        exit;
      end if;
      for ActiveBus in 1 to 2 loop -- loop for bus 1 or 2
        CmdWord1 <= std_logic_vector(to_unsigned(CmdValues1(CmdValuesIndex), 16));
        CmdWord2 <= std_logic_vector(to_unsigned(CmdValues2(CmdValuesIndex), 16));
        wait for 0 ns;
        BC_RT2RT(RtAddr1_i, RtAddr2_i, SubAddr_i, Len_i, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord1, CmdWord2, BC_cpu_bus, BC1_DiscretesOut, SB_RT, SB_BC, Manager1Id);
        WaitForBarrier(BC_CMD_SEND_Done); --set the barrier for RTs
        ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
        Log(Manager1Id, "Waiting for RTs to complete", DEBUG);
        WaitForBarrier(RT_Done); -- set the barrier
        Log(Manager1Id, "RTs to compeleted", DEBUG);
        BC_RT2RT_Check(RtAddr1_i, RtAddr2_i, SubAddr_i, Len_i, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord1, CmdWord2, BC_cpu_bus, BC1_DiscretesOut, SB_RT, SB_BC, Manager1Id);
        -- ensure that after each test, the SB is empty again
        AlertIf(Manager1Id, not IsEmpty(SB_RT), "Error: SB_RT is not empty");
        AlertIf(Manager1Id, not IsEmpty(SB_BC), "Error: SB_BC is not empty");
        wait for tGAP; -- need to wait for the GAP timer before starting new transaction TODO: should the FSM not capture this and just start when the BC reaches IDLE after the GAP timer?
      end loop; -- Bus 1/2
    end loop; -- RT Rx Addresses

    BC_done <= '1'; -- This is set to let the RTs know that they can end their infinite loops in order to do TESTDONE BARRIER
    wait for 100 us;
    Log(Manager1Id, "WaitingForBarrier TestDone", DEBUG);
    WaitForBarrier(BC_CMD_SEND_Done); --The RTs might be waiting for it again
    WaitForBarrier(TestDone);
    Log(Manager1Id, "Done WaitingForBarrier TestDone", DEBUG);
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
    Write(RT1_cpu_bus, reg_node_control, bitBrdcstEn or bitIS_RT);
    printImportantRegisters(RT1_cpu_bus, "RT1", Manager1Id);
    loop
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
      exit when BC_Done = '1';
      WaitForBarrier(BC_CMD_SEND_Done);
      exit when BC_Done = '1';
      RT_RT2RT(MyRtAddr1, MyRtAddr2, CmdWord1, CmdWord2, RT1_cpu_bus, RT1_DiscretesOut, SB_RT, SB_BC, Manager1Id);
      Log(Manager1Id, "RT1 is now waiting for BC to send the next command", DEBUG);
      WaitForBarrier(RT_Done); -- set the barrier
    end loop;
    Log(Manager1Id, "WaitingForBarrier TestDone", DEBUG);
    WaitForBarrier(TestDone);
    Log(Manager1Id, "Done WaitingForBarrier TestDone", DEBUG);
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
    Write(RT2_cpu_bus, reg_node_control, bitBrdcstEn or bitIS_RT);
    printImportantRegisters(RT2_cpu_bus, "RT2", Manager1Id);
    loop
      ClearInterrupts(RT2_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT2_cpu_bus, 2, IrqMask, Manager1Id);
      exit when BC_Done = '1';
      WaitForBarrier(BC_CMD_SEND_Done);
      exit when BC_Done = '1';
      RT_RT2RT(MyRtAddr2, MyRtAddr1, CmdWord1, CmdWord2, RT2_cpu_bus, RT2_DiscretesOut, SB_RT, SB_BC, Manager1Id);
      Log(Manager1Id, "RT2 is now waiting for BC to send the next command", DEBUG);
      WaitForBarrier(RT_Done); -- set the barrier
    end loop;
    Log(Manager1Id, "WaitingForBarrier TestDone", DEBUG);
    WaitForBarrier(TestDone);
    Log(Manager1Id, "Done WaitingForBarrier TestDone", DEBUG);
  end process;

end architecture;
-- #################################################################################################################
configuration mil1553_rt2rt_dir_cfg of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(mil1553_rt2rt_dir);
    end for;
  end for;
end configuration;
