--
-- VHDL Architecture mil1553_tb.AS4111A_5_2_1_2_1_InterMsgGap
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
architecture AS4111A_5_2_1_2_1_InterMsgGap of osvvm_Mil1553_dualbus_testctrl is
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
  signal BC_Done       : bit                           := '0';
  signal BC_Check_Done : std_logic                     := '0';
  signal BC_NextCmd    : std_logic                     := '0';
  signal RT1_Done      : std_logic                     := '0';
  signal RT2_Done      : std_logic                     := '0';
  signal BC_Exit       : std_logic                     := '0';
  signal BC_Check_Exit : std_logic                     := '0';
  signal DataWord      : std_logic_vector(15 downto 0) := X"A5A5"; -- Data word to send
  signal MultiComdList : MultiCommandRec_type;

  constant repRegValue : std_logic_vector(15 downto 0) := x"00BC"; -- Response timer value
  constant gapRegValue : std_logic_vector(15 downto 0) := x"00A7"; -- Intermessage gap timer value

  -- #################################################################################################################
  -- Define command pair types and array to hold them
  type MessagePairType is record
    cmd1, cmd2        : Command_type;   -- Using the Command_type from MultiCommandRec_type
    expected_response : string(1 to 5); -- "CS,CS" or "NR,CS"
  end record;
  type MessagePairArray is array (1 to 12) of MessagePairType;
  -- Define all message pairs from Table 2
  constant MSG_PAIRS : MessagePairArray := (
    -- Pairs 1-7 (CS,CS response expected)
    --  type Command_type is record
    --     RtAddr  : integer;
    --     TxnRx   : integer;
    --     SubAddr : integer;
    --     Len     : integer;
    --     MilBus  : integer;
    --     Rt2RT   : std_logic;
    --  end record;
    1  => (cmd1              => (15, 0, 1, 0, 1, '0'), -- Message A
          cmd2              => (15, 0, 2, 0, 1, '0'), -- Message A
          expected_response => "CS,CS"),

    2  => (cmd1              => (15, 1, 1, 0, 1, '0'), -- Message B
          cmd2              => (15, 0, 3, 0, 1, '0'), -- Message A
          expected_response => "CS,CS"),

    3  => (cmd1              => (15, 0, 1, 0, 1, '1'), -- Message C
          cmd2              => (16, 1, 1, 0, 1, '0'), -- Message A
          expected_response => "CS,CS"),

    4  => (cmd1              => (16, 0, 1, 0, 1, '1'), -- Message D
          cmd2              => (15, 1, 1, 0, 1, '0'), -- Message A
          expected_response => "CS,CS"),

    5  => (cmd1              => (15, 1, 0, 0, 1, '0'), -- Message E (DBC request)
          cmd2              => (15, 0, 6, 0, 1, '0'), -- Message A
          expected_response => "CS,CS"),

    6  => (cmd1              => (15, 1, 0, 18, 1, '0'), -- Message F (Transmit last command word)
          cmd2              => (15, 0, 7, 0, 1, '0'),  -- Message A
          expected_response => "CS,CS"),

    7  => (cmd1              => (15, 0, 0, 17, 1, '0'), -- Message G (Synchronise with data word)
          cmd2              => (15, 0, 8, 0, 1, '0'),  -- Message A
          expected_response => "CS,CS"),

    -- Pairs 8-12 (NR,CS response expected)
    8  => (cmd1              => (31, 0, 1, 0, 1, '0'), -- Message H
          cmd2              => (15, 0, 9, 0, 1, '0'), -- Message A
          expected_response => "NR,CS"),

    9  => (cmd1              => (31, 0, 1, 0, 1, '1'), -- Message I
          cmd2              => (16, 1, 1, 0, 1, '0'), -- Message A
          expected_response => "NR,CS"),

    10 => (cmd1              => (31, 0, 1, 0, 1, '1'), -- Message J
           cmd2              => (15, 1, 1, 0, 1, '0'), -- Message A
           expected_response => "NR,CS"),

    11 => (cmd1              => (31, 1, 0, 1, 1, '0'), -- Message K
           cmd2              => (15, 0, 1, 0, 1, '0'), -- Message A
           expected_response => "NR,CS"),

    12 => (cmd1              => (31, 0, 0, 17, 1, '0'), -- Message L
           cmd2              => (15, 0, 1, 0, 1, '0'),  -- Message A
           expected_response => "NR,CS")
  );

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
    variable ControlDebug : boolean := FALSE;
  begin
    SetTestName("AS4111A_5_2_1_2_1_InterMsgGap");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, ControlDebug);
    -- SetLogEnable()
    Log("-----------------------------", DEBUG);
    Log("-----------------------------", ALWAYS);
    Log("AS4111A_5_2_1_2_1_InterMsgGap", ALWAYS);
    Log("-----------------------------", ALWAYS);
    Log("-----------------------------", DEBUG);
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
    SetLogEnable(BCID, DEBUG, ControlDebug);
    SetLogEnable(BCIDCHECK, DEBUG, ControlDebug);
    SetLogEnable(RT1ID, DEBUG, ControlDebug);
    SetLogEnable(RT2ID, DEBUG, ControlDebug);
    SetLogEnable(RT2ID, PASSED, FALSE);
    SetLogEnable(RT1ID, PASSED, FALSE);
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_1_2_1_InterMsgGap.txt");
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
    variable TempSubaddr : integer := 1;
    variable TempRtAddr  : integer := 15;
    variable Step1Cmd    : std_logic_vector(15 downto 0);
    variable SubaddrRxed : std_logic_vector(31 downto 0);
    variable ReadData    : std_logic_vector(15 downto 0);
    variable NumTests    : integer := 10;
    -- Variables for test execution
    variable current_pair    : integer := 1;
    variable iteration_count : integer := 0;
    constant MIN_ITERATIONS : integer := 2;
    constant MIN_GAP_TIME   : time    := 4.0 us;
    variable test_results : std_logic_vector(1 to 12) := (others => '1'); -- Pass/Fail for each pair

    -- #################################################################################################################
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "----------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting Test AS4111A_5_2_1_2_1: Minimum Intermessage Gap ", ALWAYS);
    Log(Manager1Id, "----------------------------------------------------------", ALWAYS);
    Write(BC_cpu_bus, reg_rt_addr, X"0001"); -- Write the softwere RtAddr Register
    Write(BC_cpu_bus, reg_wrap_subaddr, X"001E"); -- Set the datawrap subaddress to 11110 (30)
    Write(BC_cpu_bus, reg_node_control, X"4000"); -- Set general RT control register
    Read(BC_cpu_bus, reg_fw_version, ReadData);
    log(Manager1Id, "BC MIL1553 core FW version is " & to_string(to_integer(unsigned(ReadData(15 downto 8)))) & "." & to_string(to_integer(unsigned(ReadData(7 downto 0)))), ALWAYS);
    Read(BC_cpu_bus, reg_node_control, ReadData);
    log(Manager1Id, "BC Node control is set to 0x" & to_hstring(ReadData), ALWAYS);
    -- read back and print the time values for tmr registers and print them in us. Every count is 10ns
    Write(BC_cpu_bus, reg_tmr_rep, repRegValue);
    Read(BC_cpu_bus, reg_tmr_rep, ReadData);
    log(Manager1Id, "BC Response Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Write(BC_cpu_bus, reg_tmr_gap, gapRegValue);
    Read(BC_cpu_bus, reg_tmr_gap, ReadData);
    log(Manager1Id, "BC Intermessage Gap Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Read(BC_cpu_bus, reg_tmr_nrp, ReadData);
    log(Manager1Id, "BC No Response Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Read(BC_cpu_bus, reg_tmr_saf, ReadData);
    log(Manager1Id, "BC Safety Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 500) & " us", ALWAYS);
    -- Calculate time values based on register settings 
    BC_done <= '0';
    BC_Check_Done <= '0';
    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrBit <= 0;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrInj <= errNone;
    wait for 100 ns;
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
    Log(Manager1Id, "------------------------------------------------------", DEBUG);
    Log(Manager1Id, "AS4111A_5_2_1_2_1_InterMsgGap ", DEBUG);
    Log(Manager1Id, "------------------------------------------------------", DEBUG);
    -- #################################################################################################################
    -- Test Explanation:
    -- Minimum Time: The purpose of this test is to verify that the UUT responds properly to valid
    -- legal messages with a minimum intermessage gap. Valid legal messages of the message
    -- pairs listed in Table 2 shall be sent to the UUT with the minimum intermessage gap time (T) of
    -- 4.0 µs as shown on Figure 7. Each message pair shall be sent to the UUT a minimum of 1,000
    -- times. Message pairs which include commands not implemented by the UUT shall be deleted
    -- from the test.
    -- The pass criteria shall be CS, CS for message pairs 1-7; and NR, CS for message pairs 8-12.
    -- All message pairs used shall be recorded and message pairs which cause the UUT to fail the
    -- test shall be indicated
    -- #################################################################################################################
    BC_done <= '0';
    -- Test execution loop
    for pair in 1 to 12 loop
      log(Manager1Id, "Testing Message Pair " & to_string(pair), ALWAYS);
      -- Execute each pair 1000 times
      for i in 1 to MIN_ITERATIONS loop
        -- Setup first command of the pair
        MultiComdList.Command(0) <= MSG_PAIRS(pair).cmd1;
        MultiComdList.Command(1) <= MSG_PAIRS(pair).cmd2;
        MultiComdList.StartAddr <= 0;
        MultiComdList.Length <= 2;
        -- Send first command and verify response
        wait for 0 ns;
        BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord,
                    BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP,
                    SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
        BC_done <= '1';
        wait for 100 ns;
        BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                       NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Exit, BCIDCHECK);
        wait for tGAP;
        BC_Exit <= '0';

        -- -- Verify responses match expected pattern
        -- if MSG_PAIRS(pair).expected_response = "CS,CS" then
        --   -- Verify both commands got "Command Sync" response
        --   -- Add your response verification logic here
        -- else -- "NR,CS"
        --   -- Verify first command got "No Response" and second got "Command Sync"
        --   -- Add your response verification logic here
        -- end if;
      end loop;
      wait for tGAP * 50; -- Wait before next iteration
    end loop;
    wait for tGAP;
    -- #################################################################################################################
    log(Manager1Id, "################### BC DONE ###################", DEBUG);
    BC_Check_Done <= '1';
    BC_Exit <= '1';
    wait for 100 ns;
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
  begin
    RT1ID := NewID("RT1");
    InitRT(RT1_cpu_bus, RT1_DiscretesIn, MyRtAddr1, RT1ID, "01111", '1');
    RT1_DiscretesIn.BitWord <= X"CCCC";
    RT1_DiscretesIn.ServiceReqVector <= X"DDDD";
    wait for 0 ns;
    Write(RT1_cpu_bus, reg_rt_addr, X"0001");
    Write(RT1_cpu_bus, reg_intr_mask, X"0003");
    Write(RT1_cpu_bus, reg_wrap_subaddr, X"001E"); -- Set the datawrap subaddress to 11110 (30)
    Write(RT1_cpu_bus, reg_node_control, X"4020");
    Read(RT1_cpu_bus, reg_fw_version, ReadData);
    log(RT1ID, "RT1 MIL1553 core FW version is " & to_string(to_integer(unsigned(ReadData(15 downto 8)))) & "." & to_string(to_integer(unsigned(ReadData(7 downto 0)))), ALWAYS);
    Read(RT1_cpu_bus, reg_node_control, ReadData);
    log(RT1ID, "RT1 Node control is set to 0x" & to_hstring(ReadData), ALWAYS);
    -- read back and print the time values for tmr registers and print them in us. Every count is 10ns
    Write(RT1_cpu_bus, reg_tmr_rep, repRegValue);
    Read(RT1_cpu_bus, reg_tmr_rep, ReadData);
    log(RT1ID, "RT1 Response Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Write(RT1_cpu_bus, reg_tmr_gap, gapRegValue);
    Read(RT1_cpu_bus, reg_tmr_gap, ReadData);
    log(RT1ID, "RT1 Intermessage Gap Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Read(RT1_cpu_bus, reg_tmr_nrp, ReadData);
    log(RT1ID, "RT1 No Response Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Read(RT1_cpu_bus, reg_tmr_saf, ReadData);
    log(RT1ID, "RT1 Safety Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 500) & " us", ALWAYS);
    ClearInterrupts(RT1_cpu_bus, 1, IrqMask, RT1ID);
    ClearInterrupts(RT1_cpu_bus, 2, IrqMask, RT1ID);
    loop
      if BC_Exit = '1' then
        exit;
      end if;
      wait until BC_Done = '1';
      while BC_Check_Done = '0' loop
        log(RT1ID, "#################################################################################################################", DEBUG);
        if BC_Exit = '1' then
          exit;
        end if;
        RT_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, RT1_cpu_bus, RT1_DiscretesOut, SB_RT1_CMD, SB_RT1_DAT, SB_RT2_CMD, SB_RT2_DAT, SB_BC, SB_RT2RT, NextCmdRT1, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT1_Done, BC_Exit, RT2RT_Busy, BC_Check_Exit, RT1ID);
        -- then clear the register
      end loop;
      if BC_Exit = '1' then
        exit;
      end if;
    end loop;
    log(RT1ID, "8 WaitForBarrier(TestDone)" & to_string(TestDone), ALWAYS);
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
    Write(RT2_cpu_bus, reg_node_control, X"4020");
    Read(RT2_cpu_bus, reg_fw_version, ReadData);
    log(RT2ID, "RT2 MIL1553 core FW version is " & to_string(to_integer(unsigned(ReadData(15 downto 8)))) & "." & to_string(to_integer(unsigned(ReadData(7 downto 0)))), ALWAYS);
    Read(RT2_cpu_bus, reg_node_control, ReadData);
    log(RT2ID, "RT2 Node control is set to 0x" & to_hstring(ReadData), ALWAYS);
    -- read back and print the time values for tmr registers and print them in us. Every count is 10ns
    Write(RT2_cpu_bus, reg_tmr_rep, repRegValue);
    Read(RT2_cpu_bus, reg_tmr_rep, ReadData);
    log(RT2ID, "RT2 Response Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Write(RT2_cpu_bus, reg_tmr_gap, gapRegValue);
    Read(RT2_cpu_bus, reg_tmr_gap, ReadData);
    log(RT2ID, "RT2 Intermessage Gap Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Read(RT2_cpu_bus, reg_tmr_nrp, ReadData);
    log(RT2ID, "RT2 No Response Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 10) & " ns", ALWAYS);
    Read(RT2_cpu_bus, reg_tmr_saf, ReadData);
    log(RT2ID, "RT2 Safety Timer is set to " & to_string((to_integer(unsigned(ReadData)) + 1) * 500) & " us", ALWAYS);
    ClearInterrupts(RT2_cpu_bus, 1, IrqMask, RT2ID);
    ClearInterrupts(RT2_cpu_bus, 2, IrqMask, RT2ID);
    loop
      if BC_Exit = '1' then
        exit;
      end if;
      wait until BC_Done = '1';
      while BC_Check_Done = '0' loop
        log(RT2ID, "#################################################################################################################", DEBUG);
        if BC_Exit = '1' then
          exit;
        end if;
        RT_MULTI_CHECK(MultiComdList, MyRtAddr2, MyRtAddr1, MyBcAddr, CmdWord, RT2_cpu_bus, RT2_DiscretesOut, SB_RT2_CMD, SB_RT2_DAT, SB_RT1_CMD, SB_RT1_DAT, SB_BC, SB_RT2RT, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT2_Done, BC_Exit, RT2RT_Busy, BC_Check_Exit, RT2ID);
        -- then clear the register
      end loop;
      if BC_Exit = '1' then
        exit;
      end if;
    end loop;
    log(RT2ID, "12 WaitForBarrier(TestDone)" & to_string(TestDone), ALWAYS);
    WaitForBarrier(TestDone);
  end process;

end architecture;
-- #################################################################################################################
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_2_1_InterMsgGap of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_1_2_1_InterMsgGap);
    end for;
  end for;
end configuration;
