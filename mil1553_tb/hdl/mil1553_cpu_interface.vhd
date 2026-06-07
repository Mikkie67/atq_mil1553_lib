library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;
use osvvm.RandomPkg.all;
use osvvm.ScoreboardPkg_slv.all;
use osvvm.AlertLogPkg.all;

library mil1553_tb;
context mil1553_tb.mil1553_context;

architecture mil1553_cpu_interface of mil1553_cpu_registers_testctrl is
  signal NEW_CMD_START                  : integer_barrier      := 1;
  signal BC_CMD_SEND_Done, RT_Done      : integer_barrier      := 1;
  signal TbID                           : AlertLogIDType;
  signal SB_RT1                         : ScoreboardIdType;
  signal SB_RT2                         : ScoreboardIdType;
  signal CmdWord                        : std_logic_vector(15 downto 0);
  signal MyRtAddr1, MyRtAddr2, MyBcAddr : integer;
  signal ActiveBus                      : integer range 1 to 2 := 1;
  signal BC_Done                        : bit                  := '0';
  -- #################################################################################################################
begin
  -- create Clock
  Osvvm.ClockResetPkg.CreateClock(
    Clk    => Clk,
    Period => 10 ns
  );
  -- #################################################################################################################

  -- create nReset
  Osvvm.ClockResetPkg.CreateReset(
    Reset       => nReset,
    ResetActive => '0',
    Clk         => Clk,
    Period      => 7 * 10 ns,
    tpd         => 1 ns
  );
  -- #################################################################################################################
  ControlProc: process
  begin
    SetTestName("mil1553_cpu_interface");
    log("mil1553_cpu_interface", ALWAYS);
    SetLogEnable(PASSED, FALSE);
    SetLogEnable(INFO, FALSE);
    SetLogEnable(DEBUG, FALSE);
    TbID <= GetAlertLogID("TB");
    -- Wait for testbench initialization 
    wait for 0 ns;
    wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "mil1553_cpu_interface.txt");
    SetTranscriptMirror(TRUE);
    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;
    -- Wait for test to finish
    WaitForBarrier(TestDone, 10 sec);
    AlertIf(now >= 10 sec, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process;
  -- #################################################################################################################
  BcProc: process
    variable Manager1Id     : AlertLogIDType;
    variable Timeout        : boolean := FALSE;
    variable CmdValues1     : int_array(0 to 100);
    variable CmdValue1_stdv : std_logic_vector(15 downto 0);
    variable ReadData       : std_logic_vector(15 downto 0);
    variable ReadData32     : std_logic_vector(31 downto 0);
    variable RtAddr_i       : integer;
    variable SubAddr_i      : integer;
    variable Len_i          : integer;
    variable ArrayIndex     : integer := 0;
    variable RtAddrTemp1    : std_logic_vector(4 downto 0);
    variable SubAddrTemp    : std_logic_vector(4 downto 0);
    variable LenTemp        : std_logic_vector(4 downto 0);
  begin
    Manager1Id := NewID("CPU");
    wait for 0 ns;
    -- #################################################################################################################
    -- configure the discretes that are driving register bits to fixed values
    MyRtAddr <= "00000";
    MyRtAddrParity <= '0';
    TimeStamp <= (others => '0');
    port_reg_bus1_status <= (others => '0');
    port_reg_bus2_status <= (others => '0');
    port_reg_cmd_rxed1 <= (others => '0');
    port_reg_cmd_rxed2 <= (others => '0');
    port_reg_mode_cmd_rxed1 <= (others => '0');
    port_reg_mode_cmd_rxed2 <= (others => '0');
    port_reg_mode_data_rxed1 <= (others => '0');
    port_reg_mode_data_rxed2 <= (others => '0');
    port_reg_rt_addr <= (others => '0');
    port_reg_rx_cmd1 <= (others => '0');
    port_reg_rx_cmd2 <= (others => '0');
    port_reg_status <= (others => '0');
    port_reg_status_rxed1 <= (others => '0');
    port_reg_status_rxed2 <= (others => '0');
    wait for 0 ns; --to propagate the discretes before using them in next statements
    -- Address bus transaction interface    
    wait until nReset = '1';
    nResetCpu <= '0';
    wait for 100 ns;
    nResetCpu <= '1';
    wait for 100 ns;
    WaitForClock(cpu_bus, 1);

    -- #################################################################################################################
    -- Add any other output signals here as needed, initialized to '0'
    -- First step is to ensure that all the power on reset values are correct
    Log(Manager1Id, "Step 1: Check all registers are at default values after reset", ALWAYS);
    for index in 0 to 63 loop
      Read(cpu_bus, std_logic_vector(to_unsigned(index, 16)), ReadData);
      ReadCheck(cpu_bus, std_logic_vector(to_unsigned(index, 16)), reg_default_array(index));
      if (ReadData /= reg_default_array(index)) then
        AlertIf(Manager1Id, ReadData /= reg_default_array(index),
                "Error: " & reg_string_array(index) & " not at correct default value: Expected =  0x" & to_hstring(reg_default_array(index)) & ", Received = 0x" & to_hstring(ReadData));
      else
        Log(Manager1Id, "Info: " & reg_string_array(index) & " = 0x" & to_hstring(ReadData), ALWAYS);
      end if;
    end loop;
    wait for 1 us;
    -- #################################################################################################################
    -- check al 16 bit from the port_reg_bus1_status feeds correctly to the status register
    -- Step1: set the bit on port_reg_bus1_status
    -- Step2: read the register and check that the bit is set,
    -- Step3: then remove the physical bit input and wait 5 cycles, read it back and make sure it is still at correct value (latched), 
    -- Step4: then clear the bit with a write to the bit and then read it back again to make sure it is cleared
    Log(Manager1Id, "Step 2: Check port_reg_bus1_status drives reg_bus1_status correctly", ALWAYS);
    for bit_index in 0 to 15 loop
      port_reg_bus1_status <= (others => '0');
      port_reg_bus1_status(bit_index) <= '1';
      wait for 0 ns; --to propagate the discretes before using them in next statements
      Read(cpu_bus, reg_bus1_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '1',
               "Error Step2: reg_bus1_status(" & integer'image(bit_index) & ") not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      port_reg_bus1_status(bit_index) <= '0';
      wait for 0 ns; --to propagate the discretes before using them in next statements
      WaitforClock(cpu_bus, 5);
      Read(cpu_bus, reg_bus1_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '1',
               "Error Step3: reg_bus1_status(" & integer'image(bit_index) & ") not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      Write(cpu_bus, reg_bus1_status, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
      Read(cpu_bus, reg_bus1_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '0',
               "Error Step4: reg_bus1_status(" & integer'image(bit_index) & ") not cleared to 0 as expected: Expected = 0, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
    end loop;
    wait for 1 us;
    -- #################################################################################################################
    -- check al 16 bit from the port_reg_bus2_status feeds correctly to the status register
    -- Step1: set the bit on port_reg_bus2_status
    -- Step2: read the register and check that the bit is set,
    -- Step3: then remove the physical bit input and wait 5 cycles, read it back and make sure it is still at correct value (latched), 
    -- Step4: then clear the bit with a write to the bit and then read it back again to make sure it is cleared
    Log(Manager1Id, "Step 3: Check port_reg_bus2_status drives reg_bus2_status correctly", ALWAYS);
    for bit_index in 0 to 15 loop
      port_reg_bus2_status <= (others => '0');
      port_reg_bus2_status(bit_index) <= '1';
      wait for 0 ns; --to propagate the discretes before using them in next statements
      Read(cpu_bus, reg_bus2_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '1',
               "Error Step2: reg_bus2_status(" & integer'image(bit_index) & ") not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      port_reg_bus2_status(bit_index) <= '0';
      wait for 0 ns; --to propagate the discretes before using them in next statements
      WaitforClock(cpu_bus, 5);
      Read(cpu_bus, reg_bus2_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '1',
               "Error Step3: reg_bus2_status(" & integer'image(bit_index) & ") not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      Write(cpu_bus, reg_bus2_status, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
      Read(cpu_bus, reg_bus2_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '0',
               "Error Step4: reg_bus2_status(" & integer'image(bit_index) & ") not cleared to 0 as expected: Expected = 0, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
    end loop;
    wait for 1 us;
    -- #################################################################################################################
    -- test the interrupt generation by writing to the interrupt mask register and then setting a status bit that is enabled in the mask
    -- the interrupt signal is controlled hierarchically. For each bus, the bits in the status register can be enabled in the interrupt mask register
    -- then for the main status register, the mask can be enabled for the different options. This test will first focus on the interrupt generated by the two bus status registers.
    -- Step1: write to the main interrupt mask register to enable bit 0 (bus1 status interrupt)
    -- Step2: enable bit 0 in the bus1 mask register
    -- Step3: set bit 0 in the bus1 status register and check that the interrupt is generated
    -- Step4: clear the bit in the bus1 status register and check that the interrupt is cleared  
    -- Step4: repeat steps 2 and 3 for bit 1 to 15
    Log(Manager1Id, "Step 4: Check interrupt generation from port_reg_bus1_status", ALWAYS);
    for bit_index in 0 to 15 loop
      Write(cpu_bus, reg_status, X"FFFF"); -- clear all the bits in the status register than can be cleared by writing a 1 to them
      -- Enable the mask bit in the main mask register
      Write(cpu_bus, reg_intr_mask, X"0001");
      -- Enable the mask bit in the bus1 mask register
      Write(cpu_bus, reg_bus1_mask, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
      -- trigger the interrupt by setting discrete active high and low against the port_reg_bus1_status
      port_reg_bus1_status(bit_index) <= '1';
      WaitForClock(cpu_bus, 2);
      port_reg_bus1_status <= (others => '0');
      wait for 0 ns;
      WaitForLevel(DiscretesOut.Intr, 50 ns, Timeout, '1');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step1: Hardware interrupt not triggered.", WARNING);
      WaitForLevel(Bus1Intr, 50 ns, Timeout, '1');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step2: Bus 1 Hardware interrupt not triggered.", WARNING);
      -- if it did trigger, check the bus1 status register to make sure it is the right cause
      Read(cpu_bus, reg_bus1_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '1',
               "Error Step3: reg_bus1_status(" & integer'image(bit_index) & ") not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      -- check the main status register to make sure it is the right cause
      port_reg_status(0) <= '1';
      wait for 0 ns;
      Read(cpu_bus, reg_status, ReadData);
      AffirmIf(Manager1Id, ReadData(0) = '1',
               "Error Step4: reg_status(0) not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(0)), WARNING);
      -- clear the latched bit in the status registers by writng to it
      port_reg_status(0) <= '0';
      wait for 0 ns; --to propagate the discretes before using them in next statements
      Write(cpu_bus, reg_bus1_status, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
      -- check that the status register is now cleared
      Read(cpu_bus, reg_bus1_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '0',
               "Error Step5: reg_bus1_status(" & integer'image(bit_index) & ") not set to 0 as expected: Expected = 0, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      -- check that the main status register is now cleared
      Read(cpu_bus, reg_status, ReadData);
      AffirmIf(Manager1Id, ReadData(0) = '0',
               "Error Step6: reg_status(0) not set to 0 as expected: Expected = 0, Received = " & std_logic'image(ReadData(0)), WARNING);
      -- check that the hardware interrupt lines clear
      WaitForLevel(DiscretesOut.Intr, 50 ns, Timeout, '0');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step7: Hardware interrupt not cleared.", WARNING);
      WaitForLevel(Bus1Intr, 50 ns, Timeout, '0');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step8: Bus 1 Hardware interrupt not cleared.", WARNING);
    end loop;
    wait for 1 us;

    -- #################################################################################################################
    -- test the interrupt generation by writing to the interrupt mask register and then setting a status bit that is enabled in the mask
    -- the interrupt signal is controlled hierarchically. For each bus, the bits in the status register can be enabled in the interrupt mask register
    -- then for the main status register, the mask can be enabled for the different options. This test will first focus on the interrupt generated by the two bus status registers.
    -- Step1: write to the main interrupt mask register to enable bit 0 (bus1 status interrupt)
    -- Step2: enable bit 0 in the bus1 mask register
    -- Step3: set bit 0 in the bus1 status register and check that the interrupt is generated
    -- Step4: clear the bit in the bus1 status register and check that the interrupt is cleared  
    -- Step4: repeat steps 2 and 3 for bit 1 to 15
    Log(Manager1Id, "Step 5: Check interrupt generation from port_reg_bus2_status", ALWAYS);
    for bit_index in 0 to 15 loop
      Write(cpu_bus, reg_status, X"FFFF"); -- clear all the bits in the status register than can be cleared by writing a 1 to them
      -- Enable the mask bit in the main mask register
      Write(cpu_bus, reg_intr_mask, X"0002");
      -- Enable the mask bit in the bus1 mask register
      Write(cpu_bus, reg_bus2_mask, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
      -- trigger the interrupt by setting discrete active high and low against the port_reg_bus1_status
      port_reg_bus2_status(bit_index) <= '1';
      WaitForClock(cpu_bus, 2);
      port_reg_bus2_status <= (others => '0');
      wait for 0 ns;
      WaitForLevel(DiscretesOut.Intr, 50 ns, Timeout, '1');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step1: Hardware interrupt not triggered.", WARNING);
      WaitForLevel(Bus2Intr, 50 ns, Timeout, '1');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step2: Bus 2 Hardware interrupt not triggered.", WARNING);
      -- if it did trigger, check the bus1 status register to make sure it is the right cause
      Read(cpu_bus, reg_bus2_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '1',
               "Error Step3: reg_bus2_status(" & integer'image(bit_index) & ") not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      -- check the main status register to make sure it is the right cause
      port_reg_status(1) <= '1';
      wait for 0 ns;
      Read(cpu_bus, reg_status, ReadData);
      AffirmIf(Manager1Id, ReadData(1) = '1',
               "Error Step4: reg_status(1) not set to 1 as expected: Expected = 1, Received = " & std_logic'image(ReadData(1)), WARNING);
      -- clear the latched bit in the status registers by writng to it
      port_reg_status(1) <= '0';
      wait for 0 ns; --to propagate the discretes before using them in next statements
      Write(cpu_bus, reg_bus2_status, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
      -- check that the status register is now cleared
      Read(cpu_bus, reg_bus2_status, ReadData);
      AffirmIf(Manager1Id, ReadData(bit_index) = '0',
               "Error Step5: reg_bus2_status(" & integer'image(bit_index) & ") not set to 0 as expected: Expected = 0, Received = " & std_logic'image(ReadData(bit_index)), WARNING);
      -- check that the main status register is now cleared
      Read(cpu_bus, reg_status, ReadData);
      AffirmIf(Manager1Id, ReadData(1) = '0',
               "Error Step6: reg_status(1) not set to 0 as expected: Expected = 0, Received = " & std_logic'image(ReadData(1)), WARNING);
      -- check that the hardware interrupt lines clear
      WaitForLevel(DiscretesOut.Intr, 50 ns, Timeout, '0');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step7: Hardware interrupt not cleared.", WARNING);
      WaitForLevel(Bus2Intr, 50 ns, Timeout, '0');
      AffirmIf(Manager1Id, Timeout = FALSE,
               "Error Step8: Bus 2 Hardware interrupt not cleared.", WARNING);
    end loop;
    wait for 1 us;
    -- #################################################################################################################
    Log(Manager1Id, "Step 6: Check correct read and write operations", ALWAYS);
    for index in 0 to 63 loop
      case index is
        ----------------------------------------------------------------------------------------------------
        when 0 | 16 | 17 | 18 | 19 | 23 | 32 | 33 | 34 | 35 | 39 | 48 | 49 | 50 | 51 | 55 | 56 =>
          -- read register to get current value
          Read(cpu_bus, std_logic_vector(to_unsigned(index, 16)), ReadData);
          -- write all the bits to the opposite value
          Write(cpu_bus, std_logic_vector(to_unsigned(index, 16)), not ReadData);
          -- read and check that the values is still the same as before
          ReadCheck(cpu_bus, std_logic_vector(to_unsigned(index, 16)), ReadData);
        ----------------------------------------------------------------------------------------------------
        when 2 =>
          -- This register, even though it is read and write is autocleared by hardware 1 cycle later.
          -- so immediatly after writting it, check the output bits from this registers
          -- read register to get current value
          Read(cpu_bus, std_logic_vector(to_unsigned(index, 16)), ReadData);
          -- write all the bits to the opposite value
          Write(cpu_bus, std_logic_vector(to_unsigned(index, 16)), not ReadData);
          -- check the "clearbits"
          AffirmIf(Manager1Id, port_reg_clear_bits = not ReadData,
                   "Error: port_reg_clear_bits not set to value just written to reg_clear_bits: Expected = 0x" & to_hstring(not ReadData) & ", Received = 0x" & to_hstring(port_reg_clear_bits), WARNING);
          -- read and check that the values is still the same as before
          Write(cpu_bus, std_logic_vector(to_unsigned(index, 16)), X"AAAA");
          -- check the "clearbits"
          AffirmIf(Manager1Id, port_reg_clear_bits = X"AAAA",
                   "Error: port_reg_clear_bits not set to value just written to reg_clear_bits: Expected = 0x" & to_hstring(X"AAAA") & ", Received = 0x" & to_hstring(port_reg_clear_bits), WARNING);
          -- read and check that the values is still the same as before
          Write(cpu_bus, std_logic_vector(to_unsigned(index, 16)), X"5555");
          -- check the "clearbits"
          AffirmIf(Manager1Id, port_reg_clear_bits = X"5555",
                   "Error: port_reg_clear_bits not set to value just written to reg_clear_bits: Expected = 0x" & to_hstring(X"5555") & ", Received = 0x" & to_hstring(port_reg_clear_bits), WARNING);
          -- read and check that the values is still the same as before
          ReadCheck(cpu_bus, std_logic_vector(to_unsigned(index, 16)), X"0000"
                   );
        ----------------------------------------------------------------------------------------------------
        when 30 =>
          -- this write to this register only clear the bits that are written.
          -- step 1 is to set its source discretes active and then clear them one by one
          port_reg_bus1_status <= X"FFFF";
          ReadCheck(cpu_bus, reg_bus1_status, X"FFFF");
          for bit_index in 0 to 15 loop
            port_reg_bus1_status <= port_reg_bus1_status and not std_logic_vector(to_unsigned(2 ** bit_index, 16));
            wait for 0 ns;
            Write(cpu_bus, reg_bus1_status, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
            ReadCheck(cpu_bus, reg_bus1_status, port_reg_bus1_status);
          end loop;
          ReadCheck(cpu_bus, reg_bus1_status, X"0000");
        ----------------------------------------------------------------------------------------------------
        when 46 =>
          -- this write to this register only clear the bits that are written.
          -- step 1 is to set its source discretes active and then clear them one by one
          port_reg_bus2_status <= X"FFFF";
          ReadCheck(cpu_bus, reg_bus2_status, X"FFFF");
          for bit_index in 0 to 15 loop
            port_reg_bus2_status <= port_reg_bus2_status and not std_logic_vector(to_unsigned(2 ** bit_index, 16));
            wait for 0 ns;
            Write(cpu_bus, reg_bus2_status, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
            ReadCheck(cpu_bus, reg_bus2_status, port_reg_bus2_status);
          end loop;
          ReadCheck(cpu_bus, reg_bus2_status, X"0000");
        ----------------------------------------------------------------------------------------------------
        when 62 =>
          -- this write to this register only clear the bits that are written.
          -- step 1 is to set its source discretes active and then clear them one by one
          -- the bits in hits subadress register is build when messages are recevied,
          -- to set all the bit, cycle through in order to create each.
          -- first make sure it is empty
          Write(cpu_bus, reg_bus1_mask, X"0000");
          Write(cpu_bus, reg_subaddr_rx_lsb, X"FFFF");
          Write(cpu_bus, reg_subaddr_rx_msb, X"FFFF");
          ReadCheck(cpu_bus, reg_subaddr_rx_lsb, X"0000");
          ReadCheck(cpu_bus, reg_subaddr_rx_msb, X"0000");
          -- to set a bit in th register, fake receipt via the reg_cmd_rxed1 register with the right subaddress
          -- then set the data received bit in the reg_bus1_status register
          ReadData32 := X"00000000";
          for subaddr_index in 0 to 31 loop
            port_reg_cmd_rxed1 <= "000000" & std_logic_vector(to_unsigned(subaddr_index, 5)) & "00000";
            port_reg_bus1_status <= X"0020"; -- set the data received bit
            wait for 0 ns;
            ReadData32 := ReadData32 or std_logic_vector(shift_left(to_unsigned(1, 32), subaddr_index)); -- read back the reg_subaddr_rx_lsb and reg_subaddr_rx_msb to see that the additional bits are set
            ReadCheck(cpu_bus, reg_subaddr_rx_lsb, ReadData32(15 downto 0));
            ReadCheck(cpu_bus, reg_subaddr_rx_msb, ReadData32(31 downto 16));
            port_reg_bus1_status <= X"0000"; -- set the data received bit
            wait for 0 ns;
          end loop;
          -- now all the bits in the sub addrs message is set, lets clear them one by one.
          -- first for the lsb
          for bit_index in 0 to 15 loop
            Read(cpu_bus, reg_subaddr_rx_lsb, ReadData);
            Write(cpu_bus, reg_subaddr_rx_lsb, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
            ReadCheck(cpu_bus, reg_subaddr_rx_lsb, ReadData and not std_logic_vector(to_unsigned(2 ** bit_index, 16)));
          end loop;
          -- first for the msb
          for bit_index in 0 to 15 loop
            Read(cpu_bus, reg_subaddr_rx_msb, ReadData);
            Write(cpu_bus, reg_subaddr_rx_msb, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
            ReadCheck(cpu_bus, reg_subaddr_rx_msb, ReadData and not std_logic_vector(to_unsigned(2 ** bit_index, 16)));
          end loop;
          ReadCheck(cpu_bus, reg_subaddr_rx_lsb, X"0000");
          ReadCheck(cpu_bus, reg_subaddr_rx_msb, X"0000");
        ----------------------------------------------------------------------------------------------------
        when 63 =>
          -- this write to this register only clear the bits that are written.
          -- step 1 is to set its source discretes active and then clear them one by one
          -- the bits in hits subadress register is build when messages are recevied,
          -- to set all the bit, cycle through in order to create each.
          -- first make sure it is empty
          Write(cpu_bus, reg_bus2_mask, X"0000");
          Write(cpu_bus, reg_subaddr_rx_lsb, X"FFFF");
          Write(cpu_bus, reg_subaddr_rx_msb, X"FFFF");
          ReadCheck(cpu_bus, reg_subaddr_rx_lsb, X"0000");
          ReadCheck(cpu_bus, reg_subaddr_rx_msb, X"0000");
          -- to set a bit in th register, fake receipt via the reg_cmd_rxed1 register with the right subaddress
          -- then set the data received bit in the reg_bus1_status register
          ReadData32 := X"00000000";
          for subaddr_index in 0 to 31 loop
            port_reg_cmd_rxed2 <= "000000" & std_logic_vector(to_unsigned(subaddr_index, 5)) & "00000";
            port_reg_bus2_status <= X"0020"; -- set the data received bit
            wait for 0 ns;
            ReadData32 := ReadData32 or std_logic_vector(shift_left(to_unsigned(1, 32), subaddr_index)); -- read back the reg_subaddr_rx_lsb and reg_subaddr_rx_msb to see that the additional bits are set
            ReadCheck(cpu_bus, reg_subaddr_rx_lsb, ReadData32(15 downto 0));
            ReadCheck(cpu_bus, reg_subaddr_rx_msb, ReadData32(31 downto 16));
            port_reg_bus2_status <= X"0000"; -- set the data received bit
            wait for 0 ns;
          end loop;
          -- now all the bits in the sub addrs message is set, lets clear them one by one.
          -- first for the lsb
          for bit_index in 0 to 15 loop
            Read(cpu_bus, reg_subaddr_rx_lsb, ReadData);
            Write(cpu_bus, reg_subaddr_rx_lsb, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
            ReadCheck(cpu_bus, reg_subaddr_rx_lsb, ReadData and not std_logic_vector(to_unsigned(2 ** bit_index, 16)));
          end loop;
          -- first for the msb
          for bit_index in 0 to 15 loop
            Read(cpu_bus, reg_subaddr_rx_msb, ReadData);
            Write(cpu_bus, reg_subaddr_rx_msb, std_logic_vector(to_unsigned(2 ** bit_index, 16)));
            ReadCheck(cpu_bus, reg_subaddr_rx_msb, ReadData and not std_logic_vector(to_unsigned(2 ** bit_index, 16)));
          end loop;
          ReadCheck(cpu_bus, reg_subaddr_rx_lsb, X"0000");
          ReadCheck(cpu_bus, reg_subaddr_rx_msb, X"0000");
        ----------------------------------------------------------------------------------------------------
        when others =>
          -- read/write registers and ensure read data changed as needed (there are some special cases that need to be handled separately)
          -- read register to get current value
          Read(cpu_bus, std_logic_vector(to_unsigned(index, 16)), ReadData);
          -- write all the bits to the opposite value
          Write(cpu_bus, std_logic_vector(to_unsigned(index, 16)), not ReadData);
          -- read and check that the values is still the same as before
          ReadCheck(cpu_bus, std_logic_vector(to_unsigned(index, 16)), not ReadData);
          null;
      end case;
    end loop;
    wait for 1 us;
    -- #################################################################################################################
    -- this test checks the RT addr and parity registers
    Log(Manager1Id, "Step 7: Checks the RT addr and parity registers", ALWAYS);
    -- set the external discretes to a known value
    MyRtAddr <= "10101";
    MyRtAddrParity <= '1'; -- correct parity for 10101
    wait for 0 ns; --to propagate the discretes before using them in next statements
    -- The RT must be reset to latch the new RT address and parity
    -- lets do a hardware reset
    nResetCpu <= '0';
    wait for 100 ns;
    nResetCpu <= '1';
    wait for 100 ns;
    -- the reg_rt_addr is build one level higher from teh discrete input, so I will map those to the register value
    -- the same is hte case of the "internallly used RTaddr"
    port_reg_rt_addr <= "0000000000" & MyRtAddrParity & MyRtAddr;
    ReadCheck(cpu_bus, reg_rt_addr, "0000000000" & '1' & "10101");
    Write(cpu_bus, reg_sw_rt_addr, "0000000000" & '1' & "10111");
    ReadCheck(cpu_bus, reg_sw_rt_addr, "0000000000" & '1' & "10111");
    wait for 1 us;
    -- #################################################################################################################
    WaitForBarrier(TestDone);
  end process;
  -- #################################################################################################################
end architecture;
-- #################################################################################################################
configuration mil1553_cpu_interface_cfg of osvvm_mil1553_cpu_registers_tb is
  for struct
    for TestCntrl_2: mil1553_cpu_registers_testctrl
      use entity mil1553_tb.mil1553_cpu_registers_testctrl(mil1553_cpu_interface);
    end for;
  end for;
end configuration;
