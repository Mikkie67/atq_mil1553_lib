-- #################################################################################################################
architecture mil1553_manchester_decoder_dir of man_dec_testctrl is
  signal TbID : AlertLogIDType;
  signal Cov  : CoverageIDType;
begin
  -- #################################################################################################################
  InitProc: process
  begin
    wait;
  end process;
  -- #################################################################################################################
  ControlProc: process
  begin
    SetTestName("mil1553_manchester_decoder_dir");
    log("mil1553_manchester_decoder_dir", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    TbID <= GetAlertLogID("TB");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_manchester_decoder_dir.txt");
    SetTranscriptMirror(TRUE);
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 1000 sec);
    AlertIf(now >= 1000 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1000, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process;
  -- #################################################################################################################
  BcProc: process
    variable Manager1Id            : AlertLogIDType;
    variable PrevUnexpectedEdgeCnt : integer := 0;
    variable Cmd                   : std_logic_vector(15 downto 0);
    variable Data                  : std_logic_vector(15 downto 0);
    variable NumRuns               : integer := 1000;
    variable Src1                  : integer := 1;
    variable Src2                  : integer := 2;
  begin
    wait for 1 us;
    Manager1Id := NewID("MAN_DEC", TbID);
    log(Manager1Id, "Starting Manchester Decoder Test", ALWAYS);
    Cov <= NewID("Cov");
    wait for 1 us;
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Manchester Decoder Direct Input Tests",ALWAYS);
    Log(Manager1Id,"Test for unexpected data sync symbol",ALWAYS);
    Log(Manager1Id,"Decoder should try and parse but ultimately ignore",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
    Send(man_dec_bus, X"0000", X"FFFF", 0, SEND_DATA, MAN_DEC_NO_ERROR);
    Send(man_dec_bus, X"0000", X"FFFF", 0, SEND_DATA, MAN_DEC_NO_ERROR);
    wait for tGAP;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected data sync");
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for unexpected bit symbols",ALWAYS);
    Log(Manager1Id,"Decoder should try and parse but ultimately ignore",ALWAYS);
    Log(Manager1Id,"The command word is used for number of bits to send",ALWAYS);
    Log(Manager1Id,"and the data word is the repeated bit pattern until end.",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
    Send(man_dec_bus, X"001F", X"AFF5", 0, SEND_BIT, MAN_DEC_NO_ERROR);
    wait for tGAP;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected data bits");
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for single command sync",ALWAYS);
    Log(Manager1Id,"Decoder should parse the command sync but then return to idle state",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
    Send(man_dec_bus, X"0000", X"FFFF", 0, SEND_CMDSYNC, MAN_DEC_NO_ERROR);
    wait for tGAP;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected single command sync");
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for single data sync",ALWAYS);
    Log(Manager1Id,"Decoder will try to parse it as a command sync but then return to idle state",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
    Send(man_dec_bus, X"0000", X"FFFF", 0, SEND_DATASYNC, MAN_DEC_NO_ERROR);
    wait for tGAP;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected single data sync");
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for single well formed command word",ALWAYS);
    Log(Manager1Id,"Decoder should parse the command word and send it to framer",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
    Send(man_dec_bus, X"0000", X"FFFF", 0, SEND_CMD, MAN_DEC_NO_ERROR);
    wait for tGAP;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected data sync");
    AffirmIf(Manager1Id, man_dec_bus.Command = man_dec_bus.CommandIn, "Command word not received correctly");
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for single well formed command and data word",ALWAYS);
    Log(Manager1Id,"Decoder shall parse the command and data word and send it to framer",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
    Send(man_dec_bus, X"0000", X"FFFF", 0, SEND_CMD_AND_DATA, MAN_DEC_NO_ERROR);
    wait for tGAP;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "1State is not IDLE after unexpected data sync");
    AffirmIf(Manager1Id, man_dec_bus.Command = man_dec_bus.CommandIn, "1Command word not received correctly");
    AffirmIf(Manager1Id, man_dec_bus.Data = man_dec_bus.DataIn, "1Data word not received correctly");
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for single well formed command and multiple data words",ALWAYS);
    Log(Manager1Id,"Decoder shall parse the command and data word and send it to framer",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
    Send(man_dec_bus, X"0000", X"FFFF", 0, SEND_CMD_AND_DATA, MAN_DEC_NO_ERROR, 3);
    wait for tGAP;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected data sync");
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for multiple well formed command and data word",ALWAYS);
    Log(Manager1Id,"Decoder shall parse the command and data word and send it to framer",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    NumRuns := 10;
    for i in 1 to NumRuns loop
      Cmd := std_logic_vector(to_unsigned(i, 16));
      Data := std_logic_vector(to_unsigned(i, 16));
      PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
      Send(man_dec_bus, Cmd, Data, 0, SEND_CMD_AND_DATA, MAN_DEC_NO_ERROR, 32);
      wait for tGAP;
      -- ensure that the state is back to IDLE and that the unexpected edge count incremented
      AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected data sync");
    end loop;
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    Log(Manager1Id,"Test for multiple well formed command and data word (cross)",ALWAYS);
    Log(Manager1Id,"Decoder shall parse the command and data word and send it to framer",ALWAYS);
    Log(Manager1Id,"----------------------------------------------------------------------------------------------------",ALWAYS);
    --AddCross(Cov, 1, GenBin(0, 256), GenBin(0, 256));
    AddCross(Cov, 1, GenBin(0, 255), GenBin(0, 255));
    loop
      (Src1, Src2) := GetRandPoint(Cov);
      PrevUnexpectedEdgeCnt := man_dec_bus.UnexpectedEdgeCnt;
      Send(man_dec_bus, std_logic_vector(to_unsigned(Src1, 16)), std_logic_vector(to_unsigned(Src2, 16)), 0, SEND_CMD_AND_DATA, MAN_DEC_NO_ERROR);
      wait for tGAP;
      -- ensure that the state is back to IDLE and that the unexpected edge count incremented
      AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected data sync");
      ICover(Cov,(Src1, Src2));
      exit when IsCovered(Cov); -- done?
    end loop;
    --WriteBin(Cov);
    ----------------------------------------------------------------------------------------------------
    WaitForBarrier(TestDone);
  end process;

end architecture;

configuration mil1553_manchester_decoder_dir_cfg of osvvm_manchester_decoder_tb is
  for struct
    for manchester_decoder_testctrl1: man_dec_testctrl
      use entity mil1553_tb.man_dec_testctrl(mil1553_manchester_decoder_dir);
    end for;
  end for;
end configuration;

