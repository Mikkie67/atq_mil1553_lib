--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_8_BusSwitching
-- Bus Switching: 
-- This test verifies that the dual redundant remote terminal properly performs the bus switching 
-- requirements of AS15531 or MIL-STD-1553B (paragraph 4.6.3.1 on Data Bus Activity).
-- Unless otherwise specified, legal messages are used in this test. The interrupting message on
-- the alternate bus shall be swept through the command word, the response time gap, the UUT’s
-- status word, and the UUT’s data transmission on the first bus. For all tests, record the command
-- words used. The following test sequences shall be performed for each interrupting command.
-- #################################################################################################################
architecture AS4111A_5_2_1_8_BusSwitching of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("AS4111A_5_2_1_8_BusSwitching");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("-----------------", ALWAYS);
    Log("-----------------", ALWAYS);
    Log("AS4111A_5_2_1_8_BusSwitching", ALWAYS);
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_1_8_BusSwitching.txt");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 sec);
    AlertIf(now >= 100 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports(ExternalErrors => (FAILURE => 0, ERROR => 0, WARNING => 0));
    std.env.stop;
    wait;
  end process;
  -- #################################################################################################################
  -- the monitor process needs to keep track of the current test step, since the different commands need to measure the time slightly differently
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
    variable Manager1Id      : AlertLogIDType;
    variable MultiCmdWord    : std_logic_vector(15 downto 0);
    variable Timeout         : boolean;
    variable ReadData        : std_logic_vector(15 downto 0);
    variable NumWords        : integer                       := 0;
    variable MilBusOffset    : std_logic_vector(15 downto 0);
    variable ModeCode        : integer                       := 0;
    variable PrevCmdWordBus1 : std_logic_vector(15 downto 0) := (others => '0');
    variable PrevCmdWordBus2 : std_logic_vector(15 downto 0) := (others => '0');
    -- #################################################################################################################
    procedure getNumWords(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("Step " & to_string(TestStep) & ": getNumWords", DEBUG);
      if (MultiComdList.Command(0).SubAddr = 0 or MultiComdList.Command(0).SubAddr = 31) then
        NumWords := 1;
      else
        if (MultiComdList.Command(0).Len = 0) then
          NumWords := 32;
        else
          NumWords := MultiComdList.Command(0).Len;
        end if;
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
      Log("checkClearStatus", DEBUG);
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
    procedure checkClearStatus_cmdwrd(TheCommand : std_logic_vector(15 downto 0); BusNum : integer) is
    begin
      Log("checkClearStatus_cmdwrd", DEBUG);
      if (BusNum = 1) then
        MilBusOffset := X"0010";
      else
        MilBusOffset := X"0020";
      end if;
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitStatusRxedFlag, bitStatusRxedFlag, Manager1Id); -- check for NRP
        -- check that the status word is clear
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        AffirmIf(Manager1Id, ReadData = (TheCommand and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(TheCommand) & " Bus " & to_string(BusNum) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, BusNum, IrqMask, Manager1Id);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatusTx_cmdwrd(TheCommand : std_logic_vector(15 downto 0); BusNum : integer) is
    begin
      Log("checkClearStatusTx_cmdwrd", ALWAYS);
      if (BusNum = 1) then
        MilBusOffset := X"0010";
      else
        MilBusOffset := X"0020";
      end if;
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", ALWAYS);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitDataReceived, bitDataReceived, Manager1Id); -- check for NRP
      end if;
      ClearInterrupts(BC_cpu_bus, BusNum, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatusME(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkClearStatusME", DEBUG);
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
    procedure checkClearStatusME_DAT(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkClearStatusME_DAT", DEBUG);
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
        WaitForLevel(BC1_DiscretesOut.Intr, tWord + tREP, Timeout, '1');
        if (Timeout) then
          Alert(Manager1Id, "Did not get BC interrupt from Data word condition", ERROR);
        else
          Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
          Read(BC_cpu_bus, reg_mode_data_rxedX or MilBusOffset, ReadData);
          AffirmIf(Manager1Id, ReadData = PrevCmdWordBus1, "Step " & to_string(TestStep) & ": reg_mode_data_rxedX = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit BIT", "ERROR: " & to_hstring(PrevCmdWordBus1), TRUE);
        end if;
      end if;
      ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatusMode(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkClearStatusMode", DEBUG);
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
        AffirmIf(Manager1Id, ReadData = ((MultiCmdWord and X"F800")), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
        WaitForLevel(BC1_DiscretesOut.Intr, tWord + tREP, Timeout, '1');
        if (Timeout) then
          Alert(Manager1Id, "Did not get BC interrupt from Data word condition", ERROR);
        else
          Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
          Read(BC_cpu_bus, reg_mode_data_rxedX or MilBusOffset, ReadData);
          AffirmIf(Manager1Id, ReadData = PrevCmdWordBus1, "Step " & to_string(TestStep) & ": reg_mode_data_rxedX = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit BIT", "ERROR: " & to_hstring(PrevCmdWordBus1), TRUE);
        end if;
      end if;
      ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatusTF(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkClearStatusTF", DEBUG);
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
        AffirmIf(Manager1Id, ReadData = ((MultiCmdWord and X"F800") or bitTerminalFlag), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR + TF", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkNRP(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkNRP", DEBUG);
      getNumWords(MultiComdList);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tNRP, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
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
    procedure checkNRP_bus(BusNum : in integer) is
    begin
      Log("checkNRP_bus", DEBUG);
      if (BusNum = 1) then
        MilBusOffset := X"0010";
      else
        MilBusOffset := X"0020";
      end if;
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tNRP, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt from NRP condition", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking NRP bit", DEBUG);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitNRP, bitNRP, Manager1Id); -- check for NRP
        ClearInterrupts(BC_cpu_bus, BusNum, IrqMask, Manager1Id);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkRT1_InitiateBit(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkRT1_InitiateBit", DEBUG);
      Read(RT1_cpu_bus, reg_status, ReadData);
      if (ReadData(0) = '1') then
        Log(RT1ID, "Step " & to_string(TestStep) & ": IRQ generated on bus 1 after BIT command", ALWAYS);
        MilBusOffset := X"0010";
      elsif (ReadData(0) = '1') then
        MilBusOffset := X"0020";
        Log(RT1ID, "Step " & to_string(TestStep) & ": IRQ generated on bus 2 after BIT command", ALWAYS);
      else
        Alert(RT1ID, "Step " & to_string(TestStep) & ": ERROR: IRQ not generated on either bus after BIT command", ERROR);
      end if;
      Read(RT1_cpu_bus, reg_busX_status or MilBusOffset, ReadData);
      AffirmIf(RT1ID,(ReadData and bitModeCmd) = bitModeCmd, "Step " & to_string(TestStep) & ": reg_bus1_status = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD", "ERROR: " & to_hstring(ReadData), TRUE);
      Read(RT1_cpu_bus, reg_rx_mode_cmdX or MilBusOffset, ReadData);
      AffirmIf(RT1ID,(ReadData and bitInitiateBIT) = bitInitiateBIT, "Step " & to_string(TestStep) & ": reg_rx_mode_cmd1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Initiate BIT", "ERROR: " & to_hstring(ReadData), TRUE);
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkRT1_TransmitBit(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkRT1_TransmitBit", ALWAYS);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord + tRep, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt following BIT word", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
      end if;
      Read(RT1_cpu_bus, reg_status, ReadData);
      if (ReadData(0) = '1') then
        Log(RT1ID, "Step " & to_string(TestStep) & ": IRQ generated on bus 1 after Transmit BIT command", ALWAYS);
        MilBusOffset := X"0010";
      elsif (ReadData(0) = '1') then
        MilBusOffset := X"0020";
        Log(RT1ID, "Step " & to_string(TestStep) & ": IRQ generated on bus 2 after Transmit BIT command", ALWAYS);
      else
        Alert(RT1ID, "Step " & to_string(TestStep) & ": ERROR: IRQ not generated on either bus after Transmit BIT command", ERROR);
      end if;
      Read(RT1_cpu_bus, reg_busX_status or MilBusOffset, ReadData);
      AffirmIf(RT1ID,(ReadData and bitModeCmd) = bitModeCmd, "Step " & to_string(TestStep) & ": reg_bus1_status = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD", "ERROR: " & to_hstring(ReadData), TRUE);
      Read(BC_cpu_bus, reg_mode_data_rxedX or MilBusOffset, ReadData);
      AffirmIf(Manager1Id, ReadData = RT1_DiscretesIn.BitWord, "Step " & to_string(TestStep) & ": reg_mode_data_rxedX = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit BIT", "ERROR: " & to_hstring(RT1_DiscretesIn.BitWord), TRUE);
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkRT1_TransmitVectorWord(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkRT1_TransmitVectorWord", DEBUG);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord + tRep, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt following Vector word", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
      end if;
      Read(RT1_cpu_bus, reg_status, ReadData);
      if (ReadData(0) = '1') then
        Log(RT1ID, "Step " & to_string(TestStep) & ": IRQ generated on bus 1 after Transmit Vector command", ALWAYS);
        MilBusOffset := X"0010";
      elsif (ReadData(0) = '1') then
        MilBusOffset := X"0020";
        Log(RT1ID, "Step " & to_string(TestStep) & ": IRQ generated on bus 2 after Transmit Vector command", ALWAYS);
      else
        Alert(RT1ID, "Step " & to_string(TestStep) & ": ERROR: IRQ not generated on either bus after Transmit BVectorIT command", ERROR);
      end if;
      Read(RT1_cpu_bus, reg_busX_status or MilBusOffset, ReadData);
      AffirmIf(RT1ID,(ReadData and bitModeCmd) = bitModeCmd, "Step " & to_string(TestStep) & ": reg_bus1_status = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD", "ERROR: " & to_hstring(ReadData), TRUE);
      Read(BC_cpu_bus, reg_mode_data_rxedX or MilBusOffset, ReadData);
      AffirmIf(Manager1Id, ReadData = RT1_DiscretesIn.ServiceReqVector, "Step " & to_string(TestStep) & ": reg_mode_data_rxedX = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit Vector word", "ERROR: " & to_hstring(RT1_DiscretesIn.ServiceReqVector), TRUE);
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkNoAction(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("Step " & to_string(TestStep) & ": checkNoAction", DEBUG);
      getNumWords(MultiComdList);
      ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, X"0000", X"0000", Manager1Id); -- check for NRP
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatus_selected(signal MultiComdList : in MultiCommandRec_type; SelectedBit : in std_logic_vector(15 downto 0)) is
    begin
      getNumWords(MultiComdList);
      Log("Step " & to_string(TestStep) & ": checkClearStatus_selected: NumWords = " & to_string(NumWords) & " Bus = " & to_string(MultiComdList.Command(0).MilBus), ALWAYS);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", ALWAYS);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitStatusRxedFlag, bitStatusRxedFlag, Manager1Id); -- check for NRP
        -- check that the status word is clear
        MultiCmdWord := getCmdWord(MultiComdList.Command(0));
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        AffirmIf(Manager1Id, ReadData = ((MultiCmdWord and X"F800") or SelectedBit), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR + FLAG", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatus_selected_bit_and_bus(TheCommand : std_logic_vector(15 downto 0); SelectedBit : in std_logic_vector(15 downto 0); BusNum : integer) is
    begin
      Log("Step " & to_string(TestStep) & ": checkClearStatus_selected_bit_and_bus: TheCommand = " & to_string(TheCommand) & " Bits = " & to_string(SelectedBit) & " Bus = " & to_string(BusNum), ALWAYS);
      WaitForLevel(BC1_DiscretesOut.Intr, '1');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", ALWAYS);
      if (BusNum = 1) then
        MilBusOffset := X"0010";
      else
        MilBusOffset := X"0020";
      end if;
      ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, SelectedBit, SelectedBit, Manager1Id); -- check for NRP
      -- check that the status word is clear
      Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
      AffirmIf(Manager1Id, ReadData = ((TheCommand and X"F800")), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(TheCommand) & " Bus " & to_string(BusNum) & ": STATUS CLEAR + FLAG", "ERROR: " & to_hstring(ReadData), TRUE);
      ClearInterrupts(BC_cpu_bus, BusNum, IrqMask, Manager1Id);
    end procedure;
    variable offset : integer := 0;
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for Test AS4111A_5_2_1_8 BusSwitching", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Write(BC_cpu_bus, X"0038", X"0001"); -- Write the softwere RtAddr Register
    ReadCheck(BC_cpu_bus, X"0036", X"FEEB"); -- Read the ID Regsister
    Write(BC_cpu_bus, X"0034", X"4000"); -- Set general RT control register
    BC_done <= '0';
    BC_Check_Done <= '0';
    MultiComdList.RepeatRate <= 0;
    InitRT(RT1_cpu_bus, RT1_DiscretesIn, MyRtAddr1, RT1ID, "01111", '1');
    InitRT(RT2_cpu_bus, RT2_DiscretesIn, MyRtAddr2, RT2ID, "10000", '0');
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
    -- Bus Switching: RT Transmitting:
    -- Step 1. Send a valid transmit command to the UUT on the bus under test requesting the
    -- maximum number of data words that the UUT is designed to transmit.
    -- Step 2. Send the interrupting command to the UUT on a bus other than that used in Step 1 beginning 4.0 µs after the beginning of the first command.
    -- Step 3. After the messages on both buses have been completed, send a valid legal
    -- transmit status mode command to the UUT on the same bus used in Step 2.
    -- Step 4. Send a valid legal transmit status mode command to the UUT on the same bus used in Step 1.

    -- Repeat Step 1 through Step 4 increasing the gap time between Step 1 and Step 2 in increments
    -- no greater than 250.0 ns until the messages no longer overlap.

    -- Perform the test with the following interrupting messages for Step 2.
    -- a. A valid legal message
    -- b. A message with a parity error in the command word.
    -- c. A valid message with a terminal address different than that of the UUT.
    -- The pass criteria shall be: 
    -- for a, 
    -- Step 1 - NR, truncated message or CS; 
    -- Step 2 - CS; 
    -- Step 3 - CS; 
    -- Step 4 - CS 
    -- and for b and c, 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - CS; 
    -- Step 4 - CS. 
    -- For test failures, record the test parameters at which the failure occurred.

    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_1_8: Bus Switching: RT Transmitting: (a)    ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for ends in 1 to 2 loop
      if (ends = 1) then
        offset := 0;
      else
        offset := 2500;
      end if;
      wait for 0 ns;
      for delaytime in 0 to 100 loop
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        MultiComdList.RepeatRate <= 0;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        -- clear interrupts before starting
        ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 2, IrqMask, Manager1Id);
        ----------------------------------------------------------------------------------------------------
        -- Step 1. Send a valid transmit command to the UUT on the bus under test requesting the
        -- maximum number of data words that the UUT is designed to transmit.
        TestStep <= 1;
        wait for 0 ns;
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending transmit command on bus 1: Delay = " & to_string(2.86 us + (250 ns * (delaytime + offset))) & " Cnt = " & to_string(delaytime + offset), ALWAYS);
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 0, 1, '0'); -- transmit on bus 1
        wait for 0 ns;
        PrevCmdWordBus1 := getCmdWord(MultiComdList.Command(0));
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 2.86 us + (250 ns * (delaytime + offset)); -- equivalent to 4 us between output enables
        ----------------------------------------------------------------------------------------------------
        -- Step 2. Send the interrupting command to the UUT on a bus other than that used in Step 1 beginning 4.0 µs after the beginning of the first command.
        TestStep <= 2;
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 2, '0'); -- receive on bus 2
        MultiComdList.StartAddr <= 2; -- start the bus 2 command in differnet spot of TXRAM so that bus 1 command is not overwritten
        MultiComdList.Length <= 1;
        wait for 0 ns;
        PrevCmdWordBus2 := getCmdWord(MultiComdList.Command(0));
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        if ((delaytime < 79) and (ends = 1)) then
          log(Manager1Id, "  if ((delaytime < 79) and (ends = 1)) then", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1'); --Wait for BC to start transmission on bus 2
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn1, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "a: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitforLevel(RT1_DiscretesOut.OutEn2, '1');
          ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
          WaitforLevel(RT1_DiscretesOut.OutEn2, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        elsif ((delaytime < 101) and (ends = 1)) then
          log(Manager1Id, "Step " & to_string(TestStep) & "y:IN THE elsif ((delaytime < 101) and (ends = 1))", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn1, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "c: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
          ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
          WaitForLevel(RT1_DiscretesOut.OutEn2, '1');
          WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        elsif ((delaytime < 79) and (ends = 2)) then
          log(Manager1Id, "Step " & to_string(TestStep) & "y:IN THE elsif ((delaytime < 79) and (ends = 2))", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn1, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "c: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitforLevel(RT1_DiscretesOut.OutEn2, '1');
          ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
          WaitforLevel(RT1_DiscretesOut.OutEn2, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        else
          log(Manager1Id, "Step " & to_string(TestStep) & "y:IN THE ELSE", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn1, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "c: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitforLevel(RT1_DiscretesOut.OutEn2, '1');
          ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
          WaitforLevel(RT1_DiscretesOut.OutEn2, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
        end if;
        ----------------------------------------------------------------------------------------------------
        -- Step 3. After the messages on both buses have been completed, send a valid legal
        -- transmit status mode command to the UUT on the same bus used in Step 2.
        TestStep <= 3;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 2, '0'); -- MODE: transmit last command on bus 2
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '1');
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '0');
        checkClearStatus(MultiComdList);
        wait for tGap;
        ----------------------------------------------------------------------------------------------------
        -- Step 4. Send a valid legal transmit status mode command to the UUT on the same bus used in Step 1.
        TestStep <= 4;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        -- the next command clears any pending BC irq due to the first status word of the RT transmission
        WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
        WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
        -- A special case if the first one, because there has not been a valid message received yet, so RxStateword = 0000
        --if (delaytime = 0) then
          Log("Step 4: first time so no value in rx status word delaytime = " & to_string(delaytime), ALWAYS);
          MultiComdList.Command(0) <= (0, 0, 0, 0, 1, '0'); -- MODE: transmit last command on bus 1
         checkClearStatus(MultiComdList);
        --else
        --checkClearStatus(MultiComdList);
        --end if;
        wait for tGap;
      end loop;
    end loop;
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_1_8: Bus Switching: RT Transmitting: (b)    ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 1, 2, '0');
    MultiComdList.StartAddr <= 2; -- start the bus 2 command in differnet spot of TXRAM so that bus 1 command is not overwritten
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    wait for 0 ns;
    PrevCmdWordBus2 := getCmdWord(MultiComdList.Command(0));
    log(Manager1Id, "Step " & to_string(TestStep) & ": MultiComdList.Command(0) = " & to_hstring(PrevCmdWordBus2), ALWAYS);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
    WaitForLevel(RT1_DiscretesOut.OutEn2, '1');
    WaitForLevel(RT1_DiscretesOut.OutEn2, '0');
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 1, 1, '0'); -- MODE: transmit last command on bus 1
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    wait for 0 ns;
    PrevCmdWordBus2 := getCmdWord(MultiComdList.Command(0));
    log(Manager1Id, "Step " & to_string(TestStep) & ": MultiComdList.Command(0) = " & to_hstring(PrevCmdWordBus2), ALWAYS);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT1_DiscretesOut.OutEn1, '1');
    WaitForLevel(RT1_DiscretesOut.OutEn1, '0');

    for ends in 1 to 2 loop -- repeat the test for both busses
      if (ends = 1) then
        offset := 0;
      else
        offset := 2550;
      end if;
      wait for 0 ns;
      for delaytime in 0 to 100 loop

        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        MultiComdList.RepeatRate <= 0;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        -- clear interrupts before starting
        ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 2, IrqMask, Manager1Id);
        ----------------------------------------------------------------------------------------------------
        -- Step 1. Send a valid transmit command to the UUT on the bus under test requesting the
        -- maximum number of data words that the UUT is designed to transmit.
        TestStep <= 1;
        wait for 0 ns;
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending transmit command on bus 1: Delay = " & to_string(2.86 us + (250 ns * (delaytime + offset))) & " Cnt = " & to_string(delaytime + offset), ALWAYS);
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 0, 1, '0'); -- Transmit on bus 1
        wait for 0 ns;
        PrevCmdWordBus1 := getCmdWord(MultiComdList.Command(0));
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        WaitForLevel(BC1_DiscretesOut.OutEn1, '1'); --Wait for BC to start transmission on bus 1
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
        wait for 2.86 us + (250 ns * (delaytime + offset)); -- equivalent to 4 us between output enables
        ----------------------------------------------------------------------------------------------------
        -- Step 2. Send the interrupting command to the UUT on a bus other than that used in Step 1 beginning 4.0 µs after the beginning of the first command.
        TestStep <= 2;
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 2, '0'); -- receive on bus 2
        MultiComdList.StartAddr <= 2; -- start the bus 2 command in different spot of TXRAM so that bus 1 command is not overwritten
        MultiComdList.Length <= 1;
        MultiComdList.ErrInj <= errParity; -- parity error in command word
        MultiComdList.ErrWrd <= 0;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        ----------------------------------------------------------------------------------------------------
        if ((delaytime < 101) and (ends = 1)) then
          log(Manager1Id, "Step " & to_string(TestStep) & ": IN THE elsif ((delaytime < 101) and (ends = 1))", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1'); --Wait for BC to start transmission on bus 2
          wait for 21 us;
          checkClearStatus_cmdwrd(PrevCmdWordBus1, 1);
          WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
          WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
          checkClearStatusTx_cmdwrd(PrevCmdWordBus1, 1);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
          checkNRP_bus(2);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        elsif ((delaytime < 101) and (ends = 2)) then
          log(Manager1Id, "Step " & to_string(TestStep) & ": IN THE elsif ((delaytime < 101) and (ends = 2) ) then", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1'); --Wait for BC to start transmission on bus 2
          wait for 21 us;
          --WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
          if (RT1_DiscretesOut.OutEn1 = '0') then
            checkClearStatus_cmdwrd(PrevCmdWordBus1, 1);
          else
            checkClearStatus_cmdwrd(PrevCmdWordBus1, 1);
            WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
            checkClearStatusTx_cmdwrd(PrevCmdWordBus1, 1);
          end if;
          WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
          checkNRP_bus(2);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        end if;
        wait for tGap;
        ----------------------------------------------------------------------------------------------------
        -- Step 3. After the messages on both buses have been completed, send a valid legal
        -- transmit status mode command to the UUT on the same bus used in Step 2.
        TestStep <= 3;
        --                                  RA TnR SA Len                Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 2, '0'); -- MODE: transmit last command on bus 2
        MultiComdList.StartAddr <= 2; -- start the bus 2 command in differnet spot of TXRAM so that bus 1 command is not overwritten
        MultiComdList.Length <= 1;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        wait for 0 ns;
        PrevCmdWordBus2 := getCmdWord(MultiComdList.Command(0));
        log(Manager1Id, "Step " & to_string(TestStep) & ": MultiComdList.Command(0) = " & to_hstring(PrevCmdWordBus2), ALWAYS);
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '1');
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '0');
        checkClearStatus_cmdwrd(PrevCmdWordBus2, 2);
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        wait for tGap;
        ----------------------------------------------------------------------------------------------------
        -- Step 4. Send a valid legal transmit status mode command to the UUT on the same bus used in Step 1.
        TestStep <= 4;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        wait for 0 ns;
        PrevCmdWordBus2 := getCmdWord(MultiComdList.Command(0));
        log(Manager1Id, "Step " & to_string(TestStep) & ": MultiComdList.Command(0) = " & to_hstring(PrevCmdWordBus2), ALWAYS);
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        -- the next command clears any pending BC irq due to the first status word of the RT transmission
        WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
        WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
        checkClearStatus(MultiComdList);
        wait for tGap;
      end loop;
    end loop;

    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_1_8: Bus Switching: RT Transmitting: (c)    ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    for ends in 1 to 2 loop
      if (ends = 1) then
        offset := 0;
      else
        offset := 2500;
      end if;
      for delaytime in 0 to 100 loop
        wait for 0 ns;
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        MultiComdList.RepeatRate <= 0;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        -- clear interrupts before starting
        ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 2, IrqMask, Manager1Id);
        ----------------------------------------------------------------------------------------------------
        -- Step 1. Send a valid transmit command to the UUT on the bus under test requesting the
        -- maximum number of data words that the UUT is designed to transmit.
        TestStep <= 1;
        wait for 0 ns;
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending transmit command on bus 1: Delay = " & to_string(2.86 us + (250 ns * (delaytime + offset))) & " Cnt = " & to_string(delaytime + offset), ALWAYS);
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 0, 1, '0'); -- receive on bus 1
        wait for 0 ns;
        PrevCmdWordBus1 := getCmdWord(MultiComdList.Command(0));
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
        ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
        wait for 2.86 us + (250 ns * (delaytime + offset));
        -- clear the RT1 IRQ caused by the command word 
        ----------------------------------------------------------------------------------------------------
        -- Step 2. Send the interrupting command to the UUT on a bus other than that used in Step 1 beginning 4.0 µs after the beginning of the first command.
        TestStep <= 2;
        --                           RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (14, 0, 1, 0, 2, '0'); -- receive on bus 2 but wrong RT address
        MultiComdList.ErrInj <= errNone; -- no error injection
        MultiComdList.ErrWrd <= 0;
        wait for 0 ns;
        PrevCmdWordBus2 := getCmdWord(MultiComdList.Command(0));
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        if (delaytime < 101) and (ends = 1) then
          log(Manager1Id, "Step " & to_string(TestStep) & ": IN THE if (delaytime < 101) and (ends = 1) then", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
          checkClearStatus_cmdwrd(PrevCmdWordBus1, 1);

          WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
          -- Step 2 result checking
          WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
          WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
          checkClearStatus_selected_bit_and_bus(PrevCmdWordBus1, bitDataReceived, 1);
          waitforLEvel(BC1_DiscretesOut.OutEn2, '0');
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        elsif (delaytime < 101) and (ends = 2) then
          log(Manager1Id, "Step " & to_string(TestStep) & ": IN THE elsif (delaytime < 101) and (ends = 2)", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
          checkClearStatus_cmdwrd(PrevCmdWordBus1, 1);
          -- Step 2 result checking
          WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
          WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
          checkClearStatus_selected_bit_and_bus(PrevCmdWordBus1, bitDataReceived, 1);
          waitforLEvel(BC1_DiscretesOut.OutEn2, '0');
          wait for tGap;
          --   -- here is the check for step 1 begin truncated (BC is busy sending data so OutEn1 is high, after the truncation 
          --   -- with known good command, the outen1 should be cleared as the message is truncated)
          --   WaitForLevel(RT1_DiscretesOut.OutEn1, tREP + 100 ns, Timeout, '1'); -- wait for RT1 to start transmitting
          --   AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & ": RT1 started transmitting on bus 1 ", "ERROR: Timeout waiting for RT to start transmitting on bus 1", TRUE);
          --   WaitForLevel(BC1_DiscretesOut.Intr, tWord + 500 ns, Timeout, '1');
          --   AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & ": BC received RT status word on bus 1 ", "ERROR: Timeout waiting for BC to receive RT status word on bus 1", TRUE);
          --   ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
          --   WaitForLevel(RT1_DiscretesOut.OutEn1, 20 us, Timeout, '1'); -- wait for RT1 to NOT truncate trnamission on bus 1
          --   AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & ": RT1 did not truncate message on bus 1 ", "ERROR: Timeout waiting for RT1 to not truncate message on bus 1", TRUE);
          --   -- Step 2 result checking
          --   WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
          --   WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
          --   checkClearStatusTx_cmdwrd(PrevCmdWordBus1, 1);
          --   wait for tGap;
        end if;
        ----------------------------------------------------------------------------------------------------
        -- Step 3. After the messages on both buses have been completed, send a valid legal
        -- transmit status mode command to the UUT on the same bus used in Step 2.
        TestStep <= 3;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 2, '0'); -- MODE: transmit last command on bus 2
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '1');
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '0');
        checkClearStatus(MultiComdList);
        wait for tGap;
        ----------------------------------------------------------------------------------------------------
        -- Step 4. Send a valid legal transmit status mode command to the UUT on the same bus used in Step 1.
        TestStep <= 4;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        -- the next command clears any pending BC irq due to the first status word of the RT transmission
        WaitforLEvel(RT1_DiscretesOut.OutEn1, '1');
        WaitforLEvel(RT1_DiscretesOut.OutEn1, '0');
        checkClearStatus(MultiComdList);
        wait for tGap;
      end loop;
    end loop;
    --------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_1_8: Bus Switching: RT Transmitting: (a)  BUS2  ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for ends in 1 to 2 loop
      if (ends = 1) then
        offset := 0;
      else
        offset := 2500;
      end if;
      wait for 0 ns;
      for delaytime in 0 to 100 loop
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        MultiComdList.RepeatRate <= 0;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        -- clear interrupts before starting
        ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT1_cpu_bus, 2, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 1, IrqMask, Manager1Id);
        ClearInterrupts(RT2_cpu_bus, 2, IrqMask, Manager1Id);
        ----------------------------------------------------------------------------------------------------
        -- Step 1. Send a valid transmit command to the UUT on the bus under test requesting the
        -- maximum number of data words that the UUT is designed to transmit.
        TestStep <= 1;
        wait for 0 ns;
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending transmit command on bus 1: Delay = " & to_string(2.86 us + (250 ns * (delaytime + offset))) & " Cnt = " & to_string(delaytime + offset), ALWAYS);
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 0, 2, '0'); -- transmit on bus 1
        wait for 0 ns;
        PrevCmdWordBus1 := getCmdWord(MultiComdList.Command(0));
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 2.86 us + (250 ns * (delaytime + offset)); -- equivalent to 4 us between output enables
        ----------------------------------------------------------------------------------------------------
        -- Step 2. Send the interrupting command to the UUT on a bus other than that used in Step 1 beginning 4.0 µs after the beginning of the first command.
        TestStep <= 2;
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 1, '0'); -- receive on bus 2
        MultiComdList.StartAddr <= 2; -- start the bus 2 command in differnet spot of TXRAM so that bus 1 command is not overwritten
        MultiComdList.Length <= 1;
        wait for 0 ns;
        PrevCmdWordBus2 := getCmdWord(MultiComdList.Command(0));
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        if ((delaytime < 79) and (ends = 1)) then
          log(Manager1Id, "  if ((delaytime < 79) and (ends = 1)) then", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn1, '1'); --Wait for BC to start transmission on bus 2
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn2, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "a: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitforLevel(RT1_DiscretesOut.OutEn1, '1');
          ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
          WaitforLevel(RT1_DiscretesOut.OutEn1, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        elsif ((delaytime < 101) and (ends = 1)) then
          log(Manager1Id, "Step " & to_string(TestStep) & "y:IN THE elsif ((delaytime < 101) and (ends = 1))", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn2, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "c: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
          ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
          WaitForLevel(RT1_DiscretesOut.OutEn1, '1');
          WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        elsif ((delaytime < 79) and (ends = 2)) then
          log(Manager1Id, "Step " & to_string(TestStep) & "y:IN THE elsif ((delaytime < 79) and (ends = 2))", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn2, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "c: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitforLevel(RT1_DiscretesOut.OutEn1, '1');
          ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
          WaitforLevel(RT1_DiscretesOut.OutEn1, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
          ----------------------------------------------------------------------------------------------------
        else
          log(Manager1Id, "Step " & to_string(TestStep) & "y:IN THE ELSE", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
          wait for 21 us; -- wait for the bus 2 transmission to be well underway
          WaitForLevel(RT1_DiscretesOut.OutEn2, tWord + 100 ns, Timeout, '0'); -- wait for RT1 to truncate trnamission on bus 1 after good Command word received on bus 2
          AffirmIf(Manager1Id, not Timeout, "Step " & to_string(TestStep) & "c: RT1 truncated message on bus 1 ", "ERROR: Timeout waiting for RT1 to truncate message on bus 1", TRUE);
          WaitforLevel(RT1_DiscretesOut.OutEn1, '1');
          ClearInterrupts(BC_cpu_bus, 2, IrqMask, Manager1Id);
          WaitforLevel(RT1_DiscretesOut.OutEn1, '0');
          checkClearStatus(MultiComdList);
          wait for tGap;
        end if;
        ----------------------------------------------------------------------------------------------------
        -- Step 3. After the messages on both buses have been completed, send a valid legal
        -- transmit status mode command to the UUT on the same bus used in Step 2.
        TestStep <= 3;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 2
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        WaitforLevel(RT1_DiscretesOut.OutEn1, '1');
        WaitforLevel(RT1_DiscretesOut.OutEn1, '0');
        checkClearStatus(MultiComdList);
        wait for tGap;
        ----------------------------------------------------------------------------------------------------
        -- Step 4. Send a valid legal transmit status mode command to the UUT on the same bus used in Step 1.
        TestStep <= 4;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 2, '0'); -- MODE: transmit last command on bus 1
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        -- the next command clears any pending BC irq due to the first status word of the RT transmission
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '1');
        WaitforLEvel(RT1_DiscretesOut.OutEn2, '0');
        MultiComdList.Command(0) <= (0, 0, 0, 0, 2, '0'); -- MODE: transmit last command on bus 1
        checkClearStatus(MultiComdList);
        wait for tGap;
      end loop;
    end loop;
    -- #################################################################################################################
    BC_Exit <= '0';
    wait for 0 ns;
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
  -- #################################################################################################################
end architecture;
-- #################################################################################################################
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_8_BusSwitching of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_1_8_BusSwitching);
    end for;
  end for;
end configuration;
