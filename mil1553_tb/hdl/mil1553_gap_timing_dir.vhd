--
-- VHDL Architecture mil1553_tb.mil1553_gap_timing_dir

-- #################################################################################################################
architecture mil1553_gap_timing_dir of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("mil1553_gap_timing_dir");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("------------------------------", ALWAYS);
    Log("------------------------------", ALWAYS);
    Log("mil1553_gap_timing_dir", ALWAYS);
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
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_gap_timing_dir.txt");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until BC1_DiscretesIn.nReset = '1';
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
        --Alert(MonId, "5 Monitor process in unknown test step: " & to_string(TestStep));
      end case;
    end loop;
  end process;
  -- #################################################################################################################
  BcProc: process
    variable Manager1Id   : AlertLogIDType;
    variable MultiCmdWord : std_logic_vector(15 downto 0);
    variable Timeout      : boolean;
    variable ReadData     : std_logic_vector(15 downto 0);
    variable GapTimerReg  : std_logic_vector(15 downto 0) := (others => '0');
    variable ClocksPerUs  : natural := 0;
    variable GapClocks    : natural := 0;
    variable tGapCfg      : time := tGAP;
    variable NumWords     : integer                       := 0;
    variable MilBusOffset : std_logic_vector(15 downto 0);
    variable ModeCode     : integer                       := 0;
    variable PrevCmdWord  : std_logic_vector(15 downto 0) := (others => '0');
    variable Step1Command : Command_type;
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
    procedure checkClearStatusCmd(StartCommand : Command_type) is
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
        MultiCmdWord := getCmdWord(StartCommand);
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
      Log("1 WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');", DEBUG);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Log(Manager1Id, "Did not get BC interrupt from CS condition", DEBUG);
      else
        Log(Manager1Id, "Got BC interrupt for transmitter status word, checking", DEBUG);
        -- check the cause of the interrupt, it might be an NRP in which case the time is important
        Read(BC_cpu_bus, reg_busX_status or MilBusOffset, ReadData);
        Log(Manager1Id, "ReadData = " & to_hstring(ReadData), DEBUG);
        if (ReadData(1) = '1') then
          -- NRP, so check the time
          --Log(Manager1Id, "Step " & to_string(TestStep) & ": NRP received  RepTimer = " & to_string((TREP + 200) * 10) & " ns", DEBUG);
        else
          -- check that the status word is clear
          MultiCmdWord := getCmdWord(MultiComdList.Command(1));
          Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
          Log(Manager1Id, "MultiCmdWord = " & to_hstring(MultiCmdWord) & " ReadData = " & to_hstring(ReadData), DEBUG);
          AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
        end if;
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
        Log("2 WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');", DEBUG);
        WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
        if (Timeout) then
          Log(Manager1Id, "Did not get BC interrupt from CS condition", DEBUG);
        else
          Log(Manager1Id, "Got BC interrupt for end of data on BC, checking", DEBUG);
          ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitDataReceived, bitDataReceived, Manager1Id); -- check for NRP
          ClearInterrupts(BC_cpu_bus, MultiComdList.Command(0).MilBus, IrqMask, Manager1Id);
          Log("3 WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');", DEBUG);
          WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
          if (Timeout) then
            Log(Manager1Id, "Did not get BC interrupt from CS condition", DEBUG);
          else
            Log(Manager1Id, "Got BC interrupt for receiving RT Status, checking", DEBUG);
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
    procedure checkClearStatusTxn(signal MultiComdList : in MultiCommandRec_type; CmdIndex : integer) is
    begin
      Log("checkClearStatusTxn", DEBUG);
      getNumWords(MultiComdList);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord * (NumWords + 1) + tRep + tStatus + 500 ns, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Did not get BC interrupt from CS condition", ERROR);
      else
        Log(Manager1Id, "Got BC interrupt, checking", DEBUG);
        ReadCheckMask(BC_cpu_bus, reg_busX_status or MilBusOffset, bitStatusRxedFlag, bitStatusRxedFlag, Manager1Id); -- check for NRP
        -- check that the status word is clear
        MultiCmdWord := getCmdWord(MultiComdList.Command(CmdIndex));
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(CmdIndex).MilBus) & ": STATUS CLEAR", "ERROR: " & to_hstring(ReadData), TRUE);
        ClearInterrupts(BC_cpu_bus, MultiComdList.Command(CmdIndex).MilBus, IrqMask, Manager1Id);
      end if;
      ClearInterrupts(BC_cpu_bus, MultiComdList.Command(CmdIndex).MilBus, IrqMask, Manager1Id);
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
    procedure checkNRPn(signal MultiComdList : in MultiCommandRec_type; CmdIndex : integer) is
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
        MultiCmdWord := getCmdWord(MultiComdList.Command(CmdIndex));
        Read(BC_cpu_bus, reg_statusword_rxedX or MilBusOffset, ReadData);
        AffirmIf(Manager1Id, ReadData = (MultiCmdWord and X"F800"), "Step " & to_string(TestStep) & ": CmdWord = " & to_hstring(MultiCmdWord) & " Bus " & to_string(MultiComdList.Command(CmdIndex).MilBus) & ": NRP", "ERROR: " & to_hstring(ReadData), TRUE);
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
    variable TestStep  : integer := 0;
    variable StartTime : time;
    variable StopTime  : time;
  begin
    wait for 10 ns;
    wait until BC1_DiscretesIn.nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "-------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for mil1553_gap_timing_dir", ALWAYS);
    Log(Manager1Id, "-------------------------------------------------------------------", ALWAYS);
    Write(BC_cpu_bus, X"0038", X"0001"); -- Write the softwere RtAddr Register
    ReadCheck(BC_cpu_bus, X"0036", X"FEEB"); -- Read the ID Regsister
    Write(BC_cpu_bus, X"0034", X"4000"); -- Set general RT control register
    -- Read the GAP timer register and convert it to a TB time used in wait statements.
    -- The RTL uses reg_tmr_1us as the timer load value to create a 1us pulse from the core clock.
    -- Therefore: clk_period = 1 us / (reg_tmr_1us + 1) and tGap = (reg_tmr_GAP + 1) * clk_period.
    Read(BC_cpu_bus, reg_tmr_1us, ReadData);
    ClocksPerUs := to_integer(unsigned(ReadData)) + 1;
    if (ClocksPerUs = 0) then
      Alert(Manager1Id, "Invalid reg_tmr_1us readback (0); using default tGAP", ERROR);
      tGapCfg := tGAP;
    else
      Read(BC_cpu_bus, reg_tmr_GAP, GapTimerReg);
      GapClocks := to_integer(unsigned(GapTimerReg)) + 1;
      tGapCfg := (GapClocks * 1 us) / ClocksPerUs;
      Log(Manager1Id,
          "GAP timing: reg_tmr_1us=" & to_string(ClocksPerUs - 1) &
          ", reg_tmr_GAP=" & to_hstring(GapTimerReg) &
          ", computed tGap=" & to_string(tGapCfg), ALWAYS);
    end if;
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
    -- This test tests the repeat function of the BC for bus 1
    TestStep := 1;
    --                                  RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0');
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.RepeatRate <= 2; -- repeat 2 x 500us
    wait for 0 ns;
    Step1Command := MultiComdList.Command(0);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    for numchecks in 1 to 1 loop
      Log(Manager1Id, "Step " & to_string(TestStep) & ": MultiCommandRec_type Repeat #" & to_string(numchecks), ALWAYS);
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      wait for tGapCfg;
    end loop;
    MultiComdList.RepeatRate <= 0;
    ----------------------------------------------------------------------------------------------------
    -- This test tests the repeat function of the BC for bus 2
    TestStep := 2;
    --                                  RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 2, '0');
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.RepeatRate <= 1; -- repeat 1 x 500us
    wait for 0 ns;
    Step1Command := MultiComdList.Command(0);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    for numchecks in 1 to 1 loop
      Log(Manager1Id, "Step " & to_string(TestStep) & ": MultiCommandRec_type Repeat #" & to_string(numchecks), ALWAYS);
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      WaitForLevel(RT1_Discretesout.OutEn2, '0');
      wait for tGapCfg;
    end loop;
    MultiComdList.RepeatRate <= 0;
    wait for tGapCfg;

    ----------------------------------------------------------------------------------------------------
    TestStep := 3;
    -- this test checks the RT addr and parity registers
    Log(Manager1Id, "Step " & to_string(TestStep) & ":Checks the RT addr and parity registers", ALWAYS);
    -- set the external discretes to a known value
    RT1_DiscretesIn.MyRtAddr <= "01111";
    RT1_DiscretesIn.MyRtAddrParity <= '1'; --in correct parity for 01111
    wait for 0 ns; --to propagate the discretes before using them in next statements
    -- The RT must be reset to latch the new RT address and parity
    -- lets do a hardware reset
    RT1_DiscretesIn.nReset <= '0';
    wait for 100 ns;
    RT1_DiscretesIn.nReset <= '1';
    wait for 100 ns;
    ReadCheck(RT1_cpu_bus, reg_rt_addr, "00" & "1" & "01111" & "00" & '1' & "01111");
    Write(RT1_cpu_bus, reg_node_control, X"4020"); -- clear the sw reset bits and enable broadcast
    wait for 1 us;
    -- now send the RT a data request command to see if it responds correctly
    --                                  RA TnR SA Len Bus RT2RT 
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0');
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.RepeatRate <= 0;
    wait for 0 ns;
    Step1Command := MultiComdList.Command(0);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT1_Discretesout.OutEn1, tWord + tRep + 5 ns, Timeout, '1');
    if (Timeout) then
      Log(Manager1Id, "Step " & to_string(TestStep) & ": RT did not respond", ALWAYS);
      Alert(Manager1Id, "RT did not respond", ERROR);
    else
      Log(Manager1Id, "Step " & to_string(TestStep) & ": RT responded in time", ALWAYS);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
    end if;
    -- now cause and Parity error by changing the parity discrete
    RT1_DiscretesIn.MyRtAddr <= "01111";
    RT1_DiscretesIn.MyRtAddrParity <= '0'; -- incorrect parity for 01111
    wait for 0 ns; --to propagate the discretes before using them in next statements
    -- The RT must be reset to latch the new RT address and parity
    -- lets do a hardware reset
    RT1_DiscretesIn.nReset <= '0';
    wait for 100 ns;
    RT1_DiscretesIn.nReset <= '1';
    wait for 100 ns;
    ReadCheck(RT1_cpu_bus, reg_rt_addr, "00" & "0" & "01111" & "00" & '0' & "01111");
    Write(RT1_cpu_bus, reg_node_control, X"4020"); -- clear the sw reset bits and enable broadcast
    wait for 1 us;
    -- now send the RT a data request command to see if it responds correctly
    --                                  RA TnR SA Len Bus RT2RT 
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0');
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.RepeatRate <= 0;
    wait for 0 ns;
    Step1Command := MultiComdList.Command(0);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT1_Discretesout.OutEn1, tWord + tRep + 5 ns, Timeout, '1');
    if (Timeout) then
      Log(Manager1Id, "Step " & to_string(TestStep) & ": RT did not respond", ALWAYS);
    else
      Log(Manager1Id, "Step " & to_string(TestStep) & ": RT responded in time", ALWAYS);
      Alert(Manager1Id, "RT responded incorrectly", ERROR);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
    end if;
    -- set the external discretes to a known value
    RT1_DiscretesIn.MyRtAddr <= "01111";
    RT1_DiscretesIn.MyRtAddrParity <= '1'; --in correct parity for 01111
    wait for 0 ns; --to propagate the discretes before using them in next statements
    -- The RT must be reset to latch the new RT address and parity
    -- lets do a hardware reset
    RT1_DiscretesIn.nReset <= '0';
    wait for 100 ns;
    RT1_DiscretesIn.nReset <= '1';
    wait for 100 ns;
    ReadCheck(RT1_cpu_bus, reg_rt_addr, "00" & "1" & "01111" & "00" & '1' & "01111");
    Write(RT1_cpu_bus, reg_node_control, X"4020"); -- clear the sw reset bits and enable broadcast
    wait for 1 us;
    wait for tGapCfg;
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.7 Terminal Fail-Safe: 
    -- The purpose of this test is to verify that the terminal fail-safe timer is properly implemented in the UUT.
    -- The UUT is required to contain a hardware implemented timer that will cause the transmitter to shutdown if
    -- the UUT transmits a message longer than 800.0 µs. A fail-safe time-out occurring on one bus shall not affect 
    -- the transmitter on any other bus. The reception of a valid command on the bus on which the time-out has occurred 
    -- shall enable the transmitter. 
    -- The test sequence below shall be performed:
    -- Step 1. Initiate a condition in the UUT which causes the fail-safe timer to timeout. Measure the duration of the transmission.
    -- Step 2. Remove the condition initiated in Step 1.
    -- Step 3. Send the UUT a valid legal message over the bus on which the time-out occurred.
    -- The pass criteria shall be that the timeout in Step 1 occurs and the transmitter is shut down
    -- allowing the total transmission time to be between 660.0 µs and 800.0 µs. 
    -- The response of the UUT in Step 3 shall be CS. Record the measured parameter at which the fail-safe time-out
    -- occurs. 
    -- For test failures, record the test parameters at which the failure occurred.
    ----------------------------------------------------------------------------------------------------
    TestStep := 4;
    -- this test checks tthe terminal fail safe action
    Log(Manager1Id, "Step " & to_string(TestStep) & ":Checks the Terminal Fail Safe action", ALWAYS);
    -- the timers section already checked the correct operation of the fail safe timer, so this test focusses on the 
    -- reaction of the rest of the system to a terminal fail condition
    -- To perform this test, the fail safe timer will be loaded with a shorter value and the RT will be sent a command that
    -- requires a response longer than the timer. 

    --After the timer expires, the status register will be checked for the terminal fail flag
    -- set the terminal fail timer to 100us
    -- now send the RT a data request command to see if it responds correctly
    Write(RT1_cpu_bus, reg_tmr_SAF, X"0064"); -- write the terminal fail timer register to 100us
    -- Step 1: Send a data request that will cause the terminal fail condition
    --                                  RA TnR SA Len Bus RT2RT 
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 0, 1, '0');
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.RepeatRate <= 0;
    wait for 0 ns;
    Step1Command := MultiComdList.Command(0);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT1_Discretesout.OutEn1, 4500 ns, Timeout, '1');
    if (Timeout) then
      Alert(Manager1Id, "Step " & to_string(TestStep) & ": RT did not respond", ERROR);
    else
      Log(Manager1Id, "Step " & to_string(TestStep) & ": RT is transmitting", ALWAYS);
      StartTime := now;
      WaitForLevel(RT1_Discretesout.OutEn1, 110 us, Timeout, '0');
      StopTime := now;
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": SAF timer did not stop transmission", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": SAF timer stopped transmission correctly after " & to_string(StopTime - StartTime), ALWAYS);
      end if;
    end if;
      wait for tGapCfg*5;
    -- send a message that will complete in less than the terminal fail timeout period to re-enable the transmitter
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0');
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.RepeatRate <= 0;
    wait for 0 ns;
    Step1Command := MultiComdList.Command(0);
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT1_Discretesout.OutEn1, 6500 ns, Timeout, '1');
    if (Timeout) then
      Alert(Manager1Id, "Step " & to_string(TestStep) & ": RT did not respond", ERROR);
    else
      Log(Manager1Id, "Step " & to_string(TestStep) & ": RT is transmitting", ALWAYS);
      StartTime := now;
      WaitForLevel(RT1_Discretesout.OutEn1, (3 * tWord) + 100 ns, Timeout, '0');
      StopTime := now;
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": RT did not stop transmission", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": RT completed message reply as expected. " & to_string(StopTime - StartTime), ALWAYS);
      end if;
    end if;
      wait for tGapCfg;
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
configuration mil1553_gap_timing_dir_cfg of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_1_3_ErrorInjection);
    end for;
  end for;
end configuration;
