--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_2_StatusWordBits
-- Status Word Bits: 
-- The following tests verify that all implemented status code bits are properly
-- used and cleared. Implementation of all status code bits in the status word except the ME bit is
-- optional. In addition to the separate tests, for each of the following status bits: service request,
-- busy, subsystem flag, and terminal flag, provide the analysis as listed below.
-- a. What conditions set the status bit in the status word transmitted on the data bus.
-- b. What conditions reset the status bit in the status word transmitted on the data bus.
-- c. If the condition specified in item a. occurred and disappeared without intervening commands
-- to the UUT, list the cases where the status bit is set and reset in response to a valid, non-
-- mode command to the UUT.
-- d. Given that the status bit was set, and the condition which set the bit has gone away, list the
-- cases where the status bit is still set in response to the second valid, non-mode command to
-- the UUT.
-- The UUT has failed a test sequence if it does not respond as indicated in each of the separate
-- tests below.
-- #################################################################################################################
architecture AS4111A_5_2_2_2_StatusWordBits of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("AS4111A_5_2_2_2_StatusWordBits");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("-----------------", ALWAYS);
    Log("-----------------", ALWAYS);
    Log("AS4111A_5_2_2_2_StatusWordBits", ALWAYS);
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
    -- in your test process

    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_2_2_StatusWordBits.txt");
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
          wait until BC_BusMonitorRec.SyncPosEdge = '1';
          wait until BC_BusMonitorRec.SyncPosEdge = '1';
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
      getNumWords(MultiComdList);
      Log("Step " & to_string(TestStep) & ": checkClearStatus: NumWords = " & to_string(NumWords), DEBUG);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
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
      Log("checkClearStatus", DEBUG);
      getNumWords(MultiComdList);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Log(Manager1Id, "Did not get BC interrupt from CS condition", ALWAYS);
      else
        Log(Manager1Id, "Got BC interrupt, checking", ALWAYS);
        -- check the cause of the interrupt, it might be an NRP in which case the time is important
        Read(BC_cpu_bus, reg_busX_status or MilBusOffset, ReadData);
        if (ReadData(2) = '1') then
          -- NRP, so check the time
          Log(Manager1Id, "Step " & to_string(TestStep) & ": NRP received  ", ALWAYS);
        else
          -- check that the status word is clear
          MultiCmdWord := getCmdWord(MultiComdList.Command(1));
          Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
          AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
        end if;
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
        WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
        if (Timeout) then
          Log(Manager1Id, "Did not get BC interrupt from CS condition", ALWAYS);
        else
          Log(Manager1Id, "Got BC interrupt, checking", ALWAYS);
          ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitDataReceived, bitDataReceived, Manager1Id); -- check for NRP
          ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
          WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
          if (Timeout) then
            Log(Manager1Id, "Did not get BC interrupt from CS condition", ALWAYS);
          else
            Log(Manager1Id, "Got BC interrupt, checking", ALWAYS);
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
    procedure checkClearStatus_selected(signal MultiComdList : in MultiCommandRec_type; SelectedBit : in std_logic_vector(15 downto 0)) is
    begin
      getNumWords(MultiComdList);
      Log("Step " & to_string(TestStep) & ": checkClearStatus_selected: NumWords = " & to_string(NumWords), ALWAYS);
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
    Log(Manager1Id, "Starting BC side for Test AS4111A_5_2_2_2 Status Word Bits", ALWAYS);
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
    --  Service Request: 
    --  This test verifies that the UUT sets the service request bit as necessary and
    -- clears it when appropriate. The UUT shall set bit time eleven of the status word when a
    -- condition in the UUT warrants the RT to be serviced. A reset of the bit shall occur as defined
    -- by each RT. The following steps shall be performed and the appropriate responses verified.
    -- Step 1. A valid legal receive command with at least one data word shall be sent to the UUT.
    -- Step 2. A condition which causes the service request bit to be set shall be introduced into the UUT. 
    -- A valid legal command that does not service the request shall be sent to the UUT.
    -- Step 3. A valid legal command that does not service the request shall be sent to the UUT.
    -- Step 4. Procedures, as defined for the UUT, shall be performed which reset the servicerequest bit.
    -- Step 5. A valid legal receive command with at least one data word shall be sent to the UUT.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS, with the service request bit reset; 
    -- Step 2 - SRB; 
    -- Step 3 - SRB; 
    -- Step 5 - CS, with the service request bit reset.
    -- all commands and UUT responses shall be recorded.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1: STEP 1 - Service Request.        ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    TestStep <= 1;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 1;
    wait for 0 ns;
     Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending  Receive command while SRB inactive", ALWAYS);
   --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    checkClearStatus(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 2;
    wait for 0 ns;
     Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending another Receive command while SRB active", ALWAYS);
   -- set the service bit active in RT1
    RT1_DiscretesIn.ServiceRequest <= '1';
    wait for 0 ns;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    checkClearStatus_selected(MultiComdList, bitServiceReq); -- check for SRB
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 3;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending another Receive command while SRB active", ALWAYS);
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    checkClearStatus_selected(MultiComdList, bitServiceReq); -- check for SRB
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 4;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending another Receive command while SRB inactive", ALWAYS);
    -- clear the service bit active in RT1
    RT1_DiscretesIn.ServiceRequest <= '0';
    wait for 0 ns;
    TestStep <= 5;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    checkClearStatus(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    -- Broadcast Command Received: 
    -- This test verifies that the UUT sets the broadcast command received bit of the status word after receiving 
    -- a broadcast command. The UUT shall set status bit fifteen to a logic one after receiving the broadcast command. 
    -- The following test sequence shall be used:
    -- Step 1. A valid legal broadcast receive message shall be sent to the UUT.
    -- Step 2. A valid legal transmit last command shall be sent to the UUT. If this mode
    -- command is not implemented, then a transmit status mode command shall be
    -- used, and the data word associated with the transmit last command mode
    -- command shall be deleted from the pass criteria.
    -- Step 3. A valid, legal, non-broadcast command shall be sent to the UUT.
    -- Step 4. Repeat Step 1.
    -- Step 5. Repeat Step 3.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - NR; 
    -- Step 2 - BCR, and the data word contains the bit pattern of the command word in Step 1; 
    -- Step 3 - CS; 
    -- Step 4 - NR; 
    -- Step 5 - CS. 
    -- All commands and UUT responses shall be recorded.    
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "---------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_2: STEP 2 - Broadcast Command Received.", ALWAYS);
    Log(Manager1Id, "---------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    TestStep <= 1;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 1;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Receive command", ALWAYS);
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (31, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    getNumWords(MultiComdList);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for (tWord * (1 + NumWords)) + tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 2;
    PrevCmdWord := getCmdWord(MultiComdList.Command(0));
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
    WaitForLevel(RT1_DiscretesOut.OutEn1, '0');
    WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
    if (Timeout) then
      Alert(Manager1Id, "Did not get BC interrupt following Transmit Last Command", ERROR);
    else
      Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
      Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
      AffirmIf(Manager1Id, ReadData = PrevCmdWord,
               "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
    end if;
    ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
        WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    checkClearStatus(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 4;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Receive command", ALWAYS);
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (31, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    getNumWords(MultiComdList);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for (tWord * (1 + NumWords)) + tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 5;
    --                                 RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus(MultiComdList); -- check for SRB
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    -- Busy: 
    -- This test verifies the capability of the UUT to set the busy bit of the status word. Bit time
    -- sixteen of the status word shall be set when the UUT is busy.
    -- Step 1. A condition which sets the busy bit must be activated.
    -- Step 2. A valid legal transmit command shall be sent to the UUT.
    -- Step 3. Procedures, as defined for the UUT, shall be performed which reset the busy bit.
    -- Step 4. A valid legal transmit command shall be sent to the UUT.
    -- Step 5. A condition which sets the busy bit must be activated.
    -- Step 6. A valid receive command shall be sent to the UUT.
    -- Step 7. Procedures, as defined by the UUT, shall be performed which reset the busy bit.
    -- Step 8. A valid legal receive command shall be sent to the UUT.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 2 - BUSY; 
    -- Step 4 - CS (with the busy bit reset); 
    -- Step 6 - BUSY; 
    -- Step 8 - CS (with the busy bit reset).
    --  All commands and UUT responses shall be recorded.    
    --  ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "---------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_3: STEP 3 - Busy", ALWAYS);
    Log(Manager1Id, "---------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    TestStep <= 1;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 1;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Setting Busy bit", ALWAYS);
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    Write(RT1_cpu_bus, reg_node_control, ReadData or bitBusBusy); -- set the busy bit
    ----------------------------------------------------------------------------------------------------
    TestStep <= 2;
    --                                  RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0');
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
        WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    checkClearStatus_selected(MultiComdList, bitBusy); -- check for BUSY
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 3;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Clearing Busy bit", ALWAYS);
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    Write(RT1_cpu_bus, reg_node_control, ReadData and not bitBusBusy); -- clear the busy bit
    ----------------------------------------------------------------------------------------------------
    TestStep <= 4;
    --                                  RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0');
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus(MultiComdList);
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 5;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Setting Busy bit", ALWAYS);
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    Write(RT1_cpu_bus, reg_node_control, ReadData or bitBusBusy); -- set the busy bit
    ----------------------------------------------------------------------------------------------------
    TestStep <= 6;
    --                                 RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus_selected(MultiComdList, bitBusy); -- check for BUSY
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 7;
    wait for 0 ns;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Clearing Busy bit", ALWAYS);
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    Write(RT1_cpu_bus, reg_node_control, ReadData and not bitBusBusy); -- clear the busy bit
    ----------------------------------------------------------------------------------------------------
    TestStep <= 8;
    --                                 RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- BC 2RT receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus(MultiComdList); -- check for BUSY
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    -- Subsystem Flag: 
    -- This test verifies the capability of the UUT to set the subsystem flag of the
    -- status word. Bit time seventeen of the status word shall be set to a logic one when a
    -- subsystem fault has been determined. 
    -- Prior to performing the test sequence below, a condition which sets the subsystem flag bit must be activated.
    -- Step 1. A valid legal transmit command shall be sent to the UUT.
    -- Step 2. Remove the condition which sets the subsystem flag bit. Cycling power to the
    -- UUT shall not be part of these procedures to reset the SF bit.
    -- Step 3. A valid legal transmit command shall be sent to the UUT.
    -- Step 4. Repeat Step 3.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - SF; 
    -- Step 3 - CS; 
    -- Step 4 - CS.
    -- All commands and UUT responses shall be recorded.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_4: STEP 4 - Sub System Flag      ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    TestStep <= 1;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    -- set the subsystem flag active in RT1
    RT1_DiscretesIn.SubsystemFlag <= '1';
    wait for 0 ns;

    TestStep <= 1;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus_selected(MultiComdList, bitSubSysFlag);
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 2;
    -- clear the subsystem flag in RT1
    RT1_DiscretesIn.SubsystemFlag <= '0';
    ----------------------------------------------------------------------------------------------------
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
          WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
  checkClearStatus(MultiComdList);
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 4;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus(MultiComdList);
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    -- Terminal Flag: 
    -- This test verifies the capability of the UUT to set the terminal flag of the
    -- status word. Bit time seventeen of the status word shall be set to a logic one when a
    -- terminal fault has been determined. 
    -- Prior to performing the test sequence below, a condition which sets the terminal flag bit must be activated.
    -- Step 1. A valid legal transmit command shall be sent to the UUT.
    -- Step 2. Remove the condition which sets the terminal flag bit. Cycling power to the
    -- UUT shall not be part of these procedures to reset the SF bit.
    -- Step 3. A valid legal transmit command shall be sent to the UUT.
    -- Step 4. Repeat Step 3.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - SF; 
    -- Step 3 - CS; 
    -- Step 4 - CS.
    -- All commands and UUT responses shall be recorded.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_5: STEP 5 - Terminal Flag      ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    TestStep <= 1;
    wait for 0 ns;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Setting terminal flag bit", ALWAYS);
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    Write(RT1_cpu_bus, reg_node_control, ReadData or bitSetTerminalFlag); -- set the terminal flag
    wait for 0 ns;

    TestStep <= 1;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus_selected(MultiComdList, bitTerminalFlag);
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 2;
    Log(Manager1Id, "Step " & to_string(TestStep) & ": Clearing terminal flag bit", ALWAYS);
    -- clear the terminal flag in RT1
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    Write(RT1_cpu_bus, reg_node_control, ReadData and not bitSetTerminalFlag); -- clear the terminal flag
    ----------------------------------------------------------------------------------------------------
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit on bus 1
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
         WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
        WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
   checkClearStatus(MultiComdList);
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    TestStep <= 4;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit on bus 1 
    MultiComdList.Length <= 1;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    checkClearStatus(MultiComdList);
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    wait for tGap;
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
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_2_StatusWordBits of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_2_2_StatusWordBits);
    end for;
  end for;
end configuration;
