library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.numeric_std_unsigned.all;
  use ieee.math_real.all;
library osvvm;
context osvvm.osvvmcontext;
use osvvm.ScoreboardPkg_slv.all;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

library mil1553_tb;
context mil1553_tb.mil1553_context;

entity man_dec_vc is
  generic (
    MODEL_ID_NAME   : string := "MAN_DEC_VC";
    tperiod_Clk     : time   := 10 ns;
    DEFAULT_DELAY   : time   := 0 ns;
    tpd_Clk_Address : time   := DEFAULT_DELAY;
    tpd_Clk_Write   : time   := DEFAULT_DELAY;
    tpd_Clk_DataIn  : time   := DEFAULT_DELAY
  );
  port (
    CmdEdge           : in    std_logic;
    Cmd_nData         : in    std_logic;
    EarlyReplyRx      : in    std_logic;
    Err_Noise         : in    integer;
    Err_Parity        : in    integer;
    NewWord           : in    std_logic;
    OutWord           : in    std_logic_vector(15 downto 0);
    SyncPosEdge       : in    std_logic;
    man_dec_bus       : inout ManchesterDecRecType;
    Clk               : out   std_logic;
    ClrNoiseErr       : out   std_logic;
    ClrParityErr      : out   std_logic;
    ERP_tmr           : out   std_logic;
    InN               : out   std_logic;
    InP               : out   std_logic;
    -- UnexpectedEdgeCnt : in    std_logic_vector(15 downto 0);
    -- ManDecState       : in    std_logic_vector(4 downto 0);
    nReset            : out   std_logic
  );

  -- Declarations
  -- Name for OSVVM Alerts  
  constant MODEL_INSTANCE_NAME : string := IfElse(MODEL_ID_NAME /= "",
                                                  MODEL_ID_NAME,
                                                  PathTail(to_lower(man_dec_vc'PATH_NAME)));

end entity;

--

architecture rtl of man_dec_vc is
  signal ModelID : AlertLogIDType;
  signal SB      : ScoreboardIdType;
  ----------------------------------------------------------------------------------------------------
  function parity(data : std_logic_vector(15 downto 0)) return std_logic is
    variable result : std_logic := '0';
  begin
    for i in data'range loop
      result := result xor data(i);
    end loop;
    return result;
  end function;
  ----------------------------------------------------------------------------------------------------
  procedure SendCmdSyncPattern(signal InPSig : out std_logic) is
  begin
    -- Send Command Sync Pattern (1 0)
    InPSig <= '1' after 0 ns;
    wait for 1500 ns;
    InPSig <= '0' after 0 ns;
    wait for 1500 ns;
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure SendDataSyncPattern(signal InPSig : out std_logic) is
  begin
    -- Send Data Sync Pattern (0 1)
    InPSig <= '0' after 0 ns;
    wait for 1500 ns;
    InPSig <= '1' after 0 ns;
    wait for 1500 ns;
  end procedure;
  ----------------------------------------------------------------------------------------------------
  -- procedure SendBit(
  --     signal InPSig    : out std_logic;
  --            BitToSend : in  std_logic
  --   ) is
  -- begin
  --   -- Send bit Pattern (1 0 1 0)
  --   InPSig <= BitToSend after 0 ns;
  --   wait for 500 ns;
  --   InPSig <= not BitToSend after 0 ns;
  --   wait for 500 ns;
  -- end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure SendBit(
      signal InPSig     : out std_logic;
             BitToSend  : in  std_logic;
             EdgeOffset : in  time := 0 ns
    ) is
  begin
    -- Send bit Pattern (1 0 1 0)
    InPSig <= BitToSend after 0 ns;
    wait for 500 ns + EdgeOffset;
    InPSig <= not BitToSend after 0 ns;
    wait for 500 ns - EdgeOffset;
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure SendCmdWord(
      signal InPSig  : out std_logic;
             CmdWord : in  std_logic_vector(15 downto 0)
    ) is
  begin
    -- Send Command word pattern
    SendCmdSyncPattern(InPSig);
    for Index in CmdWord'range loop
      SendBit(InPSig, CmdWord(Index));
    end loop;
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure SendDataWord(
      signal InPSig   : out std_logic;
             DataWord : in  std_logic_vector(15 downto 0)
    ) is
  begin
    -- Send Data word pattern
    SendDataSyncPattern(InPSig);
    for Index in DataWord'range loop
      SendBit(InPSig, DataWord(Index));
    end loop;
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure SendCmdWord_Parity(
      signal InPSig     : out std_logic;
             CmdWord    : in  std_logic_vector(15 downto 0);
             ErrorBit   : in  integer := 0;
             EdgeOffset : in  time    := 0 ns
    ) is
  begin
    -- Send Command word pattern
    SendCmdSyncPattern(InPSig);
    for Index in CmdWord'range loop
      if (Index = ErrorBit) and (std_logic_vector(man_dec_bus.ErrorMode) = MAN_DEC_ZEROCROSS_ERROR)  then
        Log("Inserting a zero offset delay of " & to_string(EdgeOffset) & " in bit position " & to_string(ErrorBit),DEBUG);
        SendBit(InPSig, CmdWord(Index), EdgeOffset);
      else
        SendBit(InPSig, CmdWord(Index));
      end if;
    end loop;
    -- Send Parity Bit
    SendBit(InPSig, not parity(CmdWord));
    Push(SB, CmdWord);
    Log("SB Push Command Word: " & to_hstring(CmdWord), DEBUG);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure SendDataWord_Parity(
      signal InPSig   : out std_logic;
             DataWord : in  std_logic_vector(15 downto 0);
             ErrorBit   : in  integer := 0;
             EdgeOffset : in  time    := 0 ns
    ) is
  begin
    -- Send Data word pattern
    SendDataSyncPattern(InPSig);
    for Index in DataWord'range loop
      SendBit(InPSig, DataWord(Index));
    end loop;
    -- Send Parity Bit
    SendBit(InPSig, not parity(DataWord));
    Push(SB, DataWord);
    Log("SB Push Data Word: " & to_hstring(DataWord), DEBUG);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------------
begin
  -- the job of the VCis to toggle the bits going to the decoder based on the drive from teh test controller
  -- the facilities provided will range fomr 
  -- 1. generating a single bit representing a low
  -- 2. generating a single bit representing a high
  -- 3. generating a single command sync pattern
  -- 4. generating a single data sync pattern
  -- 5. generating a complete command word  
  -- 6. generating a complete data word
  -- for all of the above some variations to shift the zero crossing point will be provided 
  -- for all of the above noise can be added to the signal in the form of single clock pulses
  -- for all of the above data word and command word parity errors can be added to the signal (controlled from the test controller)
  ----------------------------------------------------------------------------------------------------
  -- Only INP is driven actively. INN is always the inverse of INP
  INN <= not INP after 0 ns;
  ------------------------------------------------------------
  -- Clk is a free running clock
  ------------------------------------------------------------
  clk_process: process
  begin
    Clk <= '0';
    wait for tperiod_Clk / 2;
    Clk <= '1';
    wait for tperiod_Clk / 2;
  end process;
  ------------------------------------------------------------
  --  Initialize alerts
  ------------------------------------------------------------
  Initialize: process
    variable ID : AlertLogIDType;
  begin
    -- Alerts
    ID := NewID(MODEL_INSTANCE_NAME);
    ModelID <= ID;
    wait;
  end process;
  ------------------------------------------------------------
  --  Transaction Handler
  --  Decodes Transactions and Handlers DUT Interface
  ------------------------------------------------------------
  TransactionHandler: process
    variable Manager1Id : AlertLogIDType;
    alias Operation : ManDecBusOperationType is man_dec_bus.Operation;
    variable LocalCommand : std_logic_vector(15 downto 0);
    variable LocalData    : std_logic_vector(15 downto 0);
    variable Qty          : natural := 0;
    variable Timeout      : boolean := false;
  begin
    Manager1Id := NewID("MAN_DEC_VC");
    SB <= NewID("SB");
    -- Initialize Outputs
    nReset <= '0';
    INP <= 'Z';
    ClrNoiseErr <= '0';
    ClrParityErr <= '0';
    ERP_tmr <= '0';
    man_dec_bus.UnexpectedEdgeCnt <= 0;
    man_dec_bus.ManDecState <= 0;
    wait for 100 ns;
    nReset <= '1';
    WaitForClock(Clk);
    wait for 0 ns; -- Allow ModelID to become valid
    loop
      WaitForTransaction(
        Clk => Clk,
        Rdy => man_dec_bus.Rdy,
        Ack => man_dec_bus.Ack
      );
      LocalCommand := SafeResize(ModelID, man_dec_bus.Command, LocalCommand'length);
      LocalData := SafeResize(ModelID, man_dec_bus.Data, LocalData'length);

      case Operation is
        -- Execute Standard Directive Transactions
        when WAIT_FOR_TRANSACTION =>
          wait for 1 ns;

        -- when WAIT_FOR_CLOCK =>
        --   WaitForClock(Clk, man_dec_bus.IntToModel);

        -- when GET_ALERTLOG_ID =>
        --   cpu_bus.IntFromModel <= integer(ModelID);

        -- Model Transaction Dispatch
        ------------------------------------------------------------
        when SEND_CMD =>
          SendCmdWord_Parity(InP, LocalCommand,man_dec_bus.ErrorBit,man_dec_bus.TimeOffset);
          INP <= 'Z' after 0 ns;
          WaitForLevel(NewWord, tWord + 200 ns, Timeout, '1');
          if (Timeout = false) then
            Log(Manager1Id, "TransactionHandler::SEND_CMD: NewWord received for command", DEBUG);
            AlertIf(Manager1Id,(Cmd_nData = '0'), "TransactionHandler::SEND_CMD: Command/Data signal not indicating command word. Cmd_nData = " & to_string(Cmd_nData));
            if (Cmd_nData = '1') then
              man_dec_bus.CommandIn <= std_logic_vector_max_c(OutWord);
            end if;
          end if;
        ------------------------------------------------------------
        when SEND_DATA =>
          SendDataWord_Parity(InP, LocalData, man_dec_bus.ErrorBit,man_dec_bus.TimeOffset);
          INP <= 'Z' after 0 ns;
          WaitForLevel(NewWord, tWord + 200 ns, Timeout, '1');
          if (Timeout = false) then
            AlertIf(Manager1Id,(Cmd_nData = '1'), "TransactionHandler::SEND_DATA: Command/Data signal not indicating data word, Cmd_nData = " & to_string(Cmd_nData));
            Log(Manager1Id, "TransactionHandler::SEND_DATA: NewWord received for data", DEBUG);
            if (Cmd_nData = '0') then
              man_dec_bus.DataIn <= std_logic_vector_max_c(OutWord);
            end if;
          end if;
        ------------------------------------------------------------
        when SEND_CMD_AND_DATA =>
          SendCmdWord_Parity(InP, LocalCommand, man_dec_bus.ErrorBit,man_dec_bus.TimeOffset);
          for i in 0 to man_dec_bus.NumWords - 1 loop
            SendDataWord_Parity(InP, LocalData + i,man_dec_bus.ErrorBit,man_dec_bus.TimeOffset);
          end loop;
          WaitForLevel(NewWord, tWord + 200 ns, Timeout, '1');
          if (Timeout = false) then
            Log(Manager1Id, "TransactionHandler::SEND_DATA: NewWord received for data", DEBUG);
            AlertIf(Manager1Id,(Cmd_nData = '1'), "TransactionHandler::SEND_DATA: Command/Data signal not indicating data word, Cmd_nData = " & to_string(Cmd_nData));
            if (Cmd_nData = '0') then
              man_dec_bus.DataIn <= std_logic_vector_max_c(OutWord);
            end if;
          end if;
          INP <= 'Z' after 0 ns;
        ------------------------------------------------------------
        when SEND_BIT =>
          Qty := to_integer(unsigned(man_dec_bus.Command));
          while Qty > 0 loop
            for j in 0 to LocalData'length - 1 loop
              SendBit(InP, LocalData(j));
              Qty := Qty - 1;
              exit when Qty = 0;
            end loop;
          end loop;
          INP <= 'Z' after 0 ns;
        ------------------------------------------------------------
        when SEND_CMDSYNC =>
          SendCmdSyncPattern(InP);
          INP <= 'Z' after 0 ns;
        ------------------------------------------------------------
        when SEND_DATASYNC =>
          SendDataSyncPattern(InP);
          INP <= 'Z' after 0 ns;
        ------------------------------------------------------------
        when MULTIPLE_DRIVER_DETECT =>
          Alert(ModelID,
                "Multiple Drivers on Transaction Record." & "  Transaction # " & to_string(man_dec_bus.Rdy),
                FAILURE);
        when others =>
          Alert(ModelID, "Unimplemented Transaction: " & to_string(Operation), FAILURE);

      end case;
      wait for 2500 ns;
      -- man_dec_bus.UnexpectedEdgeCnt <= to_integer(unsigned(UnexpectedEdgeCnt));
      -- man_dec_bus.ManDecState <= to_integer(unsigned(ManDecState));
      wait for 0 ns;
    end loop;
  end process;

  DecoderMonitor: process
    variable Manager1Id : AlertLogIDType;
    variable RecvWord   : std_logic_vector(15 downto 0);
    variable Timeout    : boolean := false;
  begin
    Manager1Id := NewID("DEC_MON");
    wait for 0 ns;
    loop
      WaitForLevel(NewWord, '1');
      Log(Manager1Id, "DecoderMonitor::DEC_MON: NewWord received for data", DEBUG);
      if (Cmd_nData = '0') then
        man_dec_bus.DataIn <= std_logic_vector_max_c(OutWord);
      elsif (Cmd_nData = '1') then
        man_dec_bus.CommandIn <= std_logic_vector_max_c(OutWord);
      end if;
      FindAndFlush(SB, OutWord);
      wait until NewWord = '0';
    end loop;

  end process;
end architecture;

