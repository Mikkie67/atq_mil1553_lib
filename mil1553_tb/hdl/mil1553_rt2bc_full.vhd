--
-- VHDL Architecture mil1553_tb.osvvm_Mil1553_dualbus_testctrl.test1
-- Test focuses on BC2RT commands
-- A loop is used to generate all the BC2RT (RT receive) command options
-- BC verifies correct responses from two RTs
-- RTs verify correct receipt of data when addresses match or broadcast command
library mil1553_tb;
  --use mil1553_tb.osvvm_mil1553_testcntrl_rt2bc_pkg;

architecture mil1553_rt2bc_full of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("mil1553_rt2bc_full");
    log("mil1553_rt2bc_full", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    SB_RT1 <= NewID("SB_RT1");
    SB_RT2 <= NewID("SB_RT2");
    TbID <= GetAlertLogID("TB");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_rt2bc_full.txt");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 sec);
    AlertIf(now >= 100 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process;
  -- #################################################################################################################
  BcProc: process
    variable Manager1Id : AlertLogIDType;
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
    for RtAddr in 0 to 30 loop -- loop through all RT address
     log (Manager1Id,"RT " & to_string(RtAddr),ALWAYS);
      for SubAddr in 1 to 30 loop -- loop through all the subaddresses (except the two mode commands of 00000 and 11111)
        for Len in 0 to 31 loop -- loop for all the length values
          for ActiveBus in 1 to 2 loop -- loop for bus 1 or 2
            Log(Manager1Id,
                " #######################" & " CMD = " & to_hex_string(std_logic_vector(to_unsigned(RtAddr, 5)) & '1' & -- TxnRx. 0 = RT Rx
                                                                       std_logic_vector(to_unsigned(SubAddr, 5)) & -- Sub Address or Mode
                                                                       std_logic_vector(to_unsigned(Len, 5))) & -- Datelen &
                " - BUS = " & to_string(ActiveBus) & " #######################", ALWAYS); -- Length or ModeCmd
            BC_RT2BC(RtAddr, SubAddr, Len, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1, SB_RT2, Manager1Id);
            WaitForBarrier(BC_CMD_SEND_Done); --set the barrier for RTs
            ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
            ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
            Log(Manager1Id, "Waiting for RTs to complete", DEBUG);
            WaitForBarrier(RT_Done); -- set the barrier
            Log(Manager1Id, "RTs to compeleted", DEBUG);
            BC_RT2BC_Check(RtAddr, SubAddr, Len, ActiveBus, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1, SB_RT2, Manager1Id);
            -- ensure that after each test, the SB is empty again
            AlertIf(Manager1Id, not IsEmpty(SB_RT1), "Error: SB_RT1 is not empty");
            AlertIf(Manager1Id, not IsEmpty(SB_RT2), "Error: SB_RT2 is not empty");
            wait for tGap;
          end loop; -- Bus 1/2
        end loop; -- Length values
      end loop; -- Sub addresses
    end loop; -- RT addresses
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
  Write(RT1_cpu_bus, reg_node_control, X"4020");
    loop
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
      exit when BC_Done = '1';
      WaitForBarrier(BC_CMD_SEND_Done);
      exit when BC_Done = '1';
      RT_RT2BC(MyRtAddr1, CmdWord, RT1_cpu_bus, RT1_DiscretesOut, SB_RT1, Manager1Id);
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
  Write(RT2_cpu_bus, reg_node_control, X"4020");
    loop
      ClearInterrupts(RT2_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT2_cpu_bus, 2, IrqMask, Manager1Id);
      exit when BC_Done = '1';
      WaitForBarrier(BC_CMD_SEND_Done);
      exit when BC_Done = '1';
      RT_RT2BC(MyRtAddr2, CmdWord, RT2_cpu_bus, RT2_DiscretesOut, SB_RT2, Manager1Id);
      Log(Manager1Id, "RT2 is now waiting for BC to send the next command", DEBUG);
      WaitForBarrier(RT_Done); -- set the barrier
    end loop;
    Log(Manager1Id, "WaitingForBarrier TestDone", DEBUG);
    WaitForBarrier(TestDone);
    Log(Manager1Id, "Done WaitingForBarrier TestDone", DEBUG);
  end process;

end architecture;
-- #################################################################################################################
configuration mil1553_rt2bc_full_cfg of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(mil1553_rt2bc_full);
    end for;
  end for;
end configuration;
