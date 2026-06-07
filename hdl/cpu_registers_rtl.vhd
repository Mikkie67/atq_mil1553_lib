-- hds interface_start
LIBRARY ieee;
USE ieee.std_logic_1164.all;
--USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--USE ieee.std_logic_arith.all;
ENTITY mil1553_cpu_registers IS
   GENERIC( 
      gID      : std_logic_vector(15 downto 0) := X"BEEF";
      gVersion : std_logic_vector(15 downto 0) := X"0203"
   );
   PORT( 
      Addr                   : IN     std_logic_vector (15 DOWNTO 0);
      Cs                     : IN     std_logic;
      DataIn                 : IN     std_logic_vector (15 DOWNTO 0);
      Rd                     : IN     std_logic;
      Wr                     : IN     std_logic;
      clk                    : IN     std_logic;
      nReset                 : IN     std_logic;
      DataOut                : OUT    std_logic_vector (15 DOWNTO 0);
      DataValid              : OUT    std_logic;
      Intr                   : OUT    std_logic;
      reg_tmr_SAF            : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_intr_mask          : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_subaddr2     : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_subaddr1     : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_tmr_REP            : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_status_rxed1       : IN     std_logic_vector (15 DOWNTO 0);
      reg_tmr_NRP            : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_rx_mode1     : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_rx_mode2     : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_tx_mode1     : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_tx_mode2     : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_brdcst_mode1 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_legal_brdcst_mode2 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_gID                : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_mode_data_rxed1    : IN     std_logic_vector (15 DOWNTO 0);
      reg_tmr_1us            : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_tmr_GAP            : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_fw_version         : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_rt_addr            : IN     std_logic_vector (15 DOWNTO 0);
      reg_mode_cmd_rxed1     : IN     std_logic_vector (15 DOWNTO 0);
      reg_clear_bits         : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_node_control       : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_err_inj_data       : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_status             : IN     std_logic_vector (15 DOWNTO 0);
      reg_rx_cmd1            : IN     std_logic_vector (15 DOWNTO 0);
      reg_tx_control1        : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_cmd_proc_start1    : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_cmd_proc_length1   : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_cmd_rxed1          : IN     std_logic_vector (15 DOWNTO 0);
      reg_24                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_25                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_26                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_27                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_28                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_29                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_bus1_status        : IN     std_logic_vector (15 DOWNTO 0);
      reg_bus1_mask          : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_status_rxed2       : IN     std_logic_vector (15 DOWNTO 0);
      reg_mode_cmd_rxed2     : IN     std_logic_vector (15 DOWNTO 0);
      reg_mode_data_rxed2    : IN     std_logic_vector (15 DOWNTO 0);
      reg_rx_cmd2            : IN     std_logic_vector (15 DOWNTO 0);
      reg_tx_control2        : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_cmd_proc_start2    : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_cmd_proc_length2   : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_cmd_rxed2          : IN     std_logic_vector (15 DOWNTO 0);
      reg_40                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_41                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_42                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_43                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_44                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_45                 : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_bus2_status        : IN     std_logic_vector (15 DOWNTO 0);
      reg_bus2_mask          : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_repeat_rate        : BUFFER std_logic_vector (15 DOWNTO 0);
      TimeStamp              : IN     std_logic_vector (63 DOWNTO 0);
      reg_wrap_subaddr       : BUFFER std_logic_vector (15 DOWNTO 0);
      Bus1Intr               : BUFFER std_logic;
      Bus2Intr               : BUFFER std_logic;
      reg_vectorword         : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_bit                : BUFFER std_logic_vector (15 DOWNTO 0);
      reg_sw_rtaddr          : BUFFER std_logic_vector (15 DOWNTO 0);
      MyRtAddrParity         : IN     std_logic;
      MyRtAddr               : IN     std_logic_vector (4 DOWNTO 0)
   );

-- Declarations

END ENTITY mil1553_cpu_registers ;
-- hds interface_end

ARCHITECTURE rtl OF mil1553_cpu_registers IS
  signal Timestamp0 : std_logic_vector(15 downto 0);
  signal Timestamp1 : std_logic_vector(15 downto 0);
  signal Timestamp2 : std_logic_vector(15 downto 0);
  signal Timestamp3 : std_logic_vector(15 downto 0);
  signal reg_subaddr_rx : std_logic_vector(31 downto 0);
  signal Bus1StatusRegLatched : std_logic_vector(15 downto 0);
  signal Bus2StatusRegLatched : std_logic_vector(15 downto 0);
  signal GenIntr : std_logic;
  signal sFirstTime : std_logic;
BEGIN

  reg_fw_version <= gVersion;

  Intr <= GenIntr or Bus1Intr or Bus2Intr;
  process (nReset,Clk)
  begin
    if (nReset = '0') then
     --reg_status <= X"0000";     --addr 0
      reg_intr_mask <= X"0000";   --addr 1
      reg_clear_bits <= X"0000";  --addr 2
      reg_tmr_1us <= X"0063";     --addr 3
      reg_tmr_GAP <= X"018F"; 
      reg_tmr_NRP <= X"0577";
      reg_tmr_REP <= X"0195";
      reg_tmr_SAF <= X"031F";
      reg_legal_subaddr1 <= X"FFFF"; --addr 8
      reg_legal_subaddr2 <= X"FFFF";
      reg_legal_rx_mode1 <= X"0000";
      reg_legal_rx_mode2 <= X"0032";
      reg_legal_tx_mode1 <= X"01FF";
      reg_legal_tx_mode2 <= X"000D";
      reg_legal_brdcst_mode1 <= X"01FA";
      reg_legal_brdcst_mode2 <= X"0032";
      -- BUS 1 registers
      --reg_status_rxed1 <= X"0000"; --> Read only
      --reg_mode_cmd_rxed1 <= X"0000"; --> Read only
      --reg_mode_data_rxed1 <= X"0000"; --> Read only
      --reg_rx_cmd <= X"0000"; --> Read only
      reg_tx_control1 <= X"0000";
      reg_cmd_proc_start1 <= X"0000";
      reg_cmd_proc_length1 <= X"0000";
      --reg_cmdrxed1 --addr 0x17  --> Read only
      reg_24 <= X"0000";
      reg_25 <= X"0000";
      reg_26 <= X"0000";
      reg_27 <= X"0000";
      reg_28 <= X"0000";
      reg_29 <= X"0000";
      --reg_bus1_status  --addr 0x1E
      reg_bus1_mask <= X"0000"; --addr 0x1F

      -- BUS 2 registers
      --reg_status_rxed2 <= X"0000"; --> Read only
      --reg_mode_cmd_rxed2 <= X"0000"; --> Read only
      --reg_mode_data_rxed2 <= X"0000"; --> Read only
      --reg_rx_cmd2 <= X"0000"; --> Read only
      reg_tx_control2 <= X"0000";
      reg_cmd_proc_start2 <= X"0000";
      reg_cmd_proc_length2 <= X"0000";
      --reg_cmdrxed2 --addr 0x27  --> Read only
      reg_40 <= X"0000";
      reg_41 <= X"0000";
      reg_42 <= X"0000";
      reg_43 <= X"0000";
      reg_44 <= X"0000";
      reg_45 <= X"0000";
      --reg_bus1_status  --addr 0x2E
      reg_bus2_mask <= X"0000"; --addr 0x2F
      Timestamp3 <= X"0000"; -- addr 0x30
      Timestamp2 <= X"0000";
      Timestamp1 <= X"0000";
      Timestamp0 <= X"0000";
      -- BusBusy is set at reset --> host needs to clear it
      -- Hardware data wrap is enabled --> for the default Subaddr 30
      reg_node_control <= X"8103";
      reg_err_inj_data <= X"0000";
      reg_gID <= gID;
      -- reg_fw_version <= gVersion; --Hardcoded, never changes after compile
      -- reg_rt_addr <= X"0000"; --addr 0x38
      reg_repeat_rate <= X"0014"; -- 20 ms default
      reg_wrap_subaddr <= X"001E";
      reg_vectorword <= X"0000";
      reg_bit <= X"0000";
      sFirstTime <= '1';
      reg_sw_rtaddr <= X"0000";

      Bus1StatusRegLatched <= (others => '0');
      Bus2StatusRegLatched <= (others => '0');
      reg_subaddr_rx <= (others => '0');
      Bus1Intr <= '0';
      Bus2Intr <= '0';
      GenIntr <= '0';
      DataValid <= '0';
    elsif (clk'event and clk='1') then
      -- Latch signals at start-up
      if (sFirstTime = '1') then
        sFirstTime    <= '0';
        reg_sw_rtaddr <= "0000000000" & MyRtAddrParity & MyRtAddr;
      end if;
      --Default assignments
      DataValid <= '0';
      Timestamp0 <= Timestamp(15 downto 0);
      Timestamp1 <= Timestamp(31 downto 16);
      Timestamp2 <= Timestamp(47 downto 32);
      Timestamp3 <= Timestamp(63 downto 48);
      if (reg_bus1_status(5) = '1') then
        reg_subaddr_rx(to_integer(unsigned(reg_cmd_rxed1(9 downto 5)))) <= '1';
      end if;
      if (reg_bus2_status(5) = '1') then
        reg_subaddr_rx(to_integer(unsigned(reg_cmd_rxed2(9 downto 5)))) <= '1';
      end if;
      -- latch the bus status register inputs
      Bus1StatusRegLatched <= Bus1StatusRegLatched OR reg_bus1_status;
      Bus2StatusRegLatched <= Bus2StatusRegLatched OR reg_bus2_status;
     -- set the bus IRQ output based on bus Status and bus Mask registers 
      if ((Bus1StatusRegLatched AND reg_bus1_mask) /= X"0000") then
        Bus1Intr <= '1';
      else
        Bus1Intr <= '0';
      end if;
      if ((Bus2StatusRegLatched AND reg_bus2_mask) /= X"0000") then
        Bus2Intr <= '1';
      else
        Bus2Intr <= '0';
      end if;
      -- SendMessage Bit clears when its txavail becomes zero
      -- Removed this to force a repeat of cmdproc until the register is cleared
      if (reg_tx_control1(14) = '1') then
        reg_tx_control1(14) <= not reg_status(15); 
      end if;
      if (reg_tx_control2(14) = '1') then
        reg_tx_control2(14) <= not reg_status(14); 
      end if;
      -- reg_ClearBits resets after one clock cycle once written
      reg_clear_bits <= (others => '0');
      -- set the IRQ output based on Status and Mask registers 
      -- (it happens on the next clock cycle)
      if ((reg_status AND reg_intr_mask) /= X"0000") then
        GenIntr <= '1';
      else
        GenIntr <= '0';
      end if;
      if (Rd = '1' and Cs = '1') then
        DataValid <= '1';
        case Addr is
        when X"0000" => DataOut <= reg_status;
        when X"0001" => DataOut <= reg_intr_mask;
        when X"0002" => DataOut <= reg_clear_bits;
        when X"0003" => DataOut <= reg_tmr_1us;
        when X"0004" => DataOut <= reg_tmr_GAP;
        when X"0005" => DataOut <= reg_tmr_NRP;
        when X"0006" => DataOut <= reg_tmr_REP;
        when X"0007" => DataOut <= reg_tmr_SAF;
        when X"0008" => DataOut <= reg_legal_subaddr1;
        when X"0009" => DataOut <= reg_legal_subaddr2;
        when X"000A" => DataOut <= reg_legal_rx_mode1;
        when X"000B" => DataOut <= reg_legal_rx_mode2;
        when X"000C" => DataOut <= reg_legal_tx_mode1;
        when X"000D" => DataOut <= reg_legal_tx_mode2;
        when X"000E" => DataOut <= reg_legal_brdcst_mode1;
        when X"000F" => DataOut <= reg_legal_brdcst_mode2;
        when X"0010" => DataOut <= reg_status_rxed1;
        when X"0011" => DataOut <= reg_mode_cmd_rxed1;
        when X"0012" => DataOut <= reg_mode_data_rxed1;
        when X"0013" => DataOut <= reg_rx_cmd1;
        when X"0014" => DataOut <= reg_tx_control1;
        when X"0015" => DataOut <= reg_cmd_proc_start1;
        when X"0016" => DataOut <= reg_cmd_proc_length1;
        when X"0017" => DataOut <= reg_cmd_rxed1;
        when X"0018" => DataOut <= reg_24;
        when X"0019" => DataOut <= reg_25;
        when X"001A" => DataOut <= reg_26;
        when X"001B" => DataOut <= reg_27;
        when X"001C" => DataOut <= reg_28;
        when X"001D" => DataOut <= reg_29;
        when X"001E" => DataOut <= Bus1StatusRegLatched;
        when X"001F" => DataOut <= reg_bus1_mask;
        when X"0020" => DataOut <= reg_status_rxed2;
        when X"0021" => DataOut <= reg_mode_cmd_rxed2;
        when X"0022" => DataOut <= reg_mode_data_rxed2;
        when X"0023" => DataOut <= reg_rx_cmd2;
        when X"0024" => DataOut <= reg_tx_control2;
        when X"0025" => DataOut <= reg_cmd_proc_start2;
        when X"0026" => DataOut <= reg_cmd_proc_length2;
        when X"0027" => DataOut <= reg_cmd_rxed2;
        when X"0028" => DataOut <= reg_40;
        when X"0029" => DataOut <= reg_41;
        when X"002A" => DataOut <= reg_42;
        when X"002B" => DataOut <= reg_43;
        when X"002C" => DataOut <= reg_44;
        when X"002D" => DataOut <= reg_45;
        when X"002E" => DataOut <= Bus2StatusRegLatched;
        when X"002F" => DataOut <= reg_bus2_mask;
        when X"0030" => DataOut <= Timestamp3;
        when X"0031" => DataOut <= Timestamp2;
        when X"0032" => DataOut <= Timestamp1;
        when X"0033" => DataOut <= Timestamp0;
        when X"0034" => DataOut <= reg_node_control;
        when X"0035" => DataOut <= reg_err_inj_data;
        when X"0036" => DataOut <= reg_gID;
        when X"0037" => DataOut <= gVersion;
        when X"0038" => DataOut <= reg_rt_addr;
        when X"0039" => DataOut <= reg_repeat_rate;
        when X"003A" => DataOut <= reg_wrap_subaddr;
        when X"003B" => DataOut <= reg_vectorword;
        when X"003C" => DataOut <= reg_bit;
        when X"003D" => DataOut <= reg_sw_rtaddr;
        when X"003E" => DataOut <= reg_subaddr_rx(31 downto 16);
        when X"003F" => DataOut <= reg_subaddr_rx(15 downto 0);
        when others  => DataOut <= X"DEAD";
        end case;
        -------------------
        -- WRITE SECTION --
        -------------------
      elsif (Wr = '1' and Cs = '1') then
        case Addr is
        --when X"0000" =>  reg_status <= DataIn; --> Read only
        when X"0001" =>  reg_intr_mask <= DataIn;
        when X"0002" =>  reg_clear_bits <= DataIn;
        when X"0003" =>  reg_tmr_1us <= DataIn;
        when X"0004" =>  reg_tmr_GAP <= DataIn;
        when X"0005" =>  reg_tmr_NRP <= DataIn;
        when X"0006" =>  reg_tmr_REP <= DataIn;
        when X"0007" =>  reg_tmr_SAF <= DataIn;
        when X"0008" =>  reg_legal_subaddr1 <= DataIn;
        when X"0009" =>  reg_legal_subaddr2 <= DataIn;
        when X"000A" =>  reg_legal_rx_mode1 <= DataIn;
        when X"000B" =>  reg_legal_rx_mode2 <= DataIn;
        when X"000C" =>  reg_legal_tx_mode1 <= DataIn;
        when X"000D" =>  reg_legal_tx_mode2 <= DataIn;
        when X"000E" =>  reg_legal_brdcst_mode1 <= DataIn;
        when X"000F" =>  reg_legal_brdcst_mode2 <= DataIn;
          --when X"0010" =>  reg_status_rxed1 <= DataIn; --> Read only
          --when X"0011" =>  reg_mode_cmd_rxed1 <= DataIn; --> Read only
          --when X"0012" =>  reg_mode_data_rxed1 <= DataIn; --> Read only
          --when X"0013" =>  reg_rx_cmd <= DataIn; --> Read only
        when X"0014" =>  reg_tx_control1 <= DataIn;
        when X"0015" =>  reg_cmd_proc_start1 <= DataIn;
        when X"0016" =>  reg_cmd_proc_length1 <= DataIn;
        when X"0018" =>  reg_24 <= DataIn;
        when X"0019" =>  reg_25 <= DataIn;
        when X"001A" =>  reg_26 <= DataIn;
        when X"001B" =>  reg_27 <= DataIn;
        when X"001C" =>  reg_28 <= DataIn;
        when X"001D" =>  reg_29 <= DataIn;
        -- writing to the bus status register clears the set bits in the write command
        when X"001E" =>  Bus1StatusRegLatched <= Bus1StatusRegLatched  AND (not DataIn);
        when X"001F" =>  reg_bus1_mask <= DataIn;
          --when X"0020" =>  reg_status_rxed2 <= DataIn; --> Read only
          --when X"0021" =>  reg_mode_cmd_rxed2 <= DataIn; --> Read only
          --when X"0022" =>  reg_mode_data_rxed2 <= DataIn; --> Read only
          --when X"0023" =>  reg_rx_cmd2 <= DataIn; --> Read only
        when X"0024" =>  reg_tx_control2 <= DataIn;
        when X"0025" =>  reg_cmd_proc_start2 <= DataIn;
        when X"0026" =>  reg_cmd_proc_length2 <= DataIn;
        when X"0028" =>  reg_40 <= DataIn;
        when X"0029" =>  reg_41 <= DataIn;
        when X"002A" =>  reg_42 <= DataIn;
        when X"002B" =>  reg_43 <= DataIn;
        when X"002C" =>  reg_44 <= DataIn;
        when X"002D" =>  reg_45 <= DataIn;
        -- writing to the bus status register clears the set bits in the write command
        when X"002E" =>  Bus2StatusRegLatched <= Bus2StatusRegLatched  AND (not DataIn);
        when X"002F" =>  reg_bus2_mask <= DataIn;
        -- The timestamp registers sit in this region of 0x30 to 0x33
        when X"0034" =>  reg_node_control <= DataIn;
        when X"0035" =>  reg_err_inj_data <= DataIn;
        when X"0036" =>  reg_gID <= DataIn;
        --when X"0037" =>  reg_fw_version <= DataIn; --> Read only
        --when X"0038" =>  reg_rt_addr <= DataIn; --> Read only
        when X"0039" =>  reg_repeat_rate <= DataIn;
        when X"003A" =>  reg_wrap_subaddr <= DataIn;
        when X"003B" =>  reg_vectorword <= DataIn;
        when X"003C" =>  reg_bit <= DataIn;
        when X"003D" =>  reg_sw_rtaddr <= DataIn;
        when X"003E" =>  reg_subaddr_rx(31 downto 16) <= reg_subaddr_rx(31 downto 16) and (not DataIn);
        when X"003F" =>  reg_subaddr_rx(15 downto 0 ) <= reg_subaddr_rx(15 downto  0) and (not DataIn);
        when others => null;
        end case;
      end if;
    end if;
  end process;
END ARCHITECTURE rtl;

