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

package osvvm_mil1553_testcntrl_rt2bc_pkg is
  procedure BC_RT2BC(
           RtAddr       :       integer;
           SubAddr      :       integer;
           Len          :       integer;
           MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
           MyRtAddr1    :       integer;
           MyRtAddr2    :       integer;
           MyBcAddr     :       integer;
    signal CmdWord      : inout std_logic_vector(15 downto 0);
    signal cpu_bus      : inout AddressBus16Type;
    signal DiscretesOut : in    CoreDiscretesOut_type;
           SB_RT1       :       ScoreboardIdType;
           SB_RT2       :       ScoreboardIdType;
           AlertLogID   :       AlertLogIDType
  );
  procedure BC_RT2BC_Check(
           RtAddr       :       integer;                   -- destination RT to receive the data
           SubAddr      :       integer;                   -- subaddress to send the data to
           Len          :       integer;                   -- length 0=32 bytes
           MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
           MyRtAddr1    :       integer;
           MyRtAddr2    :       integer;
           MyBcAddr     :       integer;
    signal CmdWord      : inout std_logic_vector(15 downto 0);
    signal cpu_bus      : inout AddressBus16Type;          -- Avalon cpu bus to core
    signal DiscretesOut : in    CoreDiscretesOut_type;     -- discretes driven by the core, such as "outen" and "intr"
           SB_RT1       :       ScoreboardIdType;
           SB_RT2       :       ScoreboardIdType;
           AlertLogID   :       AlertLogIDType
  );

  procedure RT_RT2BC(
           MyRtAddr     :       integer; -- destination RT to receive the data
           CmdWord      : in    std_logic_vector(15 downto 0);
    signal cpu_bus      : inout AddressBus16Type;
    signal DiscretesOut : in    CoreDiscretesOut_type;
           SB           :       ScoreboardIDType;
           AlertLogID   :       AlertLogIDType
  );
end package;

package body osvvm_mil1553_testcntrl_rt2bc_pkg is
  ----------------------------------------------------------------------------------------------------
  procedure BC_RT2BC(
             RtAddr       :       integer;
             SubAddr      :       integer;
             Len          :       integer;
             MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
             MyRtAddr1    :       integer;
             MyRtAddr2    :       integer;
             MyBcAddr     :       integer;
      signal CmdWord      : inout std_logic_vector(15 downto 0);
      signal cpu_bus      : inout AddressBus16Type;
      signal DiscretesOut : in    CoreDiscretesOut_type;
             SB_RT1       :       ScoreboardIdType;
             SB_RT2       :       ScoreboardIdType;
             AlertLogID   :       AlertLogIDType
    ) is
    variable Timeout    : boolean;
    variable MilBusStdv : std_logic_vector(15 downto 0);

  begin
    -- Validate the input values
    AlertIf(AlertLogId, RtAddr > 31, "RT Address invalid"); -- for RT2BC, address 31 (broadcast) is not valid, but is tested here to provide BC NRP timeout.
    AlertIf(AlertLogId,((SubAddr = 0) or (SubAddr > 30)), "Sub Address invalid");
    AlertIf(AlertLogId, Len > 31, "Word length invalid");
    MilBusStdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MilBus, 16))), 4));
    -- Set the active BC bus (RT autodetects)
    if (MilBus = 1) then
      Write(cpu_bus, reg_node_control, bitBrdcstEn); -- Set BUS 1 Active
    else
      Write(cpu_bus, reg_node_control, bitBrdcstEn or bitActiveBus); -- Set BUS 2 Active
    end if;
    -- Set BUS 1 CmdProcStart and Length
    SetCmdProc(cpu_bus, MilBus, X"0000", X"0001");
    -- Build the command word from the input variables
    CmdWord <= std_logic_vector(to_unsigned(RtAddr, 5)) & -- Rt Address
      '1' & -- TxnRx. 0 = RT Rx
      std_logic_vector(to_unsigned(SubAddr, 5)) & -- Sub Address or Mode
      std_logic_vector(to_unsigned(Len, 5)); -- Length or ModeCmd
    wait for 0 ns;
    Write(cpu_bus, X"0400", CmdWord); -- first position in the TxCmdProc
    ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
    Write(cpu_bus, reg_tx_controlX or MilBusStdv, bitSendMessage);
    if (MilBus = 1) then
      WaitForLevel(DiscretesOut.OutEn1, tGAP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC OutEn1 did not go HIGH as expected");
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      WaitForLevel(DiscretesOut.OutEn1, tWord, Timeout, '0');
      AlertIf(AlertLogID, Timeout, "BC OutEn1 did not go LOW as expected");
    else
      WaitForLevel(DiscretesOut.OutEn2, tGAP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC OutEn2 did not go HIGH as expected");
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      WaitForLevel(DiscretesOut.OutEn2, tWord, Timeout, '0');
      AlertIf(AlertLogID, Timeout, "BC OutEn2 did not go LOW as expected");
    end if;
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure BC_RT2BC_Check(
             RtAddr       :       integer;                   -- destination RT to receive the data
             SubAddr      :       integer;                   -- subaddress to send the data to
             Len          :       integer;                   -- length 0=32 bytes
             MilBus       : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
             MyRtAddr1    :       integer;
             MyRtAddr2    :       integer;
             MyBcAddr     :       integer;
      signal CmdWord      : inout std_logic_vector(15 downto 0);
      signal cpu_bus      : inout AddressBus16Type;          -- Avalon cpu bus to core
      signal DiscretesOut : in    CoreDiscretesOut_type;     -- discretes driven by the core, such as "outen" and "intr"
             SB_RT1       :       ScoreboardIdType;
             SB_RT2       :       ScoreboardIdType;
             AlertLogID   :       AlertLogIDType
    ) is
    variable RV         : RandomPType;
    variable Timeout    : boolean;
    variable MilBusStdv : std_logic_vector(15 downto 0);
    variable WordLen    : integer;
    variable RxRamAddr  : integer;
    variable RxData     : std_logic_vector(15 downto 0);
  begin
    -- Validate the input values
    wait for 1 us; -- this is just to allow the BVto propagate teh data received flag.
    AlertIf(AlertLogId, RtAddr > 31, "RT Address invalid");
    AlertIf(AlertLogId, SubAddr > 31, "Sub Address invalid");
    AlertIf(AlertLogId, Len > 31, "Word length invalid");
    WordLen := to_integer(unsigned(CmdWord(4 downto 0)));
    if (WordLen = 0) then
      WordLen := 32;
    end if;
    Log(AlertLogID, "MilBus = " & to_string(MilBus), DEBUG);
    MilBusStdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MilBus, 16))), 4));
    -- Non-matching RTs or Broadcast messages shall have no Status reply
    Log(AlertLogID, "RtAddr=" & to_string(RtAddr), DEBUG);
    Log(AlertLogID, "MyRtAddr1=" & to_string(MyRtAddr1), DEBUG);
    Log(AlertLogID, "MyRtAddr2=" & to_string(MyRtAddr2), DEBUG);
    if (((RtAddr /= MyRtAddr1) and (RtAddr /= MyRtAddr2))) then
      Log(AlertLogID, "if (((RtAddr /= MyRtAddr1) and (RtAddr /= MyRtAddr2))) then --> RTAddr=" & to_string(RtAddr), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tNRP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for NRP timer");
      ReadCheckMask(cpu_bus, reg_busX_status or MilBusStdv, bitNRP, IrqMask, AlertLogID); -- Check that NRP bit intr for bus is set
   else
      Log(AlertLogID, "else --> RTAddr=" & to_string(RtAddr), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tWord, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for Status from RT");
      ReadCheckMask(cpu_bus,reg_busX_status or MilBusStdv, bitStatusRxedFlag or bitDataReceived, IrqMask,AlertLogID); -- Check that CS bit for bus is set
      ReadCheck(cpu_bus,(reg_statusword_rxedX or MilBusStdv),(CmdWord and X"F800")); -- Check that CS for bus is set
      -- loop through the received data and compare with SB
      for i in 1 to WordLen loop
        Log(AlertLogID, "WordLen = " & to_string(WordLen), DEBUG);
        -- 0x0800 = 2048 --> offset of RxRam
        RxRamAddr := 2047 + (SubAddr * 32) + i;
        Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), RxData);
        if (RtAddr = MyRtAddr1) then
          Check(SB_RT1, RxData);
        else
          Check(SB_RT2, RxData);
        end if;
      end loop;
      AlertIf(AlertLogID, not IsEmpty(SB_RT1), "Error: SB_RT1 is empty");
      AlertIf(AlertLogID, not IsEmpty(SB_RT2), "Error: SB_RT2 is empty");
    end if;
    ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
    Log("Exiting BC_Check procedure", DEBUG);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure RT_RT2BC(
             MyRtAddr     :       integer;
             CmdWord      : in    std_logic_vector(15 downto 0);
      signal cpu_bus      : inout AddressBus16Type;
      signal DiscretesOut : in    CoreDiscretesOut_type;
             SB           :       ScoreboardIDType;
             AlertLogID   :       AlertLogIDType
    ) is
    variable RV         : RandomPType;
    variable RandomData : std_logic_vector(15 downto 0);
    variable WordLen    : integer;
    variable RxRamAddr  : integer;
    variable Timeout    : boolean;
    variable SubAddr    : integer;
    variable CmdRtAddr  : integer;
    variable MilBusStdv : std_logic_vector(15 downto 0);
    variable MilBus     : integer;
    variable Test       : std_logic_vector(15 downto 0);
  begin
    RV.InitSeed(T => now); -- Initialize the random number generator
    -- Validate the input values
    CmdRtAddr := to_integer(unsigned(CmdWord(15 downto 11)));
    SubAddr := to_integer(unsigned(CmdWord(9 downto 5)));
    WordLen := to_integer(unsigned(CmdWord(4 downto 0)));
    if (WordLen = 0) then
      WordLen := 32;
    end if;
    if (MyRtAddr = CmdRtAddr) then
      Log(AlertLogID, "Command for this RT=" & to_string(MyRtAddr), DEBUG);
      -- write the length number of random words
      for i in 0 to WordLen - 1 loop --start at 0 and end 1 sooner for the sake of address offsets in TxRam
        -- 0x0400 = 1024 --> offset of TxRam
        RxRamAddr := 1024 + (SubAddr * 32) + i;
        RandomData := RV.RandSlv(Min => 0, Max => 65525, Size => 16);
        Push(SB, RandomData);
        Write(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), RandomData);
      end loop;
      AlertIf(AlertLogID, GetFifoCount(SB) /= WordLen, "Error in number items pushed to SB: " & to_String(GetFifoCount(SB)));

      WaitForLevel(DiscretesOut.Intr, tWord, Timeout, '1');
      Log(AlertLogID, "IRQ Received", DEBUG);
      AlertIf(AlertLogID, Timeout, "RT" & to_string(CmdRtAddr) & " did not receive Intr as expected");
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
      -- 7. Check the last received command word
      ReadCheck(cpu_bus, reg_cmd_rxedX or MilBusStdv, CmdWord);
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
    else
      Log(AlertLogID, "Command NOT for this RT=" & to_string(MyRtAddr), DEBUG);
    end if;
    Log("Exiting RT_RT2BC procedure", DEBUG);
  end procedure;
end package body;
