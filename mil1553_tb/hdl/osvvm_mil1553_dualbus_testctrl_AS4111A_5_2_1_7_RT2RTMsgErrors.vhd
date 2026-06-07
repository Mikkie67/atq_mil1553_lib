--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_7_RT2RTMsgErrors
-- RT to RT Message Errors: 
-- The purpose of this test is to examine the UUT's response to specific errors in the message stream
--  when operating as the receiving RT in an RT to RT transfer. For these tests, the bus tester shall 
--  act as the bus controller and the transmitting remote terminal as required.
-- #################################################################################################################
architecture AS4111A_5_2_1_7_RT2RTMsgErrors of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("AS4111A_5_2_1_7_RT2RTMsgErrors");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("------------------------------", ALWAYS);
    Log("------------------------------", ALWAYS);
    Log("AS4111A_5_2_1_7_RT2RTMsgErrors", ALWAYS);
    Log("------------------------------", ALWAYS);
    Log("------------------------------", ALWAYS);
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
    -- in your test process

    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_1_7_RT2RTMsgErrors.txt");
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
          wait until BC_BusMonitorRec.SyncPosEdge = '1';
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
    variable NumWords     : integer                       := 0;
    variable MilBusOffset : std_logic_vector(15 downto 0);
    variable ModeCode     : integer                       := 0;
    variable PrevCmdWord  : std_logic_vector(15 downto 0) := (others => '0');
    variable RepTimer     : integer                       := 200; -- default REP timer value
    -- #################################################################################################################
    procedure getNumWords(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("getNumWords", DEBUG);
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
    procedure checkClearStatusRT2RT(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkClearStatus", ALWAYS);
      getNumWords(MultiComdList);
      Log("1 WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');", ALWAYS);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Log(Manager1Id, "Did not get BC interrupt from CS condition", ALWAYS);
      else
        Log(Manager1Id, "Got BC interrupt for transmitter status word, checking", ALWAYS);
        -- check the cause of the interrupt, it might be an NRP in which case the time is important
        Read(BC_cpu_bus, reg_busX_status or MilBusOffset, ReadData);
        Log (Manager1Id, "ReadData = " & to_hstring(ReadData), ALWAYS);
        if (ReadData(1) = '1') then
          -- NRP, so check the time
          Log(Manager1Id, "Step " & to_string(TestStep) & ": NRP received  RepTimer = " & to_string((RepTimer + 200) * 10) & " ns", ALWAYS);
        else
          -- check that the status word is clear
          MultiCmdWord := getCmdWord(MultiComdList.Command(1));
          Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
          Log(Manager1Id, "MultiCmdWord = " & to_hstring(MultiCmdWord) & " ReadData = " & to_hstring(ReadData), ALWAYS);
          AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
        end if;
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
        Log("2 WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');", ALWAYS);
        WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
        if (Timeout) then
          Log(Manager1Id, "Did not get BC interrupt from CS condition", ALWAYS);
        else
          Log(Manager1Id, "Got BC interrupt for end of data on BC, checking", ALWAYS);
          ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitDataReceived, bitDataReceived, Manager1Id); -- check for NRP
          ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
          Log("3 WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');", ALWAYS);
          WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
          if (Timeout) then
            Log(Manager1Id, "Did not get BC interrupt from CS condition", ALWAYS);
          else
            Log(Manager1Id, "Got BC interrupt for receiving RT Status, checking", ALWAYS);
            ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitStatusRxedFlag, bitStatusRxedFlag, Manager1Id); -- check for NRP
            -- check that the status word is clear
            MultiCmdWord := getCmdWord(MultiComdList.Command(0));
            Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
            AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
            ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
          end if;
        end if;
      end if;
      ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure checkClearStatusTx(signal MultiComdList : in MultiCommandRec_type) is
    begin
      Log("checkClearStatusTx", DEBUG);
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
        WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep, Timeout, '1');
        if (Timeout) then
          Alert(Manager1Id, "Did not get BC interrupt from CS condition", ERROR);
        else
          Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
          ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitDataReceived, bitDataReceived, Manager1Id); -- check for NRP
        end if;
      end if;
      ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
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
          AffirmIf(Manager1Id, ReadData = PrevCmdWord, "Step " & to_string(TestStep) & ": reg_mode_data_rxedX = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit BIT", "ERROR: " & to_hstring(PrevCmdWord), TRUE);
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
          AffirmIf(Manager1Id, ReadData = PrevCmdWord, "Step " & to_string(TestStep) & ": reg_mode_data_rxedX = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit BIT", "ERROR: " & to_hstring(PrevCmdWord), TRUE);
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
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for Test AS4111A_5_2_1_7_RT2RT Message Errors", ALWAYS);
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
    --  RT to RT Timeout: 
    -- The purpose of this test is to verify that the UUT times out properly when
    -- operating as a receiving RT in an RT to RT transfer. Time T, as shown in Figure 8, is
    -- measured from the zero crossing of the parity bit of the receive command to the mid sync zero
    -- crossing of the first data word. The following test sequence shall be performed.
    --
    -- Step 1. Send a valid legal RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid
    -- status word with the RT address of the transmit command and the proper number
    -- of data words shall be sent to the UUT.
    --
    -- Step 2. Send a transmit status mode command to the UUT.
    --
    -- Repeat Step 1 and Step 2 incrementing the time in Step 1 between the transmit command and
    -- the status word in no greater than 0.5 µs increments until the time is equal to 30.0 µs.
    -- When the UUT (receiving RT) stops responding, the time T, as specified in Figure 8, shall be
    -- measured and recorded.
    --
    -- The pass criteria shall be: 
    -- Step 1 - CS for T ≤ 54.0 µs, CS or NR for 54.0 < T ≤ 60.0 µs, and NR to T > 60.0 µs; 
    -- Step 2 - CS if Step 1 is CS, ME if Step 1 is NR.    
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_1_7_1: STEP 1 - RT to RT Timeout  ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    -- Set RT2 response time to minimum of 4us
    RepTimer := 400 - 50 - 150; -- this is 4000ns - 500ns - 1500ns = 2000ns = 2us where the 500 is last bit second halve and 1500ns is the time of mid sync of next word
    Write(RT2_cpu_bus, reg_tmr_REP, std_logic_vector(to_unsigned(RepTimer, 16)));
    for i in 1 to 50 loop
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 2;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (15, 0, 1, 2, 1, '1'); -- RT2 to RT1 on bus 1 
      MultiComdList.Command(1) <= (16, 1, 1, 2, 1, '0');
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatusRT2RT(MultiComdList);
      wait for tGap;
      -- update the tRep of RT2 to RT1 command to increase the time delay in response by 500ns
      RepTimer := RepTimer + 50; -- increase by 500ns
      Log(Manager1Id, "Increasing RT2 REP timer to " & integer'image(RepTimer + 200) & " (x10ns) for next iteration", ALWAYS);
      Write(RT2_cpu_bus, reg_tmr_REP, std_logic_vector(to_unsigned(RepTimer, 16)));
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- RT to RT Message Format Errors: 
    -- The purpose of this test is to verify that the UUT will not malfunction and responds properly to errors
    -- in the message stream associated with the transmitting RT when the UUT is the receiving RT in a RT to RT transfer. 
    -- The following test sequence shall be used:

    -- Step 1. Send a valid legal RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid status word and N data words 
    -- to the UUT, where N is the number of data words indicated in the receive command.
    -- Step 2. Send the same RT to RT message as in Step 1 injecting one of the errors indicated below.
    -- Step 3. Send a transmit status mode command to the UUT.

    -- Record the UUT's response to each step when the test is performed with each of the following
    -- format errors (Step 2):
    -- a. Invalid transmit command word. Inject an invalid sync pattern in the transmit command
    -- word 
    -- THE NEXT PORTION CANNOT BE DONE WITH THE CURRENT COMMAND PROCESSOR BUT IT WILL MAKE NO DIFFERENCE TO THE RECEIVING RT
    -- followed in 4.0 µs to 12.0 µs with a receive command with the same address as the
    -- transmit command followed by N data words and no status response. This command
    -- combination will appear to the UUT as the same message format in Step 1 with an invalid
    -- transmitting RT's command word.
    -- b. Invalid transmitting RT's status word. Inject an invalid sync pattern in the transmitting RT's
    -- status word.
    -- c. Wrong sync type in the transmitting RT's status word. Send the same RT to RT command
    -- pair as in Step 1 followed in 4.0 µs to 12.0 µs by N+1 data words.
    --
    -- The pass criteria for each of the test formats shall be as follows: 
    -- Step 1 - CS; 
    -- Step 2 - NR,
    -- Step 3 - ME.  
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_1_7_2: STEP 2 - RT to RT Message Format Errors", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    -- RATIONALE FOR NOT PERFORMING TEST
    -- This test is not done at this level. All sync errors were done in the decoder testbench.
    -- When there is a sync error in the command or status word, the word/command will not be accepted
    -- and as such the standard NRP process is followed.
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    -- Transmitting RT Errors: 
    -- The purpose of this test is to verify proper occurrence of the transmitting RT's command and status words. 
    -- The purpose of this test is twofold: first to determine whether the UUT verifies the proper occurrence of 
    -- the transmitting RT's command and status word and, secondly, to verify that the UUT will not malfunction 
    -- and responds properly to errors in the message stream associated with the transmitting RT when the UUT is
    -- the receiving RT in an RT to RT transfer. Although recommended by Notice 2, the standard does not require 
    -- the receiving RT to verify the proper occurrence of the transmitting RT's command and status word. Therefore, 
    -- the first purpose of this test is for characterization of the UUT only. 

    -- The following test sequence shall be used:
    -- Step 1. Send a valid legal RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid
    -- status word and N data words to the UUT, where N is the number of data words indicated in the receive command.
    -- Step 2. Send the same RT to RT command pair as in Step 1 followed in 4.0 µs to 12.0 µs by a status word containing 
    -- a terminal address different from both the transmit command and the UUT, followed by N data words.
    -- Step 3. A transmit status mode command shall be sent to the UUT.

    -- The pass criteria shall be the following: 
    -- Step 1 - CS; 
    -- Step 2 - CS or NR, 
    -- Step 3 - CS if Step 2 is CS; ME if Step 2 is NR.    
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_1_7_3: STEP 3 - Transmitting RT Errors", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    -- RATIONALE FOR NOT PERFORMING TEST
    -- The RT does not implement this feature. The RT does not check the address in the status word.
    -- As such this test is not performed.
    ----------------------------------------------------------------------------------------------------
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
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_7_RT2RTMsgErrors of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_1_7_RT2RTMsgErrors);
    end for;
  end for;
end configuration;
