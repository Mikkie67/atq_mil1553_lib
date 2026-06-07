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

package osvvm_mil1553_testcntrl_bc2rt_pkg is
  procedure BC_BC2RT(
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
  procedure BC_BC2RT_Check(
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

  procedure RT_BC2RT(
           MyRtAddr     :       integer; -- destination RT to receive the data
           CmdWord      : in    std_logic_vector(15 downto 0);
    signal cpu_bus      : inout AddressBus16Type;
    signal DiscretesOut : in    CoreDiscretesOut_type;
           SB           :       ScoreboardIDType;
           AlertLogID   :       AlertLogIDType
  );
end package;

package body osvvm_mil1553_testcntrl_bc2rt_pkg is
  ----------------------------------------------------------------------------------------------------
  procedure BC_BC2RT(
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
    variable RV         : RandomPType;
    variable RandomData : std_logic_vector(15 downto 0);
    variable WordLen    : integer; -- the actual number of data words
    variable TxRamAddr  : integer;
    variable Timeout    : boolean;
    variable MilBusStdv : std_logic_vector(15 downto 0);

  begin
    Log(AlertLogID,
        "#######################" & " RtAddr = " & to_string(RtAddr) & " TxnRx = 0" & " SubAddr = " & to_string(SubAddr) & " Len = " & to_string(Len) & " BUS = " & to_string(MilBus) & " #######################",
        ALWAYS);
    -- Validate the input values
    AlertIf(AlertLogID, RtAddr > 31, "RT Address invalid");
    AlertIf(AlertLogID, SubAddr > 31, "Sub Address invalid");
    AlertIf(AlertLogID, Len > 31, "Word length invalid");
    RV.InitSeed(T => now); -- Initialize the random number generator
    MilBusStdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MilBus, 16))), 4));
    -- Set the active BC bus (RT autodetects)
    if (MilBus = 1) then
      -- Set BUS 1 Active
      Write(cpu_bus, reg_node_control, bitBrdcstEn);
    else
      -- Set BUS 2 Active
      Write(cpu_bus, reg_node_control, bitBrdcstEn or bitActiveBus);
    end if;
    -- Set BUS 1 CmdProcStart and Length
    SetCmdProc(cpu_bus, MilBus, X"0000", X"0001");
    -- the Len value of 0 indicates 32  bytes, so just fix the WordLen here to count from 1 to 32 (and also trim to 32)
    if (Len > 31) or (Len = 0) then
      WordLen := 32;
    else
      WordLen := Len;
    end if;
    -- write the length number of random words
    for i in 0 to WordLen - 1 loop --start at 0 and end 1 sooner for the sake of address offsets in TxRam
      -- 0x0400 = 1024 --> offset of TxRam
      TxRamAddr := 1024 + (SubAddr * 32) + i;
      RandomData := RV.RandSlv(Min => 0, Max => 65525, Size => 16);
      if (RtAddr = MyRtAddr1) then
        Push(SB_RT1, RandomData);
      elsif (RtAddr = MyRtAddr2) then
        Push(SB_RT2, RandomData);
      elsif (RtAddr = 31) then
        Push(SB_RT1, RandomData);
        Push(SB_RT2, RandomData);
      end if;
      Write(cpu_bus, std_logic_vector(to_unsigned(TxRamAddr, 16)), RandomData); -- the actual command word
    end loop;
    if (RtAddr = 31) then
      AlertIf(AlertLogID,(GetFifoCount(SB_RT1) /= WordLen), "Error in number items pushed to Broadcast SB_RT1: " & to_String(GetFifoCount(SB_RT1)));
      AlertIf(AlertLogID,(GetFifoCount(SB_RT2) /= WordLen), "Error in number items pushed to Broadcast SB_RT2: " & to_String(GetFifoCount(SB_RT2)));
    elsif (RtAddr = MyRtAddr1) then
      AlertIf(AlertLogID, GetFifoCount(SB_RT1) /= WordLen, "Error in number items pushed to SB_RT1: " & to_String(GetFifoCount(SB_RT1)));
    elsif (RtAddr = MyRtAddr2) then
      AlertIf(AlertLogID, GetFifoCount(SB_RT2) /= WordLen, "Error in number items pushed to SB_RT2: " & to_String(GetFifoCount(SB_RT2)));
    end if;
    -- Build the command word from the input variables
    CmdWord <= std_logic_vector(to_unsigned(RtAddr, 5)) & -- Rt Address
      '0' & -- TxnRx. 0 = RT Rx
      std_logic_vector(to_unsigned(SubAddr, 5)) & -- Sub Address or Mode
      std_logic_vector(to_unsigned(Len, 5)); -- Length or ModeCmd
    wait for 0 ns;
    Write(cpu_bus, X"0400", CmdWord); -- first position in the TxCmdProc
    ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
    Write(cpu_bus, reg_tx_controlX or MilBusStdv, bitSendMessage);
    if (MilBus = 1) then
      WaitForLevel(DiscretesOut.OutEn1, tGAP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC OutEn1 did not go HIGH as expected");
      AlertIf(AlertLogID, not (DiscretesOut.OutEn2 = '0'), "BC OutEn2 is HIGH when it should be LOW");
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      WaitForLevel(DiscretesOut.OutEn1, tStatus + (tWord * WordLen), Timeout, '0');
      AlertIf(AlertLogID, Timeout, "BC OutEn1 did not go LOW as expected");
    else
      WaitForLevel(DiscretesOut.OutEn2, tGAP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC OutEn2 did not go HIGH as expected");
      AlertIf(AlertLogID, not (DiscretesOut.OutEn1 = '0'), "BC OutEn1 is HIGH when it should be LOW");
      ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
      WaitForLevel(DiscretesOut.OutEn2, tStatus + (tWord * WordLen), Timeout, '0');
      AlertIf(AlertLogID, Timeout, "BC OutEn2 did not go LOW as expected");
    end if;
    wait for 50 ns;
    ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID);
    ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure BC_BC2RT_Check(
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
  begin
    -- Validate the input values
    AlertIf(AlertLogId, RtAddr > 31, "RT Address invalid");
    AlertIf(AlertLogId, SubAddr > 31, "Sub Address invalid");
    AlertIf(AlertLogId, Len > 31, "Word length invalid");
    Log(AlertLogID, "MilBus = " & to_string(MilBus), DEBUG);
    MilBusStdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MilBus, 16))), 4));
    -- Non-matching RTs or Broadcast messages shall have no Status reply
    Log(AlertLogID, "RtAddr=" & to_string(RtAddr), DEBUG);
    Log(AlertLogID, "MyRtAddr1=" & to_string(MyRtAddr1), DEBUG);
    Log(AlertLogID, "MyRtAddr2=" & to_string(MyRtAddr2), DEBUG);
    if (((RtAddr /= MyRtAddr1) and (RtAddr /= MyRtAddr2) and RtAddr /= 31)) then
      Log(AlertLogID, "if (((RtAddr /= MyRtAddr1) and (RtAddr /= MyRtAddr2))) then --> RTAddr=" & to_string(RtAddr), DEBUG);
      WaitForLevel(DiscretesOut.Intr, tNRP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for NRP timer");
      ReadCheckMask(cpu_bus, reg_busX_status or MilBusStdv, bitNRP, IrqMask, AlertLogID); -- Check that NRP bit intr for bus is set
    elsif (RtAddr = 31) then
      Log(AlertLogID, "elsif (RtAddr = 31) then --> RTAddr=" & to_string(RtAddr), DEBUG);
    else
      Log(AlertLogID, "else --> RTAddr=" & to_string(RtAddr),DEBUG);
      WaitForLevel(DiscretesOut.Intr, tStatus + tREP, Timeout, '1');
      AlertIf(AlertLogID, Timeout, "BC Intr did not go HIGH as expected for Status from RT");
      ReadCheckMask(cpu_bus,(reg_busX_status or MilBusStdv),bitStatusRxedFlag, IrqMask,AlertLogID); -- Check that CS bit for bus is set
      ReadCheck(cpu_bus,(reg_statusword_rxedX or MilBusStdv),(CmdWord and X"F800")); -- Check that CS for bus is set
      
    end if;
    ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID); -- Clear all latched interrupts
    -- ensure that after each test, the SB is empty again
    AlertIf(AlertLogID, not IsEmpty(SB_RT1), "Error: SB_RT1 is not empty");
    AlertIf(AlertLogID, not IsEmpty(SB_RT2), "Error: SB_RT2 is not empty");
    Log("Exiting BC_Check procedure", DEBUG);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure RT_BC2RT(
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
    variable Test       : std_logic_vector(15 downto 0);
  begin
    -- Validate the input values
    CmdRtAddr := to_integer(unsigned(CmdWord(15 downto 11)));
    SubAddr := to_integer(unsigned(CmdWord(9 downto 5)));
    WordLen := to_integer(unsigned(CmdWord(4 downto 0)));
    if (WordLen = 0) then
      WordLen := 32;
    end if;
    if ((MyRtAddr = CmdRtAddr) or (CmdRtAddr = 31)) then
      if (MyRtAddr = CmdRtAddr) then
        Log(AlertLogID, "Command for this RT=" & to_string(MyRtAddr), DEBUG);
      else
        Log(AlertLogID, "Command is BROADCAST", DEBUG);
      end if;
      WaitForLevel(DiscretesOut.Intr, tWord * (WordLen + 1), Timeout, '1');
      if (not Timeout) then
        Log(AlertLogID, "IRQ Received", DEBUG);
      end if;
      AlertIf(AlertLogID, Timeout, "RT" & to_string(CmdRtAddr) & " did not receive Intr as expected");
      -- Now check which bus created the IRQ in order to work with correct bus registers
      Read(cpu_bus, reg_status, Test);
      MilBusStdv := getActiveBus(Test);
      wait for 0 ns;
      -- 6. Check the bus 1 status
      ReadCheckMask(cpu_bus, reg_busX_status or MilBusStdv, bitDataReceived, IrqMask, AlertLogID); -- mask out the other timers
      -- 7. Check the last received command word
      ReadCheck(cpu_bus, reg_cmd_rxedX or MilBusStdv, CmdWord);
      wait for 0 ns;
      -- 8. Check the actual data agaisnt scoreboard dataÍ
      if (WordLen > 0) then
        -- write the length number of random words
        Log(AlertLogID, "WordLen = " & to_string(WordLen), DEBUG);
        -- 0x0800 = 2048 --> offset of TxRam
        for i in 1 to WordLen loop
          RxRamAddr := 2047 + (SubAddr * 32) + i;
          Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), RandomData);
          Check(SB, RandomData);
        end loop;
        AlertIf(AlertLogID, not IsEmpty(SB), "Error: SB RT" & to_string(MyRtAddr) & " is not empty");
      end if;
      ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID); -- Clear all latched interrupts
      ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID); -- Clear all latched interrupts
      -- Need to wait for the status message to complete before exiting this check
      wait for tREP + tWord;
      -- 9. Clear the interrupts
    else
      Log(AlertLogID, "Command NOT for this RT=" & to_string(MyRtAddr), DEBUG);
    end if;
    ClearInterrupts(cpu_bus, 1, IrqMask, AlertLogID); -- Clear all latched interrupts
    ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID); -- Clear all latched interrupts
    AlertIf(AlertLogID, not IsEmpty(SB), "Error: SB RT" & to_string(MyRtAddr) & " is not empty");
    Log(AlertLogID, "Exiting RT_BC2RT1 procedure", DEBUG);
  end procedure;
end package body;
