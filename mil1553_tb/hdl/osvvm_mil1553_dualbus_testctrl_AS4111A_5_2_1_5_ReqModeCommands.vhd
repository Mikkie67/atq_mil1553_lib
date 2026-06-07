--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_ReqModeCommands
-- This test is for the required mode commands
-- AS4111A_5_1_5 Required Mode Commands: 
-- The purpose of these tests is to verify that the UUT responds
-- properly to the required mode commands. The tests are not intended to verify the mission
-- aspects stated in the equipment specification. 
-- The UUT shall be tested for each required mode code with a subaddress field mode code 
-- indicator of all zeros and repeated with a subaddress field of all ones.
----------------------------------------------------------------------------------------------------
-- Transmit Status: The purpose of this test is to verify that the UUT has the ability to recognize
-- the transmit status mode command and to transmit its last status word.
-- #################################################################################################################
architecture AS4111A_5_2_1_5_ReqModeCommands of osvvm_Mil1553_dualbus_testctrl is
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
  constant cNumTests : integer := 1;

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
    SetTestName("AS4111A_5_2_1_5_ReqModeCommands");

    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("-----------------", ALWAYS);
    Log("-----------------", ALWAYS);
    Log(GetTestName, ALWAYS);
    Log("-----------------", ALWAYS);
    Log("-----------------", ALWAYS);
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_1_5_ReqModeCommands");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 sec);
    AlertIf(now >= 100 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    -- WriteTestResults(GetTestName & "_cmdwrds", GetTestName);
    -- WriteTestYaml(GetTestName & "_cmdwrds", GetTestName);
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
    variable Manager1Id   : AlertLogIDType;
    variable MultiCmdWord : std_logic_vector(15 downto 0);
    variable Timeout      : boolean;
    variable ReadData     : std_logic_vector(15 downto 0);
    variable NumWords     : integer := 0;
    variable MilBusOffset : std_logic_vector(15 downto 0);
    variable ModeCode     : integer := 0;
    -- #################################################################################################################
    procedure getNumWords(signal MultiComdList : in MultiCommandRec_type) is
    begin
      if (MultiComdList.Command(0).Len = 0) then
        NumWords := 32;
      else
        NumWords := MultiComdList.Command(0).Len;
      end if;
      if (MultiComdList.Command(0).MilBus = 1) then
        MilBusOffset := X"0010";
      else
        MilBusOffset := X"0020";
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatus(signal MultiComdList : in MultiCommandRec_type) is
    begin
      getNumWords(MultiComdList);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitStatusRxedFlag, bitStatusRxedFlag, Manager1Id); -- check for NRP
        -- check that the status word is clear
        MultiCmdWord := getCmdWord(MultiComdList.Command(0));
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatusME(signal MultiComdList : in MultiCommandRec_type) is
    begin
      getNumWords(MultiComdList);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitStatusRxedFlag, bitStatusRxedFlag, Manager1Id); -- check for NRP
        -- check that the status word is clear
        MultiCmdWord := getCmdWord(MultiComdList.Command(0));
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        AffirmIf(Manager1Id, ReadData = ((MultiCmdWord and X"F800") or bitMessageError), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR + ME", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkNRP(signal MultiComdList : in MultiCommandRec_type) is
    begin
      getNumWords(MultiComdList);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tNRP, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitNRP, bitNRP, Manager1Id); -- check for NRP
        -- check that the status word is clear
        MultiCmdWord := getCmdWord(MultiComdList.Command(0));
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": NRP", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for Test AS4111A_5_1_5 Required Mode Commands", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Write(BC_cpu_bus, X"0038", X"0001"); -- Write the softwere RtAddr Register
    ReadCheck(BC_cpu_bus, X"0036", X"FEEB"); -- Read the ID Regsister
    Write(BC_cpu_bus, X"0034", X"4000"); -- Set general RT control register
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
    -- 4. When working with different busses, the commands must be split between the multicommand list.
    -- 5. only a single error injection can be used per cmd proc run. It is applied outside the loop    
    ----------------------------------------------------------------------------------------------------
    -- Transmit Status: The purpose of this test is to verify that the UUT has the ability to recognize
    -- the transmit status mode command and to transmit its last status word.
    -- The following sequence shall be performed:
    -- Step 1. A valid legal message shall be sent to the UUT on the bus under test.
    -- Step 2. A transmit status mode command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 3. A valid legal message shall be sent to the UUT on a bus other than that used in Step 1.
    -- Step 4. A transmit status mode command shall be sent to the UUT on the same bus used in Step 3.
    -- Step 5. A valid legal receive command with a parity error in a data word shall be sent on the same bus used in Step 1.
    -- Step 6. A transmit status mode command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 7. Repeat Step 6.
    -- Step 8. Repeat Step 4.
    -- Step 9. Repeat Step 1.
    -- Step 10. Repeat Step 2.
    -- Step 11. Repeat Step 4.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; Step 2 - CS;
    -- Step 3 - CS; Step 4 - CS; Step 5 - NR; Step 6 - ME; Step 7 - ME; Step 8 - ME; Step 9 - CS;
    -- Step 10 - CS; Step 11 - CS.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_1_5_1: STEP 1 - Transmit Status word.   ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 2;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 1, '0'); -- MODE: Transmit status word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 4;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 2, '0'); -- MODE: Transmit status word command to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 5;
      MultiComdList.Command(0) <= (15, 0, 5, 1, 1, '0'); -- Receive SA5 to RT1 on bus 1 with parity error in data word
      MultiComdList.ErrInj <= errParity;
      MultiComdList.ErrWrd <= 1;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 6;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 1, '0'); -- MODE: Transmit status word command to RT1 on bus 1
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusME(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 7;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 1, '0'); -- MODE: Transmit status word command to RT1 on bus 1
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusME(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 8;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 2, '0'); -- MODE: Transmit status word command to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- NOTE: AS4111A says this step must provide ME, but there was no error on Bus 2, so CS is expected. Clarification is required.
      --checkClearStatusME(MultiComdList);
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 9;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 10;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 1, '0'); -- MODE: Transmit status word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 11;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 2, '0'); -- MODE: Transmit status word command to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Transmitter Shutdown and Override: 
    -- This test shall verify that the UUT recognizes the dual
    -- redundant mode commands to shutdown the alternate bus transmitter and to override the
    -- shutdown. A valid legal transmitter shutdown mode command shall be sent to the UUT to
    -- cause an alternate bus transmitter shutdown. A valid legal override transmitter shutdown mode
    -- command shall be sent to the UUT to cause an override of the transmitter shut down. The
    -- following test sequence shall be used for each case including verification of the UUT response
    -- indicated.
    -- Step 1. A valid legal command shall be sent to the UUT on the bus under test.
    -- Step 2. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
    -- Step 3. A valid legal transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 4. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 5. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 6. A valid legal override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 7. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 8. A valid legal override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 9. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 10. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; Step 2 - CS; Step 3 - CS; 
    -- Step 4 - NR; 
    -- Step 5 - CS; 
    -- Step 6 - NR; Step 7 - NR; 
    -- Step 8 - CS; Step 9 - CS; Step 10 - CS.   
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "---------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_1_5_2: STEP 2 - Transmitter Shutdown and Override", ALWAYS);
    Log(Manager1Id, "---------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 2;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TxShutdown, 1, '0'); -- MODE: Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 4;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 5;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 6;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TxShutdownOvr, 2, '0'); -- MODE: Transmitter shutdown word command to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 7;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 8;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TxShutdownOvr, 1, '0'); -- MODE: Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 9;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 10;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Reset Remote Terminal: 
    -- The purpose of this test is to verify that the UUT has the ability to recognize and properly operate 
    -- when the reset remote terminal mode command is received. Note that this test provides characterization
    -- of the reset time (TRST) as a first step. If the reset time is variable, the test must be performed 
    -- with conditions in the UUT set such that a maximum reset time results. The following sequence shall be performed.
    --
    -- Step 1. A reset remote terminal mode command shall be sent to the UUT on the bus under test.
    -- Step 2. After time T from Step 1, as measured per Figure 7, a valid legal command shall be sent to the UUT on the same bus used in Step 1.   
    --
    -- Starting with time T at 100.0 ms repeat Step 1 and Step 2 while decreasing time T from 100.0 ms down to 4.0 µs 
    -- in the following steps: from 100.0 ms to 6.0 ms in no greater than 1.0 ms steps, and from 6.0 ms to 4.0 µs in 
    -- no greater than 10.0 µs steps. --> we will test on the minimum time of 4.0 us, thus 4us - 500ns = 3.5us gap
    --
    -- The minimum time, TRST, between Step 1 and Step 2, as measured per Figure 7, in which the
    -- UUT's response to Step 2 is CS (with busy bit reset), shall be recorded.
    -- Step 3. A valid legal transmitter shutdown mode command shall be sent to the UUT on the bus used in Step 1.
    -- Step 4. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
    -- Step 5. A reset remote terminal mode command shall be sent to the UUT on the bus used in Step 1.
    -- Step 6. After an intermessage gap equal to TRST, a valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; Step 2 - CS (with busy bit reset) for all time T ≥ 5.0 ms, and CS or NR for T < 5.0 ms; 
    -- Step 3 - CS; Step 4 - NR; Step 5 - CS; Step 6 - CS (with busy bit reset).NR; Step 5 - CS; Step 6 - CS (with busy bit reset).
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_1_5_3: STEP 3 - Reset Remote Terminal BUS1", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_ResetRt, 1, '0'); -- MODE: Reset RT command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      -- After the RT is reset, register need to be configured to get it ready for operation
      BC_Done <= '1';
      wait for 3400 ns;
      BC_Done <= '0';
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 2;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TxShutdown, 1, '0'); -- MODE: Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 4;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 5;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_ResetRt, 1, '0'); -- MODE: Reset RT command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      -- After the RT is reset, register need to be configured to get it ready for operation
      BC_Done <= '1';
      wait for 3400 ns;
      BC_Done <= '0';
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 6;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
    end loop;
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_1_5_3: STEP 3 - Reset Remote Terminal BUS2", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_ResetRt, 2, '0'); -- MODE: Reset RT command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      -- After the RT is reset, register need to be configured to get it ready for operation
      BC_Done <= '1';
      wait for 3400 ns;
      BC_Done <= '0';
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 2;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TxShutdown, 2, '0'); -- MODE: Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 4;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 5;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_ResetRt, 2, '0'); -- MODE: Reset RT command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      -- After the RT is reset, register need to be configured to get it ready for operation
      BC_Done <= '1';
      wait for 3400 ns;
      BC_Done <= '0';
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 6;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    BC_Exit <= '0';
    wait for 0 ns;
    -- #################################################################################################################
    log(Manager1Id, "################### BC DONE ###################", ALWAYS);
    BC_Check_Done <= '1';
    BC_Exit <= '1';
    wait for 0 ns;
    BC_Done <= '1';
    wait for 0 ns;
    log(Manager1Id, "4 WaitForBarrier(TestDone)" & to_string(TestDone), ALWAYS);
    WaitForBarrier(TestDone);
    wait;
  end process;

  --   -- #################################################################################################################
  RT1Proc: process
    variable RT1ID : AlertLogIDType;
  begin
    RT1ID := NewID("RT1");
    InitRT(RT1_cpu_bus, RT1_DiscretesIn, MyRtAddr1, RT1ID, "01111", '1');
    loop
      Log(RT1ID, "RT1 Process Started", DEBUG);
      RT1_DiscretesIn.BitWord <= X"CCCC";
      RT1_DiscretesIn.ServiceReqVector <= X"DDDD";
      RT1_DiscretesIn.ServiceRequest <= '0';
      RT1_DiscretesIn.SubsystemFlag <= '0';
      Write(RT1_cpu_bus, reg_rt_addr, X"0001");
      Write(RT1_cpu_bus, reg_intr_mask, X"0003");
      ReadCheck(RT1_cpu_bus, reg_gID, X"FEEB");
      Write(RT1_cpu_bus, reg_node_control, X"4020");
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, RT1ID);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, RT1ID);
      wait until BC_Done = '1';
      if BC_Exit = '1' then
        exit;
      end if;
      --       RT_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, RT1_cpu_bus, RT1_DiscretesOut, SB_RT1_CMD, SB_RT1_DAT, SB_RT2_CMD, SB_RT2_DAT, SB_BC, SB_RT2RT, NextCmdRT1, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT1_Done, BC_Exit, RT2RT_Busy, BC_Check_Exit, RT1ID);
      --       -- then clear the register
      --     end loop;
    end loop;
    log(RT1ID, "8 WaitForBarrier(TestDone)" & to_string(TestDone), ALWAYS);
    WaitForBarrier(TestDone);
  end process;
  --   -- #################################################################################################################
  RT2Proc: process
    variable RT2ID       : AlertLogIDType;
    variable SubaddrRxed : std_logic_vector(31 downto 0);
  begin
    RT2ID := NewID("RT2");
    InitRT(RT2_cpu_bus, RT2_DiscretesIn, MyRtAddr2, RT2ID, "10000", '1');
    RT2_DiscretesIn.BitWord <= X"EEEE";
    RT2_DiscretesIn.ServiceReqVector <= X"FFFF";
    ReadCheck(RT2_cpu_bus, reg_gID, X"FEEB");
    Write(RT2_cpu_bus, reg_node_control, X"4020");
    ClearInterrupts(RT2_cpu_bus, 1, IrqMask, RT2ID);
    ClearInterrupts(RT2_cpu_bus, 2, IrqMask, RT2ID);
    --     wait until BC_Done = '1';
    --     while BC_Check_Done = '0' loop
    --       --   if BC_Exit = '1' then
    --       --     exit;
    --       --   end if;
    --       RT_MULTI_CHECK(MultiComdList, MyRtAddr2, MyRtAddr1, MyBcAddr, CmdWord, RT2_cpu_bus, RT2_DiscretesOut, SB_RT2_CMD, SB_RT2_DAT, SB_RT1_CMD, SB_RT1_DAT, SB_BC, SB_RT2RT, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT2_Done, BC_Exit, RT2RT_Busy, BC_Check_Exit, RT2ID);
    --     end loop;
    log(RT2ID, "12 WaitForBarrier(TestDone)" & to_string(TestDone), ALWAYS);
    WaitForBarrier(TestDone);
  end process;
end architecture;
-- #################################################################################################################
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_5_ReqModeCommands of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_1_5_ReqModeCommands);
    end for;
  end for;
end configuration;
