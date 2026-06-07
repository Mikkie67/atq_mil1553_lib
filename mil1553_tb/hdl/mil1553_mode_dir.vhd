--
-- VHDL Architecture mil1553_tb.osvvm_Mil1553_dualbus_testctrl.mil1553_mode_dir
-- Test focuses on MODE commands
-- A loop is used to generate all the BC2RT (RT receive) command options
-- BC verifies correct responses from two RTs
-- RTs verify correct receipt of data when addresses match or broadcast command
architecture mil1553_mode_dir of osvvm_Mil1553_dualbus_testctrl is
  signal BC_CMD_SEND_Done, RT_Done, NextCmdRT1, NextCmdRT2 : integer_barrier := 1;
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
  signal DataWord      : std_logic_vector(15 downto 0) := X"A5A5"; -- Data word to send
  signal MultiComdList : MultiCommandRec_type;

  -- #################################################################################################################

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
    wait for 0 ns;
    MyBcAddr <= to_integer(unsigned(BC1_DiscretesIn.MyRtAddr));
    wait for 200 ns;
    BC1_DiscretesIn.nReset <= '1';
    wait for 0 ns;

    wait;
  end process;
  -- #################################################################################################################
  ControlProc: process
  begin
    SetTestName("mil1553_mode_dir");
    log("mil1553_mode_dir", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    -- SetLogEnable()
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
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_mode_dir.txt");
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
    -- variable Manager1Id    : AlertLogIDType;
    --variable ActiveBus  : integer;
    variable Mode : integer;
    --variable ModeCode   : integer;
    -- variable TxnRx      : integer;
    variable DataLen  : integer;
    variable DataWord : integer;
    variable PrevCmd  : std_logic_vector(15 downto 0);
    variable cmd      : integer;
    procedure BC_MODE_TEST(
        RtAddr   :    integer;
        SubAddr  :    integer;
        Len      :    integer;
        MilBus   : in integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
        TxnRx    :    integer;                   -- 0 for receive, 1 for transmit
        DataLen  :    integer;
        DataWord :    integer
      ) is
    begin
      Log(BCID,
          " TEST 4 #######################" & " CMD = " & to_hex_string(std_logic_vector(to_unsigned(RtAddr, 5)) & std_logic_vector(to_unsigned(TxnRx, 1)) & std_logic_vector(to_unsigned(SubAddr, 5)) & std_logic_vector(to_unsigned(Len, 5))) & " - BUS = " & to_string(MilBus) & " #######################");
      --BC_CMD(RtAddr, SubAddr, Len, MilBus, TxnRx, DataLen, DataWord, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1, SB_RT2, Manager1Id);
      log(BCID, "A WaitForBarrier(BC_CMD_SEND_Done)" & to_string(BC_CMD_SEND_Done), DEBUG);
      PrevCmd := std_logic_vector(to_unsigned(RtAddr, 5)) & std_logic_vector(to_unsigned(TxnRx, 1)) & std_logic_vector(to_unsigned(SubAddr, 5)) & std_logic_vector(to_unsigned(Len, 5));
      WaitForBarrier(BC_CMD_SEND_Done);
      log(BCID, "B WaitForBarrier(RT_Done)" & to_string(RT_Done), DEBUG);
      WaitForBarrier(RT_Done);
      --BC_CMD_Check(RtAddr, SubAddr, Len, MilBus, TxnRx, DataLen, DataWord, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, PrevCmd,BC_cpu_bus, BC1_DiscretesOut, SB_RT1, SB_RT2, Manager1Id);
    end procedure;
    -- #################################################################################################################
  begin
    wait until nReset = '1';
    WaitForClock(BC_cpu_bus, 1);
    -- Manager1Id := NewID("BC Cpu Bus", TbID);
    Write(BC_cpu_bus, X"0038", X"0001"); -- Write the softwere RtAddr Register
    ReadCheck(BC_cpu_bus, X"0036", X"FEEB"); -- Read the ID Regsister
    Write(BC_cpu_bus, X"0034", X"4000"); -- Set general RT control register
    -- ########################################### BC_MODE_TEST START HERE #############################################
    -- Some restrictions in using the cmd proc to send a batch of commands:
    -- 1. Only one command proct is avaialable even though the registers is split in the memoery map.
    -- 2. If multiple commands are to tge sub address, the data in the TxRam will be overwritten by the last command.
    --    Best solution is to not do the same command to the same subadres in one cmd proc process if you need the data to be different.
    -- 3. Also be carefull of multiple mode commands with the same command (i.e. the same LEN portion)
    -- Build the multiple MODE commands in the array
    -- first grouping is with SA = 00000
    log(BCID, "################### CONFIGURING THE MULTI COMMAND LIST ###################", ALWAYS);

    MultiComdList.RepeatRate <= 0;
    MultiComdList.ErrInj <= errNone;
    MultiComdList.ErrWrd <= 0;
    MultiComdList.ErrBit <= 0;
    --                          RA TnR  SA Len Bus RT2RT
    MultiComdList.Command(0) <= (15, 1, 0, 0, 1, '0'); -- Dynamic Bus Control (DBC), no data, no broadcast
    MultiComdList.Command(1) <= (15, 1, 0, 1, 1, '0'); -- Synchronize
    MultiComdList.Command(2) <= (15, 1, 0, 2, 1, '0'); -- Transmit last status word
    MultiComdList.Command(3) <= (15, 1, 0, 3, 1, '0'); -- Initiate Self Test
    MultiComdList.Command(4) <= (15, 1, 0, 4, 1, '0'); -- Transmitter Shutdown
    MultiComdList.Command(5) <= (15, 1, 0, 5, 1, '0'); -- Override Transmitter shutdown
    MultiComdList.Command(6) <= (15, 1, 0, 6, 1, '0'); -- Inhibit terminal Flag bit
    MultiComdList.Command(7) <= (15, 1, 0, 7, 1, '0'); -- Override inhibit terminal flag bit
    -- The reset terminal mode command is handled in a dedicated reset test.
    -- MultiComdList.Command(8 ) <= (15, 1, 0,  8 , 1 , '0'); -- Reset Remote Terminal
    MultiComdList.Command(8) <= (15, 1, 0, 9, 1, '0'); -- Reserved, no data
    MultiComdList.Command(9) <= (15, 1, 0, 9, 1, '0'); -- Reserved, no data
    MultiComdList.Command(10) <= (15, 1, 0, 10, 1, '0'); -- Reserved, no data
    MultiComdList.Command(11) <= (15, 1, 0, 11, 1, '0'); -- Reserved, no data
    MultiComdList.Command(12) <= (15, 1, 0, 12, 1, '0'); -- Reserved, no data
    MultiComdList.Command(13) <= (15, 1, 0, 13, 1, '0'); -- Reserved, no data
    MultiComdList.Command(14) <= (15, 1, 0, 14, 1, '0'); -- Reserved, no data
    MultiComdList.Command(15) <= (15, 1, 0, 15, 1, '0'); -- Reserved, no data
    MultiComdList.Command(16) <= (15, 1, 0, 16, 1, '0'); -- Transmit vector word (data word)
    MultiComdList.Command(17) <= (15, 1, 0, 17, 1, '0'); -- Reserved
    MultiComdList.Command(18) <= (15, 1, 0, 18, 1, '0'); -- Transmit Last Command word (data word)
    MultiComdList.Command(19) <= (15, 1, 0, 19, 1, '0'); -- Transmit BIT (data word)
    MultiComdList.Command(20) <= (15, 1, 0, 20, 1, '0'); -- Reserved
    MultiComdList.Command(21) <= (15, 1, 0, 21, 1, '0'); -- Reserved
    MultiComdList.Command(22) <= (15, 1, 0, 22, 1, '0'); -- Reserved
    MultiComdList.Command(23) <= (15, 1, 0, 23, 1, '0'); -- Reserved
    MultiComdList.Command(24) <= (15, 1, 0, 24, 1, '0'); -- Reserved
    MultiComdList.Command(25) <= (15, 1, 0, 25, 1, '0'); -- Reserved
    MultiComdList.Command(26) <= (15, 1, 0, 26, 1, '0'); -- Reserved
    MultiComdList.Command(27) <= (15, 1, 0, 27, 1, '0'); -- Reserved
    MultiComdList.Command(28) <= (15, 1, 0, 28, 1, '0'); -- Reserved
    MultiComdList.Command(29) <= (15, 1, 0, 29, 1, '0'); -- Reserved
    MultiComdList.Command(30) <= (15, 1, 0, 30, 1, '0'); -- Reserved
    MultiComdList.Command(31) <= (15, 1, 0, 31, 1, '0'); -- Reserved
    MultiComdList.StartAddr <= 0;
    MultiComdList.Length <= 32;
    wait for 0 ns;
    BC_done <= '0';
    BC_Check_Done <= '0';
    RtGo <= false;
    wait for 0 ns;
    BC_MULTICMD(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, SB_RT1_CMD, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_TMP, SB_RT2RT, RT2RT_DestAddr, RT2RT_Busy, BCID);
    log(BCID, "################### BC DONE ###################", DEBUG);
    BC_done <= '1';
    RtGo <= false;
    wait for 0 ns;
    BC_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, BC_cpu_bus, BC1_DiscretesOut, RtGo, SB_RT1_CMD, SB_RT1_DAT, SB_RT1_TMP, SB_RT2_CMD, SB_RT2_DAT, SB_RT2_TMP, SB_BC, SB_RT2RT,
                   NextCmdRT1, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, RT2RT_Busy, BC_Exit, BC_NextCmd, RT1_Done, RT2_Done, BC_Check_Done, BCIDCHECK);
    -- #################################################################################################################
    wait for 100 us;
    BC_Check_Done <= '1';
    wait for 500 us;
    log(BCID, "4 WaitForBarrier(TestDone)" & to_string(TestDone), DEBUG);
    -- WaitForBarrier(TestDone);
    wait;
  end process;

  -- #################################################################################################################
  RT1Proc: process
    -- variable Manager1Id : AlertLogIDType;
  begin
    wait until nReset = '1';
    WaitForClock(RT1_cpu_bus, 1);
    -- Manager1Id := NewID("RT1 Cpu Bus", TbID);
    RT1_DiscretesIn.MyRtAddr <= "01111";
    RT1_DiscretesIn.MyRtAddrParity <= '1'; -- Odd parity
    RT1_DiscretesIn.BitWord <= X"CCCC";
    RT1_DiscretesIn.ServiceReqVector <= X"DDDD";
    RT1_DiscretesIn.ServiceRequest <= '0';
    RT1_DiscretesIn.SubsystemFlag <= '0';
    RT1_DiscretesIn.nReset <= '0';
    wait for 0 ns;
    MyRtAddr1 <= to_integer(unsigned(RT1_DiscretesIn.MyRtAddr));
    wait for 200 ns;
    RT1_DiscretesIn.nReset <= '1';
    wait for 0 ns;
    wait for 0 ns;
    MyRtAddr1 <= to_integer(unsigned(RT1_DiscretesIn.MyRtAddr));
    wait for 0 ns;
    Write(RT1_cpu_bus, reg_rt_addr, X"0001");
    Write(RT1_cpu_bus, reg_intr_mask, X"0003");
    ReadCheck(RT1_cpu_bus, reg_gID, X"FEEB");
    Write(RT1_cpu_bus, reg_node_control, X"4120");
    ClearInterrupts(RT1_cpu_bus, 1, IrqMask, RT1ID);
    ClearInterrupts(RT1_cpu_bus, 2, IrqMask, RT1ID);
    wait until BC_Done = '1';
    while BC_Check_Done = '0' loop
      if BC_Exit = '1' then
        exit;
      end if;
      --wait until RtGo = true;
      RT_MULTI_CHECK(MultiComdList, MyRtAddr1, MyRtAddr2, MyBcAddr, CmdWord, RT1_cpu_bus, RT1_DiscretesOut, SB_RT1_CMD, SB_RT1_DAT, SB_RT2_CMD, SB_RT2_DAT, SB_BC, SB_RT2RT, NextCmdRT1, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT1_Done, BC_Exit, RT2RT_Busy, BC_Check_Done, RT1ID);
    end loop;
    log(RT1ID, "8 WaitForBarrier(TestDone)" & to_string(TestDone), DEBUG);
    WaitForBarrier(TestDone);
  end process;
  -- #################################################################################################################
  RT2Proc: process
    -- variable Manager1Id : AlertLogIDType;
  begin
    wait until nReset = '1';
    WaitForClock(RT2_cpu_bus, 1);
    -- Manager1Id := NewID("RT2 Cpu Bus", TbID);
    RT2_DiscretesIn.MyRtAddr <= "10000";
    RT2_DiscretesIn.MyRtAddrParity <= '0'; -- Odd parity
    RT2_DiscretesIn.BitWord <= X"EEEE";
    RT2_DiscretesIn.ServiceReqVector <= X"FFFF";
    RT2_DiscretesIn.ServiceRequest <= '0';
    RT2_DiscretesIn.SubsystemFlag <= '0';
    RT2_DiscretesIn.nReset <= '0';
    wait for 0 ns;
    MyRtAddr2 <= to_integer(unsigned(RT2_DiscretesIn.MyRtAddr));
    wait for 200 ns;
    RT2_DiscretesIn.nReset <= '1';
    wait for 0 ns;
    MyRtAddr2 <= to_integer(unsigned(RT2_DiscretesIn.MyRtAddr));
    wait for 0 ns;

    Write(RT2_cpu_bus, reg_rt_addr, X"0001");
    Write(RT2_cpu_bus, reg_intr_mask, X"0003");
    ReadCheck(RT2_cpu_bus, reg_gID, X"FEEB");
    Write(RT2_cpu_bus, reg_node_control, X"4120");
    ClearInterrupts(RT2_cpu_bus, 1, IrqMask, RT2ID);
    ClearInterrupts(RT2_cpu_bus, 2, IrqMask, RT2ID);
    wait until BC_Done = '1';
    while BC_Check_Done = '0' loop
      if BC_Exit = '1' then
        exit;
      end if;
      RT_MULTI_CHECK(MultiComdList, MyRtAddr2, MyRtAddr1, MyBcAddr, CmdWord, RT2_cpu_bus, RT2_DiscretesOut, SB_RT2_CMD, SB_RT2_DAT, SB_RT1_CMD, SB_RT1_DAT, SB_BC, SB_RT2RT, NextCmdRT2, CurCmdIndex, TransmittingRT, ReceivingRT, RT2RT_DestAddr, BC_NextCmd, RT2_Done, BC_Exit, RT2RT_Busy, BC_Check_Done, RT2ID);
    end loop;
    log(RT2ID, "12 WaitForBarrier(TestDone)" & to_string(TestDone), DEBUG);
    WaitForBarrier(TestDone);
  end process;

end architecture;
-- #################################################################################################################
configuration mil1553_mode_dir_cfg of osvvm_mil1553_dualbus_tb is
  -- Legacy configuration name replaced by mil1553_mode_dir_cfg.
  for struct
    for TestCntrl_1: osvvm_mil1553_dualbus_testctrl
      use entity mil1553_tb.osvvm_mil1553_dualbus_testctrl(mil1553_mode_dir);
    end for;
  end for;
end configuration;

