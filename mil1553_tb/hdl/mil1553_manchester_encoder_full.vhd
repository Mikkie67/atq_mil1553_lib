--
-- VHDL Architecture mil1553_tb.manchester_encoder_testctntrl.mil1553_manchester_encoder_full
use std.textio.all; 

architecture mil1553_manchester_encoder_full of manchester_encoder_testcntrl is
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
    SetTestName("mil1553_manchester_encoder_full");
    log("mil1553_manchester_encoder_full", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    TbID <= GetAlertLogID("TB");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_manchester_encoder_full.txt");
    SetTranscriptMirror(TRUE);
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 1000 sec);
    AlertIf(now >= 1000 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
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
    variable TestStep   : natural   := 0;
    variable StopTime   : time;
    variable ExpTimeout : time;
    variable ExpLevel   : std_logic;
    variable BitName    : line; -- Unconstrained string for bit names
    variable RV         : RandomPType;
    variable Parity     : std_logic := '0';
    procedure CheckBit is
    begin
      wait for 0 ns;
      WaitForLevel(OutP, ExpTimeout, Timeout, ExpLevel);
      Alertif(Timeout, "TestStep " & integer'image(TestStep) & " 1 " & BitName.all & " level wait timed out", ERROR);
      WaitForLevel(OutN, ExpTimeout, Timeout, not ExpLevel);
      Alertif(Timeout, "TestStep " & integer'image(TestStep) & " 2 " & BitName.all & " level wait timed out", ERROR);
      AlertIf(OutN /= not OutP, "a Encoder Output Differential Pair not Complementary");
      StartTime := now;
      WaitForLevel(OutP, ExpTimeout, Timeout, not ExpLevel); -- the transition in the middle of the bit
      StopTime := now;
      AlertIf(StopTime - StartTime < ExpTimeout, "TestStep " & integer'image(TestStep) & " a " & BitName.all & " level not as expected: Measured: " & time'image(StopTime - StartTime) & ", Expected: " & time'image(ExpTimeout), ERROR);
      AlertIf(OutN /= not OutP, "b Encoder Output Differential Pair not Complementary");
      StartTime := now;
      wait for ExpTimeout;
      --WaitForLevel(OutP, ExpLevel,ExpTimeout, Timeout);
      StopTime := now;
      AlertIf(OutP /= not ExpLevel, "TestStep " & integer'image(TestStep) & " b " & BitName.all & " level not as expected: Measured: " & to_string(OutP) & ", Expected: " & to_string(not ExpLevel), ERROR);
    end procedure;
  begin
    RV.InitSeed(T => now); -- Initialize the random number generator once per group of messages
    wait for 1 us;
    Manager1Id := NewID("ENC", TbID);
    log(Manager1Id, "Starting mil1553_manchester_encoder_full", ALWAYS);
    nReset <= '0';
    Go <= '0';
    Err_inj <= (others => '0');
    Data <= (others => '0');
    Cmd_nData <= '0';
    tmr_Blank <= '0';
    wait for 0 ns;
    wait for 1 us;
    nReset <= '1';
    wait for 100 ns;
    ----------------------------------------------------------------------------------------------------
    -- Command word encoding test
    ----------------------------------------------------------------------------------------------------
    TestStep := 1;
    for words in 0 to 65535 loop
      Log(Manager1Id, "TestStep " & integer'image(TestStep) & ": Command Word Encoding Word " & to_string(words), ALWAYS);
      Parity := '0';
      Cmd_nData <= '1';
      Data <= std_logic_vector(to_unsigned(words, 16));
      Err_inj <= (others => '0');
      tmr_Blank <= '0';
      WaitForLevel(Clk, '0');
      WaitForLevel(Clk, '1');
      wait for 4 ns;
      Go <= '1', '0' after 10 ns;
      wait for 0 ns;
      deallocate(BitName);
      write(BitName, string'("CmdSync"));
      ExpTimeout := 1500 ns;
      ExpLevel := '1';
      CheckBit;
      for bitnumber in 15 downto 0 loop
        -- Create bit name string using write
        deallocate(BitName);
        write(BitName, string'("CmdBit"));
        write(BitName, integer'image(bitnumber));
        Parity := Parity xor Data(bitnumber);
        if Data(bitnumber) = '1' then
          ExpLevel := '1';
        else
          ExpLevel := '0';
        end if;
        ExpTimeout := 500 ns;
        CheckBit;
      end loop;
      deallocate(BitName);
      write(BitName, string'("CmdParityBit")); -- Write to line object
      ExpTimeout := 500 ns;
      Parity := not Parity;
      if Parity = '0' then -- invert here for odd parity
        ExpLevel := '0';
      else
        ExpLevel := '1';
      end if;
      CheckBit;
      wait for 4 us;
      tmr_Blank <= '1';
      wait for 10 ns;
      tmr_Blank <= '0';
    end loop;
    wait for 1 us;
    ----------------------------------------------------------------------------------------------------
    -- Data word encoding test
    ----------------------------------------------------------------------------------------------------
    TestStep := 1;
    for words in 0 to 65535 loop
      Log(Manager1Id, "TestStep " & integer'image(TestStep) & ": Data Word Encoding Word " & to_string(words), ALWAYS);
      Parity := '0';
      Cmd_nData <= '0';
      Data <= std_logic_vector(to_unsigned(words, 16));
      Err_inj <= (others => '0');
      tmr_Blank <= '0';
      WaitForLevel(Clk, '0');
      WaitForLevel(Clk, '1');
      wait for 4 ns;
      Go <= '1', '0' after 10 ns;
      wait for 0 ns;
      deallocate(BitName);
      write(BitName, string'("CmdSync"));
      ExpTimeout := 1500 ns;
      ExpLevel := '0';
      CheckBit;
      for bitnumber in 15 downto 0 loop
        -- Create bit name string using write
        deallocate(BitName);
        write(BitName, string'("CmdBit"));
        write(BitName, integer'image(bitnumber));
        Parity := Parity xor Data(bitnumber);
        if Data(bitnumber) = '1' then
          ExpLevel := '1';
        else
          ExpLevel := '0';
        end if;
        ExpTimeout := 500 ns;
        CheckBit;
      end loop;
      deallocate(BitName);
      write(BitName, string'("CmdParityBit")); -- Write to line object
      ExpTimeout := 500 ns;
      Parity := not Parity;
      if Parity = '0' then -- invert here for odd parity
        ExpLevel := '0';
      else
        ExpLevel := '1';
      end if;
      CheckBit;
      wait for 4 us;
      tmr_Blank <= '1';
      wait for 10 ns;
      tmr_Blank <= '0';
    end loop;
    Parity := '0';
    AffirmIf(TbID, Parity = '0', "FakeTest", ERROR);
    WaitForBarrier(TestDone);
  end process;
end architecture;

configuration mil1553_manchester_encoder_full_cfg of manchester_encoder_tb is
  for struct
    for testcntrl1: manchester_encoder_testcntrl
      use entity mil1553_tb.manchester_encoder_testcntrl(mil1553_manchester_encoder_full);
    end for;
  end for;
end configuration;
