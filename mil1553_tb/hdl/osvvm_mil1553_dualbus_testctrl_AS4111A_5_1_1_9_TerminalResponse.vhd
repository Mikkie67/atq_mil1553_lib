--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111_5_1_1_9
-- This test is for the Terminal response time of the RT
-- AS4111A 5.1.1.9 Terminal Response Time
-- Step 1: The BC shall issue a valid legal transmit command to the RT and the response time shall be measured. 4us < tREP  < 12us
-- Step 2: The BC shall issue a valid legal receive command to the RT and the response time shall be measured. 4us < tREP  < 12us
-- Step 3: The BC shall issue a valid legal RT-RT command to the RT and the response time shall be measured. 4us < tREP  < 12us
-- Step 4: The BC shall issue a valid legal mode command to the RT and the response time shall be measured. 4us < tREP  < 12us
-- Repeat the test 100 times for each step
-- Record the commands used and response times measured
-- #################################################################################################################
-- The test mostly runs the same bench as the multi test, but has the added special manchester decoder to signal the 
-- edges that must be measured to get the response time
architecture AS4111A_5_1_1_9_TerminalResponse of osvvm_Mil1553_dualbus_testctrl is
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
  signal TestStep                                          : integer         := 0;
  --signal ActiveBus                      : integer range 1 to 2          := 1;
  signal RtGo          : boolean                       := false;
  signal BC_Done       : bit                           := '0';
  signal BC_Check_Done : std_logic                     := '0';
  signal BC_NextCmd    : std_logic                     := '0';
  signal RT1_Done      : std_logic                     := '0';
  signal RT2_Done      : std_logic                     := '0';
  signal BC_Exit       : std_logic                     := '0';
  signal BC_Check_Exit : std_logic                     := '0';
  signal DataWord      : std_logic_vector(15 downto 0) := X"A5A5"; -- Data word to send
  signal MultiComdList : MultiCommandRec_type;
  constant cNumTests : integer := 10;

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
    SetTestName("AS4111A_5_1_1_9_TerminalResponse");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("--------------------------------", ALWAYS);
    Log("--------------------------------", ALWAYS);
    Log("AS4111A_5_1_1_9_TerminalResponse", ALWAYS);
    Log("--------------------------------", ALWAYS);
    Log("--------------------------------", ALWAYS);
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_1_1_9_TerminalResponse.txt");
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
  -- the monitor process needs to keep track of the current test step, since the different commands need to measure hte time slightly differently
  -- For step 1, there is a single "lastEdge" from the BC command and a single "SyncNegEdge" from the RT response that need to be measured
  -- For step 2, there is multiple "lastEdge" from the BC command (one for the command word and one for each data word) and a single "SyncNegEdge" from the RT response that need to be measured
  -- For step 3, there is a very quick lastedge and sync edge for the two commands, but only the last lastedge and sync edge need to be measured. It also need to measureh te response time for the receiving RT CS
  -- For step 4, there is a single "lastEdge" from the BC command and a single "SyncNegEdge" from the RT response that need to be measured
  -- #################################################################################################################
  MON_BC2RT1: process -- this process just monitors the BC2RT1 messages, last edge of BC and sync edge of RT1
    variable MonId          : AlertLogIDType;
    variable timeOfLastEdge : time := 0 ns;
    variable timeOfGap      : time := 0 ns;
    variable CommandWord    : std_logic_vector(15 downto 0);
    variable CommandWord2   : std_logic_vector(15 downto 0);
    -- #################################################################################################################
  begin
    MonId := NewID("MON_BC2RT1");
    wait for 0 ns;
    loop
      WaitForToggle(MON1);
      case TestStep is
        when 1 =>
          wait until BC_BusMonitorRec.LastEdge = '1';
          if (BC_BusMonitorRec.CmdnData = '1') then
            CommandWord := BC_BusMonitorRec.OutWord;
          end if;
          timeOfLastEdge := now;
          wait until BC_BusMonitorRec.SyncNegEdge = '1';
          timeOfGap := now - timeOfLastEdge;
          Affirmif(MonId, timeOfGap > 4 us, "1 Gap between messages is less than 4 us");
          Log(MonId, "1 Gap from LastEdge of command " & to_hstring(CommandWord) & " to SyncNegEdge measured as " & to_string(now - timeOfLastEdge), ALWAYS);
          wait for 0 ns; -- to allow SyncNegEdge to be sampled
          null;
        when 2 =>
          wait until BC_BusMonitorRec.LastEdge = '1';
          if (BC_BusMonitorRec.CmdnData = '1') then
            CommandWord := BC_BusMonitorRec.OutWord;
          end if;
          wait for 100 ns;
          wait until BC_BusMonitorRec.LastEdge = '1'; -- for each data word
          timeOfLastEdge := now;
          wait until BC_BusMonitorRec.SyncNegEdge = '1';
          timeOfGap := now - timeOfLastEdge;
          Affirmif(MonId, timeOfGap > 4 us, "2 Gap between messages is less than 4 us");
          Log(MonId, "2 Gap from LastEdge of command " & to_hstring(CommandWord) & " to SyncNegEdge measured as " & to_string(now - timeOfLastEdge), ALWAYS);
          wait for 0 ns; -- to allow SyncNegEdge to be sampled
          null;
        when 3 =>
          WaitForLevel(BC_BusMonitorRec.SyncNegEdge, '1');
          wait for 1000 ns;
          WaitForLevel(BC_BusMonitorRec.LastEdge, '1'); -- first command in RT2RT
          if (BC_BusMonitorRec.CmdnData = '1') then
            CommandWord := BC_BusMonitorRec.OutWord;
          end if;
          wait for 1000 ns;
          WaitForLevel(BC_BusMonitorRec.LastEdge, '1'); -- second command in RT2RT
          if (BC_BusMonitorRec.CmdnData = '1') then
            CommandWord2 := BC_BusMonitorRec.OutWord;
          end if;
          timeOfLastEdge := now;
          wait for 1000 ns;
          WaitForLevel(BC_BusMonitorRec.SyncNegEdge, '1');
          timeOfGap := now - timeOfLastEdge;
          Affirmif(MonId, timeOfGap > 4 us, "3 Gap between messages is less than 4 us");
          Log(MonId, "3 RT2RT Command Word 1 = " & to_hstring(CommandWord) & " and Command Word2 = " & to_hstring(CommandWord2) & ", Gap from LastEdge to SyncNegEdge of first data segment measured as " & to_string(now - timeOfLastEdge), ALWAYS);
          wait for 0 ns; -- to allow SyncNegEdge to be sampled
          null;
          WaitForLevel(BC_BusMonitorRec.LastEdge, '1'); -- first data in RT2RT
          wait for 1000 ns;
          WaitForLevel(BC_BusMonitorRec.LastEdge, '1'); -- second command in RT2RT
          timeOfLastEdge := now;
          wait for 1000 ns;
          WaitForLevel(BC_BusMonitorRec.SyncNegEdge, '1');
          timeOfGap := now - timeOfLastEdge;
          Affirmif(MonId, timeOfGap > 4 us, "3 Gap between messages is less than 4 us");
          Log(MonId, "3 RT2RT receiving status word response time = " & to_string(now - timeOfLastEdge), ALWAYS);
          wait for 0 ns; -- to allow SyncNegEdge to be sampled
          null;
        when 4 =>
          wait until BC_BusMonitorRec.LastEdge = '1';
          if (BC_BusMonitorRec.CmdnData = '1') then
            CommandWord := BC_BusMonitorRec.OutWord;
          end if;
          timeOfLastEdge := now;
          wait until BC_BusMonitorRec.SyncNegEdge = '1';
          timeOfGap := now - timeOfLastEdge;
          Affirmif(MonId, timeOfGap > 4 us, "4 Gap between messages is less than 4 us");
          Log(MonId, "4 Gap from LastEdge of command " & to_hstring(CommandWord) & " to SyncNegEdge measured as " & to_string(now - timeOfLastEdge), ALWAYS);
          wait for 0 ns; -- to allow SyncNegEdge to be sampled
          null;
        when others =>
          Alert(MonId, "5 Monitor process in unknown test step: " & to_string(TestStep));
      end case;
    end loop;
  end process;
  -- #################################################################################################################
  BcProc: process
    variable Manager1Id : AlertLogIDType;
    --variable ActiveBus  : integer;
    variable Mode : integer;
    --variable ModeCode   : integer;
    -- variable TxnRx      : integer;
    variable DataLen     : integer;
    variable DataWord    : integer;
    variable PrevCmd     : std_logic_vector(15 downto 0);
    variable SubaddrRxed : std_logic_vector(31 downto 0);
    variable cmd         : integer;
    -- #################################################################################################################
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for Test AS4111_5_1_1_9", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Write(BC_cpu_bus, X"0038", X"0001"); -- Write the softwere RtAddr Register
    ReadCheck(BC_cpu_bus, X"0036", X"FEEB"); -- Read the ID Regsister
    Write(BC_cpu_bus, X"0034", X"4000"); -- Set general RT control register
    BC_done <= '0';
    BC_Check_Done <= '0';
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrInj <= errNone;
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
    Log(Manager1Id, "Test AS4111_5_1_1_9: STEP 1 - Legal transmit command", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    TestStep <= 1;
    wait for 0 ns;
    for i in 1 to cNumTests loop
      Toggle(MON1);
      --                          RA TnR  SA Len Bus RT2RT
      MultiComdList.Command(0) <= (15, 1, 1, 1, 1, '0'); -- Transmit to RT1
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      BC_done <= '0';
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      BC_done <= '1';
      wait for 100 ns;
      BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                     NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Exit, BCIDCHECK);
      --WaitForLevel(BC_Exit, '1');
      wait for tGAP;
      -- Toggle(MON1);
      Read(BC_cpu_bus, reg_subaddr_rx_lsb, SubaddrRxed(15 downto 0));
      Read(BC_cpu_bus, reg_subaddr_rx_msb, SubaddrRxed(31 downto 16));
      AffirmIf(BCID, SubaddrRxed = X"00000001", "Subaddress Rx register incorrect, expected 00000001, got " & to_hstring(SubaddrRxed));
      Write(BC_cpu_bus, reg_subaddr_rx_lsb, SubaddrRxed(15 downto 0));
      Write(BC_cpu_bus, reg_subaddr_rx_msb, SubaddrRxed(31 downto 16));
      BC_Exit <= '0';
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- STEP 2
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_1_1_9: STEP 2 - Legal receive command", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    TestStep <= 2;
    wait for 0 ns;
    for i in 1 to cNumTests loop
      Toggle(MON1);
      --                          RA TnR  SA Len Bus RT2RT
      MultiComdList.Command(0) <= (15, 0, 2, 1, 1, '0'); -- Receive to RT1
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      BC_done <= '0';
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      BC_done <= '1';
      wait for 100 ns;
      BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                     NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Exit, BCIDCHECK);
      --WaitForLevel(BC_Exit, '1');
      wait for tGAP;
      BC_Exit <= '0';
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- STEP 3
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_1_1_9: STEP 3 - Legal RT-RT command", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    TestStep <= 3;
    wait for 0 ns;
    for i in 1 to 10 loop
      Toggle(MON1);
      --                          RA TnR  SA Len Bus RT2RT
      MultiComdList.Command(0) <= (15, 0, 3, 2, 1, '1'); -- Receive to RT1
      MultiComdList.Command(1) <= (16, 1, 3, 2, 1, '0'); -- Transmit to RT2
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 2;
      BC_done <= '0';
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      BC_done <= '1';
      wait for 100 ns;
      BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                     NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Exit, BCIDCHECK);
      --WaitForLevel(BC_Exit, '1');
      wait for tGAP;
      -- check the subaddr rx register to see that right bit is set
      Read(BC_cpu_bus, reg_subaddr_rx_lsb, SubaddrRxed(15 downto 0));
      Read(BC_cpu_bus, reg_subaddr_rx_msb, SubaddrRxed(31 downto 16));
      AffirmIf(BCID, SubaddrRxed = X"00000001", "Subaddress Rx register incorrect, expected 00000001, got " & to_hstring(SubaddrRxed));
      Write(BC_cpu_bus, reg_subaddr_rx_lsb, SubaddrRxed(15 downto 0));
      Write(BC_cpu_bus, reg_subaddr_rx_msb, SubaddrRxed(31 downto 16));
      BC_Exit <= '0';
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- STEP 4
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_1_1_9: STEP 4 - Legal mode command", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    TestStep <= 4;
    wait for 0 ns;
    for i in 1 to cNumTests loop
      Toggle(MON1);
      --                          RA TnR  SA Len Bus RT2RT
      MultiComdList.Command(0) <= (15, 0, 0, 0, 1, '0'); -- Mode to RT1
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      BC_done <= '0';
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      BC_done <= '1';
      wait for 100 ns;
      BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                     NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Exit, BCIDCHECK);
      --WaitForLevel(BC_Exit, '1');
      wait for tGAP;
      BC_Exit <= '0';
    end loop;
    -- #################################################################################################################
    log(Manager1Id, "################### BC DONE ###################", ALWAYS);
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
    variable RT1ID : AlertLogIDType;
  begin
    RT1ID := NewID("RT1");
    InitRT(RT1_cpu_bus, RT1_DiscretesIn, MyRtAddr1, RT1ID, "01111", '1');
    RT1_DiscretesIn.BitWord <= X"CCCC";
    RT1_DiscretesIn.ServiceReqVector <= X"DDDD";
    wait for 0 ns;
    Write(RT1_cpu_bus, reg_rt_addr, X"0001");
    Write(RT1_cpu_bus, reg_intr_mask, X"0003");
    ReadCheck(RT1_cpu_bus, reg_gID, X"FEEB");
    Write(RT1_cpu_bus, reg_node_control, X"4020");
    ClearInterrupts(RT1_cpu_bus, 1, IrqMask, RT1ID);
    ClearInterrupts(RT1_cpu_bus, 2, IrqMask, RT1ID);
    wait until BC_Done = '1';
    while BC_Check_Done = '0' loop
      RT_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, RT1_cpu_bus, RT1_DiscretesOut, SB_RT1_CMD, SB_RT1_DAT, SB_RT2_CMD, SB_RT2_DAT, SB_BC, SB_RT2RT, NextCmdRT1, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT1_Done, BC_Exit, RT2RT_Busy, BC_Check_Exit, RT1ID);
      -- then clear the register
    end loop;
    log(RT1ID, "8 WaitForBarrier(TestDone)" & to_string(TestDone), DEBUG);
    WaitForBarrier(TestDone);
  end process;
  -- #################################################################################################################
  RT2Proc: process
    variable RT2ID       : AlertLogIDType;
    variable SubaddrRxed : std_logic_vector(31 downto 0);
  begin
    RT2ID := NewID("RT2");
    InitRT(RT2_cpu_bus, RT2_DiscretesIn, MyRtAddr2, RT2ID, "10000", '0');
    RT2_DiscretesIn.BitWord <= X"EEEE";
    RT2_DiscretesIn.ServiceReqVector <= X"FFFF";
    wait for 0 ns;
    Write(RT2_cpu_bus, reg_rt_addr, X"0001");
    Write(RT2_cpu_bus, reg_intr_mask, X"0003");
    ReadCheck(RT2_cpu_bus, reg_gID, X"FEEB");
    Write(RT2_cpu_bus, reg_node_control, X"4020");
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
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_1_1_9_TerminalResponse of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_1_1_9_TerminalResponse);
    end for;
  end for;
end configuration;
