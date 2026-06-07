--
-- VHDL Architecture mil1553_tb.osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_3_ErrorInjection
-- Error Injection: 
-- The purpose of these tests is to examine the UUT’s response to specific errors in the message stream. 
-- Unless otherwise noted, the following test sequence shall be used for all error injection tests. 
-- The error to be encoded in Step 2 for a given message is specified in each test paragraph.
-- Test sequence:
-- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be
-- Step 2. A legal message containing the specified error shall be sent to the UUT.
-- Step 3. A transmit status mode command shall be sent to the UUT.    
-- The pass criteria is defined in each test paragraph.all commands and responses shall be recorded.
-- #################################################################################################################
architecture AS4111A_5_2_1_3_ErrorInjection of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("AS4111A_5_2_1_3_ErrorInjection");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("------------------------------", ALWAYS);
    Log("------------------------------", ALWAYS);
    Log("AS4111A_5_2_1_3_ErrorInjection", ALWAYS);
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_1_3_ErrorInjection.txt");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 sec);
    AlertIf(now >= 100 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports(ExternalErrors => (FAILURE => 0, ERROR => -1, WARNING => 0));  
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
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "--------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting BC side for Test AS4111A_5_2_1_3 Error Injection", ALWAYS);
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
    --   5.2.1.3.1 Parity: 
    --   The purpose of these tests is to verify the UUT’s capability of detecting parity errors embedded in different 
    --   words within a message. 
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.1.1 Transmit Command Word: 
    -- This test verifies the ability of the UUT to detect a parity error occurring in a transmit command word. 
    -- The test sequence as defined in 5.2.1.3 shall be performed with a parity error encoded into a transmit 
    -- command word for test Step 2.
    -- The pass criteria for this test shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - CS.
    ----------------------------------------------------------------------------------------------------
    TransmitCommandWordTest: loop
      Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.1.1 Transmit Command Word Parity error  ", ALWAYS);
      Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
      TestStep <= 1;
      --                                  RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      Step1Command := MultiComdList.Command(0);
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. A legal message containing a parity error in the transmit command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit command 
      MultiComdList.ErrInj <= errParity;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatusCmd(Step1Command);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      exit;
    end loop;
    ----------------------------------------------------------------------------------------------------
    --  5.2.1.3.1.2 Receive Command Word: 
    --  This test verifies the ability of the UUT to recognize a parity error occurring in a receive command word. 
    --  The test sequence as defined in 5.2.1.3 shall be performed with a parity error encoded in a receive command 
    --  word for test Step 2.
    -- The pass criteria for this test shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - CS.
    ----------------------------------------------------------------------------------------------------
    ReceiveCommandWordTest: loop
      Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.1.2 Receive Command Word                ", ALWAYS);
      Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
      TestStep <= 1;
      --                                  RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      Step1Command := MultiComdList.Command(0);
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. A legal message containing a parity error in the receive command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive command
      MultiComdList.ErrInj <= errParity;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      -- note that we check here for a CS + ME since after the parity error, the decoder will start decoding the next word transmited 
      -- by the BC, which is now out of sync data bits, causing the decoder error and thus ME flag set.
      -- In the waveforms it is clear that the parity erro on its own does not cause the ME flag, but the following out of sync data word does.
      checkClearStatusCmd(Step1Command);
      wait for tGap;
      exit;
    end loop;
    ----------------------------------------------------------------------------------------------------
    --  5.2.1.3.1.3 Receive Data Words: 
    -- This test verifies the ability of UUT to recognize a parity error occurring in a data word. 
    -- The test sequence as defined in 5.2.1.3 shall be performed with a parity error encoded in a 
    -- data word for test Step 2. The message shall be a receive command with the maximum number of
    -- data words that the UUT is designed to receive. The test sequence must be sent N times, where N 
    -- equals the number of data words sent. Individually each data word must have the parity bit inverted. 
    -- Only one parity error is allowed per message.
    -- The pass criteria for this test shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - ME.
    -- ----------------------------------------------------------------------------------------------------
    ReceiveDataWordsTest: loop
      Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.1.3 Receive Data Words.                 ", ALWAYS);
      Log(Manager1Id, "------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      for dataWordNum in 1 to 32 loop
        Log(Manager1Id, "Configuring to inject error in data word number " & to_string(dataWordNum), ALWAYS);
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        ----------------------------------------------------------------------------------------------------
        -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
        -- Step 2. A legal message containing a parity error in the receive command word shall be sent to the UUT.
        TestStep <= 2;
        --                                  RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 1, '0'); -- receive command
        MultiComdList.ErrInj <= errParity;
        MultiComdList.ErrWrd <= dataWordNum; -- error in data word
        MultiComdList.ErrBit <= 0;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        -- wait for Bc to start and complete sending broadcast command
        WaitForLevel(BC1_Discretesout.OutEn1, '1');
        WaitForLevel(BC1_Discretesout.OutEn1, '0');
        checkNRP(MultiComdList);
        wait for tGap;
        ----------------------------------------------------------------------------------------------------
        -- Step 3. A transmit status mode command shall be sent to the UUT.
        TestStep <= 3;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
        MultiComdList.Length <= 1;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        WaitForLevel(BC1_Discretesout.OutEn1, '1');
        WaitForLevel(BC1_Discretesout.OutEn1, '0');
        WaitForLevel(RT1_Discretesout.OutEn1, '1');
        WaitForLevel(RT1_Discretesout.OutEn1, '0');
        checkClearStatus_selected(MultiComdList, bitMessageError);
        wait for tGap;
      end loop;
      exit;
    end loop;
    ----------------------------------------------------------------------------------------------------
    --   5.2.1.3.2 Word Length: 
    -- This test verifies the ability of the UUT to recognize an error in word length occurring within a message. 
    -- The test plan excludes testing of high bit errors on a transmit command and on the last data word of a receive message.    
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.2.1 Transmit Command Word: 
    -- This test verifies the ability of the UUT to recognize transmit command word length errors. 
    -- The test sequence as defined in 5.2.1.3 shall be performed with the command word shortened as defined below for test Step 2.
    -- a. Transmit command shortened by one bit
    -- b. Transmit command shortened by two bits
    -- The pass criteria for this test shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - CS.
    ----------------------------------------------------------------------------------------------------
    TransmitCommandWordLengthNeg1bitTest: loop
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.2.1 Transmit Command Word length error (-1 bit)  ", ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a parity error in the transmit command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit command 
      MultiComdList.ErrInj <= errWordLength;
      MultiComdList.ErrWrd <= 0; -- means command word
      MultiComdList.ErrBit <= - 1; -- means shorten by 1 bit
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      exit;
    end loop;
    ----------------------------------------------------------------------------------------------------
    TransmitCommandWordLengthNeg2bitTest: loop
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.2.1 Transmit Command Word length error (-2 bit)  ", ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a parity error in the transmit command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit command 
      MultiComdList.ErrInj <= errWordLength;
      MultiComdList.ErrWrd <= 0; -- means command word
      MultiComdList.ErrBit <= - 2; -- means shorten by 2 bits
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      exit;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.2.2 Receive Command Word:
    -- This test verifies the ability of the UUT to recognize receive command word length errors. 
    -- The test sequence as defined in 5.2.1.3 shall be performed with the command word as defined below for test Step 2.
    -- a. Shorten the receive command word by one bit
    -- b. Shorten the receive command word by two bits
    -- c. Lengthen the receive command word by two bits
    -- d. Lengthen the receive command word by three bits
    -- The pass criteria for this test shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - CS, 
    -- or alternately for c and d only, the pass criteria may be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - ME.
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111 5.2.1.3.2.2 Receive Command Word length error (-1 bit)  ", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
    -- Step 2. A legal message containing a length error in the receive command word shall be sent to the UUT.
    TestStep <= 2;
    --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive command
    MultiComdList.ErrInj <= errWordLength;
    MultiComdList.ErrWrd <= 0; -- means command word
    MultiComdList.ErrBit <= - 1; -- means shorten by 1 bit
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    -- wait for Bc to start and complete sending broadcast command
    WaitForLevel(BC1_Discretesout.OutEn1, '1');
    WaitForLevel(BC1_Discretesout.OutEn1, '0');
    checkNRP(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    -- Step 3. A transmit status mode command shall be sent to the UUT.
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
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
    ReceiveCommandWordLengthNeg2bitTest: loop
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.2.2 Receive Command Word length error (-2 bit)  ", ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a length error in the transmit command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive command 
      MultiComdList.ErrInj <= errWordLength;
      MultiComdList.ErrWrd <= 0; -- means command word
      MultiComdList.ErrBit <= - 2; -- means shorten by 2 bits
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus(MultiComdList);
      wait for tGap;
      exit;
    end loop;
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111 5.2.1.3.2.2 Receive Command Word length error (+2 bit)  ", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
    -- Step 2. A legal message containing a length error in the transmit command word shall be sent to the UUT.
    TestStep <= 2;
    --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive command 
    MultiComdList.ErrInj <= errWordLength;
    MultiComdList.ErrWrd <= 0; -- means command word
    MultiComdList.ErrBit <= 2; -- means extend by 2 bits
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    -- wait for Bc to start and complete sending broadcast command
    WaitForLevel(BC1_Discretesout.OutEn1, '1');
    WaitForLevel(BC1_Discretesout.OutEn1, '0');
    checkNRP(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    -- Step 3. A transmit status mode command shall be sent to the UUT.
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
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
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111 5.2.1.3.2.2 Receive Command Word length error (+3 bit)  ", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
    -- Step 2. A legal message containing a length error in the transmit command word shall be sent to the UUT.
    TestStep <= 2;
    --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '0'); -- receive command 
    MultiComdList.ErrInj <= errWordLength;
    MultiComdList.ErrWrd <= 0; -- means command word
    MultiComdList.ErrBit <= 3; -- means extend by 3 bits
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    -- wait for Bc to start and complete sending broadcast command
    WaitForLevel(BC1_Discretesout.OutEn1, '1');
    WaitForLevel(BC1_Discretesout.OutEn1, '0');
    checkNRP(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    -- Step 3. A transmit status mode command shall be sent to the UUT.
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
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

    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.2.3 Receive Data Words:
    -- This test verifies the ability of the UUT to recognize data word length errors. 
    -- The test sequence as defined in 5.2.1.3 shall be performed as defined below for test Step 2. 
    -- The message shall be a receive command with the maximum number of data words that the UUT is designed to receive.
    -- a. Shorten the data word by one bit
    -- b. Shorten the data word by two bits
    -- c. Lengthen the data word by two bits
    -- d. Lengthen the data word by three bits
    -- The test sequence of 5.2.1.3 shall be performed N times for a and b and N-1 times for c and
    -- d, where N equals the number of data words sent. High bit errors shall not be tested in the
    -- last data word of a receive message. Only one data word shall be altered at a time. Steps a
    -- through d shall be performed for each applicable data word in the message.
    -- The pass criteria for this test shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR;
    -- Step 3 - ME.    
    ----------------------------------------------------------------------------------------------------
    for dataWordNum in 1 to 32 loop
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.2.3 Receive Data Words length error (-1 bit) Word= " & to_string(dataWordNum), ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a length error in the receive data words shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 1, '0'); -- receive command
      MultiComdList.ErrInj <= errWordLength;
      MultiComdList.ErrWrd <= dataWordNum; -- means data word
      MultiComdList.ErrBit <= - 1; -- means shorten by 1 bit
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitMessageError);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      ReceiveDataWordLengthNeg2bitTest: loop
        Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
        Log(Manager1Id, "Test AS4111 5.2.1.3.2.2 Receive Data Words length error (-2 bit) Word= " & to_string(dataWordNum), ALWAYS);
        Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
        wait for 0 ns;
        Toggle(MON1);
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 1;
        MultiComdList.RepeatRate <= 0;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        ----------------------------------------------------------------------------------------------------
        -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
        -- Step 2. A legal message containing a length error in the transmit command word shall be sent to the UUT.
        TestStep <= 2;
        --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 1, '0'); -- receive command
        MultiComdList.ErrInj <= errWordLength;
        MultiComdList.ErrWrd <= dataWordNum; -- means data word
        MultiComdList.ErrBit <= - 2; -- means shorten by 2 bits
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        -- wait for Bc to start and complete sending broadcast command
        WaitForLevel(BC1_Discretesout.OutEn1, '1');
        WaitForLevel(BC1_Discretesout.OutEn1, '0');
        checkNRP(MultiComdList);
        wait for tGap;
        ----------------------------------------------------------------------------------------------------
        -- Step 3. A transmit status mode command shall be sent to the UUT.
        TestStep <= 3;
        --                          RA TnR SA Len Bus RT2RT
        MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
        MultiComdList.Length <= 1;
        MultiComdList.ErrInj <= errNone;
        MultiComdList.ErrWrd <= 0;
        MultiComdList.ErrBit <= 0;
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        wait for 100 ns;
        WaitForLevel(BC1_Discretesout.OutEn1, '1');
        WaitForLevel(BC1_Discretesout.OutEn1, '0');
        WaitForLevel(RT1_Discretesout.OutEn1, '1');
        WaitForLevel(RT1_Discretesout.OutEn1, '0');
        checkClearStatus_selected(MultiComdList, bitMessageError);
        wait for tGap;
        exit;
      end loop;
      ----------------------------------------------------------------------------------------------------
      -- AS4111A specifies the lengthened data word cases (c and d) as N-1 tests,
      -- so skip the final data word. The shortened cases above still run for all N words.
      if (dataWordNum < 32) then
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.2.2 Receive Data Words length error (+2 bit) Word= " & to_string(dataWordNum), ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a length error in the transmit command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 1, '0'); -- transmit command 
      MultiComdList.ErrInj <= errWordLength;
      MultiComdList.ErrWrd <= dataWordNum; -- means data word
      MultiComdList.ErrBit <= 2; -- means extend by 2 bits
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitMessageError);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.2.2 Receive Command Word length error (+3 bit) Word= " & to_string(dataWordNum), ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a length error in the transmit command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR ModeCode  ModeCmd          Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 0, 1, '0'); -- transmit command 
      MultiComdList.ErrInj <= errWordLength;
      MultiComdList.ErrWrd <= dataWordNum; -- means data word
      MultiComdList.ErrBit <= 3; -- means extend by 3 bits
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode command shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitMessageError);
      wait for tGap;
      end if;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.5 Message Length: These tests shall verify that the UUT properly detects an error when an
    -- incorrect number of data words is received.
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.5.1 Transmit Command: 
    -- This test verifies the ability of the UUT to respond properly if the data word is contiguous to a 
    -- transmit command word. Perform the test sequence as defined in 5.2.1.3 with a data word contiguously 
    -- following a transmit command word for test Step 2. This means, the BC send a transmit command, but 
    -- then immediately sends a data word without any gap. 
    -- The pass criteria for this test shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - ME.   
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111 5.2.1.3.5.1 Transmit Command Word contiguous data error ", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
    -- Step 2. A legal message containing a length error in the transmit command word shall be sent to the UUT.
    -- The BC encoder has an error injection for this test.
    TestStep <= 2;
    --                                  RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 1, 2, 1, '0'); -- transmit command 
    MultiComdList.ErrInj <= errTxCmdContiguousData;
    MultiComdList.ErrWrd <= 1;
    MultiComdList.ErrBit <= 0;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    -- wait for Bc to start and complete sending broadcast command
    WaitForLevel(BC1_Discretesout.OutEn1, '1');
    WaitForLevel(BC1_Discretesout.OutEn1, '0');
    checkNRP(MultiComdList);
    wait for tGap;
    Write(RT1_cpu_bus, reg_tmr_REP, x"0195"); -- restore the RT 1 REP timer
    ----------------------------------------------------------------------------------------------------
    -- Step 3. A transmit status mode command shall be sent to the UUT.
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_Discretesout.OutEn1, '1');
    WaitForLevel(BC1_Discretesout.OutEn1, '0');
    WaitForLevel(RT1_Discretesout.OutEn1, '1');
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    checkClearStatus_selected(MultiComdList, bitMessageError);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    --for dataWordNum in 32 downto 1 loop
    for dataWordNum in 1 downto 32 loop
      if (dataWordNum = 32) then
        NumWords := 0;
      else
        NumWords := dataWordNum;
      end if;
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.5.2 Receive Message Word length error Word= " & to_string(dataWordNum), ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
      TestStep <= 1;
      --                                  RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, NumWords, 1, '0'); -- receive on bus 1
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
      WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
      checkClearStatus(MultiComdList);
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 2. A legal message containing a word length error in the receive command word shall be sent to the UUT.
      TestStep <= 2;
      --                                  RA TnR SA  Len     Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, NumWords, 1, '0'); -- receive command 
      MultiComdList.ErrInj <= errNumWordLen; -- this will increase sent length by 1 word.
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode commasnd shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitMessageError);
      wait for tGap;
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.5.3 Mode Command Word Count Error: 
    -- This test verifies the ability of the UUT to respond properly when an incorrect number of words 
    -- is sent with a mode command. 
    -- Case 1: Perform the test sequence defined in 5.2.1.3 using a valid receive mode command in Step 2 which 
    -- would normally have an associated data word transmitted with it, but send the number of data words 
    -- equal to the mode code value used. 
    -- Case 2: Repeat the test sequence with the same mode command but with no data word in Step 2. 
    -- Case 3: Repeat the test sequence using a valid transmit mode command except send a data word contiguously following the command word.
    -- In all three cases the pass criteria shall be: 
    -- Step 1 - CS; 
    -- Step 2 - NR; 
    -- Step 3 - ME.   
    ----------------------------------------------------------------------------------------------------
    for dataWordNum in 1 to 16 loop
      -- Set ModeCode based on dataWordNum for receive mode commands
      case dataWordNum is
        when 1 => ModeCode := 16;
        when 2 => ModeCode := 17;
        when 3 => ModeCode := 18;
        when 4 => ModeCode := 19;
        when 5 => ModeCode := 20;
        when 6 => ModeCode := 21;
        when 7 => ModeCode := 22;
        when 8 => ModeCode := 23;
        when 9 => ModeCode := 24;
        when 10 => ModeCode := 25;
        when 11 => ModeCode := 26;
        when 12 => ModeCode := 27;
        when 13 => ModeCode := 28;
        when 14 => ModeCode := 29;
        when 15 => ModeCode := 30;
        when 16 => ModeCode := 31;
      end case;
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.5.3 Mode Command Word Count Error: Case 1: ModeCode= " & to_string(ModeCode), ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a word length error in the receive command word shall be sent to the UUT.
      TestStep <= 2;
      wait for 0 ns;
      --                                  RA TnR SA  Len     Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 0, ModeCode, 1, '0'); -- receive command 
      MultiComdList.ErrInj <= errNumWordLen; -- this will send the number of words indicated by the command mode code
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode commasnd shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitMessageError);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.5.3 Mode Command Word Count Error: Case 2: ModeCode= " & to_string(ModeCode), ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a word length error in the receive command word shall be sent to the UUT.
      TestStep <= 2;
      wait for 0 ns;
      --                                  RA TnR SA  Len     Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 0, 0, ModeCode, 1, '0'); -- receive command 
      MultiComdList.ErrInj <= errNoModeData; -- this will not send a data word as indicated by the command mode code
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode commasnd shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitMessageError);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      Log(Manager1Id, "Test AS4111 5.2.1.3.5.3 Mode Command Word Count Error: Case 3: ModeCode= " & to_string(ModeCode), ALWAYS);
      Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
      wait for 0 ns;
      Toggle(MON1);
      MultiComdList.StartAddr <= 0;
      MultiComdList.Length <= 1;
      MultiComdList.RepeatRate <= 0;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      ----------------------------------------------------------------------------------------------------
      -- Step 1. A valid legal message shall be sent to the UUT. A mode command shall not be used for this step.
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
      -- Step 2. A legal message containing a word length error in the receive command word shall be sent to the UUT.
      TestStep <= 2;
      wait for 0 ns;
      --                                  RA TnR SA  Len     Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, ModeCode, 1, '0'); -- receive command
      MultiComdList.ErrInj <= errTxModeData; -- this will  send a data word for a tx mode command (incorrectly, the RT should be sending the data word)
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      -- wait for Bc to start and complete sending broadcast command
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      checkNRP(MultiComdList);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
      -- Step 3. A transmit status mode commasnd shall be sent to the UUT.
      TestStep <= 3;
      --                          RA TnR SA Len Bus RT2RT
      MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
      MultiComdList.Length <= 1;
      MultiComdList.ErrInj <= errNone;
      MultiComdList.ErrWrd <= 0;
      MultiComdList.ErrBit <= 0;
      wait for 0 ns;
      BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
      wait for 100 ns;
      WaitForLevel(BC1_Discretesout.OutEn1, '1');
      WaitForLevel(BC1_Discretesout.OutEn1, '0');
      WaitForLevel(RT1_Discretesout.OutEn1, '1');
      WaitForLevel(RT1_Discretesout.OutEn1, '0');
      checkClearStatus_selected(MultiComdList, bitMessageError);
      wait for tGap;
      ----------------------------------------------------------------------------------------------------
    end loop;
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    -- 5.2.1.3.5.3 RT to RT Word Count Error: 
    -- This test verifies the ability of the UUT to respond properly when an incorrect number of words is sent 
    -- to it as a receiving RT during an RT to RT transfer. Perform the following test sequence. 
    -- Step 1 Send a valid legal RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid status word 
    -- and N data words to the UUT, where N is the number of data words requested in the transmit command.
    -- Step 2 Send the same RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid status word and N-1 data words.
    -- Step 3 A transmit status mode command shall be sent to the receiving RT.
    -- Step 4 (Case 2) Repeat Steps 1 through 3 using a word count of N+1 in Step 2.
    -- The pass criteria in both cases shall be that the receiving RT’s status is: 
    -- Step 1 - CS;
    -- Step 2 - NR; 
    -- Step 3 - ME.    
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111 5.2.1.3.5.4 RT to RT Word Count Error: Case 1: -1 word count", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    -- Step 1 Send a valid legal RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid status word 
    -- and N data words to the UUT, where N is the number of data words requested in the transmit command.    
    TestStep <= 1;
    --                                  RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '1');
    MultiComdList.Command(1) <= (MyRtAddr2, 1, 1, 2, 1, '0');
    MultiComdList.Length <= 2;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT2_DiscretesOut.OutEn1, '1');
    checkClearStatusRT2RT(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    -- Step 2 Send the same RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid status word and N-1 data words.
    TestStep <= 2;
    wait for 0 ns;
    --                                 RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 3, 1, '1');
    MultiComdList.Command(1) <= (MyRtAddr2, 1, 1, 3, 1, '0');
    MultiComdList.Length <= 2;
    MultiComdList.ErrInj <= errRT2RTWrdCnt; -- the transmitting RT must inject an error in the outgoing number of data words
    MultiComdList.ErrWrd <= 1; -- 1 is encoded as one word less than the command word count and 2 is encoded as 1 word more than the command word count
    MultiComdList.ErrBit <= 0;
    wait for 0 ns;
    -- The injection of the RT error is not handled by the BC_MULTICMD so we need to write the injection register directly for RT2    -- v4p formatting off
    Write(RT2_cpu_bus, reg_err_inj_data,
          std_logic_vector(to_unsigned(MultiComdList.ErrWrd, 6)) & 
          std_logic_vector(to_unsigned(MultiComdList.ErrBit, 6)) & 
          std_logic_vector(to_unsigned(MultiComdList.ErrInj, 4)));
    -- v4p formatting on
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT2_DiscretesOut.OutEn1, '1');
    checkClearStatusTxn(MultiComdList, 1); -- check the status of the transmitting RT
    WaitForLevel(RT2_DiscretesOut.OutEn1, '0');
    checkNRPn(MultiComdList, 1);
    wait for tGap;
    -- The injection of the RT error is not handled by the BC_MULTICMD so we need to clear the injection register directly for RT2
    Write(RT2_cpu_bus, reg_err_inj_data, X"0000");
    ----------------------------------------------------------------------------------------------------
    -- Step 3 A transmit status mode command shall be sent to the receiving RT.
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_Discretesout.OutEn1, '1');
    WaitForLevel(BC1_Discretesout.OutEn1, '0');
    WaitForLevel(RT1_Discretesout.OutEn1, '1');
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    checkClearStatus_selected(MultiComdList, bitMessageError);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Test AS4111 5.2.1.3.5.4 RT to RT Word Count Error: Case 2: +1 word count", ALWAYS);
    Log(Manager1Id, "--------------------------------------------------------------------", ALWAYS);
    wait for 0 ns;
    Toggle(MON1);
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 1;
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    ----------------------------------------------------------------------------------------------------
    -- Step 1 Send a valid legal RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid status word 
    -- and N data words to the UUT, where N is the number of data words requested in the transmit command.    
    TestStep <= 1;
    --                                  RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 2, 1, '1');
    MultiComdList.Command(1) <= (MyRtAddr2, 1, 1, 2, 1, '0');
    MultiComdList.Length <= 2;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT2_DiscretesOut.OutEn1, '1');
    checkClearStatusRT2RT(MultiComdList);
    wait for tGap;
    ----------------------------------------------------------------------------------------------------
    -- Step 2 Send the same RT to RT command pair followed in 4.0 µs to 12.0 µs by a valid status word and N-1 data words.
    TestStep <= 2;
    wait for 0 ns;
    --                                 RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 0, 1, 3, 1, '1');
    MultiComdList.Command(1) <= (MyRtAddr2, 1, 1, 3, 1, '0');
    MultiComdList.Length <= 2;
    MultiComdList.ErrInj <= errRT2RTWrdCnt; -- the transmitting RT must inject an error in the outgoing number of data words
    MultiComdList.ErrWrd <= 2; -- 1 is encoded as one word less than the command word count and 2 is encoded as 1 word more than the command word count
    MultiComdList.ErrBit <= 0;
    wait for 0 ns;
    -- The injection of the RT error is not handled by the BC_MULTICMD so we need to write the injection register directly for RT2    -- v4p formatting off
    Write(RT2_cpu_bus, reg_err_inj_data,
          std_logic_vector(to_unsigned(MultiComdList.ErrWrd, 6)) & 
          std_logic_vector(to_unsigned(MultiComdList.ErrBit, 6)) & 
          std_logic_vector(to_unsigned(MultiComdList.ErrInj, 4)));
    -- v4p formatting on
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_DiscretesOut.OutEn1, '1');
    WaitForLevel(BC1_DiscretesOut.OutEn1, '0');
    WaitForLevel(RT2_DiscretesOut.OutEn1, '1');
    checkClearStatusTxn(MultiComdList, 1);
    WaitForLevel(RT2_DiscretesOut.OutEn1, '0');
    checkNRPn(MultiComdList, 1);
    wait for tGap;
    -- The injection of the RT error is not handled by the BC_MULTICMD so we need to clear the injection register directly for RT2
    Write(RT2_cpu_bus, reg_err_inj_data, X"0000");
    ----------------------------------------------------------------------------------------------------
    -- Step 3 A transmit status mode command shall be sent to the receiving RT.
    TestStep <= 3;
    --                          RA TnR SA Len Bus RT2RT
    MultiComdList.Command(0) <= (MyRtAddr1, 1, 0, txMC_TransmitStatus, 1, '0'); -- MODE: transmit last command on bus 1 
    MultiComdList.Length <= 1;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    wait for 100 ns;
    WaitForLevel(BC1_Discretesout.OutEn1, '1');
    WaitForLevel(BC1_Discretesout.OutEn1, '0');
    WaitForLevel(RT1_Discretesout.OutEn1, '1');
    WaitForLevel(RT1_Discretesout.OutEn1, '0');
    checkClearStatus_selected(MultiComdList, bitMessageError);
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
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_3_ErrorInjection of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_1_3_ErrorInjection);
    end for;
  end for;
end configuration;
