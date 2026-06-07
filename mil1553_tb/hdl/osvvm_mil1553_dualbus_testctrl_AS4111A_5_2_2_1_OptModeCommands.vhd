--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_1_OptModeCommands
-- Optional Mode Commands: 
-- The purpose of these tests is to verify that the UUT responds properly to implemented mode commands.
-- The tests are not intended to verify the mission aspects stated in the equipment specification. 
-- The UUT shall be tested for each mode code implemented with a subaddress field mode code indicator 
-- of all zeros and repeated with a subaddress field of all ones.
-- The pass criteria is defined in each test paragraph. If any test fails, record the UUT response to
-- that test.
-- #################################################################################################################
architecture AS4111A_5_2_2_1_OptModeCommands of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("AS4111A_5_2_2_1_OptModeCommands");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("-----------------", ALWAYS);
    Log("-----------------", ALWAYS);
    Log("AS4111A_5_2_2_1_OptModeCommands", ALWAYS);
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_2_1_OptModeCommands.txt");
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
    variable Manager1Id   : AlertLogIDType;
    variable MultiCmdWord : std_logic_vector(15 downto 0);
    variable Timeout      : boolean;
    variable ReadData     : std_logic_vector(15 downto 0);
    variable NumWords     : integer                       := 0;
    variable MilBusOffset : std_logic_vector(15 downto 0);
    variable ModeCode     : integer                       := 0;
    variable PrevCmdWord  : std_logic_vector(15 downto 0) := (others => '0');
    variable MilBus_i     : integer                       := 1;
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
    procedure WaitFor_OutenToComplete(
        OutEnHighTime : time := tWord
      ) is
    begin
      if (MilBus_i = 1) then
        WaitForLevel(BC1_DiscretesOut.OutEn1, tGAP + 1 us, Timeout, '1');
        AlertIf(Manager1Id, Timeout, "OutEn1 did not go HIGH as expected", FAILURE);
        WaitForLevel(BC1_DiscretesOut.OutEn1, OutEnHighTime + 1 us, Timeout, '0');
        AlertIf(Manager1Id, Timeout, "OutEn1 did not go LOW as expected", FAILURE);
      else
        WaitForLevel(BC1_DiscretesOut.OutEn2, tGAP + 1 us, Timeout, '1');
        AlertIf(Manager1Id, Timeout, "OutEn2 did not go HIGH as expected", FAILURE);
        WaitForLevel(BC1_DiscretesOut.OutEn2, OutEnHighTime + 1 us, Timeout, '0');
        AlertIf(Manager1Id, Timeout, "OutEn2 did not go LOW as expected", FAILURE);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for Test AS4111A_5_2_2_1_Optional Mode Commands", ALWAYS);
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
    -- Dynamic Bus Control: 
    -- The purpose of this test is to verify that the UUT has the ability to recognize the dynamic bus control mode 
    -- command and to take control of the data bus. A valid legal dynamic bus control mode command shall be sent to the UUT. 
    -- The UUT shall take control of the data bus when its response is DBA as required in the UUT’s design specification.
    -- The pass criteria shall be that the UUT responds with a DBA upon acceptance of bus control or a CS upon rejection of bus control. 
    -- Since the CORE does not implement DBC, the response shall be a CS.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_1: STEP 1 - Dynamic Bus Control.  ", ALWAYS);
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
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_DBC, 1, '0'); -- MODE: Dynamic bus control command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatus(MultiComdList);
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Synchronize (Without Data Word): 
    -- The purpose of this test is to verify that the UUT has the ability to recognize a synchronization mode command 
    -- without using a data word. A validlegal synchronize (without data word) mode command shall be sent to the UUT.
    -- The pass criteria shall be that the UUT responds with CS.    
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "---------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_2_1: STEP 2 - Synchronize (Without Data Word)  ", ALWAYS);
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
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_Synchronize, 1, '0'); -- MODE: Synchronize command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Synchronize (With Data Word): 
    -- The purpose of this test is to verify that the UUT has the ability to recognize a synchronization mode command 
    -- which uses a data word. A valid legal synchronize (with data word) mode command shall be sent to the UUT.
    -- The pass criteria shall be that the UUT responds with CS.    
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_2_2: STEP 3 - Synchronize (With Data Word)", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 0, ModeCode, rxMC_Synchronize, 1, '0'); -- MODE: Synchronize command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Initiate Self-Test: 
    -- The purpose of this test is to verify that the UUT has the ability to recognize and properly operate 
    -- when the initiate self-test mode command is received. Note that this test provides characterization of 
    -- self-test time as a first step. If the self-test time is variable, the test must be performed with conditions 
    -- in the UUT set such that a maximum self-test time results.
    -- The following sequences shall be performed:
    -- Step 1. An initiated self-test mode command shall be sent to the UUT on one bus.
    -- Step 2. After time T from Step 1, as measured per Figure 7, a valid legal command shall be sent to the UUT on the same bus.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; Check that the initiate bit is indicated by the RT.
    -- Step 2 - CS (with busy bit reset) for all time T ≥ 100.0 ms, and CS or NR for time T < 100.0 ms. --> we will test with the minimum time of 4us
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_3: STEP 4 - Initiate Self-Test", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_InitiateBIT, 1, '0'); -- MODE: Initiate Self-Test command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatus(MultiComdList);
      TestStep <= 2;
      checkRT1_InitiateBit(MultiComdList);
      wait for 3400 ns; -- wait for 3.4 us to make total of 4 us from start of command
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Transmit BIT Word: 
    -- The purpose of this test is to verify that the UUT has the ability to recognize this mode command. 
    -- A valid legal transmit BIT mode command shall be sent to the UUT. The BIT word transmitted by the UUT shall be recorded.
    -- The pass criteria shall be that the UUT responds with CS followed by a valid BIT Word.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_4: STEP 5 - Transmit BIT Word ", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitBit, 1, '0'); -- MODE: Transmit BIT command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(RT1_DiscretesOut.OutEn1, '1');
      checkClearStatus(MultiComdList);
      TestStep <= 2;
      -- compare the BIT word received by the BC with the BIT word settings on the RT discretes.
      WaitForLevel(RT1_DiscretesOut.OutEn1, '0');
      checkRT1_TransmitBit(MultiComdList);
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      wait for 3400 ns; -- wait for 3.4 us to make total of 4 us from start of command
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      WaitForLevel(RT1_DiscretesOut.OutEn2, '1');
      WaitForLevel(RT1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Selected Transmitter Shutdown and Override: 
    -- This test shall verify that the UUT recognizes the multi-redundant mode commands to shut down 
    -- a selected bus transmitter and to override the shutdown. A valid legal selected transmitter 
    -- shutdown mode command shall be sent to the UUT accompanied by the appropriate data word to 
    -- cause a selected bus transmitter shutdown. A valid legal override selected transmitter shutdown 
    -- mode command shall be sent to the UUT accompanied by the appropriate data word to cause an 
    -- override of the selected bus transmitter shutdown. 
    -- Step 1. A valid legal command shall be sent to the UUT on the bus under test.
    -- Step 2. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
    -- Step 3. A valid legal selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the data word encoded to shut down the bus used in Step 2.
    -- Step 4. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 5. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 6. A valid legal override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2 with the same data word as sent in Step 3.
    -- Step 7. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 8. A valid legal override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the same data word as sent in Step 3.
    -- Step 9. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 10. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 11. Repeat Step 3 except that the data word shall be encoded with a bit pattern that would normally shut down the same bus used in Step 1 if it was sent on the same bus used in Step 2.
    -- Step 12. Repeat Step 4.
    -- Step 13. Repeat Step 5.   
    -- The data words associated with Step 3 and Step 11 for each bus shall be recorded.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS, Step 2 - CS, Step 3 - CS, 
    -- Step 4 - NR, 
    -- Step 5 - CS, 
    -- Step 6 - NR, Step 7 - NR, 
    -- Step 8 - CS, Step 9 - CS, Step 10 - CS, Step 11 - CS, Step 12 - CS, Step 13 - CS.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_5: STEP 6 - Selected Transmitter Shutdown and Override", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------------", ALWAYS);
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
      MultiComdList.ErrWrd <= 2; -- the Error word (ErrWrd) is also used to send the data word for mode commands instead of random data (ErrInj must be errNone).
      MultiComdList.Command(0) <= (15, 0, ModeCode, rxMC_TxShutdown, 1, '0'); -- MODE: Selected Transmitter shutdown word command to RT1 on bus 1
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
      MultiComdList.Command(0) <= (15, 0, ModeCode, rxMC_TxShutdownOvr, 2, '0'); -- MODE: Selected Transmitter shutdown override command to RT1 on bus 2
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
      MultiComdList.ErrWrd <= 2; -- the Error word (ErrWrd) is also used to send the data word for mode commands instead of random data (ErrInj must be errNone).
      MultiComdList.Command(0) <= (15, 0, ModeCode, rxMC_TxShutdownOvr, 1, '0'); -- MODE: Selected Transmitter shutdown override command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
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
      TestStep <= 11;
      MultiComdList.ErrWrd <= 1; -- the Error word (ErrWrd) is also used to send the data word for mode commands instead of random data (ErrInj must be errNone).
      MultiComdList.Command(0) <= (15, 0, ModeCode, rxMC_TxShutdown, 1, '0'); -- MODE: Selected Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 12;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn2, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 13;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Terminal Flag Bit Inhibit and Override: 
    -- This test verifies that the UUT recognizes and responds properly to the mode command(s) 
    -- of inhibit terminal flag bit and override inhibit terminal flag bit.
    -- Step 1. A valid legal receive command with at least one data word shall be sent to the UUT.
    -- Step 2. Procedures as defined for the UUT, shall be performed that will set the terminal flag in the UUT status response. Send a valid legal receive command with at least one data word to the UUT.
    -- Step 3. A valid legal inhibit terminal flag mode command shall be sent to the UUT.
    -- Step 4. Repeat Step 1.
    -- Step 5. A valid legal override inhibit terminal flag mode command shall be sent to the UUT.
    -- Step 6. A valid legal receive command with at least one data word shall be sent to theUUT.
    -- Step 7. Procedures, as defined for the UUT, shall be performed which resets the TF bit.
    -- Step 8. Repeat Step 1.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS, 
    -- Step 2 - TF, 
    -- Step 3 - CS or TF, 
    -- Step 4 - CS, 
    -- Step 5 - CS or TF, 
    -- Step 6 - TF, 
    -- Step 8 - CS.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_6: STEP 7 - Terminal Flag Bit Inhibit and Override.   ", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------------", ALWAYS);
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
      -- clear the terminal flag on the RT using the node control register, best to read it back first and then clear the new bit
      Read(RT1_cpu_bus, reg_node_control, ReadData);
      Write(RT1_cpu_bus, reg_node_control, ReadData and (not bitSetTerminalFlag)); -- set bitSetTerminalFlag to clear
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
      -- set the terminal flag on the RT using the node control register, best to read it back first and then set the new bit
      Read(RT1_cpu_bus, reg_node_control, ReadData);
      Write(RT1_cpu_bus, reg_node_control, ReadData or bitSetTerminalFlag); -- set bitSetTerminalFlag to set
      wait for 0 ns;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusTF(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TerminalFlagInh, 1, '0'); -- MODE: Inhibit terminal flag mode command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 4;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 5;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TerminalFlagOvr, 1, '0'); -- MODE: Inhibit terminal flag override mode command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusTF(MultiComdList);
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 6;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusTF(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 7;
      -- clear the terminal flag on the RT using the node control register, best to read it back first and then clear the new bit
      Read(RT1_cpu_bus, reg_node_control, ReadData);
      Write(RT1_cpu_bus, reg_node_control, ReadData and (not bitSetTerminalFlag)); -- set bitSetTerminalFlag to clear
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 8;
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
    -- Transmit Vector Word: 
    -- This test verifies the capability of the UUT to recognize and respond
    -- properly to a transmit vector word mode command. A valid legal transmit vector word mode
    -- command shall be sent to the UUT. The vector word transmitted by the UUT shall be recorded.
    -- The pass criteria shall be that the UUT responds with CS followed by a valid Vector Word.   
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "-----------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_7: STEP 8 - Transmit Vector Word ", ALWAYS);
    Log(Manager1Id, "-----------------------------------------------------", ALWAYS);
    wait for 0 ns;
    for i in 1 to 2 loop
      if (i = 1) then
        ModeCode := 0;
      else
        ModeCode := 31;
      end if;
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      --                          RA TnR  SA Len Bus RT2RT
      ----------------------------------------------------------------------------------------------------
      TestStep <= 1;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitVector, 1, '0'); -- MODE: Transmit Vector command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatus(MultiComdList);
      TestStep <= 2;
      -- compare the Vector word received by the BC with the Vector word settings on the RT discretes.
      checkRT1_TransmitVectorWord(MultiComdList);
      wait for 3400 ns; -- wait for 3.4 us to make total of 4 us from start of command
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    -- Transmit Last Command: 
    -- This test verifies that the UUT recognizes and responds properly to
    -- a transmit last command mode command. The following test sequence shall be used:
    -- Step 1. A valid legal receive command with at least one data word shall be sent to the UUT.
    -- Step 2. A valid legal receive command different from that used in Step 1 above with at least one data word shall be sent to the UUT and a parity error shall be encoded into the first data word.
    -- Step 3. A valid transmit last command mode command shall be sent to the UUT.
    -- Step 4. A valid transmit status mode command shall be sent to the UUT.
    -- Step 5. A valid legal transmit last command mode command shall be sent to the UUT.
    -- Step 6. A valid legal transmit last command mode command shall be sent to the UUT.
    -- Step 7. A valid legal receive command with at least one data word shall be sent to the UUT.
    -- Step 8. A valid legal transmit last command mode command shall be sent to the UUT.
    -- Step 9. A valid legal transmit command shall be sent to the UUT.
    -- Step 10. A valid legal transmit last command mode command shall be sent to the UUT.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; 
    -- Step 2 - NR;
    -- Step 3 - ME, followed by a data word containing the command word from Step 2; 
    -- Step 4 - ME;
    -- Step 5 - ME, followed by a data word containing the command word from Step 4; 
    -- Step 6 - ME, followed by a data word containing the command word from Step 4; 
    -- Step 7 - CS; 
    -- Step 8 - CS, followed by a data word containing the command word from Step 7; 
    -- Step 9 - CS;
    -- Step 10 - CS, followed by a data word containing the command word from Step 9.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "----------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_8: STEP 9 - Transmit Last Command.   ", ALWAYS);
    Log(Manager1Id, "----------------------------------------------------------", ALWAYS);
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
      -- remember the previous command word for later comparison
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      -- introduce a parity error in the first data word
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
      TestStep <= 3;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusME_DAT(MultiComdList);
      -- check the received command word data
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 4;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 1, '0'); -- MODE: transmit status to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusME(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 5;
      -- remember the previous command word for later comparison
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusME_DAT(MultiComdList);
      -- check the received command word data
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 6;
      -- remember the previous command word for later comparison
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusME_DAT(MultiComdList);
      -- check the received command word data
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 7;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 8;
      -- remember the previous command word for later comparison
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusMode(MultiComdList);
      -- check the received command word data
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 9;
      MultiComdList.Command(0) <= (15, 1, 3, 1, 1, '0'); -- Transmit SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusTx(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      TestStep <= 10;
      -- remember the previous command word for later comparison
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatusMode(MultiComdList);
      -- check the received command word data
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
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
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_1_OptModeCommands of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_2_1_OptModeCommands);
    end for;
  end for;
end configuration;
