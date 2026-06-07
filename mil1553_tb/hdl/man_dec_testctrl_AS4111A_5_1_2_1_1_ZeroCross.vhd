-- Zero Crossing Distortion: 
-- A legal valid receive message shall be sent to the UUT and the proper response verified. Positive 
-- and negative zero crossing distortions equal to 150 ns from the ideal, with respect to the previous
-- ideal zero crossing, (i.e., 2.0 µs ± 150 ns, 1.5 µs ± 150 ns, 1.0 µs ± 150 ns, 0.5 µs ± 150 ns) 
-- shall be introduced individually to each zero crossing as follows:
-- a. All zero crossings in the command word;
-- b. All 35 zero crossings in a single data word where the data pattern is 0000H;
-- c. The zero crossing between bit times 19 and 20 in a single data word where the data pattern is 8000H.
-- d. The zero crossing in the middle at bit time 4 and the zero crossing between bit time 4 and 5 in 
-- a single data word where the pattern is C000H.

-- Each zero crossing distortion shall be transmitted to the UUT a minimum of 1000 times.
-- This test shall use Figure 1A or Figure 1B. The signal amplitude transmitted to the UUT,
-- measured at point "A" shall be 2.1 VPP for transformer coupled stubs and 3.0 VPP for direct
-- coupled stubs. The rise and fall time of this signal (measured at the data bit zero crossing with
-- the prior zero crossing and the next zero crossing at 500 ns intervals from the measured zero
-- crossing) measured at point "A" shall be 200 ns ± 20 ns.
-- The pass criteria is CS for each message transmitted.
-- Positive and negative zero crossing distortions (equal to N ns) shall then be applied in turn to a
-- single zero crossing. The zero crossings shall be increased in steps to determine the positive
-- and negative values at which the first NR occurs. It is recommended that the steps be no
-- greater than 5 ns. The value at which the first NR occurs, for both positive and negative zero
-- crossing distortions, shall be recorded.
-- #################################################################################################################
architecture AS4111A_5_1_2_1_1_ZeroCross of man_dec_testctrl is
  signal TbID           : AlertLogIDType;
  signal Cov            : CoverageIDType;
  signal SB_CMD, SB_DAT : ScoreboardIdType;
  signal MON1           : std_logic := '0';
  signal Dataword       : std_logic_vector(15 downto 0);
  signal Cmdword        : std_logic_vector(15 downto 0);
  constant cNumTests : integer := 10;
begin
  -- #################################################################################################################
  InitProc: process
  begin
    wait;
  end process;
  -- #################################################################################################################
  ControlProc: process
  begin
    SetTestName("AS4111A_5_1_2_1_1_ZeroCross");
    log("AS4111A_5_1_2_1_1_ZeroCross", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    TbID <= GetAlertLogID("TB");
    SB_CMD <= NewID("SB_CMD");
    SB_DAT <= NewID("SB_DAT");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "man_deAS4111A_5_1_2_1_1_ZeroCross_full.txt");
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
  BUS_MON: process
    variable MonId          : AlertLogIDType;
    variable timeOfLastEdge : time    := 0 ns;
    variable timeOfGap      : time    := 0 ns;
    variable CommandWord    : std_logic_vector(15 downto 0);
    variable CommandWord2   : std_logic_vector(15 downto 0);
    variable Timeout        : boolean := false;
    -- #################################################################################################################
  begin
    MonId := NewID("BUS_MON");
    wait for 0 ns;
    loop
      WaitForToggle(MON1);
      WaitForLevel(BusMonitorRec.SyncNegEdge, 25000 ns, Timeout, '1');
      if (Timeout) then
        Alert(MonId, "Timeout waiting for falling cmd sync, DECODER ERROR");
        exit;
      else
        wait for 100 ns;
        WaitForLevel(BusMonitorRec.NewWord, 20000 ns, Timeout, '1');
        if (Timeout) then
          Alert(MonId, "Timeout waiting for new word, DECODER ERROR");
          exit;
        else
          Affirmif(MonId, BusMonitorRec.OutWord = Cmdword, "Decoded command word does not match sent command word.");
          wait for 100 ns;
          WaitForLevel(BusMonitorRec.SyncPosEdge, 21000 ns, Timeout, '1');
          if (Timeout) then
            Alert(MonId, "Timeout waiting for rising data sync, DECODER ERROR");
            exit;
          else
            wait for 100 ns;
            WaitForLevel(BusMonitorRec.NewWord, 20000 ns, Timeout, '1');
            if (Timeout) then
              Alert(MonId, "Timeout waiting for new word, DECODER ERROR");
              exit;
            else
              Affirmif(MonId, BusMonitorRec.OutWord = Dataword, "Decoded command word does not match sent command word.");

            end if;
          end if;
        end if;
      end if;
    end loop;
  end process;
  -- #################################################################################################################

  -- #################################################################################################################
  BcProc: process
    variable Manager1Id            : AlertLogIDType;
    variable PrevUnexpectedEdgeCnt : integer := 0;
    variable Cmd                   : std_logic_vector(15 downto 0);
    variable Data                  : std_logic_vector(15 downto 0);
    variable NumRuns               : integer := 10;
    variable Src1                  : integer := 1;
    variable Src2                  : integer := 2;
  begin
    wait for 1 us;
    Manager1Id := NewID("MAN_DEC", TbID);
    log(Manager1Id, "Starting AS4111A_5_1_2_1_1_ZeroCross Test", ALWAYS);
    Cov <= NewID("Cov");
    wait for 1 us;
    ----------------------------------------------------------------------------------------------------
    -- Step 1: send a valid receive command and ensure that the new word is generated for each and that the outword matches the sent data.
    ----------------------------------------------------------------------------------------------------
    wait for 1 us;
    for test in 1 to cNumTests loop
    Log("Test iteration " & to_string(test) & " of " & to_string(cNumTests), ALWAYS);
      for teststep in 0 to 5 loop
        case teststep is
          when 0 =>
            Cmdword <= X"0000";
            Dataword <= X"0000";
          when 1 =>
            Cmdword <= X"FFFF";
            Dataword <= X"FFFF";
          when 2 =>
            Cmdword <= X"5555";
            Dataword <= X"5555";
          when 3 =>
            Cmdword <= X"AAAA";
            Dataword <= X"AAAA";
          when 4 =>
            Cmdword <= X"8C42";
            Dataword <= X"8000";
          when 5 =>
            Cmdword <= X"7C21";
            Dataword <= X"C000";
        end case;
        wait for 0 ns;

        for i in 15 downto 0 loop
          Toggle(MON1);
          wait for 100 ns;
          Send(man_dec_bus, Cmdword, Dataword, 0, SEND_CMD_AND_DATA, MAN_DEC_NO_ERROR, 1);
          wait for tGAP;
          Toggle(MON1);
          wait for 100 ns;
          Send(man_dec_bus, Cmdword, Dataword, 0, SEND_CMD_AND_DATA, MAN_DEC_ZEROCROSS_ERROR, 1, i, - 150 ns);
          wait for tGAP;
          Toggle(MON1);
          wait for 100 ns;
          Send(man_dec_bus, Cmdword, Dataword, 0, SEND_CMD_AND_DATA, MAN_DEC_ZEROCROSS_ERROR, 1, i, 150 ns);
          wait for tGAP;
          wait for tGAP;
        end loop;
      end loop;
    end loop;
    -- ensure that the state is back to IDLE and that the unexpected edge count incremented
    --AffirmIf(Manager1Id, man_dec_bus.ManDecState = 0, "State is not IDLE after unexpected data sync");
    --AffirmIf(Manager1Id, man_dec_bus.UnexpectedEdgeCnt = (PrevUnexpectedEdgeCnt + 34), "UnexpectedEdgeCnt did not increment after unexpected data sync: Prev = " & to_string(PrevUnexpectedEdgeCnt) & " Count = " & to_string(man_dec_bus.UnexpectedEdgeCnt));
    ----------------------------------------------------------------------------------------------------
    wait for 100 us;
    WaitForBarrier(TestDone);
  end process;

end architecture;

configuration man_dec_testctrl_AS4111A_5_1_2_1_1_ZeroCross of osvvm_manchester_decoder_tb is
  for struct
    for manchester_decoder_testctrl1: man_dec_testctrl
      use entity mil1553_tb.man_dec_testctrl(AS4111A_5_1_2_1_1_ZeroCross);
    end for;
  end for;
end configuration;

