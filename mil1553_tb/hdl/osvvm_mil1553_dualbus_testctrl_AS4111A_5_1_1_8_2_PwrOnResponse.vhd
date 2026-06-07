--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111_5_1_1_9
-- Power On Response: 
-- The purpose of this test is to verify that the UUT responds correctly to commands after power is 
-- applied to the UUT. Using the normal power on sequence for the UUT, repeat the following test 
-- sequence a minimum of ten times.
-- Step 1. Power the UUT off.
-- Step 2. Send valid, legal, non-broadcast, non-mode commands to the UUT with a maximum intermessage gap of 1 ms.
-- Step 3. Power on the UUT and observe all the responses for a minimum of 2 seconds from the first transmission of the UUT after power on.
-- The pass criteria shall be: 
-- Step 3 - NR until the first UUT transmission, and CS for the first transmission and all responses thereafter.
-- #################################################################################################################
-- The test mostly runs the same bench as the multi test, but has the added special manchester decoder to signal the 
-- edges that must be measured to get the response time
architecture AS4111A_5_1_1_8_2_PwrOnResponse of osvvm_Mil1553_dualbus_testctrl is
  signal BC_CMD_SEND_Done, RT_Done, NextCmdRT1, NextCmdRT2 : integer_barrier := 1;
  signal MON1, MON2, MON3, MON4                            : std_logic       := '0';
  signal TbID                                              : AlertLogIDType;
  signal BCID                                              : AlertLogIDType;
  signal BCIDCHECK                                         : AlertLogIDType;
  signal RT1ID                                             : AlertLogIDType;
  signal RT2ID                                             : AlertLogIDType;
  signal SB_RT1_CMD                                        : ScoreboardIdType;
  signal SB_RT2_CMD                                        : ScoreboardIdType;
  signal SB_RT1_DAT                                        : ScoreboardIdType;
  signal SB_RT2_DAT                                        : ScoreboardIdType;
  signal SB_RT1_TMP                                        : ScoreboardIdType;
  signal SB_RT2_TMP                                        : ScoreboardIdType;
  signal SB_BC                                             : ScoreboardIdType;
  signal SB_RT2RT                                          : ScoreboardIdType;
  signal CmdWord                                           : std_logic_vector(15 downto 0);
  signal ReceivingRT                                       : integer         := 0;
  signal TransmittingRT                                    : integer         := 0;
  signal RT2RT_DestAddr                                    : integer         := 0;
  signal CurCmdIndex                                       : integer         := 0;
  signal RT2RT_Busy                                        : boolean         := false;
  signal MyRtAddr1, MyRtAddr2, MyBcAddr                    : integer         := 0;
  --signal ActiveBus                      : integer range 1 to 2          := 1;
  signal RtGo          : boolean                       := false;
  signal BC_Done       : std_logic                     := '0';
  signal BC_Check_Done : std_logic                     := '0';
  signal BC_NextCmd    : std_logic                     := '0';
  signal RT1_Done      : std_logic                     := '0';
  signal RT2_Done      : std_logic                     := '0';
  signal BC_Exit       : std_logic                     := '0';
  signal BC_Check_Exit : std_logic                     := '0';
  signal DataWord      : std_logic_vector(15 downto 0) := X"A5A5"; -- Data word to send
  signal MultiComdList : MultiCommandRec_type;
  signal Go            : std_logic                     := '0';
  signal Go2           : std_logic                     := '0';
  signal StopTest      : std_logic                     := '0';

  -- #################################################################################################################
  procedure InitRT(
      signal cpu_bus       : inout AddressBus16Type;
      signal DiscretesIn   : inout CoreDiscretesIn_type;
      signal MyRtAddr1     : out   integer;
             AlertLogID    :       AlertLogIDType;
             pRtAddr       :       std_logic_vector(4 downto 0);
             pRtAddrParity :       std_logic) is
  begin
    Log(AlertLogID, "RT Process Started", DEBUG);
    DiscretesIn.MyRtAddr <= pRtAddr;
    DiscretesIn.MyRtAddrParity <= pRtAddrParity; -- Odd parity
    DiscretesIn.BitWord <= X"CCCC";
    DiscretesIn.ServiceReqVector <= X"DDDD";
    DiscretesIn.ServiceRequest <= '0';
    DiscretesIn.SubsystemFlag <= '0';
    DiscretesIn.nReset <= '0';
    wait for 0 ns;
    MyRtAddr1 <= to_integer(unsigned(DiscretesIn.MyRtAddr));
    wait for 200 ns;
    DiscretesIn.nReset <= '1';
    wait for 0 ns;
    Write(cpu_bus, reg_rt_addr, X"0001");
    Write(cpu_bus, reg_intr_mask, X"0003");
    ReadCheck(cpu_bus, reg_gID, X"FEEB");
    Write(cpu_bus, reg_node_control, X"4020");
    ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID);
    ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID);
  end procedure;

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
    wait for 200 ns;
    BC1_DiscretesIn.nReset <= '1';
    wait for 0 ns;

    wait;
  end process;
  -- #################################################################################################################
  ControlProc: process
  begin
    SetTestName("AS4111A_5_1_1_8_2_PwrOnResponse");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("-------------------------------", DEBUG);
    Log("-------------------------------", DEBUG);
    Log("AS4111A_5_1_1_8_2_PwrOnResponse", ALWAYS);
    Log("-------------------------------", DEBUG);
    Log("-------------------------------", DEBUG);
    SB_RT1_CMD <= NewID("SB_RT1_CMD");
    SB_RT2_CMD <= NewID("SB_RT2_CMD");
    SB_RT1_DAT <= NewID("SB_RT1_DAT");
    SB_RT2_DAT <= NewID("SB_RT2_DAT");
    SB_RT1_TMP <= NewID("SB_RT1_TMP");
    SB_RT2_TMP <= NewID("SB_RT2_TMP");
    SB_BC <= NewID("SB_BC");
    --SB_BC <= NewID("SB_BC");
    SB_RT2RT <= NewID("SB_RT2RT");
    TbID <= GetAlertLogID("TB");
    wait for 0 ns;
    BCID <= NewID("BC1 SEND", TbID);
    BCIDCHECK <= NewID("BC CHECK", TbID);
    RT1ID <= NewID("RT1", TbID);
    RT2ID <= NewID("RT2", TbID);
    wait for 0 ns;
    SetLogEnable(BCID, DEBUG, FALSE);
    SetLogEnable(BCIDCHECK, DEBUG, FALSE);
    SetLogEnable(RT1ID, DEBUG, FALSE);
    SetLogEnable(RT2ID, DEBUG, FALSE);
    SetLogEnable(RT2ID, PASSED, FALSE);
    SetLogEnable(RT1ID, PASSED, FALSE);
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_1_1_8_2_PwrOnResponse.txt");
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
    variable Manager1Id  : AlertLogIDType;
    variable SubaddrRxed : std_logic_vector(31 downto 0);
    variable ReadData    : std_logic_vector(15 downto 0);
    variable StartTime   : time;
    -- #################################################################################################################
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting Test AS4111A_5_1_1_8_2_PwrOnResponse", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Write(BC_cpu_bus, reg_rt_addr, X"0001"); -- Write the software RtAddr Register
    Write(BC_cpu_bus, reg_wrap_subaddr, X"001E"); -- Set the datawrap subaddress to 11110 (30)
    Write(BC_cpu_bus, reg_node_control, X"4100"); -- Set general RT control register
    Read(BC_cpu_bus, reg_fw_version, ReadData);
    log(Manager1Id, "BC MIL1553 core FW version is " & to_string(to_integer(unsigned(ReadData(15 downto 8)))) & "." & to_string(to_integer(unsigned(ReadData(7 downto 0)))), ALWAYS);
    Read(BC_cpu_bus, reg_node_control, ReadData);
    log(Manager1Id, "BC Node control is set to 0x" & to_hstring(ReadData), ALWAYS);
    BC_done <= '0';
    BC_Check_Done <= '0';
    MultiComdList.RepeatRate <= 0;
    wait for 0 ns;
    -- ########################################### BC_MODE_TEST START HERE #############################################
    -- Some restrictions in using the cmd proc to send a batch of commands:
    -- 1. Only one command proct is avaialable even though the registers is split in the memoery map.
    -- 2. If multiple commands are to tge sub address, the data in the TxRam will be overwritten by the last command.
    --    Best solution is to not do the same command to the same subadres in one cmd proc process if you need the data to be different.
    -- 3. Also be carefull of multiple mode commands with the same command (i.e. the same LEN portion)
    -- Build the multiple MODE commands in the array
    -- first grouping is with SA = 00000
    ----------------------------------------------------------------------------------------------------
    -- STEP 1
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test PwrOnResponse", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Toggle(MON1);
    --                          RA TnR  SA Len Bus RT2RT
    MultiComdList.Command(0) <= (15, 0, 30, 1, 1, '0'); -- Transmit to RT1
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.RepeatRate <= 3; -- 2ms
    MultiComdList.ErrBit <= 0;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrInj <= errNone;
    BC_done <= '0';
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    -- now the autorepeat is running in core at 2ms rate
    -- the RT1 will come out of reset and toggle the Go signal.
    -- record the time of this go signal.
    -- then record the time of the next interrupt from BC receiving the RT status word
    -- print the status word and the time difference
    -- this is the response time
    BC_done <= '1';
    loop
      if (StopTest = '1') then
        exit;
      end if;
      WaitForToggle(Go);
      wait for 100 ns;
      loop
        StartTime := now;
        Log(Manager1Id, "RT1 exited reset state/poweron at " & to_string(StartTime), ALWAYS);
        WaitForLevel(BC1_DiscretesOut.Intr);
        Read(BC_cpu_bus,(reg_bus1_status), ReadData);
        if ((ReadData and bitStatusRxedFlag) = bitStatusRxedFlag) then
          ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
          Log(Manager1Id, "Power On Response Time " & to_string(now - StartTime) & " StatusWord = " & to_hstring(ReadData), ALWAYS);
          Toggle(Go2);
          wait for 0 ns;
          exit;
        else
          ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        end if;
        --WaitForLevel(BC_Exit, '1');
      end loop;
    end loop;
    wait for 0 ns;
    wait for tGAP;
    BC_Exit <= '0';
    -- #################################################################################################################
    log(Manager1Id, "################### BC DONE ###################", DEBUG);
    BC_Check_Done <= '1';
    BC_Exit <= '1';
    wait for 0 ns;
    Toggle(BC_NextCmd);
    wait for 0 ns;
    wait for 500 us;
    log(Manager1Id, "4 WaitForBarrier(TestDone)" & to_string(TestDone), DEBUG);
    WaitForBarrier(TestDone);
    wait;
  end process;

  -- #################################################################################################################
  RT1Proc: process
    variable RT1ID    : AlertLogIDType;
    variable ReadData : std_logic_vector(15 downto 0);
    variable NumTests : integer := 10;
  begin
    RT1ID := NewID("RT1");
    InitRT(RT1_cpu_bus, RT1_DiscretesIn, MyRtAddr1, RT1ID, "01111", '1');
    RT1_DiscretesIn.BitWord <= X"CCCC";
    RT1_DiscretesIn.ServiceReqVector <= X"DDDD";
    wait for 0 ns;
    Write(RT1_cpu_bus, reg_rt_addr, X"0001");
    Write(RT1_cpu_bus, reg_intr_mask, X"0003");
    Write(RT1_cpu_bus, reg_wrap_subaddr, X"001E"); -- Set the datawrap subaddress to 11110 (30)
    Read(RT1_cpu_bus, reg_fw_version, ReadData);
    log(RT1ID, "RT1 MIL1553 core FW version is " & to_string(to_integer(unsigned(ReadData(15 downto 8)))) & "." & to_string(to_integer(unsigned(ReadData(7 downto 0)))), ALWAYS);
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    log(RT1ID, "RT1 Node control is set to 0x" & to_hstring(ReadData), ALWAYS);
    for i in 1 to NumTests loop
      log(RT1ID, "Starting test iteration " & to_string(i) & " of " & to_string(NumTests), ALWAYS);
      Write(RT1_cpu_bus, reg_node_control, X"4123"); -- both cores are in reset
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, RT1ID);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, RT1ID);
     WaitForLevel(BC_Done, '1');
      wait for 3 ms;
      Write(RT1_cpu_bus, reg_node_control, X"4120"); -- clear the reset of RT1 cores
      Toggle(Go); -- signal that RT1 is out of reset
      wait for 0 ns;
     WaitForToggle(Go2);
    end loop;
    StopTest <= '1';
    wait for 0 ns;
    Toggle(Go); -- signal that RT1 is out of reset
    log(RT1ID, "Test repeated " & to_string(NumTests) & " times", ALWAYS);
    WaitForBarrier(TestDone);
  end process;
  -- #################################################################################################################
  RT2Proc: process
    variable RT2ID    : AlertLogIDType;
    variable ReadData : std_logic_vector(15 downto 0);
  begin
    RT2ID := NewID("RT2");
    InitRT(RT2_cpu_bus, RT2_DiscretesIn, MyRtAddr2, RT2ID, "10000", '0');
    RT2_DiscretesIn.BitWord <= X"EEEE";
    RT2_DiscretesIn.ServiceReqVector <= X"FFFF";
    wait for 0 ns;
    Write(RT2_cpu_bus, reg_rt_addr, X"0001");
    Write(RT2_cpu_bus, reg_intr_mask, X"0003");
    Write(RT2_cpu_bus, reg_wrap_subaddr, X"001E"); -- Set the datawrap subaddress to 11110 (30)
    Write(RT2_cpu_bus, reg_node_control, X"4123"); -- both cores are in reset
    Read(RT2_cpu_bus, reg_fw_version, ReadData);
    log(RT2ID, "RT2 MIL1553 core FW version is " & to_string(to_integer(unsigned(ReadData(15 downto 8)))) & "." & to_string(to_integer(unsigned(ReadData(7 downto 0)))), ALWAYS);
    Read(RT2_cpu_bus, reg_node_control, ReadData);
    log(RT2ID, "RT2 Node control is set to 0x" & to_hstring(ReadData), ALWAYS);
    ClearInterrupts(RT2_cpu_bus, 1, IrqMask, RT2ID);
    ClearInterrupts(RT2_cpu_bus, 2, IrqMask, RT2ID);
    wait until BC_Done = '1';
    while BC_Check_Done = '0' loop
      RT_MULTI_CHECK(MultiComdList, MyRtAddr2, MyRtAddr1, MyBcAddr, CmdWord, RT2_cpu_bus, RT2_DiscretesOut, SB_RT2_CMD, SB_RT2_DAT, SB_RT1_CMD, SB_RT1_DAT, SB_BC, SB_RT2RT, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT2_Done, BC_Exit, RT2RT_Busy, BC_Check_Exit, RT2ID);
    end loop;
    log(RT2ID, "12 WaitForBarrier(TestDone)" & to_string(TestDone), DEBUG);
    WaitForBarrier(TestDone);
  end process;

end architecture;
-- #################################################################################################################
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_1_1_8_2_PwrOnResponse of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_1_1_8_2_PwrOnResponse);
    end for;
  end for;
end configuration;
