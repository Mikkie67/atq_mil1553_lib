--
architecture test1 of manchester_testcntrl is
  signal ExpectedSB, ActualSB : ScoreboardIDType;
begin

  process
    variable tx_data  : std_logic_vector(15 downto 0);
    variable rx_data  : std_logic_vector(15 downto 0);
  begin
    -- Create the scoreboard
    ExpectedSB := NewScoreboard("Manchester Expected");
    ActualSB   := NewScoreboard("Manchester Actual");

    for i in 0 to 65535 loop
      tx_data := std_logic_vector(to_unsigned(i, 16));

      -- Send transaction to encoder
      Send(EncRec, tx_data);

      -- Push expected value to scoreboard
      Push(ExpectedSB, tx_data);

      -- Wait for decoder to report valid data
      wait until rising_edge(Clk) and DecRec.GotData = '1';

      -- Capture the data and push to scoreboard
      rx_data := DecRec.ReceivedData;
      Push(ActualSB, rx_data);

      -- Optional: logging
      log("TX: " & to_hstring(tx_data) & "  RX: " & to_hstring(rx_data));
    end loop;

    -- Compare expected vs actual
    CheckScoreboard(ExpectedSB, ActualSB);

    -- Report result
    ReportAlerts;

    wait;
  end process;

end architecture;
