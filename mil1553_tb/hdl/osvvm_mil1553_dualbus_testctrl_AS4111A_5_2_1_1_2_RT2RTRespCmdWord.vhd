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
architecture AS4111A_5_2_1_1_2_RT2RTRespCmdWord of osvvm_Mil1553_dualbus_testctrl is
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
    SetTestName("AS4111A_5_2_1_1_2_RT2RTRespCmdWord");
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
    Log("----------------------------------", ALWAYS);
    Log("----------------------------------", ALWAYS);
    Log("AS4111A_5_2_1_1_2_RT2RTRespCmdWord", ALWAYS);
    Log("----------------------------------", ALWAYS);
    Log("----------------------------------", ALWAYS);
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "AS4111A_5_2_1_1_2_RT2RTRespCmdWord.txt");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 200 sec);
    AlertIf(now >= 200 sec, "Test finished due to timeout");
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
    variable TempLen     : integer := 2;
    variable Step1Cmd    : std_logic_vector(15 downto 0);
    variable SubaddrRxed : std_logic_vector(31 downto 0);
    variable ReadData    : std_logic_vector(15 downto 0);
    variable NumTests    : integer := 2;
    -- #################################################################################################################
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    Manager1Id := NewID("BC", TbID);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "Starting Test AS4111A_5_2_1_1_2: RT2RT Resp Cmd Word", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Write(BC_cpu_bus, reg_rt_addr, X"0001"); -- Write the softwere RtAddr Register
    Write(BC_cpu_bus, reg_wrap_subaddr, X"001E"); -- Set the datawrap subaddress to 11110 (30)
    Write(BC_cpu_bus, reg_node_control, X"4000"); -- Set general RT control register
    Read(BC_cpu_bus, reg_fw_version, ReadData);
    log(Manager1Id, "BC MIL1553 core FW version is " & to_string(to_integer(unsigned(ReadData(15 downto 8)))) & "." & to_string(to_integer(unsigned(ReadData(7 downto 0)))), ALWAYS);
    Read(BC_cpu_bus, reg_node_control, ReadData);
    log(Manager1Id, "BC Node control is set to 0x" & to_hstring(ReadData), ALWAYS);
    BC_done <= '0';
    BC_Check_Done <= '0';
    MultiComdList.RepeatRate <= 0;
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
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    Log(Manager1Id, "AS4111A_5_2_1_1_2_RT2RTRespCmdWord ", ALWAYS);
    Log(Manager1Id, "------------------------------------------------------", ALWAYS);
    -- #################################################################################################################
    -- THIS LOOP DESIGN IS FOR FULL COVERAGE OF ALL BC TO RT RX COMMANDS, INCLUDING BROADCASTS
    -- #################################################################################################################
    for RtAddr1 in 0 to 31 loop
      for RtAddr in 0 to 30 loop -- loop through all RT address (transmitter cannot be broadcast address)
        log(Manager1Id, "RT RX " & to_string(RtAddr1) & " RT TX " & to_string(RtAddr));
        if (RtAddr1 = RtAddr) then -- Rx and Tx addresses cannot be the same
          Log(Manager1Id, "Skipping matching Addrs " & to_String(RtAddr1));
          exit;
        end if;

        for SubAddr in 1 to 30 loop -- loop through all the subaddresses (except the two mode commands of 00000 and 11111)
          for Length in 0 to 31 loop -- loop for all the length values
            wait for 100 ns;
            log(Manager1Id, "#################################################################################################################", DEBUG);
            -- note that a broadcast is not allowed with a RTtransmit command
            --add code to check the results from both RTs

            -- Be carefull of the sub addr used in command 0, because the data will be overwritten by the varaible command
            -- so make the valid command subaddress a function of the loop subaddres, add 1 to Subaddress and handle the wrap
            TempSubaddr := Subaddr + 1;
            if TempSubaddr = 31 then
              TempSubaddr := 1;
            end if;
            -- if the Rt address is either MyRtAddr1 or MyRtAddr2, then make the valid command to the same RT address 
            if (RtAddr = MyRtAddr1) or (RtAddr = MyRtAddr2) then
              TempRtAddr := RtAddr;
            else
              TempRtAddr := 15; -- make the valid command to RT 15
            end if;
            BC_done <= '0';
            -- compare the last received command to either step1 or step 2 depending on whether the addressed RT is on the network or not.
            if (RtAddr = MyRtAddr1) or (RtAddr = MyRtAddr2) or (RtAddr = 31) then
              -- the addressed RT is on the network so expect the command that was sent to it
              Step1Cmd := std_logic_vector(to_unsigned(RtAddr, 5)) & '1' & std_logic_vector(to_unsigned(SubAddr, 5)) & std_logic_vector(to_unsigned(Length, 5));
              wait for 0 ns;
            else
              -- the addressed RT is not on the network so expect the command from Step1
              Step1Cmd := std_logic_vector(to_unsigned(TempRtAddr, 5)) & '0' & std_logic_vector(to_unsigned(TempSubAddr, 5)) & std_logic_vector(to_unsigned(TempLen, 5));
            end if;
            log(Manager1Id, "Expected Command Word = " & to_hstring(Step1Cmd), DEBUG);
            wait for 0 ns;
            MultiComdList.ErrBit <= 0;
            MultiComdList.ErrWrd <= 0;
            MultiComdList.ErrInj <= errNone;
              -- v4p formatting off
              --                           RA        TnR     SA        Len    Bus RT2RT
              MultiComdList.Command(0) <= (TempRtAddr, 0, TempSubaddr, TempLen                  , 1, '0'); -- Valid receive to RT1
              MultiComdList.Command(1) <= (RtAddr1   , 0, SubAddr    , Length                   , 1, '1'); -- Variable test command
              MultiComdList.Command(2) <= (RtAddr    , 1, SubAddr    , Length                   , 1, '0'); -- Variable test command
              MultiComdList.Command(3) <= (TempRtAddr, 1, 0          , txMC_TransmitLastCmd     , 1, '0'); -- Transmit last valid command word received by RT1
              MultiComdList.StartAddr <= 0;
              MultiComdList.Length <= 4;
              -- v4p formatting on
            wait for 0 ns;
            BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
            BC_done <= '1';
            wait for 100 ns;
            BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                           NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Exit, BCIDCHECK);
            BC_Exit <= '0';
            wait for 0 ns;
            ----------------------------------------------------------------------------------------------------
            ReadCheck(BC_cpu_bus, reg_mode_data_rxed1, Step1Cmd);
            -- wait for the TxGAP before starting the next command
            wait for tGAP;
          end loop; -- Length values
        end loop; -- Sub addresses
      end loop; -- RT addresses
    end loop; -- RT1 address
    -- #################################################################################################################
    ----------------------------------------------------------------------------------------------------
    -- STEP 2 Some directed tests
    ----------------------------------------------------------------------------------------------------
    log(Manager1Id, "################### STARTING DIRECTED TEST ###################", ALWAYS);
    MultiComdList.ErrBit <= 0;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrInj <= errNone;
              -- v4p formatting off
              --                           RA TnR SA Len Bus RT2RT
           --   MultiComdList.Command(0) <= (15, 0, 1,  1  , 1, '0'); -- Valid receive to RT1
              MultiComdList.Command(0) <= (15, 0, 2,  1  , 1, '1'); -- Variable test command
              MultiComdList.Command(1) <= (16, 1, 2,  1  , 1, '0'); -- Variable test command
              MultiComdList.Command(2) <= (15, 0, 3,  1  , 1, '1'); -- Variable test command
              MultiComdList.Command(3) <= (16, 1, 3,  1  , 1, '0'); -- Variable test command
              MultiComdList.Command(4) <= (31, 0, 4,  1  , 1, '1'); -- Variable test command
              MultiComdList.Command(5) <= (16, 1, 4,  1  , 1, '0'); -- Variable test command
              MultiComdList.Command(6) <= (15, 1, 0, txMC_TransmitLastCmd , 1, '0'); -- Transmit last valid command word received by RT1
              MultiComdList.StartAddr <= 0;
              MultiComdList.Length <= 7;
              -- v4p formatting on
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    BC_done <= '1';
    wait for 100 ns;
    BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                   NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Exit, BCIDCHECK);
    BC_Exit <= '0';
    wait for 0 ns;
    wait for 1 ms;
    log(Manager1Id, "################### DONE WITH DIRECTED TEST ###################", ALWAYS);
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
configuration osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_2_RT2RTRespCmdWord of osvvm_mil1553_dualbus_tb is
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(AS4111A_5_2_1_1_2_RT2RTRespCmdWord);
    end for;
  end for;
end configuration;
