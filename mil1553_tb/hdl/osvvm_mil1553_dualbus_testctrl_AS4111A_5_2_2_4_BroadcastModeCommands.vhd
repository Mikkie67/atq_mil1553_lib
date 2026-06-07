--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_4_BroadcastModeCommands
-- Broadcast Mode Commands: 
-- The purpose of this test is to verify that the UUT responds properly to implemented broadcast mode commands. 
-- This test is not intended to verify the mission aspects stated in the equipment specification. 
-- The UUT shall be tested for each mode code implemented with a subaddress field mode code indicator of all zeros 
-- and repeated with a subaddress field of all ones. 
-- Use the following test sequence unless otherwise noted.
-- Step 1. A valid receive message shall be sent to the UUT.
-- Step 2. A valid legal broadcast message shall be sent to the UUT.
-- Step 3. A transmit last command mode command shall be sent to the UUT. 
-- If this mode command is not implemented, then a transmit status mode command shall be used, and the data word 
-- associated with the transmit last command mode command shall be deleted from the pass criteria.
-- The pass criteria is defined in each test paragraph. If any test fails, record the UUT response to that test.
-- #################################################################################################################
architecture AS4111A_5_2_2_4_BroadcastModeCommands of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("AS4111A_5_2_2_4_BroadcastModeCommands");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("-----------------", ALWAYS);
    Log("-----------------", ALWAYS);
    Log("AS4111A_5_2_2_4_BroadcastModeCommands", ALWAYS);
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_2_4_BroadcastModeCommands.txt");
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

  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for Test AS4111A_5_2_4 Broadcast Mode Commands", ALWAYS);
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
    -- Broadcast Synchronize (Without Data Word): 
    -- The purpose of this test is to verify that the UUT has the ability to recognize a 
    -- broadcast synchronize (without data word) mode command. 
    -- Use the following test sequence unless otherwise noted.
    -- Step 1. A valid receive message shall be sent to the UUT.
    -- Step 2. A valid legal broadcast synchronize (without data word) message shall be sent to the UUT.
    -- Step 3. A transmit last command mode command shall be sent to the UUT. 
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; 
    -- Step 2 - NR;
    -- Step 3 - BCR and the data word contains the broadcast command sent in Step 2.  
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_4_1: STEP 1 -  Broadcast Synchronize NODAT  ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
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
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid receive message shall be sent to the UUT.
      TestStep <= 1;
      --                                  RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. A valid legal broadcast synchronize (without data word) message shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_Synchronize, 1, '0'); -- Tx MODE: Synchronize (No Data) on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      wait for tGap;
      -- check that no interrupt generated
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit last command mode command shall be sent to the UUT. 
      TestStep <= 3;
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    -- Broadcast Synchronize (With Data Word): 
    -- The purpose of this test is to verify that the UUT has the ability to recognize a 
    -- broadcast synchronize (with data word) mode command. 
    -- Use the following test sequence unless otherwise noted.
    -- Step 1. A valid receive message shall be sent to the UUT.
    -- Step 2. A valid legal broadcast synchronize (with data word) message shall be sent to the UUT.
    -- Step 3. A transmit last command mode command shall be sent to the UUT. 
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; 
    -- Step 2 - NR;
    -- Step 3 - BCR and the data word contains the broadcast command sent in Step 2.  
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_4_2: STEP 2 -  Broadcast Synchronize DAT  ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
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
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid receive message shall be sent to the UUT.
      TestStep <= 1;
      --                                  RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. A valid legal broadcast synchronize (with data word) message shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (31, 0, ModeCode, rxMC_Synchronize, 1, '0'); -- Rx MODE: Synchronize (Data) on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      wait for tGap;
      -- check that no interrupt generated
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit last command mode command shall be sent to the UUT. 
      TestStep <= 3;
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Broadcast Initiate Self-Test: 
    -- The purpose of this test is to verify that the UUT has the ability to recognize and properly operate 
    -- when the broadcast initiate self-test mode command is received. Note that this test provides characterization of 
    -- self-test time as a first step. If the self-test time is variable, the test must be performed with conditions 
    -- in the UUT set such that a maximum self-test time results.
    -- The following sequences shall be performed:
    -- Step 1. An broadcast initiated self-test mode command shall be sent to the UUT on one bus.
    -- Step 2. After time T from Step 1, as measured per Figure 7, a valid legal command shall be sent to the UUT on the same bus.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; Check that the initiate bit is indicated by the RT.
    -- Step 2 - CS (with busy bit reset) for all time T ≥ 100.0 ms, and CS or NR for time T < 100.0 ms. --> we will test with the minimum time of 4us
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_4_3: STEP 3 - Broadcast Initiate Self-Test", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
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
      -- Step 1. An broadcast initiated self-test mode command shall be sent to the UUT on one bus.
      TestStep <= 1;
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_InitiateBIT, 1, '0'); -- MODE: Initiate Self-Test command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 2. After time T from Step 1, as measured per Figure 7, a valid legal command shall be sent to the UUT on the same bus.
      TestStep <= 2;
      checkRT1_InitiateBit(MultiComdList);
      wait for tGap; -- wait for 3.4 us to make total of 4 us from start of command
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Broadcast Transmitter Shutdown and Override: 
    -- This test shall verify that the UUT recognizes the dual
    -- redundant mode commands to shutdown the alternate bus transmitter and to override the
    -- shutdown. A valid legal transmitter shutdown mode command shall be sent to the UUT to
    -- cause an alternate bus transmitter shutdown. A valid legal override transmitter shutdown mode
    -- command shall be sent to the UUT to cause an override of the transmitter shut down. The
    -- following test sequence shall be used for each case including verification of the UUT response
    -- indicated.
    -- Step 1. A valid legal command shall be sent to the UUT on the bus under test.
    -- Step 2. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
    -- Step 3. A valid legal broadcast transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 4. A transmit last command mode command shall be sent to the UUT on bus 1
    -- Step 5. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 6. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 7. A valid legal broadcast override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 8. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 9. A valid legal broadcast override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 10. A transmit last command mode command shall be sent to the UUT on bus 1
    -- Step 11. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 12. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; 
    -- Step 2 - CS; 
    -- Step 3 - NR; 
    -- Step 4 - BCR + DAT; 
    -- Step 5 - NR; 
    -- Step 6 - CS; 
    -- Step 7 - NR; 
    -- Step 8 - NR; 
    -- Step 9 - NR; 
    -- Step 10 - BCR + DAT.
    -- Step 11 - CS; 
    -- Step 12 - CS.   
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "---------------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_4_4: STEP 4 - Broadcast Transmitter Shutdown and Override", ALWAYS);
    Log(Manager1Id, "---------------------------------------------------------------------------", ALWAYS);
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
      -- Step 1. A valid legal command shall be sent to the UUT on the bus under test.
      TestStep <= 1;
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
      TestStep <= 2;
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      WaitForLevel(RT1_Discretesout.OutEn2, '1');
      WaitForLevel(RT1_Discretesout.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A valid legal broadcast transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1.
      TestStep <= 3;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Transmitter Shutdown Mode Command", ALWAYS);
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_TxShutdown, 1, '0'); -- MODE: broadcast Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 4. A transmit last command mode command shall be sent to the UUT on bus 1
      TestStep <= 4;
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- Log(Manager1Id, "Step " & to_string(TestStep) & ":1 WaitForLevel(BC1_Discretesout.OutEn1, '1');", ALWAYS);
      -- WaitForLevel(BC1_Discretesout.OutEn1, '1');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":2 WaitForLevel(BC1_Discretesout.OutEn1, '0');", ALWAYS);
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":3 checkClearStatus_selected(MultiComdList, bitBrdcstRxed);", ALWAYS);
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      Log(Manager1Id, "Step " & to_string(TestStep) & ":4 WaitForLevel(RT1_Discretesout.OutEn1, '1');", ALWAYS);
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":5 WaitForLevel(RT1_Discretesout.OutEn1, '0');", ALWAYS);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":6 WaitForLevel(BC1_DiscretesOut.Intrn1, '1');", ALWAYS);
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 5. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
      Log(Manager1Id, "Step 5. A valid legal command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      TestStep <= 5;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ":1 WaitForLevel(BC1_Discretesout.OutEn2, '1');", ALWAYS);
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":1 WaitForLevel(BC1_Discretesout.OutEn2, '0');", ALWAYS);
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 6. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
      Log(Manager1Id, "Step 6. A valid legal command shall be sent to the UUT on the same bus used in Step 1.", ALWAYS);
      TestStep <= 6;
      MultiComdList.Command(0) <= (15, 0, 3, 2, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ":1 WaitForLevel(BC1_Discretesout.OutEn1, '1');", ALWAYS);
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":1 WaitForLevel(BC1_Discretesout.OutEn1, '0');", ALWAYS);
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":1 WaitForLevel(RT1_Discretesout.OutEn1, '1');", ALWAYS);
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      Log(Manager1Id, "Step " & to_string(TestStep) & ":1 WaitForLevel(RT1_Discretesout.OutEn2, '0');", ALWAYS);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
      -- Step 7. A valid legal broadcast override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2.
      TestStep <= 7;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal broadcast override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_TxShutdownOvr, 2, '0'); -- MODE: Broadcast Transmitter shutdown word command to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Override Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 8. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
      Log(Manager1Id,"Step 8. A valid legal command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      TestStep <= 8;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 9. A valid legal broadcast override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1.
      Log(Manager1Id, "Step 9. A valid legal broadcast override transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1.", ALWAYS);
      TestStep <= 9;
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_TxShutdownOvr, 1, '0'); -- MODE: Broadcast Transmitter shutdown override word command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Transmitter Shutdown Override Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Override Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 10. A transmit last command mode command shall be sent to the UUT on bus 1
      Log(Manager1Id, "Step 10. A transmit last command mode command shall be sent to the UUT on bus 1.", ALWAYS);
      TestStep <= 10;
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 11. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
      Log(Manager1Id, "Step 11. A valid legal command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      TestStep <= 11;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 2, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      --WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      WaitForLevel(RT1_Discretesout.OutEn2, '1');
      WaitForLevel(RT1_Discretesout.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 12. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
      Log(Manager1Id, "Step 12. A valid legal command shall be sent to the UUT on the same bus used in Step 1.", ALWAYS);
      TestStep <= 12;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
    end loop;

    ----------------------------------------------------------------------------------------------------
    -- Broadcast Selected Transmitter Shutdown and Override: 
    -- This test shall verify that the UUT recognizes the multi-redundant mode commands to shut down 
    -- a selected bus transmitter and to override the shutdown. A valid legal broadcast selected transmitter 
    -- shutdown mode command shall be sent to the UUT accompanied by the appropriate data word to 
    -- cause a selected bus transmitter shutdown. A valid legal broadcast override selected transmitter shutdown 
    -- mode command shall be sent to the UUT accompanied by the appropriate data word to cause an 
    -- override of the selected bus transmitter shutdown. 
    -- Step 1. A valid legal command shall be sent to the UUT on the bus under test.
    -- Step 2. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
    -- Step 3. A valid legal broadcast selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the data word encoded to shut down the bus used in Step 2.
    -- Step 4. A transmit last command mode command shall be sent to the UUT on bus 1
    -- Step 5. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 6. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 7. A valid legal broadcast override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2 with the same data word as sent in Step 3.
    -- Step 8. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 9. A valid legal broadcast override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the same data word as sent in Step 3.
    -- Step 10. Repeat Step 4.
    -- Step 11. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
    -- Step 12. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
    -- Step 13. A valid legal broadcast selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the data word encoded to shut down the bus used in Step 1.
    -- Step 14. Repeat Step 4.
    -- Step 15. Repeat Step 5.
    -- Step 16. Repeat Step 6.
    -- The data words associated with Step 3 and Step 11 for each bus shall be recorded.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS, Step 2 - CS, Step 3 - CS, 
    -- Step 4 - NR, 
    -- Step 5 - CS, 
    -- Step 6 - NR, Step 7 - NR, 
    -- Step 8 - CS, Step 9 - CS, Step 10 - CS, Step 11 - CS, Step 12 - CS, Step 13 - CS.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_5: STEP 5 - Selected Transmitter Shutdown and Override", ALWAYS);
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
      -- Step 1. A valid legal command shall be sent to the UUT on the bus under test.
      TestStep <= 1;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the bus under test", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 3, 2, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
      TestStep <= 2;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 4, 2, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      WaitForLevel(RT1_Discretesout.OutEn2, '1');
      WaitForLevel(RT1_Discretesout.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A valid legal broadcast selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the data word encoded to shut down the bus used in Step 2.
      TestStep <= 3;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal broadcast selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the data word encoded to shut down the bus used in Step 2.", ALWAYS);
      MultiComdList.ErrWrd <= 2; -- the Error word (ErrWrd) is also used to send the data word for mode commands instead of random data (ErrInj must be errNone).
      MultiComdList.Command(0) <= (31, 0, ModeCode, rxMC_TxShutdown, 1, '0'); -- MODE: Selected Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Transmitter Shutdown Bus 2 Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Bus 2 Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 4. A transmit last command mode command shall be sent to the UUT on bus 1
      TestStep <= 4;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 5. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
      TestStep <= 5;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 6. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
      TestStep <= 6;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the bus under test", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
      -- Step 7. A valid legal broadcast override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2 with the same data word as sent in Step 3.
      TestStep <= 7;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal broadcast override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 2 with the same data word as sent in Step 3.", ALWAYS);
      MultiComdList.ErrWrd <= 2; -- the Error word (ErrWrd) is also used to send the data word for mode commands instead of random data (ErrInj must be errNone).
      MultiComdList.Command(0) <= (31, 0, ModeCode, rxMC_TxShutdownOvr, 2, '0'); -- MODE: Selected Transmitter shutdown override command to RT1 on bus 2
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Transmitter Shutdown override Bus 2 Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Bus 2 Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 8. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
      TestStep <= 8;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 9. A valid legal broadcast override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the same data word as sent in Step 3.
      TestStep <= 9;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal broadcast override selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the same data word as sent in Step 3.", ALWAYS);
      MultiComdList.ErrWrd <= 2; -- the Error word (ErrWrd) is also used to send the data word for mode commands instead of random data (ErrInj must be errNone).
      MultiComdList.Command(0) <= (31, 0, ModeCode, rxMC_TxShutdownOvr, 1, '0'); -- MODE: Broadcast Selected Transmitter shutdown override command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Transmitter Shutdown Override Bus 1 Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Override Bus 1 Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 10. A transmit last command mode command shall be sent to the UUT on bus 1
      TestStep <= 10;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the bus under test", ALWAYS);
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 11. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
      TestStep <= 11;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the same bus used in Step 2.", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      WaitForLevel(RT1_Discretesout.OutEn2, '1');
      WaitForLevel(RT1_Discretesout.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 12. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
      TestStep <= 12;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the same bus used in Step 1.", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 13. A valid legal broadcast selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the data word encoded to shut down the bus used in Step 1.
      TestStep <= 13;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal broadcast selected transmitter shutdown mode command shall be sent to the UUT on the same bus used in Step 1 with the data word encoded to shut down the bus used in Step 1.", ALWAYS);
      MultiComdList.ErrWrd <= 1; -- the Error word (ErrWrd) is also used to send the data word for mode commands instead of random data (ErrInj must be errNone).
      MultiComdList.Command(0) <= (31, 0, ModeCode, rxMC_TxShutdown, 1, '0'); -- MODE: Selected Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Transmitter Shutdown Override for bus 1 on bus 1(error) Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Override for bus 1 on bus 1(error) Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 14. A transmit last command mode command shall be sent to the UUT on bus 1
      TestStep <= 14;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A transmit last command mode command shall be sent to the UUT on bus 1", ALWAYS);
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      ClearInterrupts(BC_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 15. A valid legal command shall be sent to the UUT on the same bus used in Step 2.
      TestStep <= 15;
      wait for 0 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": A valid legal command shall be sent to the UUT on the same bus used in Step 2", ALWAYS);
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      WaitForLevel(RT1_Discretesout.OutEn2, '1');
      WaitForLevel(RT1_Discretesout.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 16. A valid legal command shall be sent to the UUT on the same bus used in Step 1.
      TestStep <= 16;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGAP;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Broadcast Terminal Flag Bit Inhibit and Override: 
    -- This test verifies that the UUT recognizes and responds properly to the mode command(s) 
    -- of broadcast inhibit terminal flag bit and broadcast override inhibit terminal flag bit.
    -- Step 1. A valid legal receive command with at least one data word shall be sent to the UUT.
    -- Step 2. Procedures as defined for the UUT, shall be performed that will set the terminal flag in the UUT status response. Send a valid legal receive command with at least one data word to the UUT.
    -- Step 3. A valid legal broadcast inhibit terminal flag mode command shall be sent to the UUT.
    -- Step 4. A transmit last command mode command shall be sent to the UUT on bus 1
    -- Step 5. Repeat Step 1.
    -- Step 6. A valid legal broadcast override inhibit terminal flag mode command shall be sent to the UUT.
    -- Step 7. A transmit last command mode command shall be sent to the UUT on bus 1
    -- Step 8. A valid legal receive command with at least one data word shall be sent to the UUT.
    -- Step 9. Procedures, as defined for the UUT, shall be performed which resets the TF bit.
    -- Step 10. Repeat Step 1.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS, 
    -- Step 2 - TF, 
    -- Step 3 - NR, 
    -- Step 4 - BCR and TF, 
    -- Step 5 - CS
    -- Step 6 - NR,
    -- Step 7 - BCR,
    -- Step 8 - TF, 
    -- Step 10 - CS.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_1_6: STEP 6 - Terminal Flag Bit Inhibit and Override.   ", ALWAYS);
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
      -- Step 1. A valid legal receive command with at least one data word shall be sent to the UUT.
      TestStep <= 1;
      -- clear the terminal flag on the RT using the node control register, best to read it back first and then clear the new bit
      Read(RT1_cpu_bus, reg_node_control, ReadData);
      Write(RT1_cpu_bus, reg_node_control, ReadData and (not bitSetTerminalFlag)); -- set bitSetTerminalFlag to clear
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. Procedures as defined for the UUT, shall be performed that will set the terminal flag in the UUT status response. Send a valid legal receive command with at least one data word to the UUT.
      TestStep <= 2;
      -- set the terminal flag on the RT using the node control register, best to read it back first and then set the new bit
      Read(RT1_cpu_bus, reg_node_control, ReadData);
      Write(RT1_cpu_bus, reg_node_control, ReadData or bitSetTerminalFlag); -- set bitSetTerminalFlag to set
      wait for 0 ns;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatusTF(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A valid legal broadcast inhibit terminal flag mode command shall be sent to the UUT.
      TestStep <= 3;
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_TerminalFlagInh, 1, '0'); -- MODE: broadcast Inhibit terminal flag mode command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Terminal flag inhibit Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Terminal flag inhibit Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 4. A transmit last command mode command shall be sent to the UUT on bus 1
      TestStep <= 4;
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed or bitTerminalFlag); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 5. A valid legal receive command with at least one data word shall be sent to the UUT.
      TestStep <= 5;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 6. A valid legal broadcast override inhibit terminal flag mode command shall be sent to the UUT.
      TestStep <= 6;
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_TerminalFlagOvr, 1, '0'); -- MODE: Broadcast Inhibit terminal flag override mode command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Transmitter Shutdown Override for bus 1 on bus 1(error) Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Transmitter Shutdown Override for bus 1 on bus 1(error) Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      -- Step 7. A transmit last command mode command shall be sent to the UUT on bus 1
      TestStep <= 7;
      PrevCmdWord := getCmdWord(MultiComdList.Command(0));
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitLastCmd, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed); -- check for SRB
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      WaitForLevel(BC1_DiscretesOut.Intr, tWord, Timeout, '1');
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Did not get BC interrupt following Transmit Last Command", ERROR);
      else
        Log(Manager1Id, "Step " & to_string(TestStep) & ": Got BC interrupt, checking", DEBUG);
        Read(BC_cpu_bus, reg_mode_data_rxed1, ReadData);
        AffirmIf(Manager1Id, ReadData = PrevCmdWord,
                 "Step " & to_string(TestStep) & ": reg_mode_data_rxed1 = " & to_hstring(ReadData) & " Bus " & to_string(MultiComdList.Command(0).MilBus) & ": MODE CMD Transmit last command", "ERROR: Expected =" & to_hstring(PrevCmdWord), TRUE);
      end if;
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, Manager1Id);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 8. A valid legal receive command with at least one data word shall be sent to the UUT.
      TestStep <= 8;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatusTF(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 9. Procedures, as defined for the UUT, shall be performed which resets the TF bit.
      TestStep <= 9;
      -- clear the terminal flag on the RT using the node control register, best to read it back first and then clear the new bit
      Read(RT1_cpu_bus, reg_node_control, ReadData);
      Write(RT1_cpu_bus, reg_node_control, ReadData and (not bitSetTerminalFlag)); -- set bitSetTerminalFlag to clear
      MultiComdList.Command(0) <= (15, 0, 4, 1, 1, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 10. A valid legal receive command with at least one data word shall be sent to the UUT.
      TestStep <= 10;
      MultiComdList.Command(0) <= (15, 0, 3, 1, 1, '0'); -- Receive SA3 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Broadcast Reset Remote Terminal: 
    -- The purpose of this test is to verify that the UUT has the ability to recognize and properly operate 
    -- when the broadcast reset remote terminal mode command is received. Note that this test provides characterization
    -- of the reset time (TRST) as a first step. If the reset time is variable, the test must be performed 
    -- with conditions in the UUT set such that a maximum reset time results. The following sequence shall be performed.
    --
    -- Step 1. A broadcast reset remote terminal mode command shall be sent to the UUT on the bus under test.
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
    -- Step 5. A broadcast reset remote terminal mode command shall be sent to the UUT on the bus used in Step 1.
    -- Step 6. After an intermessage gap equal to TRST, a valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
    -- The pass criteria for each of the above steps shall be as follows: 
    -- Step 1 - CS; Step 2 - CS (with busy bit reset) for all time T ≥ 5.0 ms, and CS or NR for T < 5.0 ms; 
    -- Step 3 - CS; Step 4 - NR; Step 5 - CS; Step 6 - CS (with busy bit reset).NR; Step 5 - CS; Step 6 - CS (with busy bit reset).
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "---------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_4_7: STEP 7 - Broadcast Reset Remote Terminal", ALWAYS);
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
      -- Step 1. A broadcast reset remote terminal mode command shall be sent to the UUT on the bus under test.
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_ResetRt, 1, '0'); -- MODE: Broadcast Reset RT command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Reset remote terminal Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Reset remote terminal Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      -- After the RT is reset, register need to be configured to get it ready for operation
      wait for 400 ns;
      Write(RT1_cpu_bus, reg_rt_addr, X"0001");
      Write(RT1_cpu_bus, reg_intr_mask, X"0003");
      ReadCheck(RT1_cpu_bus, reg_gID, X"FEEB");
      Write(RT1_cpu_bus, reg_node_control, X"4020");
      ClearInterrupts(RT1_cpu_bus, 1, IrqMask, RT1ID);
      ClearInterrupts(RT1_cpu_bus, 2, IrqMask, RT1ID);
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. After time T from Step 1, as measured per Figure 7, a valid legal transmit command shall be sent to the UUT on the same bus used in Step 1.
      TestStep <= 2;
      MultiComdList.Command(0) <= (15, 1, 4, 2, 1, '0'); -- Transmit SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatusTx(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A valid legal transmitter shutdown mode command shall be sent to the UUT on the bus used in Step 1.
      TestStep <= 3;
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TxShutdown, 1, '0'); -- MODE: Transmitter shutdown word command to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 4. A valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
      TestStep <= 4;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 2
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 5. A broadcast reset remote terminal mode command shall be sent to the UUT on the bus used in Step 1.
      TestStep <= 5;
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_ResetRt, 1, '0'); -- MODE: Broadcast Reset RT command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Reset remote terminal Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Reset remote terminal Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      -- After the RT is reset, register need to be configured to get it ready for operation
      wait for 400 ns;
      Write(RT1_cpu_bus, reg_rt_addr, X"0001");
      Write(RT1_cpu_bus, reg_intr_mask, X"0003");
      ReadCheck(RT1_cpu_bus, reg_gID, X"FEEB");
      Write(RT1_cpu_bus, reg_node_control, X"4020");
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      -- Step 6. After an intermessage gap equal to TRST, a valid legal command shall be sent to the UUT on a bus other than that used in Step 1.
      TestStep <= 6;
      MultiComdList.Command(0) <= (15, 0, 4, 1, 2, '0'); -- Receive SA4 to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn2, '1');
      WaitForLevel(BC1_Discretesout.OutEn2, '0');
      WaitForLevel(RT1_Discretesout.OutEn2, '1');
      WaitForLevel(RT1_Discretesout.OutEn2, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- Broadcast Dynamic Bus Control: 
    -- The purpose of this test is to verify that the UUT has the ability to recognize the broadcast dynamic bus control mode 
    -- command and to take control of the data bus. A valid legal broadcast dynamic bus control mode command shall be sent to the UUT. 
    -- The UUT shall take control of the data bus when its response is DBA as required in the UUT’s design specification.
    -- The pass criteria shall be that the UUT responds with a DBA upon acceptance of bus control or a CS upon rejection of bus control. 
    -- Step 1. A broadcast dynamic bus control mode command shall be sent to the UUT.
    -- Step 2. A transmit status mode command shall be sent to the UUT.
    -- Since the CORE does not implement DBC, the response shall be a CS.
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "----------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111_5_2_2_4_8: STEP 8 - Broadcast Dynamic Bus Control.  ", ALWAYS);
    Log(Manager1Id, "----------------------------------------------------------------", ALWAYS);
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
      MultiComdList.Command(0) <= (31, 1, ModeCode, txMC_DBC, 1, '0'); -- MODE:Broadcast Dynamic bus control command to RT1 on bus 1
      wait for 0 ns;
      MultiCmdWord := getCmdWord(MultiComdList.Command(0));
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Sending Broadcast Terminal flag inhibit Mode Command: " & to_hstring(MultiCmdWord), ALWAYS);
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Done sending Broadcast Terminal flag inhibit Mode Command", ALWAYS);
      wait for tGap;
      checkNoAction(MultiComdList);
      ----------------------------------------------------------------------------------------------------
      MultiComdList.Command(0) <= (15, 1, ModeCode, txMC_TransmitStatus, 1, '0'); -- MODE: transmit status to RT1 on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitBrdcstRxed or bitMessageError); -- check for SRB
      wait for tGap;
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
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_4_BroadcastModeCommands of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_2_4_BroadcastModeCommands);
    end for;
  end for;
end configuration;
