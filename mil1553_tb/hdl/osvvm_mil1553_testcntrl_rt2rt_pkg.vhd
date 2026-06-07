library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

library osvvm;
context osvvm.OsvvmContext;
use osvvm.RandomPkg.all;
use osvvm.ScoreboardPkg_slv.all;
use osvvm.AlertLogPkg.all;

library mil1553_tb;
  use mil1553_tb.osvvm_mil1553_pkg.all;
  use mil1553_tb.osvvm_mil1553_testcntrl_component_pkg.all; -- Test Control Component Package

package osvvm_mil1553_testcntrl_rt2rt_pkg is
  procedure BC_RT2RT(
           CmdRtAddr1   :       integer;
           CmdRtAddr2   :       integer;
           SubAddr      :       integer;
           Len          :       integer;
           MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
           MyRtAddr1    :       integer;
           MyRtAddr2    :       integer;
           MyBcAddr     :       integer;
    signal CmdWord1     : in    std_logic_vector(15 downto 0);
    signal CmdWord2     : in    std_logic_vector(15 downto 0);
    signal cpu_bus      : inout AddressBus16Type;
    signal DiscretesOut : in    CoreDiscretesOut_type;
           SB_RT        :       ScoreboardIdType;
           SB_BC        :       ScoreboardIdType;
           AlertLogID   :       AlertLogIDType
  );
  procedure BC_RT2RT_Check(
           CmdRtAddr1   :       integer;                   -- destination RT to receive the data
           CmdRtAddr2   :       integer;                   -- source RT sending the data
           SubAddr      :       integer;                   -- subaddress to send the data to
           Len          :       integer;                   -- length 0=32 bytes
           MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
           MyRtAddr1    :       integer;
           MyRtAddr2    :       integer;
           MyBcAddr     :       integer;
    signal CmdWord1     : in    std_logic_vector(15 downto 0);
    signal CmdWord2     : in    std_logic_vector(15 downto 0);
    signal cpu_bus      : inout AddressBus16Type;          -- Avalon cpu bus to core
    signal DiscretesOut : in    CoreDiscretesOut_type;     -- discretes driven by the core, such as "outen" and "intr"
           SB_RT        :       ScoreboardIdType;
           SB_BC        :       ScoreboardIdType;
           AlertLogID   :       AlertLogIDType
  );

  procedure RT_RT2RT(
           MyRtAddr     :       integer; -- destination RT to receive the data
           OtherRtAddr  :       integer;
    signal CmdWord1     : in    std_logic_vector(15 downto 0);
    signal CmdWord2     : in    std_logic_vector(15 downto 0);
    signal cpu_bus      : inout AddressBus16Type;
    signal DiscretesOut : in    CoreDiscretesOut_type;
           SB_RT        :       ScoreboardIDType;
           SB_BC        :       ScoreboardIDType;
           AlertLogID   :       AlertLogIDType
  );
end package;

package body osvvm_mil1553_testcntrl_rt2rt_pkg is
  ----------------------------------------------------------------------------------------------------
  procedure BC_RT2RT(
             CmdRtAddr1   :       integer;
             CmdRtAddr2   :       integer;
             SubAddr      :       integer;
             Len          :       integer;
             MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
             MyRtAddr1    :       integer;
             MyRtAddr2    :       integer;
             MyBcAddr     :       integer;
      signal CmdWord1     : in    std_logic_vector(15 downto 0);
      signal CmdWord2     : in    std_logic_vector(15 downto 0);
      signal cpu_bus      : inout AddressBus16Type;
      signal DiscretesOut : in    CoreDiscretesOut_type;
             SB_RT        :       ScoreboardIdType;
             SB_BC        :       ScoreboardIdType;
             AlertLogID   :       AlertLogIDType
    ) is
    variable Timeout    : boolean;
    variable MilBusStdv : std_logic_vector(15 downto 0);

  begin
    -- Validate the input values
    Log(AlertLogID, "Entering BC_RT2RT", DEBUG);
    AlertIf(AlertLogId, CmdRtAddr1 > 31, "RT1 Address is invalid"); -- for RT2BC, address 31 (broadcast) is not valid, but is tested here to provide BC NRP timeout.
    AlertIf(AlertLogId, CmdRtAddr2 > 31, "RT2 Address is invalid"); -- for RT2BC, address 31 (broadcast) is not valid, but is tested here to provide BC NRP timeout.
    AlertIf(AlertLogId,(CmdRtAddr2 = 31), "RT2 Address cannot be broadcast"); -- for RT2BC, address 31 (broadcast) is not valid, but is tested here to provide BC NRP timeout.
    AlertIf(AlertLogId,((SubAddr = 0) or (SubAddr > 30)), "Sub Address invalid");
    AlertIf(AlertLogId, Len > 31, "Word length invalid");
    Log(AlertLogID, "CmdRtAddr1=" & to_string(CmdRtAddr1), DEBUG);
    Log(AlertLogID, "CmdRtAddr2=" & to_string(CmdRtAddr2), DEBUG);
    Log(AlertLogID, "MyRtAddr1=" & to_string(MyRtAddr1), DEBUG);
    Log(AlertLogID, "MyRtAddr2=" & to_string(MyRtAddr2), DEBUG);
    MilBusStdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MilBus, 16))), 4));
    -- Set the active BC bus (RT autodetects)
    if (MilBus = 1) then
      Write(cpu_bus, reg_node_control, bitBrdcstEn); -- Set BUS 1 Active
    else
      Write(cpu_bus, reg_node_control, bitBrdcstEn or bitActiveBus); -- Set BUS 2 Active
    end if;
    -- Set BUS 1 CmdProcStart and Length for two commands
    SetCmdProc(cpu_bus, MilBus, X"0000", X"0002");
    -- Build the command word from the input variables
    wait for 0 ns;
    -- Set the RT2RT bit first
    write(cpu_bus, reg_tx_controlX or MilBusStdv, bitRT2RT);
    Write(cpu_bus, X"0400", CmdWord1); -- first position in the TxCmdProc
    write(cpu_bus, reg_tx_controlX or MilBusStdv, X"0000");
    Write(cpu_bus, X"0401", CmdWord2); -- second position in the TxCmdProc
    ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
    Write(cpu_bus, reg_tx_controlX or MilBusStdv, bitSendMessage);
    if (MilBus = 1) then
      WaitForLevel(DiscretesOut.OutEn1, tGAP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC OutEn1 did not go HIGH as expected");
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      WaitForLevel(DiscretesOut.OutEn1, tWord * 2, Timeout, '0');
      AlertIf(AlertLogID, Timeout, "BC OutEn1 did not go LOW as expected");
    else
      WaitForLevel(DiscretesOut.OutEn2, tGAP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC OutEn2 did not go HIGH as expected");
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      WaitForLevel(DiscretesOut.OutEn2, tWord * 2, Timeout, '0');
      AlertIf(AlertLogID, Timeout, "BC OutEn2 did not go LOW as expected");
    end if;
    Log(AlertLogID, "Exiting BC_RT2RT", DEBUG);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure BC_RT2RT_Check(
             CmdRtAddr1   :       integer;                   -- destination RT to receive the data
             CmdRtAddr2   :       integer;                   -- source RT sending the data
             SubAddr      :       integer;                   -- subaddress to send the data to
             Len          :       integer;                   -- length 0=32 bytes
             MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
             MyRtAddr1    :       integer;
             MyRtAddr2    :       integer;
             MyBcAddr     :       integer;
      signal CmdWord1     : in    std_logic_vector(15 downto 0);
      signal CmdWord2     : in    std_logic_vector(15 downto 0);
      signal cpu_bus      : inout AddressBus16Type;          -- Avalon cpu bus to core
      signal DiscretesOut : in    CoreDiscretesOut_type;     -- discretes driven by the core, such as "outen" and "intr"
             SB_RT        :       ScoreboardIdType;
             SB_BC        :       ScoreboardIdType;
             AlertLogID   :       AlertLogIDType
    ) is
    variable RV         : RandomPType;
    variable Timeout    : boolean;
    variable MilBusStdv : std_logic_vector(15 downto 0);
    variable WordLen    : integer;
    variable RxRamAddr  : integer;
    variable RxData     : std_logic_vector(15 downto 0);
  begin
    Log(AlertLogID, "Entering BC_RT2RT_Check", DEBUG);
    -- Validate the input values
    wait for 1 us; -- this is just to allow the BC to propagate the data received flag.
    AlertIf(AlertLogId, CmdRtAddr1 > 31, "RT1 Address is invalid"); -- for RT2BC, address 31 (broadcast) is not valid, but is tested here to provide BC NRP timeout.
    AlertIf(AlertLogId, CmdRtAddr2 > 31, "RT2 Address is invalid"); -- for RT2BC, address 31 (broadcast) is not valid, but is tested here to provide BC NRP timeout.
    AlertIf(AlertLogId,(CmdRtAddr2 = 31), "RT2 Address cannot be broadcast"); -- for RT2BC, address 31 (broadcast) is not valid, but is tested here to provide BC NRP timeout.
    AlertIf(AlertLogId,((SubAddr = 0) or (SubAddr > 30)), "Sub Address invalid");
    AlertIf(AlertLogId, Len > 31, "Word length invalid");
    Alertif(AlertLogID, CmdWord1(9 downto 0) /= CmdWord2(9 downto 0), "The Subaddresses and the length has to be the same");
    WordLen := to_integer(unsigned(CmdWord1(4 downto 0)));
    if (WordLen = 0) then
      WordLen := 32;
    end if;
    Log(AlertLogID, "MilBus = " & to_string(MilBus), DEBUG);
    MilBusStdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MilBus, 16))), 4));
    --######################################################################################################################
    -- Non-matching RTs or Broadcast messages shall have no Status reply
    -- this is the case where neither RT address matches
    if (((CmdRtAddr1 /= MyRtAddr1) and (CmdRtAddr1 /= MyRtAddr2)) and ((MyRtAddr1 /= CmdRtAddr2) and (MyRtAddr2 /= CmdRtAddr2))) then
      Log(AlertLogID, "STEP1:  if (((CmdRtAddr1 /= MyRtAddr1) and (CmdRtAddr1 /= MyRtAddr2)) and ((MyRtAddr1 /= CmdRtAddr2) and (MyRtAddr2 /= CmdRtAddr1))) then --> CmdRtAddr1=" & to_string(CmdRtAddr1), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tNRP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for NRP timer");
      ReadCheckMask(cpu_bus, reg_busX_status or MilBusStdv, bitNRP, IrqMask, AlertLogID); -- Check that NRP bit intr for bus is set
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      --######################################################################################################################
      -- STEP2 is for both addresses matching and valid transfer with ending CS should occur
    elsif ((MyRtAddr1 = CmdRtAddr1) and (MyRtAddr2 = CmdRtAddr2)) or ((MyRtAddr1 = CmdRtAddr2) and (MyRtAddr2 = CmdRtAddr1)) then
      -- This should result is a valid transfer with data and final CS from receiving RT
      Log(AlertLogID, "STEP2: elsif ((MyRtAddr1 = CmdRtAddr1) and (MyRtAddr2 = CmdRtAddr2)) or ( (MyRtAddr1 = CmdRtAddr2) and (MyRtAddr2 = CmdRtAddr1)) then = " & to_string(CmdRtAddr1), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tREP + tStatus + (tWord * WordLen), Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for Status and Data from Tx RT");
      ReadCheckMask(cpu_bus,(reg_busX_status or MilBusStdv),(bitStatusRxedFlag or bitDataReceived), IrqMask, AlertLogID); -- Check that CS bit for bus is set
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts

      ReadCheckMask(cpu_bus,(reg_statusword_rxedX or MilBusStdv),CmdWord1 and X"F800",X"FFFF",AlertLogID); -- Check that CS for bus is set
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      -- loop through the received data and compare with SB
      for i in 1 to WordLen loop
        Log(AlertLogID, "WordLen = " & to_string(WordLen), DEBUG);
        -- 0x0800 = 2048 --> offset of RxRam
        RxRamAddr := 2047 + (SubAddr * 32) + i;
        Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), RxData);
        Check(SB_BC, RxData);
        --Check(SB_RT, RxData); -- not really needed, but might as well check and flush
      end loop;
      -- Flush the RT SB since no RT to read it

      --######################################################################################################################
      -- The case where the receiver is in the network, but not the transmitter
      -- in this case, the BC will timeout because it does not see the transmission from the transmitter before NRP
    elsif ((MyRtAddr1 = CmdRtAddr1) and (MyRtAddr2 /= CmdRtAddr2)) or ((MyRtAddr1 /= CmdRtAddr2) and (MyRtAddr2 = CmdRtAddr1)) then
      --######################################################################################################################
      Log(AlertLogID, "STEP3: elsif ((MyRtAddr1 = CmdRtAddr1) and (MyRtAddr2 /= CmdRtAddr2)) or ((MyRtAddr1 /= CmdRtAddr2) and (MyRtAddr2 = CmdRtAddr1)) then --> RTAddr=" & to_string(CmdRtAddr1), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tNRP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for NRP from RT");
      ReadCheckMask(cpu_bus,(reg_busX_status or MilBusStdv), bitNRP, IrqMask,AlertLogID); -- Check that CS bit for bus is set
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      --######################################################################################################################
      -- The case where the transmitter is in the network, but not the receiver
      -- in this case, the BC will receive the status interrupt, and then the data received interrupt
      -- The BC will compare the data to ensure it is correct
      -- since there is not receiver present, the BC will not receive the receiver status word and should trigger an NRP
      -- The BC will only enter this code AFTER the transmitting RT sent all the data (and set is BARRIER)
      -- so the interrupt would already be active, and the next one would be for the NRP
    elsif ((MyRtAddr1 /= CmdRtAddr1) and (MyRtAddr2 = CmdRtAddr2)) or ((MyRtAddr1 = CmdRtAddr2) and (MyRtAddr2 /= CmdRtAddr1)) then
      Log(AlertLogID, "STEP4: elsif ((MyRtAddr1 /= CmdRtAddr1) and (MyRtAddr2 = CmdRtAddr2)) or ((MyRtAddr1 = CmdRtAddr2) and (MyRtAddr2 /= CmdRtAddr1)) then --> RTAddr=" & to_string(CmdRtAddr1), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tNRP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for Status and Data from Tx RT");
      if (CmdRtAddr1 = 31) then
        ReadCheckMask(cpu_bus,(reg_busX_status or MilBusStdv),(bitStatusRxedFlag or bitDataReceived), IrqMask, AlertLogID); -- Check that CS bit for bus is set
      else
        ReadCheckMask(cpu_bus,(reg_busX_status or MilBusStdv),(bitStatusRxedFlag or bitDataReceived), IrqMask, AlertLogID); -- Check that CS bit for bus is set
      end if;
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      if (CmdRtAddr1 /= 31) then
        -- wait for the NRP timeout
        wait for 100 ns;
        Log(AlertLogID, "BC Waiting for the NRP IRQ due to no CS", DEBUG);
        WaitForLevel(DiscretesOut.Intr, tNRP, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for NRP from Rx RT");
        ReadCheckMask(cpu_bus,(reg_busX_status or MilBusStdv), bitNRP, IrqMask, AlertLogID); -- Check that CS bit for bus is set
        ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      end if;
      -- loop through the received data and compare with SB
      for i in 1 to WordLen loop
        Log(AlertLogID, "WordLen = " & to_string(WordLen), DEBUG);
        -- 0x0800 = 2048 --> offset of RxRam
        RxRamAddr := 2047 + (SubAddr * 32) + i;
        Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), RxData);
        Check(SB_BC, RxData);
        if (CmdRtAddr1 /= 31) then
          Check(SB_RT, RxData);
        end if;
      end loop;
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      --######################################################################################################################
    else
      Log(AlertLogID, "STEP5: else --> RTAddr=" & to_string(CmdRtAddr1), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tWord, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for Status from RT");
      ReadCheck(cpu_bus,(reg_busX_status or MilBusStdv),((bitStatusRxedFlag or bitDataReceived) and IrqMask)); -- Check that CS bit for bus is set
      ReadCheck(cpu_bus,(reg_statusword_rxedX or MilBusStdv),(CmdWord1 and X"F800")); -- Check that CS for bus is set
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      -- loop through the received data and compare with SB
      for i in 1 to WordLen loop
        Log(AlertLogID, "WordLen = " & to_string(WordLen), DEBUG);
        -- 0x0800 = 2048 --> offset of RxRam
        RxRamAddr := 2047 + (SubAddr * 32) + i;
        Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), RxData);
        Check(SB_BC, RxData);
      end loop;
    end if;
    ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
    Log(AlertLogID, "Exiting BC_RT2RT_Check", DEBUG);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure RT_RT2RT(
             MyRtAddr     :       integer;
             OtherRtAddr  :       integer;
      signal CmdWord1     : in    std_logic_vector(15 downto 0);
      signal CmdWord2     : in    std_logic_vector(15 downto 0);
      signal cpu_bus      : inout AddressBus16Type;
      signal DiscretesOut : in    CoreDiscretesOut_type;
             SB_RT        :       ScoreboardIDType;
             SB_BC        :       ScoreboardIDType;
             AlertLogID   :       AlertLogIDType
    ) is
    variable RV         : RandomPType;
    variable RandomData : std_logic_vector(15 downto 0);
    variable WordLen    : integer;
    variable RxRamAddr  : integer;
    variable TxRamAddr  : integer;
    variable Timeout    : boolean;
    variable SubAddr    : integer;
    variable CmdRtAddr1 : integer;
    variable CmdRtAddr2 : integer;
    variable MilBusStdv : std_logic_vector(15 downto 0);
    variable MilBus     : integer;
    variable Test       : std_logic_vector(15 downto 0);
  begin
    Log(AlertLogID, "Entering RT_RT2RT", DEBUG);
    RV.InitSeed(T => now); -- Initialize the random number generator
    -- Validate the input values
    CmdRtAddr1 := to_integer(unsigned(CmdWord1(15 downto 11)));
    CmdRtAddr2 := to_integer(unsigned(CmdWord2(15 downto 11)));
    SubAddr := to_integer(unsigned(CmdWord1(9 downto 5)));
    WordLen := to_integer(unsigned(CmdWord1(4 downto 0)));
    if (WordLen = 0) then
      WordLen := 32;
    end if;
    -- Case where THIS ONE receiving RT matches the command RT and CmdAddr2 matches the other RT in the network
    if (((MyRtAddr = CmdRtAddr1) or (CmdRtAddr1 = 31)) and (OtherRtAddr = CmdRtAddr2)) then -- perform the reception of data (like BC2RT code)
      Log(AlertLogID, "RT STEP1 RX Command for this RT = " & to_string(MyRtAddr) & " and TX Command for RT = " & to_string(OtherRtAddr), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tREP + tStatus + (tWord * WordLen), Timeout, '1');
      Log(AlertLogID, "IRQ Received", DEBUG);
      AlertIf(AlertLogID, Timeout, "RT" & to_string(CmdRtAddr1) & " did not receive Intr as expected");
      -- Now check which bus created the IRQ in order to work with correct bus registers
      Read(cpu_bus, reg_status, Test);
      if ((Test and X"0001") = X"0001") then
        MilBusStdv := X"0010";
      elsif ((Test and X"0002") = X"0002") then
        MilBusStdv := X"0020";
      else
        MilBusStdv := X"0010"; -- default to bus 1
      end if;
      wait for 0 ns;
      -- 6. Check the bus 1 status
      ReadCheckMask(cpu_bus, reg_busX_status or MilBusStdv, bitDataReceived, IrqMask, AlertLogID); -- mask out the other timers
      ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID); -- Clear all latched interrupts
      -- 7. Check the last received command word
      ReadCheck(cpu_bus, reg_cmd_rxedX or MilBusStdv, CmdWord1);
      wait for 0 ns;
      -- 8. Check the actual data agaisnt scoreboard dataÍ
      -- write the length number of random words
      for i in 1 to WordLen loop
        Log(AlertLogID, "WordLen = " & to_string(WordLen), DEBUG);
        -- 0x0800 = 2048 --> offset of TxRam
        RxRamAddr := 2047 + (SubAddr * 32) + i;
        Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), RandomData);
        Check(SB_RT, RandomData);
      end loop;
      AlertIf(AlertLogID, not IsEmpty(SB_RT), "Error: SB_RT is not empty");
      -- Need to wait for the status message to complete before exiting this check
      wait for tREP + tWord;
      -- 9. Clear the interrupts
      ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID); -- Clear all latched interrupts
      ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID); -- Clear all latched interrupts
      --######################################################################################################################
    elsif ((MyRtAddr = CmdRtAddr2) and ((OtherRtAddr = CmdRtAddr1) or (CmdRtAddr1 = 31))) then -- do the transmission of data (like RT2BC code).  
      Log(AlertLogID, "RT STEP2 TX Command for this RT = " & to_string(MyRtAddr) & " and RX Command for RT = " & to_string(OtherRtAddr), DEBUG);
      -- write the length number of random words
      for i in 1 to WordLen loop --start at 0 and end 1 sooner for the sake of address offsets in TxRam
        -- 0x0400 = 1024 --> offset of TxRam
        TxRamAddr := 1023 + (SubAddr * 32) + i;
        RandomData := RV.RandSlv(Min => 0, Max => 65525, Size => 16);
        -- push the data to both RT SB and BC SB
        Push(SB_RT, RandomData);
        Push(SB_BC, RandomData);
        Write(cpu_bus, std_logic_vector(to_unsigned(TxRamAddr, 16)), RandomData);
        Log(AlertLogID, "TxData: Addr= " & to_hstring(std_logic_vector(to_unsigned(TxRamAddr, 16))) & " Data= " & to_hstring(RandomData), DEBUG);
      end loop;
      AlertIf(AlertLogID, GetFifoCount(SB_RT) /= WordLen, "Error in number items pushed to SB_RT: " & to_String(GetFifoCount(SB_RT)));
      AlertIf(AlertLogID, GetFifoCount(SB_BC) /= WordLen, "Error in number items pushed to SB_BC: " & to_String(GetFifoCount(SB_BC)));
      WaitForLevel(DiscretesOut.Intr, tWord+tGAP, Timeout, '1');
      Log(AlertLogID, "IRQ Received", DEBUG);
      AlertIf(AlertLogID, Timeout, "RT" & to_string(CmdRtAddr2) & " did not receive Intr as expected");
      -- Now check which bus created the IRQ in order to work with correct bus registers
      Read(cpu_bus, reg_status, Test);
      if ((Test and X"0001") = X"0001") then
        MilBusStdv := X"0010";
        MilBus := 1;
      elsif ((Test and X"0002") = X"0002") then
        MilBusStdv := X"0020";
        MilBus := 2;
      else
        MilBusStdv := X"0010"; -- default to bus 1
        MilBus := 1;
      end if;
      wait for 0 ns;
      -- 6. Check the bus 1 status
      ReadCheckMask(cpu_bus, reg_busX_status or MilBusStdv, bitDataReq, IrqMask, AlertLogID); -- mask out the other timers
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      -- 7. Check the last received command word
      ReadCheck(cpu_bus, reg_cmd_rxedX or MilBusStdv, CmdWord2);
      wait for 0 ns;
      -- 8. Send the status word followed by the data
      -- Need to wait for the status message to complete before exiting this check
      wait for tREP + tWord;
      if (MilBus = 1) then
        WaitForLevel(DiscretesOut.OutEn1, tGAP, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "RT OutEn1 did not go HIGH as expected");
        ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
        WaitForLevel(DiscretesOut.OutEn1, tStatus + (tWord * WordLen), Timeout, '0');
        AlertIf(AlertLogID, Timeout, "RT OutEn1 did not go LOW as expected");
      else
        WaitForLevel(DiscretesOut.OutEn2, tGAP, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "RT OutEn2 did not go HIGH as expected");
        ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
        WaitForLevel(DiscretesOut.OutEn2, tStatus + (tWord * WordLen), Timeout, '0');
        AlertIf(AlertLogID, Timeout, "RT OutEn2 did not go LOW as expected");
      end if;

      -- 9. Clear the interrupts
      ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID); -- Clear all latched interrupts
      ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID); -- Clear all latched interrupts
      --######################################################################################################################
      -- This RT is the transmitter, but the other Receiver is not in the network
    elsif (MyRtAddr = CmdRtAddr2) and (OtherRtAddr /= CmdRtAddr1) then -- do the transmission of data (like RT2BC code).
      Log(AlertLogID, "TX Command for this RT = " & to_string(MyRtAddr) & " and RX Command NOT for RT = " & to_string(OtherRtAddr), DEBUG);
      -- write the length number of random words
      for i in 1 to WordLen loop --start at 0 and end 1 sooner for the sake of address offsets in TxRam
        -- 0x0400 = 1024 --> offset of TxRam
        TxRamAddr := 1023 + (SubAddr * 32) + i;
        RandomData := RV.RandSlv(Min => 0, Max => 65525, Size => 16);
        -- push the data to both RT SB and BC SB
        Push(SB_RT, RandomData);
        Push(SB_BC, RandomData);
        Write(cpu_bus, std_logic_vector(to_unsigned(TxRamAddr, 16)), RandomData);
        Log(AlertLogID, "TxData: Addr= " & to_hstring(std_logic_vector(to_unsigned(TxRamAddr, 16))) & " Data= " & to_hstring(RandomData), DEBUG);
      end loop;
      AlertIf(AlertLogID, GetFifoCount(SB_RT) /= WordLen, "Error in number items pushed to SB_RT: " & to_String(GetFifoCount(SB_RT)));
      AlertIf(AlertLogID, GetFifoCount(SB_BC) /= WordLen, "Error in number items pushed to SB_BC: " & to_String(GetFifoCount(SB_BC)));
      WaitForLevel(DiscretesOut.Intr, tWord, Timeout, '1');
      Log(AlertLogID, "IRQ Received", DEBUG);
      AlertIf(AlertLogID, Timeout, "RT" & to_string(CmdRtAddr2) & " did not receive Intr as expected");
      -- Now check which bus created the IRQ in order to work with correct bus registers
      Read(cpu_bus, reg_status, Test);
      if ((Test and X"0001") = X"0001") then
        MilBusStdv := X"0010";
        MilBus := 1;
      elsif ((Test and X"0002") = X"0002") then
        MilBusStdv := X"0020";
        MilBus := 2;
      else
        MilBusStdv := X"0010"; -- default to bus 1
        MilBus := 1;
      end if;
      wait for 0 ns;
      -- 6. Check the bus 1 status
      ReadCheckMask(cpu_bus, reg_busX_status or MilBusStdv, bitDataReq, IrqMask, AlertLogID); -- mask out the other timers
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      -- 7. Check the last received command word
      ReadCheck(cpu_bus, reg_cmd_rxedX or MilBusStdv, CmdWord2);
      wait for 0 ns;
      -- 8. Send the status word followed by the data
      -- Need to wait for the status message to complete before exiting this check
      wait for tREP + tWord;
      if (MilBus = 1) then
        WaitForLevel(DiscretesOut.OutEn1, tGAP, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "RT OutEn1 did not go HIGH as expected");
        ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
        WaitForLevel(DiscretesOut.OutEn1, tStatus + (tWord * WordLen), Timeout, '0');
        AlertIf(AlertLogID, Timeout, "RT OutEn1 did not go LOW as expected");
      else
        WaitForLevel(DiscretesOut.OutEn2, tGAP, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "RT OutEn2 did not go HIGH as expected");
        ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
        WaitForLevel(DiscretesOut.OutEn2, tStatus + (tWord * WordLen), Timeout, '0');
        AlertIf(AlertLogID, Timeout, "RT OutEn2 did not go LOW as expected");
      end if;
      -- 9. Clear the interrupts
      ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID); -- Clear all latched interrupts
      ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID); -- Clear all latched interrupts
      --######################################################################################################################
      -- This RT is the receiver, but the transmitter is not in the network
    elsif (((MyRtAddr = CmdRtAddr1) or (CmdRtAddr1 = 31)) and (OtherRtAddr /= CmdRtAddr2)) then -- perform the reception of data (like BC2RT code)
      Log(AlertLogID, "RX Command for this RT = " & to_string(MyRtAddr) & " but TX Command NOT for RT = " & to_string(OtherRtAddr), DEBUG);
      -- the RT will enter the "Wait1stWord" but would not exit because of no data arriving from transmitting RT.
      -- eventually, when the new command comes in again, this RT will reset to receiving the new command.
      -- but in this test case, just exit the test. There should also be nothing in the SB because no data was transmitted
      -- Need to wait for the status message to complete before exiting this check
      wait for tREP + tWord;
      -- 9. Clear the interrupts
    else
      Log(AlertLogID, "Command NOT for this RT=" & to_string(MyRtAddr), DEBUG);
    end if;
    Log(AlertLogID, "Exiting RT_RT2RT procedure", DEBUG);
  end procedure;
end package body;
