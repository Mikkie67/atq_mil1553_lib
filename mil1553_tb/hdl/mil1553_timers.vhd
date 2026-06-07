-- VHDL Architecture mil1553_tb.mill1553_timers_testcntrl.test8
-- #################################################################################################################
architecture mil1553_timers of mill1553_timers_testcntrl is
  signal TbID : AlertLogIDType;
  signal Cov  : CoverageIDType;
begin
  -- #################################################################################################################
  ------------------------------------------------------------
  -- Clk is a free running clock
  ------------------------------------------------------------
  clk_process: process
  begin
    Clk <= '0';
    wait for 10 ns / 2;
    Clk <= '1';
    wait for 10 ns / 2;
  end process;

  InitProc: process
  begin
    wait;
  end process;
  -- #################################################################################################################
  ControlProc: process
  begin
    SetTestName("mil1553_timers");
    log("mil1553_timers", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    TbID <= GetAlertLogID("TB");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_timers.txt");
    SetTranscriptMirror(TRUE);
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 1000 sec);
    AlertIf(now >= 1000 sec, "Test finished due to timeout");
    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process;
  -- #################################################################################################################
  BcProc: process
    variable Manager1Id : AlertLogIDType;
    variable StartTime  : time;
    variable Timeout    : boolean;
    variable TestStep   : natural := 0;
    variable StopTime   : time;
    variable ExpTimeout : time;
    variable RV         : RandomPType;
    procedure TimerTest(
        signal   TimerSignal : in  std_logic;
        signal   TimerStart  : out std_logic;
        signal   TimerStop   : out std_logic;
        signal   TimerLoad   : out std_logic_vector(15 downto 0);
        constant DefaultLoad : in  natural
      ) is
    begin
      ExpTimeout := DefaultLoad * 10 ns;
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Checking Timer with load value " & to_string(DefaultLoad) & " expected timeout " & to_string(ExpTimeout), ALWAYS);
      TimerLoad <= std_logic_vector(to_unsigned(DefaultLoad, TimerLoad'length));
      TimerStart <= '1';
      TimerStop <= '1';
      wait for 20 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer cleared after reset", "ERROR: Timer not cleared after reset", TRUE);
      TimerStart <= '1';
      TimerStop <= '0';
      -- wait for long enough to ensure that the timer did not run (both start and stop are low)
      wait for ExpTimeout + 100 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer did not run after start=1 and stop=0", "ERROR: Timer timed out incorrectly", TRUE);
      TimerStart <= '0';
      TimerStop <= '1';
      -- wait for long enough to ensure that the timer did not run (both start and stop are low)
      wait for ExpTimeout + 100 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer did not run after start=0 and stop=1", "ERROR: Timer timed out incorrectly", TRUE);
      -- now start the timer and wait for it to time out
      TimerStart <= '1';
      TimerStop <= '0';
      wait for 15 ns;
      TimerStart <= '0';
      WaitForClock(clk, 1);
      StartTime := now;
      WaitForLevel(TimerSignal, ExpTimeout + 100 ns, Timeout, '1');
      StopTime := now;
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Timer did not time out as expected t = " & to_string(StopTime - StartTime), ERROR);
      else
        AffirmIf(Manager1Id,(StopTime - StartTime) = ExpTimeout, "Step " & to_string(TestStep) & ": Timer timed out as expected t = " & to_string(StopTime - StartTime), "ERROR: Incorrect timeout period t = " & to_string(StopTime - StartTime), TRUE);
      end if;
      -- reset the timer withouts stopping it, it should time out again
      TimerStart <= '1';
      wait for 15 ns;
      TimerStart <= '0';
      WaitForClock(clk, 1);
      StartTime := now;
      WaitForLevel(TimerSignal, ExpTimeout + 100 ns, Timeout, '1');
      StopTime := now;
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Timer did not time out as expected", ERROR);
      else
        AffirmIf(Manager1Id,(StopTime - StartTime) = ExpTimeout, "Step " & to_string(TestStep) & ": Timer timed out as expected t = " & to_string(StopTime - StartTime), "ERROR: Incorrect timeout period t = " & to_string(StopTime - StartTime), TRUE);
      end if;
      -- no stop and reset the timer, the timout should be cleared and the timer should not timeout again
      TimerStop <= '1';
      TimerStart <= '1';
      wait for 20 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer cleared after reset", "ERROR: Timer not cleared after reset t = " & to_string(StopTime - StartTime), TRUE);
      -- wait for long enough to ensure that the timer did not run (both start and stop are low)
      wait for ExpTimeout + 100 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer did not run after start and stop cleared", "ERROR: Timer timed out incorrectly t = " & to_string(StopTime - StartTime), TRUE);
    end procedure;
    procedure TimerTest_enabled(
        signal   TimerSignal  : in  std_logic;
        signal   TimerStart   : out std_logic;
        signal   TimerStop    : out std_logic;
        signal   TimerEnable  : in  std_logic;
                 EnablePeriod : in  time;
        signal   TimerLoad    : out std_logic_vector(15 downto 0);
        constant DefaultLoad  : in  natural
      ) is
    begin
      ExpTimeout := DefaultLoad * EnablePeriod + 10 ns; -- the 10ns is added to account for the pipeline delay between to counters
      Log(Manager1Id, "Step " & to_string(TestStep) & ": Checking Timer with load value " & to_string(DefaultLoad) & " expected timeout " & to_string(ExpTimeout), ALWAYS);
      TimerLoad <= std_logic_vector(to_unsigned(DefaultLoad, TimerLoad'length));
      TimerStart <= '1';
      TimerStop <= '1';
      wait for 20 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer cleared after reset", "ERROR: Timer not cleared after reset", TRUE);
      TimerStart <= '1';
      TimerStop <= '0';
      -- wait for long enough to ensure that the timer did not run (both start and stop are low)
      wait for ExpTimeout + 100 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer did not run after start=1 and stop=0", "ERROR: Timer timed out incorrectly", TRUE);
      TimerStart <= '0';
      TimerStop <= '1';
      -- wait for long enough to ensure that the timer did not run (both start and stop are low)
      wait for ExpTimeout + 100 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer did not run after start=0 and stop=1", "ERROR: Timer timed out incorrectly", TRUE);
      -- now start the timer and wait for it to time out
      TimerStart <= '1';
      TimerStop <= '0';
      wait for 5 ns;
      TimerStart <= '0';
      WaitForClock(TimerEnable, 1);
      StartTime := now;
      WaitForLevel(TimerSignal, ExpTimeout + 100 ns, Timeout, '1');
      StopTime := now;
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Timer did not time out as expected t = " & to_string(StopTime - StartTime), ERROR);
      else
        AffirmIf(Manager1Id,(StopTime - StartTime) = ExpTimeout, "Step " & to_string(TestStep) & ": Timer timed out as expected t = " & to_string(StopTime - StartTime), "ERROR: Incorrect timeout period t = " & to_string(StopTime - StartTime), TRUE);
      end if;
      -- reset the timer withouts stopping it, it should time out again
      TimerStart <= '1';
      wait for 5 ns;
      TimerStart <= '0';
      WaitForClock(TimerEnable, 1);
      StartTime := now;
      WaitForLevel(TimerSignal, ExpTimeout + 100 ns, Timeout, '1');
      StopTime := now;
      if (Timeout) then
        Alert(Manager1Id, "Step " & to_string(TestStep) & ": Timer did not time out as expected", ERROR);
      else
        AffirmIf(Manager1Id,(StopTime - StartTime) = ExpTimeout, "Step " & to_string(TestStep) & ": Timer timed out as expected t = " & to_string(StopTime - StartTime), "ERROR: Incorrect timeout period t = " & to_string(StopTime - StartTime), TRUE);
      end if;
      -- no stop and reset the timer, the timout should be cleared and the timer should not timeout again
      TimerStop <= '1';
      TimerStart <= '1';
      wait for 20 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer cleared after reset", "ERROR: Timer not cleared after reset t = " & to_string(StopTime - StartTime), TRUE);
      -- wait for long enough to ensure that the timer did not run (both start and stop are low)
      wait for ExpTimeout + 100 ns;
      AffirmIf(Manager1Id, TimerSignal = '0', "Step " & to_string(TestStep) & ": Timer did not run after start and stop cleared", "ERROR: Timer timed out incorrectly t = " & to_string(StopTime - StartTime), TRUE);
    end procedure;
  begin
    RV.InitSeed(T => now); -- Initialize the random number generator once per group of messages
    wait for 1 us;
    Manager1Id := NewID("TMRS", TbID);
    log(Manager1Id, "Starting mil1553_timers test", ALWAYS);
    nReset <= '0';
    wait for 1 us;
    nReset <= '1';
    wait for 100 ns;
    ----------------------------------------------------------------------------------------------------
    -- each timer will be checked against:
    -- 1. default load value (as done by the CPU IF after reset)
    -- 2. random load value (within limits)
    -- keep in mind that "Start" is actually a reset signal for the timers, so to start a timer you need to
    -- set Start high and then when released low the timer will start
    ----------------------------------------------------------------------------------------------------
    -- Blank timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 1;
    -- this timer is not controlled from CPU, so check that it times out correctly from the hardcoded value
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking BLANK Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    TimerTest(
      TimerSignal => tmr_BLANK, TimerStart => tmr_BLANK_Start, TimerStop => tmr_BLANK_Stop, TimerLoad => reg_tmr_GAP, DefaultLoad => 400);
    ----------------------------------------------------------------------------------------------------
    -- GAP timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 2;
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking GAP Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    TimerTest(
      TimerSignal => tmr_GAP, TimerStart => tmr_GAP_Start, TimerStop => tmr_GAP_Stop, TimerLoad => reg_tmr_GAP, DefaultLoad => 512);
    TimerTest(
      TimerSignal => tmr_GAP, TimerStart => tmr_GAP_Start, TimerStop => tmr_GAP_Stop, TimerLoad => reg_tmr_GAP, DefaultLoad => RV.RandInt(Min => 100, Max => 65535));
    ----------------------------------------------------------------------------------------------------
    -- NRP timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 3;
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking NRP Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    -- to test NRP timer, first stop the 25us timer since the timouet signal is an OR of both timers
    tmr_25us_Stop <= '1';
    tmr_25us_Start <= '1';
    TimerTest(
      TimerSignal => tmr_NRP, TimerStart => tmr_NRP_Start, TimerStop => tmr_NRP_Stop, TimerLoad => reg_tmr_NRP, DefaultLoad => 1399);
   TimerTest(
      TimerSignal => tmr_NRP, TimerStart => tmr_NRP_Start, TimerStop => tmr_NRP_Stop, TimerLoad => reg_tmr_NRP, DefaultLoad => RV.RandInt(Min => 100, Max => 65535));
    ----------------------------------------------------------------------------------------------------
    -- REP timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 4;
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking REP Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    TimerTest(
      TimerSignal => tmr_REP, TimerStart => tmr_REP_Start, TimerStop => tmr_REP_Stop, TimerLoad => reg_tmr_REP, DefaultLoad => 405);
    TimerTest(
      TimerSignal => tmr_REP, TimerStart => tmr_REP_Start, TimerStop => tmr_REP_Stop, TimerLoad => reg_tmr_REP, DefaultLoad => RV.RandInt(Min => 100, Max => 65535));
    ----------------------------------------------------------------------------------------------------
    -- SAF timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 5;
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking SAF Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    TimerTest(
      TimerSignal => tmr_SAF, TimerStart => tmr_SAF_Start, TimerStop => tmr_SAF_Stop, TimerLoad => reg_tmr_SAF, DefaultLoad => 799);
    TimerTest(
      TimerSignal => tmr_SAF, TimerStart => tmr_SAF_Start, TimerStop => tmr_SAF_Stop, TimerLoad => reg_tmr_SAF, DefaultLoad => RV.RandInt(Min => 100, Max => 65535));
    ----------------------------------------------------------------------------------------------------
    -- ERP timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 6;
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking ERP Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    -- enable the ERP timer
    tmr_ERP_enable <= '1';
    TimerTest(
      TimerSignal => tmr_ERP, TimerStart => tmr_ERP_Reset, TimerStop => tmr_ERP_Stop, TimerLoad => reg_tmr_ERP, DefaultLoad => 400);
    TimerTest(
      TimerSignal => tmr_ERP, TimerStart => tmr_ERP_Reset, TimerStop => tmr_ERP_Stop, TimerLoad => reg_tmr_ERP, DefaultLoad => RV.RandInt(Min => 100, Max => 65535));
    ----------------------------------------------------------------------------------------------------
    -- 1us timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 7;
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking 1us Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    TimerTest(
      TimerSignal => tmr_1us, TimerStart => tmr_1us_Start, TimerStop => tmr_1us_Stop, TimerLoad => reg_tmr_1us, DefaultLoad => 99);
    TimerTest(
      TimerSignal => tmr_1us, TimerStart => tmr_1us_Start, TimerStop => tmr_1us_Stop, TimerLoad => reg_tmr_1us, DefaultLoad => RV.RandInt(Min => 10, Max => 65535));
    TimerTest(
      TimerSignal => tmr_1us, TimerStart => tmr_1us_Start, TimerStop => tmr_1us_Stop, TimerLoad => reg_tmr_1us, DefaultLoad => 99);
   ----------------------------------------------------------------------------------------------------
    -- 25us timer
    ----------------------------------------------------------------------------------------------------
    TestStep := 8;
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    log(Manager1Id, "Step " & to_string(TestStep) & ": Checking 25us Timer default timeout", ALWAYS);
    log(Manager1Id, "----------------------------------------------------------------------------------------------------", ALWAYS);
    -- This timer is enabled on 1us pulses, so start it first
    tmr_1us_Start <= '1';
    tmr_1us_Stop <= '0';
    wait for 200 ns;
    tmr_1us_Start <= '0';
    TimerTest_enabled(TimerEnable => tmr_1us, EnablePeriod => 1 us,
                      TimerSignal => tmr_25us, TimerStart => tmr_25us_Start, TimerStop => tmr_25us_Stop, TimerLoad => reg_tmr_GAP, DefaultLoad => 24);
    AffirmIf(TbID, tmr_1us_Start = '0', "FakeTest", ERROR);
    WaitForBarrier(TestDone);
  end process;
end architecture;

configuration mil1553_timers_cfg of mill1553_timers_tb is
  for struct
    for testcntrl1: mill1553_timers_testcntrl
      use entity mil1553_tb.mill1553_timers_testcntrl(mil1553_timers);
    end for;
  end for;
end configuration;
