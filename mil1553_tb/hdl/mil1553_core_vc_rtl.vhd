--
-- VHDL Architecture mil1553_tb.mil1553_core_vc.rtl
--
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

entity mil1553_core_vc is
  generic (
    MODEL_ID_NAME   : string := "MIL1553_VC";
    tperiod_Clk     : time   := 10 ns;
    DEFAULT_DELAY   : time   := 1 ns;
    tpd_Clk_Address : time   := DEFAULT_DELAY;
    tpd_Clk_Write   : time   := DEFAULT_DELAY;
    tpd_Clk_DataIn  : time   := DEFAULT_DELAY
  );
  port (
    -- VC reset and clock signals
    nReset           : in    std_logic;
    Clk              : in    std_logic;
    -- cpu bus interface signals
    DataOut          : in    std_logic_vector(15 downto 0);
    DataValid        : in    std_logic;
    Intr             : in    std_logic;
    Addr             : out   std_logic_vector(15 downto 0);
    Cs               : out   std_logic;
    DataIn           : out   std_logic_vector(15 downto 0);
    Rd               : out   std_logic;
    Wr               : out   std_logic;
    -- Address bus transaction interface
    cpu_bus          : inout AddressBus16Type;
    DiscretesIn      : in    CoreDiscretesIn_type;
    DiscretesOut     : out   CoreDiscretesOut_type;
    OutEn1           : in    std_logic;
    Strobe1          : in    std_logic;
    OutEn2           : in    std_logic;
    Strobe2          : in    std_logic;
    MyRtAddr         : out   std_logic_vector(4 downto 0);
    MyRtAddrParity   : out   std_logic;
    BitWord          : out   std_logic_vector(15 downto 0);
    ServiceReqVector : out   std_logic_vector(15 downto 0);
    ServiceRequest   : out   std_logic;
    SubsystemFlag    : out   std_logic;
    ClkOut           : out   std_logic;
    nResetOut        : out   std_logic
  );

  -- Declarations
  -- Name for OSVVM Alerts  
  constant MODEL_INSTANCE_NAME : string := IfElse(MODEL_ID_NAME /= "",
                                                  MODEL_ID_NAME,
                                                  PathTail(to_lower(mil1553_core_vc'PATH_NAME)));

end entity;

--

architecture rtl of mil1553_core_vc is
  signal ModelID : AlertLogIDType;
begin
  ClkOut    <= Clk;
  nResetOut <= DiscretesIn.nReset;

  MyRtAddr             <= DiscretesIn.MyRtAddr;
  MyRtAddrParity       <= DiscretesIn.MyRtAddrParity;
  BitWord              <= DiscretesIn.BitWord;
  ServiceReqVector     <= DiscretesIn.ServiceReqVector;
  ServiceRequest       <= DiscretesIn.ServiceRequest;
  SubsystemFlag        <= DiscretesIn.SubsystemFlag;
  DiscretesOut.OutEn1  <= OutEn1;
  DiscretesOut.OutEn2  <= OutEn2;
  DiscretesOut.Strobe1 <= Strobe1;
  DiscretesOut.Strobe2 <= Strobe2;
  DiscretesOut.Intr    <= Intr;

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
    alias Operation : AddressBusOperationType is cpu_bus.Operation;
    variable ExpectedData : DataOut'subtype;
    variable LocalAddress : Addr'subtype;
    variable LocalData    : DataIn'subtype;

    variable NumFifoElements : integer; -- number of fifo elements
  begin
    -- Initialize Outputs
    Addr <= (Addr'range => 'X');
    Wr <= 'X';
    Rd <= 'X';
    Cs <= 'X';
    DataIn <= (DataIn'range => 'X');

    wait for 0 ns; -- Allow ModelID to become valid

    loop
      WaitForTransaction(
        Clk => Clk,
        Rdy => cpu_bus.Rdy,
        Ack => cpu_bus.Ack
      );
      LocalAddress := SafeResize(ModelID, cpu_bus.Address, Addr'length);
      LocalData := SafeResize(ModelID, cpu_bus.DataToModel, DataIn'length);

      case Operation is
        -- Execute Standard Directive Transactions
        when WAIT_FOR_TRANSACTION =>
          wait for 1 ns;

        when WAIT_FOR_CLOCK =>
          WaitForClock(Clk, cpu_bus.IntToModel);

        when GET_ALERTLOG_ID =>
          cpu_bus.IntFromModel <= integer(ModelID);

        -- Model Transaction Dispatch
        when WRITE_OP =>
          WaitForClock(Clk);
          Addr <= LocalAddress after tpd_Clk_Address;
          DataIn <= LocalData after tpd_Clk_DataIn;
          Wr <= '1' after tpd_Clk_Write;
          Rd <= '0' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;

          WaitForClock(Clk);

          -- Write Operation Accepted at this clock edge
          Log(ModelID,
              "Write Operation, Address: " & to_hxstring(LocalAddress) & "  Data: " & to_hxstring(DataIn) & "  Operation# " & to_string(cpu_bus.Rdy),
              INFO,
              cpu_bus.StatusMsgOn
             );
          Addr <= not LocalAddress after tpd_Clk_Address ;
          DataIn   <= not DataIn    after tpd_Clk_DataIn ;
          Wr <= '0' after tpd_Clk_Write;
          Rd <= '0' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;

        when READ_OP | READ_CHECK =>
          WaitForClock(Clk);
          Addr <= LocalAddress after tpd_Clk_Address;
          Wr <= '0' after tpd_Clk_Write;
          Rd <= '1' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;
          -- ACTUALLY  I WANT TO WAIT FOR DATAVALID AND CLK
          WaitForClock(Clk);
          Rd <= '0' after tpd_Clk_Write;
          WaitForLevel(DataValid, '1');
          WaitForClock(Clk);
          cpu_bus.DataFromModel <= SafeResize(ModelID, DataOut, cpu_bus.DataFromModel'length);
          Addr <= not LocalAddress  after tpd_Clk_Address;
          Wr <= '0' after tpd_Clk_Write;
          Rd <= '0' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;

          if IsReadCheck(Operation) then
            ExpectedData := SafeResize(ModelID, cpu_bus.DataToModel, ExpectedData'length);
            AffirmIfEqual(ModelID,
                          DataOut,
                          ExpectedData,
                          "ReadCheck Operation, Address: " & to_hxstring(LocalAddress) & "  Operation# " & to_string(cpu_bus.Rdy) & "  Data: ",
                          cpu_bus.StatusMsgOn or IsLogEnabled(ModelID, INFO)
                         );
          else
            Log(ModelID,
                "Read Operation, Address: " & to_hxstring(LocalAddress) & "  Data: " & to_hxstring(DataOut) & "  Operation# " & to_string(cpu_bus.Rdy),
                INFO,
                cpu_bus.StatusMsgOn
               );
          end if;

        when WRITE_AND_READ =>
          Addr <= LocalAddress after tpd_Clk_Address;
          DataIn <= LocalData after tpd_Clk_DataIn;
          Wr <= '1' after tpd_Clk_Write;
          Rd <= '0' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;

          WaitForClock(Clk);
          Log(ModelID,
              "Write Operation, Address: " & to_hxstring(LocalAddress) & "  Data: " & to_hxstring(DataIn) & "  Operation# " & to_string(cpu_bus.Rdy),
              INFO,
              cpu_bus.StatusMsgOn
             );
          Addr <= not LocalAddress after tpd_Clk_Address;
          DataIn <= not DataIn after tpd_Clk_DataIn;
          Wr <= '0' after tpd_Clk_Write;
          Rd <= '0' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;

          WaitForClock(Clk);
          -- ACTUALLY  I WANT TO WAIT FOR DATAVALID AND CLK
          cpu_bus.DataFromModel <= SafeResize(ModelID, DataOut, cpu_bus.DataFromModel'length);

          if IsReadCheck(Operation) then
            ExpectedData := SafeResize(ModelID, cpu_bus.DataToModel, ExpectedData'length);
            AffirmIfEqual(ModelID,
                          DataOut,
                          ExpectedData,
                          "Read Operation, Address: " & to_hxstring(LocalAddress) & "  Operation# " & to_string(cpu_bus.Rdy) & "  Data: ",
                          cpu_bus.StatusMsgOn or IsLogEnabled(ModelID, INFO)
                         );
          else
            Log(ModelID,
                "Read Operation, Address: " & to_hxstring(LocalAddress) & "  Data: " & to_hxstring(DataOut) & "  Operation# " & to_string(cpu_bus.Rdy),
                INFO,
                cpu_bus.StatusMsgOn
               );
          end if;

        when WRITE_BURST =>
          log(ModelID,
              "Initiating write burst operation in DpRamController",
              INFO,
              cpu_bus.StatusMsgOn);

          -- Get number of FIFO elements
          NumFifoElements := cpu_bus.DataWidth;
          log(ModelID,
              "Number of FIFO elements = " & to_string(NumFifoElements),
              INFO,
              cpu_bus.StatusMsgOn);

          -- Get Starting address
          LocalAddress := SafeResize(ModelID, cpu_bus.Address, Addr'length);
          log(ModelID,
              "Start address = " & to_hxstring(LocalAddress),
              INFO,
              cpu_bus.StatusMsgOn);

          -- Do write burst
          for WriteLoop in 1 to NumFifoElements loop
            -- write operation starts by presenting address, data, and write indicator
            Addr <= LocalAddress after tpd_Clk_Address;
            DataIn <= Pop(cpu_bus.WriteBurstFifo) after tpd_Clk_DataIn;
            Wr <= '1' after tpd_Clk_Write;
            Rd <= '0' after tpd_Clk_Write;
            Cs <= '1' after tpd_Clk_Address;

            WaitForClock(Clk);

            -- Write Operation Accepted at this clock edge
            Log(ModelID,
                "Write Operation, Address: " & to_hxstring(LocalAddress) & "  Data: " & to_hxstring(DataIn) & "  Operation# " & to_string(cpu_bus.Rdy),
                INFO,
                cpu_bus.StatusMsgOn);

            -- Increment LocalAddress
            LocalAddress := LocalAddress + 1;
          end loop;
          --Addr <= not LocalAddress after tpd_Clk_Address ;
          --DataIn   <= not DataIn    after tpd_Clk_DataIn ;  
          Wr <= '0' after tpd_Clk_Write;
          Rd <= '0' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;

        when READ_BURST =>
          log(ModelID,
              "Initiating read burst operation in DpRamController",
              INFO,
              cpu_bus.StatusMsgOn);

          -- Get number of FIFO elements
          NumFifoElements := cpu_bus.DataWidth;
          log(ModelID,
              "Number of FIFO elements = " & to_string(NumFifoElements),
              INFO,
              cpu_bus.StatusMsgOn);

          -- Get Starting address
          LocalAddress := SafeResize(ModelID, cpu_bus.Address, Addr'length);
          log(ModelID,
              "Start address = " & to_hxstring(LocalAddress),
              INFO,
              cpu_bus.StatusMsgOn);

          -- Do read burst:
          -- read operation starts by presenting address
          Addr <= LocalAddress after tpd_Clk_Address;
          Wr <= '0' after tpd_Clk_Write;
          Rd <= '1' after tpd_Clk_Write;
          Cs <= '1' after tpd_Clk_Address;

          WaitForClock(Clk);

          for ReadLoop in 1 to NumFifoElements loop
            -- read Operation Accepted at this clock edge

            -- Increment LocalAddress and present next address
            LocalAddress := LocalAddress + 1;
            --Addr <= LocalAddress after tpd_Clk_Address ;
            Wr <= '0' after tpd_Clk_Write;
            Rd <= '0' after tpd_Clk_Write;
            Cs <= '1' after tpd_Clk_Address;
            WaitForClock(Clk);

            -- read operations copmleted at this clock edge and data available @DataOut
            --            Push(cpu_bus.ReadBurstFifo, SafeResize(ModelID, DataOut, cpu_bus.DataFromModel'length));
            Push(cpu_bus.ReadBurstFifo, DataOut); -- FifoWidth matches size of DataOut

            Log(ModelID,
                "Read Operation, Address: " & to_hxstring(LocalAddress - 1) & -- "... - 1" since read is from previous loop
                "  Data: " & to_hxstring(DataOut) & "  Operation# " & to_string(cpu_bus.Rdy),
                INFO,
                cpu_bus.StatusMsgOn
               );
          end loop;

        when MULTIPLE_DRIVER_DETECT =>
          Alert(ModelID,
                "Multiple Drivers on Transaction Record." & "  Transaction # " & to_string(cpu_bus.Rdy),
                FAILURE);

        when others =>
          Alert(ModelID, "Unimplemented Transaction: " & to_string(Operation), FAILURE);

      end case;
    end loop;
  end process;

end architecture;

