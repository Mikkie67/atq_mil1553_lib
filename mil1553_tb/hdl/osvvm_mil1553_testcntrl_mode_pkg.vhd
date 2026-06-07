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
  use mil1553_tb.CommandLoggerPkg.all; -- Command Logger Package

package osvvm_mil1553_testcntrl_mode_pkg is
  procedure BC_MULTICMD(
           MultiCommandRec :       MultiCommandRec_type;
           MyRtAddr1       :       integer;
           MyRtAddr2       :       integer;
           MyBcAddr        :       integer;
    signal CmdWord         : in    std_logic_vector(15 downto 0);
    signal cpu_bus         : inout AddressBus16Type;
    signal DiscretesOut    : in    CoreDiscretesOut_type;
    signal SB_RT1_CMD      :       ScoreboardIdType;
    signal SB_RT1_TMP      :       ScoreboardIdType;
    signal SB_RT2_CMD      :       ScoreboardIdType;
    signal SB_RT2_TMP      :       ScoreboardIdType;
           SB_RT2RT        :       ScoreboardIdType;
    signal RT2RT_DestAddr  : in    integer;
    signal RT2RT_Busy      : in    boolean;
    --  signal BC_CMD_SEND_Done : inout integer_barrier;
    --  signal RT_Done          : inout integer_barrier;
           AlertLogId      :       AlertLogIDType
  );
  procedure BC_MULTI_CHECK(
           MultiCommandRec :       MultiCommandRec_type;
           MyRtAddr1       :       integer;
           MyRtAddr2       :       integer;
           MyBcAddr        :       integer;
    signal CmdWord         : inout std_logic_vector(15 downto 0);
    signal cpu_bus         : inout AddressBus16Type;
    signal DiscretesOut    : in    CoreDiscretesOut_type;
    signal RtGo            : out   boolean;
    signal SB_RT1_CMD      :       ScoreboardIdType;
    signal SB_RT1_DAT      :       ScoreboardIdType;
    signal SB_RT1_TMP      :       ScoreboardIdType;
    signal SB_RT2_CMD      :       ScoreboardIdType;
    signal SB_RT2_DAT      :       ScoreboardIdType;
    signal SB_RT2_TMP      :       ScoreboardIdType;
           SB_BC           :       ScoreboardIdType;
           SB_RT2RT        :       ScoreboardIdType;
    --    signal BC_CMD_SEND_Done : inout integer_barrier;
    signal NextCmdRT1      : inout integer_barrier;
    signal NextCmdRT2      : inout integer_barrier;
    signal CurCmdIndex     : inout integer;
    signal TransmittingRT  : inout integer;
    signal ReceivingRT     : inout integer;
    signal RT2RT_DestAddr  : out   integer;
    signal RT2RT_Busy      : inout boolean;
    signal BC_Exit         : out   std_logic;
    signal BC_NextCmd      : inout std_logic;
    signal RT1_Done        : in    std_logic;
    signal RT2_Done        : in    std_logic;
    signal BC_Check_Exit   : out   std_logic;
           AlertLogId      :       AlertLogIDType
  );
  procedure RT_MULTI_CHECK(
           MultiCommandRec :       MultiCommandRec_type;
           MyRtAddr        :       integer;
           OtherRtAddr     :       integer;
           MyBcAddr        :       integer;
    signal CmdWord         : in    std_logic_vector(15 downto 0);
    signal cpu_bus         : inout AddressBus16Type;
    signal DiscretesOut    : in    CoreDiscretesOut_type;
    signal SB_CMD          :       ScoreboardIdType;
    signal SB_DAT          :       ScoreboardIdType;
    signal SB_OTHER_CMD    :       ScoreboardIdType;
    signal SB_OTHER_DAT    :       ScoreboardIdType;
           SB_BC           :       ScoreboardIdType;
           SB_RT2RT        :       ScoreboardIdType;
    --    signal BC_CMD_SEND_Done : inout integer_barrier;
    signal NextCmd         : inout integer_barrier;
    signal CurCmdIndex     : in    integer;
    signal TransmittingRT  : in    integer;
    signal ReceivingRT     : in    integer;
    signal RT2RT_DestAddr  : in    integer;
    signal BC_NextCmd      : in    std_logic;
    signal RT_Done         : out   std_logic;
    signal BC_Exit         : in    std_logic;
    signal RT2RT_Busy      : in    boolean;
    signal BC_Check_Exit   : in    std_logic;
           AlertLogId      :       AlertLogIDType
  );

end package;

package body osvvm_mil1553_testcntrl_mode_pkg is
  procedure BC_MULTICMD(
             MultiCommandRec :       MultiCommandRec_type;
             MyRtAddr1       :       integer;
             MyRtAddr2       :       integer;
             MyBcAddr        :       integer;
      signal CmdWord         : in    std_logic_vector(15 downto 0);
      signal cpu_bus         : inout AddressBus16Type;
      signal DiscretesOut    : in    CoreDiscretesOut_type;
      signal SB_RT1_CMD      :       ScoreboardIdType;
      signal SB_RT1_TMP      :       ScoreboardIdType;
      signal SB_RT2_CMD      :       ScoreboardIdType;
      signal SB_RT2_TMP      :       ScoreboardIdType;
             SB_RT2RT        :       ScoreboardIdType;
      --    signal BC_CMD_SEND_Done : inout integer_barrier;
      --      signal RT_Done          : inout integer_barrier;
      signal RT2RT_DestAddr  : in    integer;
      signal RT2RT_Busy      : in    boolean;
             AlertLogId      :       AlertLogIDType
    ) is
    variable TxRamAddr   : integer := 0;
    variable Timeout     : boolean;
    variable MilBusStdv  : std_logic_vector(15 downto 0);
    variable RtAddrStdv  : std_logic_vector(4 downto 0);
    variable SubAddrStdv : std_logic_vector(4 downto 0);
    variable ReadData    : std_logic_vector(15 downto 0);
    variable LenStdv     : std_logic_vector(4 downto 0);
    variable TxnRxStd    : std_logic;
    variable RV          : RandomPType;
    variable RandomData  : std_logic_vector(15 downto 0);
    variable WordLen     : integer; -- the actual number of data words
    variable NextCmdWord : std_logic_vector(15 downto 0);
    variable CurCmdWord  : std_logic_vector(15 downto 0);
    variable BitErrInj   : std_logic_vector(5 downto 0);
    variable MilBus     : integer;
  begin
    RV.InitSeed(T => now); -- Initialize the random number generator once per group of messages
    for CurCmdIndex in 0 to MultiCommandRec.Length - 1 loop
      if (CurCmdIndex < (MultiCommandRec.Length - 2)) then
        RtAddrStdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurCmdIndex + 1).RtAddr, 5));
        SubAddrStdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurCmdIndex + 1).SubAddr, 5));
        LenStdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurCmdIndex + 1).Len, 5));
        TxnRxStd := std_logic(to_unsigned(MultiCommandRec.Command(CurCmdIndex + 1).TxnRx, 1)(0));
        NextCmdWord := RtAddrStdv & TxnRxStd & SubAddrStdv & LenStdv;
      end if;
      RtAddrStdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurCmdIndex).RtAddr, 5));
      SubAddrStdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurCmdIndex).SubAddr, 5));
      LenStdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurCmdIndex).Len, 5));
      TxnRxStd := std_logic(to_unsigned(MultiCommandRec.Command(CurCmdIndex).TxnRx, 1)(0));
      MilBusStdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MultiCommandRec.Command(CurCmdIndex).MilBus, 16))), 4));
      MilBus := MultiCommandRec.Command(CurCmdIndex).MilBus;
      CurCmdWord := RtAddrStdv & TxnRxStd & SubAddrStdv & LenStdv;
      LogCommandWord(to_integer(unsigned(CurCmdWord)));

      wait for 0 ns;
      Log(AlertLogID,
          "######### " & to_string(CurCmdIndex) & " BC CurCmdWord = " & to_hstring(CurCmdWord) & " Bus = " & to_string(MultiCommandRec.Command(CurCmdIndex).MilBus) & " ######### RtAddr = " & to_string(MultiCommandRec.Command(CurCmdIndex).RtAddr) & " TxnRx =  " & to_string(MultiCommandRec.Command(CurCmdIndex).TxnRx) & " SubAddr = " & to_string(MultiCommandRec.Command(CurCmdIndex).SubAddr) & " Len = " & to_string(MultiCommandRec.Command(CurCmdIndex).Len) & " #########",
          INFO);
      printCmdWord(AlertLogID, CurCmdWord, MultiCommandRec.Command(CurCmdIndex).MilBus);
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      ----------------------------------------------------------------------------------------------------
      if (MultiCommandRec.Command(CurCmdIndex).Len > 31) or (MultiCommandRec.Command(CurCmdIndex).Len = 0) then
        WordLen := 32;
      else
        WordLen := MultiCommandRec.Command(CurCmdIndex).Len;
      end if;
      ----------------------------------------------------------------------------------------------------
      if (MultiCommandRec.Command(CurCmdIndex).MilBus = 1) then
        SetCmdProc(cpu_bus, 1,
                   std_logic_vector(to_unsigned(MultiCommandRec.StartAddr, 16)),
                   std_logic_vector(to_unsigned(MultiCommandRec.Length, 16)));
      elsif (MultiCommandRec.Command(CurCmdIndex).MilBus = 2) then
        SetCmdProc(cpu_bus, 2,
                   std_logic_vector(to_unsigned(MultiCommandRec.StartAddr, 16)),
                   std_logic_vector(to_unsigned(MultiCommandRec.Length, 16)));
      else
        Alert(AlertLogId, "BC_MULTICMD: Invalid bus number " & to_string(MultiCommandRec.Command(CurCmdIndex).MilBus), ERROR);
      end if;
      ----------------------------------------------------------------------------------------------------
      -- Set the active BC bus (RT autodetects)
      if (MultiCommandRec.Command(CurCmdIndex).MilBus = 1) then
        Write(cpu_bus, reg_node_control, bitBrdcstEn);
      else
        Write(cpu_bus, reg_node_control, bitBrdcstEn or bitActiveBus);
      end if;
      ----------------------------------------------------------------------------------------------------
      if (MultiCommandRec.Command(CurCmdIndex).Rt2RT = '0') then
        if (MultiCommandRec.Command(CurCmdIndex).RtAddr = MyRtAddr1) then
          Push(SB_RT1_CMD, CurCmdWord);
          Log(AlertLogId, to_string(CurCmdIndex) & " (Not RT2RT,MyAddr1) SB_RT1_CMD, Push CurCmdWord " & to_hstring(CurCmdWord), DEBUG);
        elsif (MultiCommandRec.Command(CurCmdIndex).RtAddr = MyRtAddr2) then
          Push(SB_RT2_CMD, CurCmdWord);
          Log(AlertLogId, to_string(CurCmdIndex) & " (Not RT2RT,MyAddr2) SB_RT2_CMD, Push CurCmdWord " & to_hstring(CurCmdWord), DEBUG);
        elsif (MultiCommandRec.Command(CurCmdIndex).RtAddr = 31) then
          Push(SB_RT1_CMD, CurCmdWord);
          Log(AlertLogId, to_string(CurCmdIndex) & " (Not RT2RT,RT31) SB_RT1_CMD, Push CurCmdWord " & to_hstring(CurCmdWord), DEBUG);
          Push(SB_RT2_CMD, CurCmdWord);
          Log(AlertLogId, to_string(CurCmdIndex) & " (Not RT2RT,RT31) SB_RT2_CMD, Push CurCmdWord " & to_hstring(CurCmdWord), DEBUG);
        end if;
      else
        -- Rt2RT command - Check the first command to see if it is a broadcast receive
        -- if so, check the second command's RTaddr:
        -- if it is for one of the attached RTs, do not push the Broadcast addr to that RTs scoreboard
        -- Push(SB_RT2RT, CurCmdWord);
        -- Push(SB_RT2RT, CurCmdWord);
        -- Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT2RT, Push NextCmdWord " & to_hstring(CurCmdWord), DEBUG);
        -- Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT2RT, Push NextCmdWord " & to_hstring(CurCmdWord), DEBUG);
        if (MultiCommandRec.Command(CurCmdIndex).RtAddr = 31) then
          if (MultiCommandRec.Command(CurCmdIndex + 1).RtAddr /= MyRtAddr1) then
            Push(SB_RT1_CMD, CurCmdWord);
            Log(AlertLogId, to_string(CurCmdIndex) & " (RT2RT, RT31, not MyAddr1) SB_RT1_CMD, Push CmdWord " & to_hstring(CurCmdWord), DEBUG);
          elsif (MultiCommandRec.Command(CurCmdIndex + 1).RtAddr /= MyRtAddr2) then
            Push(SB_RT2_CMD, CurCmdWord);
            Log(AlertLogId, to_string(CurCmdIndex) & " (RT2RT, RT31, not MyAddr2) SB_RT2_CMD, Push CmdWord " & to_hstring(CurCmdWord), DEBUG);
          else
            Push(SB_RT1_CMD, CurCmdWord);
            Log(AlertLogId, to_string(CurCmdIndex) & " (RT2RT, RT31) SB_RT1_CMD, Push CmdWord " & to_hstring(CurCmdWord), DEBUG);
            Push(SB_RT2_CMD, CurCmdWord);
            Log(AlertLogId, to_string(CurCmdIndex) & " (RT2RT, RT31) SB_RT2_CMD, Push CmdWord " & to_hstring(CurCmdWord), DEBUG);
          end if;
        else
          if (MultiCommandRec.Command(CurCmdIndex + 1).RtAddr /= MyRtAddr1) then
            Push(SB_RT1_CMD, CurCmdWord);
            Log(AlertLogId, to_string(CurCmdIndex) & " (RT2RT, not RT31, not MyAddr1) SB_RT1_CMD, Push CmdWord " & to_hstring(CurCmdWord), DEBUG);
          elsif (MultiCommandRec.Command(CurCmdIndex + 1).RtAddr /= MyRtAddr2) then
            Push(SB_RT2_CMD, CurCmdWord);
            Log(AlertLogId, to_string(CurCmdIndex) & " (RT2RT, not RT31, not MyAddr2) SB_RT2_CMD, Push CmdWord " & to_hstring(CurCmdWord), DEBUG);
          end if;
        end if;
      end if;
      ----------------------------------------------------------------------------------------------------
      if (MultiCommandRec.Command(CurCmdIndex).Rt2RT = '1') then
        write(cpu_bus, reg_tx_controlX or MilBusStdv, bitRT2RT);
        Write(cpu_bus, std_logic_vector(to_unsigned(1024 + MultiCommandRec.StartAddr + CurCmdIndex, 16)), CurCmdWord);
        write(cpu_bus, reg_tx_controlX or MilBusStdv, X"0000");
      else
        Write(cpu_bus, std_logic_vector(to_unsigned(1024 + MultiCommandRec.StartAddr + CurCmdIndex, 16)), CurCmdWord);
        Log(AlertLogId, to_string(CurCmdIndex) & "Cmd = " & to_hstring(CurCmdWord) & " Written to TxRAM Addr = " & to_hstring(std_logic_vector(to_unsigned(1024 + MultiCommandRec.StartAddr + CurCmdIndex, 16))), ALWAYS);
      end if;
      ----------------------------------------------------------------------------------------------------
      -- fill the random data for the RT Rx messages (i.e. data sent by BC)
      if (TxnRxStd = '0') then
        if (SubAddrStdv > "00000") and (SubAddrStdv < "11111") and (MultiCommandRec.Command(CurCmdIndex).Rt2RT = '0') then
          for i in 0 to WordLen - 1 loop
            TxRamAddr := 1024 + (MultiCommandRec.Command(CurCmdIndex).SubAddr * 32) + i;
            RandomData := RV.RandSlv(Min => 0, Max => 65535, Size => 16);
            if (MultiCommandRec.Command(CurCmdIndex).RtAddr = MyRtAddr1) then
              Push(SB_RT1_TMP, RandomData);
              Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT1_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
            elsif (MultiCommandRec.Command(CurCmdIndex).RtAddr = MyRtAddr2) then
              Push(SB_RT2_TMP, RandomData);
              Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT2_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
            elsif (MultiCommandRec.Command(CurCmdIndex).RtAddr = 31) then
              Push(SB_RT1_TMP, RandomData);
              Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT1_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
              Push(SB_RT2_TMP, RandomData);
              Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT2_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
            end if;
            Write(cpu_bus, std_logic_vector(to_unsigned(TxRamAddr, 16)), RandomData);
          end loop;
        elsif (MultiCommandRec.Command(CurCmdIndex).Rt2RT = '0') then
          TxRamAddr := 1024 + (32 * 31) + MultiCommandRec.Command(CurCmdIndex).Len;
          Log(AlertLogId, to_string(CurCmdIndex) & "-------------> ModeCmd " & to_string(MultiCommandRec.Command(CurCmdIndex).Len), DEBUG);
          Log(AlertLogId, to_string(CurCmdIndex) & "-------------> TxRamAddr " & to_hstring(std_logic_vector(to_unsigned(TxRamAddr, 16))), DEBUG);
          RandomData := std_logic_vector(to_unsigned(MultiCommandRec.ErrWrd, 16)); --RV.RandSlv(Min => 0, Max => 65535, Size => 16);
          if (MultiCommandRec.Command(CurCmdIndex).RtAddr = MyRtAddr1) then
            Push(SB_RT1_TMP, RandomData);
            Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT1_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
          elsif (MultiCommandRec.Command(CurCmdIndex).RtAddr = MyRtAddr2) then
            Push(SB_RT2_TMP, RandomData);
            Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT2_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
          elsif (MultiCommandRec.Command(CurCmdIndex).RtAddr = 31) then
            Push(SB_RT1_TMP, RandomData);
            Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT1_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
            Push(SB_RT2_TMP, RandomData);
            Log(AlertLogId, to_string(CurCmdIndex) & " SB_RT2_TMP, Push RandomData " & to_hstring(RandomData), DEBUG);
          end if;
          Write(cpu_bus, std_logic_vector(to_unsigned(TxRamAddr, 16)), RandomData);
        end if;
      end if;
      -- v4p formatting off
      ----------------------------------------------------------------------------------------------------      
       log(AlertLogId, LF & 
      "SB_RT1_CMD: " & to_string(GetFifoCount(SB_RT1_CMD)) & LF & 
      "SB_RT1_TMP: " & to_string(GetFifoCount(SB_RT1_TMP)) & LF & 
      "SB_RT2_CMD: " & to_string(GetFifoCount(SB_RT2_CMD)) & LF & 
      "SB_RT2_TMP: " & to_string(GetFifoCount(SB_RT2_TMP)) & LF & 
      "SB_RT2RT: " & to_string(GetFifoCount(SB_RT2RT)), DEBUG);
      -- v4p formatting on
    end loop;
    -- v4p formatting off
    if (MultiCommandRec.ErrInj /= 0) then
      if (MultiCommandRec.ErrBit < 0) then
        Log(AlertLogId, " Negative Error Injection bits", ALWAYS);
        BitErrInj := '1' & std_logic_vector(to_unsigned(MultiCommandRec.ErrBit*(-1), 5 ));
      else
        BitErrInj := std_logic_vector(to_unsigned(MultiCommandRec.ErrBit, 6 ));
      end if;
      Write(cpu_bus, reg_err_inj_data,
            std_logic_vector(to_unsigned(MultiCommandRec.ErrWrd, 6)) & 
            BitErrInj &
            std_logic_vector(to_unsigned(MultiCommandRec.ErrInj, 4)));
      Read(cpu_bus, reg_err_inj_data, ReadData);
      Log(AlertLogId, " Error Injection bits = " & to_hstring(ReadData), ALWAYS);
    else
      Write(cpu_bus, reg_err_inj_data, X"0000");
    end if;
      -- v4p formatting on
    if (MultiCommandRec.RepeatRate > 0) then
      Write(cpu_bus, reg_repeat_rate, std_logic_vector(to_unsigned(MultiCommandRec.RepeatRate, 16)));
      Read(cpu_bus, reg_node_control, ReadData);
      Write(cpu_bus, reg_node_control, ReadData or bitUseBcRepeat or bitBcRepeatStart);
      Write(cpu_bus, reg_node_control,(ReadData or bitUseBcRepeat) and not bitBcRepeatStart);
    else
      Read(cpu_bus, reg_node_control, ReadData);
      Write(cpu_bus, reg_node_control, ReadData and not bitUseBcRepeat and not bitBcRepeatStart);
    end if;
    Read(cpu_bus, reg_node_control, ReadData);
    Log(AlertLogId, "RT Control = " & to_hstring(ReadData), DEBUG);
    ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogID);
    --ClearInterrupts(cpu_bus, 2, IrqMask, AlertLogID);
    Write(cpu_bus, reg_tx_controlX or MilBusStdv, bitSendMessage);
    wait for 100 ns;
    Write(cpu_bus, reg_tx_controlX or MilBusStdv, X"0000");

    ----------------------------------------------------------------------------------------------------
  end procedure;
  procedure BC_MULTI_CHECK(
             MultiCommandRec :       MultiCommandRec_type;
             MyRtAddr1       :       integer;
             MyRtAddr2       :       integer;
             MyBcAddr        :       integer;
      signal CmdWord         : inout std_logic_vector(15 downto 0);
      signal cpu_bus         : inout AddressBus16Type;
      signal DiscretesOut    : in    CoreDiscretesOut_type;
      signal RtGo            : out   boolean;
      signal SB_RT1_CMD      :       ScoreboardIdType;
      signal SB_RT1_DAT      :       ScoreboardIdType;
      signal SB_RT1_TMP      :       ScoreboardIdType;
      signal SB_RT2_CMD      :       ScoreboardIdType;
      signal SB_RT2_DAT      :       ScoreboardIdType;
      signal SB_RT2_TMP      :       ScoreboardIdType;
             SB_BC           :       ScoreboardIdType;
             SB_RT2RT        :       ScoreboardIdType;
      --    signal BC_CMD_SEND_Done : inout integer_barrier;
      signal NextCmdRT1      : inout integer_barrier;
      signal NextCmdRT2      : inout integer_barrier;
      signal CurCmdIndex     : inout integer;
      signal TransmittingRT  : inout integer;
      signal ReceivingRT     : inout integer;
      signal RT2RT_DestAddr  : out   integer;
      signal RT2RT_Busy      : inout boolean;
      signal BC_Exit         : out   std_logic;
      signal BC_NextCmd      : inout std_logic;
      signal RT1_Done        : in    std_logic;
      signal RT2_Done        : in    std_logic;
      signal BC_Check_Exit   : out   std_logic;
             AlertLogId      :       AlertLogIDType
    ) is
    variable RxRamAddr           : integer;
    variable Timeout             : boolean;
    variable MilBus_stdv         : std_logic_vector(15 downto 0);
    variable MilBus_std          : std_logic;
    variable MilBus_i            : integer;
    variable CmdRtAddr_stdv      : std_logic_vector(4 downto 0);
    variable CmdSubAddr_stdv     : std_logic_vector(4 downto 0);
    variable CmdLen_stdv         : std_logic_vector(4 downto 0);
    variable CmdTxnRx_std        : std_logic;
    variable Rd_reg_status       : std_logic_vector(15 downto 0);
    variable Rd_reg_intr_mask    : std_logic_vector(15 downto 0);
    variable Rd_reg_cmd_rxedX    : std_logic_vector(15 downto 0);
    variable Rd_reg_rx_mode_cmdX : std_logic_vector(15 downto 0);
    variable Rd_reg_busX_mask    : std_logic_vector(15 downto 0);
    variable Rd_reg_busX_status  : std_logic_vector(15 downto 0);
    variable ThisCmdWord         : std_logic_vector(15 downto 0);
    variable ThisRtAddr          : integer;
    variable PrevCmdWord         : std_logic_vector(15 downto 0);
    variable PrevRtAddr_i        : integer;
    variable WordLen             : integer; -- the actual number of data words
    variable ReadData            : std_logic_vector(15 downto 0);
    variable IsRT2RT             : boolean;
    variable CurrentCmdIndex     : integer;
    ----------------------------------------------------------------------------------------------------
    function IsReservedModeCommand(
        ModeCode : std_logic_vector(4 downto 0);
        TxnRx    : std_logic
      ) return boolean is
    begin
      case ModeCode is
        -- Reserved mode codes.
        when "01001" | "01010" | "01011" | "01100" | "01101" | "01110" | "01111" |
             "10110" | "10111" | "11000" | "11001" | "11010" | "11011" | "11100" | "11101" | "11110" | "11111" =>
          return true;

        -- Transmit vector word, transmit last command word, and transmit BIT word.
        when "10000" | "10010" | "10011" =>
          return TxnRx = '0';

        -- Synchronize with data word, selected transmitter shutdown, and override selected transmitter shutdown.
        when "10001" | "10100" | "10101" =>
          return TxnRx = '1';

        when others =>
          return false;
      end case;
    end function;
    ----------------------------------------------------------------------------------------------------
    procedure WaitFor_OutenToComplete(
        OutEnHighTime : time := tWord
      ) is
    begin
      if (MilBus_i = 1) then
        WaitForLevel(DiscretesOut.OutEn1, tGAP + 1 us, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "OutEn1 did not go HIGH as expected", FAILURE);
        WaitForLevel(DiscretesOut.OutEn1, OutEnHighTime + 1 us, Timeout, '0');
        AlertIf(AlertLogID, Timeout, "OutEn1 did not go LOW as expected", FAILURE);
      else
        WaitForLevel(DiscretesOut.OutEn2, tGAP + 1 us, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "OutEn2 did not go HIGH as expected", FAILURE);
        WaitForLevel(DiscretesOut.OutEn2, OutEnHighTime + 1 us, Timeout, '0');
        AlertIf(AlertLogID, Timeout, "OutEn2 did not go LOW as expected", FAILURE);
      end if;
    end procedure;
    ---------------------------------------------------------------------------------------------------
    procedure WaitFor_get_and_checkModeCmdDat is
    begin
      Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": Waiting in WaitFor_get_and_checkModeCmdDat", DEBUG);
      WaitForLevel(DiscretesOut.Intr, tGap + tCommand + tRep + tStatus + tCommand + (tWord * WordLen) + tNRP + tGap / 2, Timeout, '1'); --TODO how long to actually wait?
      if (timeout = false) then
        Log(AlertLogID, "2a WaitFor_get_and_checkModeCmd: " & to_string(CurrentCmdIndex) & " BC: data word IRQ Received and entering BC CHECK", DEBUG);
      end if;
      -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
      AlertIf(AlertLogID, Timeout, "3a WaitFor_get_and_checkModeCmd: " & to_string(CurrentCmdIndex) & " BC did not receive data word Intr as expected");
      ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
      Read(cpu_bus,(reg_mode_data_rxedX or MilBus_stdv), ReadData);
      Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": MODE RT TX Command with data word, Data Word = " & to_hstring(ReadData), DEBUG);

      case CmdLen_stdv is
        when "00000" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: DBC", DEBUG);
          -- check that the DBC bit is set
          ReadCheckMask(cpu_bus,(reg_cmd_rxedX or MilBus_stdv),(bitDBC_accepted), X"1F00", AlertLogID);
        when "00001" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Synchronize", DEBUG);
          ReadCheckMask(cpu_bus,(reg_cmd_rxedX or MilBus_stdv),(bitSynchronize), X"1F00", AlertLogID);
        when "00010" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Transmit Status word", DEBUG);
        --ReadCheckMask(cpu_bus,(reg_rx_cmdX or MilBus_stdv),(bitDBC_accepted), X"1F00", AlertLogID);
        when "00011" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Initiate Self Test", DEBUG);
          ReadCheckMask(cpu_bus,(reg_cmd_rxedX or MilBus_stdv),(bitInitiateBIT), X"1F00", AlertLogID);
        when "00100" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Transmitter Shutdown", DEBUG);
          -- The RT will send the status and then disable this transmitter.
          -- this can be checked in the status register bit 12 or 13
          Read(cpu_bus, reg_status, ReadData);
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Transmitter Shutdown: Status = " & to_hstring(ReadData), DEBUG);
        --ReadCheckMask(cpu_bus,(reg_rx_cmdX or MilBusStdv),(bitDBC_accepted), X"1F00", AlertLogID);
        when "00101" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Override Transmitter Shutdown", DEBUG);
          ReadCheckMask(cpu_bus,(reg_cmd_rxedX or MilBus_stdv),(bitDBC_accepted), X"1F00", AlertLogID);
        when "00110" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Inhibit Terminal Flag bit", DEBUG);
          ReadCheckMask(cpu_bus,(reg_cmd_rxedX or MilBus_stdv),(bitDBC_accepted), X"1F00", AlertLogID);
        when "00111" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Override Inhibit Terminal Flag bit", DEBUG);
          ReadCheckMask(cpu_bus,(reg_cmd_rxedX or MilBus_stdv),(bitDBC_accepted), X"1F00", AlertLogID);
        when "01000" =>
          Log(AlertLogID, "WaitFor_get_and_checkModeCmd: Transmit Mode Command: Reset Remote Terminal", DEBUG);
          ReadCheckMask(cpu_bus,(reg_cmd_rxedX or MilBus_stdv),(bitDBC_accepted), X"1F00", AlertLogID);
        when "01001" | "01010" | "01011" | "01100" | "01101" | "01110" | "01111" =>
        -- do nothing for now
        when "10000" =>
        -- RandomData := RV.RandSlv(Min => 0, Max => 65535, Size => 16);
        -- Push(SB, RandomData);
        -- DiscretesIn.ServiceReqVector <= RandomData;
        -- wait for 0 ns;
        -- Log(AlertLogID, "Transmit ServiceReqVector = " & to_hstring(RandomData), DEBUG);
        when "10010" =>
          Log(AlertLogID, "Transmit Last CommandWord Received = " & to_hstring(ReadData), DEBUG);
        --AffirmIf(AlertLogId,(ReadData) = PrevCmdWord, "5 WaitFor_get_and_checkModeCmd: " & to_string(CurrentCmdIndex) & " BC: Last Command Word not correct  " & to_hstring(ReadData) & " should be " & to_hstring(PrevCmdWord), ERROR);
        when "10011" =>
        -- RandomData := RV.RandSlv(Min => 0, Max => 65535, Size => 16);
        -- Push(SB, RandomData);
        -- DiscretesIn.BitWord <= RandomData;
        -- wait for 0 ns;
        -- Log(AlertLogID, "Transmit BIT = " & to_hstring(RandomData), DEBUG);
        when "10111" | "11000" | "11001" | "11010" | "11011" | "11100" | "11101" | "11110" | "11111" =>
        -- do nothing special, these are reserved mode commands 
        when others =>
      end case;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure WaitFor_get_and_checkStatusword is
    begin
      Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": Waiting in WaitFor_get_and_checkStatusword", DEBUG);
      WaitForLevel(DiscretesOut.Intr, tGap + tCommand + tRep + tStatus + tCommand + (tWord * WordLen) + tNRP + tGap / 2, Timeout, '1'); --TODO how long to actually wait?
      if (timeout = false) then
        Log(AlertLogID, "2a WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: bitStatusRxedFlag IRQ Received and entering BC CHECK", DEBUG);
      end if;
      -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
      AlertIf(AlertLogID, Timeout, "3a WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC did not receive bitStatusRxedFlag Intr as expected");
      -- check that is was a status received IRQ
      Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
      AffirmIf(AlertLogId,(ReadData and bitStatusRxedFlag) = bitStatusRxedFlag, "4 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: IRQ: bitStatusRxedFlag  " & to_hstring(ReadData), ERROR);
      ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
      Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": MODE RT TX Command with no data word, Status IRQ received and checked. Status Register = " & to_hstring(ReadData), DEBUG);
      -- Read the status word itself and check contents
      Read(cpu_bus,(reg_statusword_rxedX or MilBus_stdv), ReadData);
      -- TODO perhaps some special checks later for specific bit in message. for now just check for CS
      -- the line below should be the next command word.
      Log(AlertLogID, "commandlist1 RT addr: " & to_string(MultiCommandRec.Command(1).RtAddr), DEBUG);
      Log(AlertLogID, "CmdRtAddr_stdv: " & to_hstring("000" & CmdRtAddr_stdv), DEBUG);
      Log(AlertLogID, "ReceivingRT: " & to_string(ReceivingRT), DEBUG);
      Log(AlertLogID, "ThisCmdWord: " & to_hstring(ThisCmdWord), DEBUG);
      -- Check status word based on command type, mode code, and T/R direction.
      if IsReservedModeCommand(CmdLen_stdv, CmdTxnRx_std) then
        Log(AlertLogID, "Reserved mode command detected: T/R=" & to_string(CmdTxnRx_std) & ", mode=" & to_hstring(CmdLen_stdv) & ", expecting message error bit", DEBUG);
        if (ReceivingRT = 31) or (MultiCommandRec.Command(1).RtAddr = 31) then 
          if (MultiCommandRec.Command(1).RtAddr = MyRtAddr1) or (MultiCommandRec.Command(1).RtAddr = MyRtAddr2) or ((MultiCommandRec.Command(1).RtAddr = 31))then
            AffirmIf(AlertLogId,(ReadData) = ((ThisCmdWord and X"F800") or bitBrdcstRxed or bitMessageError), "15 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: Status with reserved mode code  " & to_hstring(ReadData), ERROR);
          else
            AffirmIf(AlertLogId,(ReadData) = ((ThisCmdWord and X"F800") or bitBrdcstRxed or bitMessageError), "16 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: Status with reserved mode code  " & to_hstring(ReadData), ERROR);
          end if;
        else
          AffirmIf(AlertLogId,(ReadData) = ((ThisCmdWord and X"F800") or bitMessageError), "17 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: Status with reserved mode code  " & to_hstring(ReadData), ERROR);
        end if;
      else
        if (ReceivingRT = 31) or (MultiCommandRec.Command(1).RtAddr = 31) then 
          if (MultiCommandRec.Command(1).RtAddr = MyRtAddr1) or (MultiCommandRec.Command(1).RtAddr = MyRtAddr2) or ((MultiCommandRec.Command(1).RtAddr = 31))then
            AffirmIf(AlertLogId,(ReadData) = ((ThisCmdWord and X"F800") or bitBrdcstRxed), "25 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: Status not clear  " & to_hstring(ReadData), ERROR);
          else
            AffirmIf(AlertLogId,(ReadData) = ((ThisCmdWord and X"F800") or bitBrdcstRxed or bitMessageError), "26 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: Status not clear  " & to_hstring(ReadData), ERROR);
          end if;
        else
          if (CmdLen_stdv = "10010") and
             (CurrentCmdIndex > 0) and
             ((PrevCmdWord(9 downto 5) = "00000") or (PrevCmdWord(9 downto 5) = "11111")) and
             IsReservedModeCommand(PrevCmdWord(4 downto 0), PrevCmdWord(10)) then
            AffirmIf(AlertLogId,(ReadData) = ((ThisCmdWord and X"F800") or bitMessageError), "27 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: Transmit last command word status after reserved mode command  " & to_hstring(ReadData), ERROR);
          else
            AffirmIf(AlertLogId,(ReadData) = (ThisCmdWord and X"F800"), "27 WaitFor_get_and_checkStatusword: " & to_string(CurrentCmdIndex) & " BC: Status not clear  " & to_hstring(ReadData), ERROR);
          end if;
        end if;
      end if;
      printStatusWord(AlertLogID, ReadData);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessModeRxCommands is
    begin
      Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": Processing MODE RT RX Commands", DEBUG);
      if (CmdLen_stdv(4) = '0') then
        Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": MODE RT RX Command with no data word", DEBUG);
        -- wait until the BC generates an IRQ, then run the process to check the results
        WaitForLevel(DiscretesOut.Intr, tGap + tCommand + (tWord * WordLen) + tREP + tStatus + tGAP / 2, Timeout, '1');
        if (timeout = false) then
          Log(AlertLogID, "ProcessModeRxCommands:" & to_string(CurrentCmdIndex) & " BC: bitStatusRxedFlag IRQ Received and entering BC CHECK", DEBUG);
        end if;
        -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
        AlertIf(AlertLogID, Timeout, "ProcessModeRxCommands:" & to_string(CurrentCmdIndex) & " BC did not receive bitStatusRxedFlag Intr as expected");
        Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
        AffirmIf(AlertLogId,(ReadData and bitStatusRxedFlag) = bitStatusRxedFlag, "ProcessModeRxCommands:" & to_string(CurrentCmdIndex) & " IRQ: bitStatusRxedFlag  " & to_hstring(ReadData), ERROR);
      else
        Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": MODE RT RX Command with data word", DEBUG);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessRxDataMessages is
    begin
      Log(AlertLogId, "ProcessRxDataMessages: " & to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": Processing RT RX Data Messages", DEBUG);
      log(AlertLogId, "ProcessRxDataMessages: CmdRtAddr " & to_hstring(CmdRtAddr_stdv) & " MyRtAddr1 " & to_string(MyRtAddr1) & " MyRtAddr2 " & to_string(MyRtAddr2), DEBUG);
      -- wait for the outen process to complete the message send
      WaitFor_OutenToComplete(tWord + (tWord * WordLen) + tGAP);
      ----------------------------------------------------------------------------------------------------
      -- if the message is not a broadcast or it is addressed to either of the present RTs, then check the status response otherwise check for the NRP IRQ
      ----------------------------------------------------------------------------------------------------
      if ((CmdRtAddr_stdv /= "11111") and ((CmdRtAddr_stdv = std_logic_vector(to_unsigned(MyRtAddr1, 5))) or (CmdRtAddr_stdv = std_logic_vector(to_unsigned(MyRtAddr2, 5))))) then
        -- wait until the BC generates an IRQ, then run the process to check the results
        WaitForLevel(DiscretesOut.Intr, tGap + tCommand + (tWord * WordLen) + tREP + tStatus + tGAP / 2, Timeout, '1');
        if (timeout = false) then
          Log(AlertLogID, "ProcessRxDataMessages: " & to_string(CurrentCmdIndex) & " BC: bitStatusRxedFlag IRQ Received and entering BC CHECK", DEBUG);
        end if;
        -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
        AlertIf(AlertLogID, Timeout, "ProcessRxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive bitStatusRxedFlag Intr as expected");
        Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
        AffirmIf(AlertLogId,(ReadData and bitStatusRxedFlag) = bitStatusRxedFlag, "ProcessRxDataMessages: " & to_string(CurrentCmdIndex) & " IRQ: bitStatusRxedFlag  " & to_hstring(ReadData), ERROR);
        printStatusWord(AlertLogID, ReadData);
        ----------------------------------------------------------------------------------------------------
        ----------------------------------------------------------------------------------------------------
      elsif (CmdRtAddr_stdv = "11111") then
      else
        -- wait until the BC generates a NRP IRQ, then run the process to check the results
        WaitForLevel(DiscretesOut.Intr, tGap + tCommand + (tWord * WordLen) + tNRP + tGAP / 2, Timeout, '1');
        if (timeout = false) then
          Log(AlertLogID, "ProcessRxDataMessages:" & to_string(CurrentCmdIndex) & " BC: NRP IRQ Received and entering BC CHECK", DEBUG);
        end if;
        -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
        AlertIf(AlertLogID, Timeout, "ProcessRxDataMessages:" & to_string(CurrentCmdIndex) & " BC did not receive NRP Intr as expected");
        ----------------------------------------------------------------------------------------------------
        Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
        AffirmIf(AlertLogId,(ReadData and bitNRP) = bitNRP, "ProcessRxDataMessages:" & to_string(CurrentCmdIndex) & " IRQ: bitNRP  " & to_hstring(ReadData), ERROR);
      end if;
      ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessModeTxCommands is
    begin
      Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": Processing MODE RT TX Commands", DEBUG);
      if (((CmdRtAddr_stdv = std_logic_vector(to_unsigned(MyRtAddr1, 5))) or (CmdRtAddr_stdv = std_logic_vector(to_unsigned(MyRtAddr2, 5))))) then
        if (CmdLen_stdv(4) = '0') then
          Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": MODE RT TX Command with no data word", DEBUG);
          -- the RT would auto respond with the correct data. Here we need to check what we received makes sense to what was requested. Use a case statement for the different mode commands
          Log(AlertLogId, "------------------------------------------------------------> 1", DEBUG);
          WaitFor_get_and_checkStatusword;
        else
          Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": MODE RT TX Command with data word", DEBUG);
          -- the RT would auto respond with the correct statusword and data word. Here we need to check what we received makes sense to what was requested. Use a case statement for the different mode commands
          Log(AlertLogId, "------------------------------------------------------------> 2", DEBUG);
          WaitFor_OutenToComplete;
          WaitFor_get_and_checkStatusword;
          WaitFor_get_and_checkModeCmdDat;
        end if;
      elsif (CmdRtAddr_stdv = "11111") then
        WaitFor_OutenToComplete(tWord + 10 ns); --to complete the sending of the data word (TODO maybe wait for 2 word sometimes????)
        Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: MODE RT TX Command is a Broadcast, no response expected.", DEBUG);
        Log(AlertLogId, "------------------------------------------------------------> 3", DEBUG);
        --WaitFor_get_and_checkStatusword;
        --WaitFor_get_and_checkModeCmdDat;
      else
        Log(AlertLogId, to_string(CurrentCmdIndex) & " BC: MODE RT TX Command not for connected RTs, NRP expected.", DEBUG);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessTxDataMessages is
    begin
      Log(AlertLogId, "1 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: RT" & to_string(ThisRtAddr) & ": Processing RT TX Data Messages", DEBUG);
      -- THE BC WILL EXPECT AND CHECK THE CLEAR STATUS MESSAGE
      -- 1st IRQ was for the status, so check to make sure it is good
      -- if (NextRtAddr /= MyRtAddr1) and (NextRtAddr /= MyRtAddr2) then
      --   Log(AlertLogID, to_string(CurCmdIndex) & " Transmitting RT not in network, Checking NRP and exiting.", DEBUG);
      --   Read(cpu_bus,(reg_busX_status or MilBusStdv), ReadData);
      --   AffirmIf(AlertLogId,(ReadData and bitNRP) = bitNRP, to_string(CurCmdIndex) & " IRQ: bitNRP  " & to_hstring(ReadData), ERROR);
      --   ClearInterrupts(cpu_bus, MilBus, IrqMask, AlertLogId);
      --   next;
      -- end if;
      log(AlertLogId, "1a BC: RT" & to_string(ThisRtAddr) & ": TransmittingRT = " & to_string(TransmittingRT), DEBUG);
      log(AlertLogId, "1b BC: RT" & to_string(ThisRtAddr) & ": ReceivingRT = " & to_string(ReceivingRT), DEBUG);
      log(AlertLogId, "1c BC: RT" & to_string(ThisRtAddr) & ": CmdRtAddr_stdv = " & to_hstring(CmdRtAddr_stdv), DEBUG);

      ----------------------------------------------------------------------------------------------------
      if (((CmdRtAddr_stdv = std_logic_vector(to_unsigned(MyRtAddr1, 5))) or (CmdRtAddr_stdv = std_logic_vector(to_unsigned(MyRtAddr2, 5))))) then
        -- wait until the BC generates an IRQ, then run the process to check the results
        if (CurrentCmdIndex > 0) then
          if (MultiCommandRec.Command(CurrentCmdIndex - 1).Rt2RT = '0') then
            WaitForLevel(DiscretesOut.Intr, tGap + tCommand + tRep + tStatus + tCommand + (tWord * WordLen) + tNRP + tGap / 2, Timeout, '1');
            if (timeout = false) then
              Log(AlertLogID, "2a ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: bitStatusRxedFlag IRQ Received and entering BC CHECK", DEBUG);
            end if;
            -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
            AlertIf(AlertLogID, Timeout, "3a ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive bitStatusRxedFlag Intr as expected");
          else -- this is RT2RT
            WaitForLevel(DiscretesOut.Intr, tGap + (tCommand * 2) + tRep + tStatus + tCommand + (tWord * WordLen) + tNRP + tGap / 2, Timeout, '1');
            if (timeout = false) then
              Log(AlertLogID, "2b ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: bitStatusRxedFlag IRQ Received and entering BC CHECK", DEBUG);
            end if;
            -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
            AlertIf(AlertLogID, Timeout, "3b ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive bitStatusRxedFlag Intr as expected");
          end if;
        else
          WaitForLevel(DiscretesOut.Intr, tGap + (tCommand * 2) + tRep + tStatus + tCommand + (tWord * WordLen) + tNRP + tGap / 2, Timeout, '1');
          if (timeout = false) then
            Log(AlertLogID, "2c ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: bitStatusRxedFlag IRQ Received and entering BC CHECK", DEBUG);
          end if;
          -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
          AlertIf(AlertLogID, Timeout, "3c ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive bitStatusRxedFlag Intr as expected");
        end if;
        ----------------------------------------------------------------------------------------------------
        Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
        AffirmIf(AlertLogId,(ReadData and bitStatusRxedFlag) = bitStatusRxedFlag, "4 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: IRQ: bitStatusRxedFlag  " & to_hstring(ReadData), ERROR);
        ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
        -- Read the status word itself and check contents
        Read(cpu_bus,(reg_statusword_rxedX or MilBus_stdv), ReadData);
        printStatusWord(AlertLogId, ReadData);
        -- A special case of clear status is for a broadcast RT2RT message, the broadcast bit will be set in the Status command
        Log(AlertLogId,
            "ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " RT2RT_Busy = " & to_string(RT2RT_Busy) & " PrevRtAddr_i = " & to_string(PrevRtAddr_i) & " PrevCmdWord = " & to_string(PrevCmdWord) & " ThisCmdWord = " & to_hstring(ThisCmdWord) & " ((ThisCmdWord and XF800 )or bitBrdcstRxed) = " & to_hstring(((ThisCmdWord and X"F800") or bitBrdcstRxed)),
            DEBUG);
        if (RT2RT_Busy) then
          if (PrevRtAddr_i = 31) then
            AffirmIf(AlertLogId,(ReadData) = ((ThisCmdWord and X"F800") or bitBrdcstRxed), "5a ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: Status not clear  " & to_hstring(ReadData), ERROR);
          else
            AffirmIf(AlertLogId,(ReadData) = (ThisCmdWord and X"F800"), "5b ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: Status not clear  " & to_hstring(ReadData), ERROR);
          end if;
        end if;
        -- TODO perhaps some special checks later for specific bit in message. for now just check for CS
        -- the line below should be the next command word.
        printStatusWord(AlertLogID, ReadData);
        -- The BC must check the data sent by RT against the BC scoreboard
        -- wait for the data to complete
        WaitForLevel(DiscretesOut.Intr, tStatus + (tWord * WordLen) + tGap / 2, Timeout, '1'); -- waiting for the end of data IRQ
        if (timeout = false) then
          Log(AlertLogID, "6 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: bitDataReceived IRQ Received", DEBUG);
        end if;
        AlertIf(AlertLogID, Timeout, "7 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive bitDataReceived Intr as expected");
        Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
        AffirmIf(AlertLogId,(ReadData and bitDataReceived) = bitDataReceived, "8 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " IRQ: bitDataReceived  " & to_hstring(ReadData), ERROR);
        ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
        -- check the data contents 
        Log(AlertLogID, "9 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " WordLen = " & to_string(WordLen), DEBUG);
        for i in 1 to WordLen loop
          RxRamAddr := 2047 + (to_integer(unsigned(CmdSubAddr_stdv)) * 32) + i;
          Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), ReadData);
          Log(AlertLogID, "10 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " Data" & to_string(i) & " = " & to_hstring(ReadData), DEBUG);
          Check(SB_BC, ReadData);
        end loop;
        ----------------------------------------------------------------------------------------------------
        -- If RT2RT, check for the receiving RT CS
        ----------------------------------------------------------------------------------------------------
        if (CurrentCmdIndex > 0) then
          if (MultiCommandRec.Command(CurrentCmdIndex - 1).Rt2RT = '1') and (MultiCommandRec.Command(CurrentCmdIndex - 1).RtAddr /= 31) then
            -- only check for Status if the receiver is in the network
            if (MultiCommandRec.Command(CurrentCmdIndex - 1).RtAddr = MyRtAddr1) or (MultiCommandRec.Command(CurrentCmdIndex - 1).RtAddr = MyRtAddr2) then
              WaitForLevel(DiscretesOut.Intr, tRep + tStatus + tGap / 2, Timeout, '1');
              if (timeout = false) then
                Log(AlertLogID, "11 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: bitStatusRxedFlag IRQ Received", DEBUG);
              end if;
              AlertIf(AlertLogID, Timeout, "12 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive bitStatusRxedFlag Intr as expected");
              Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
              AffirmIf(AlertLogId,(ReadData and bitStatusRxedFlag) = bitStatusRxedFlag, "13 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " IRQ: bitStatusRxedFlag  " & to_hstring(ReadData), ERROR);
              ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
            else -- check for the NRP if the destination is not in the network§
              WaitForLevel(DiscretesOut.Intr, tGap + tCommand + tNRP + tGap / 2, Timeout, '1');
              if (timeout = false) then
                Log(AlertLogID, "14 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: tNRP IRQ Received and entering BC CHECK", DEBUG);
              end if;
              -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
              AlertIf(AlertLogID, Timeout, "15 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive tNRP Intr as expected");
              ----------------------------------------------------------------------------------------------------
              Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
              AffirmIf(AlertLogId,(ReadData and bitNRP) = bitNRP, "16 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: IRQ: bitNRP  " & to_hstring(ReadData), ERROR);
              ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
            end if;
          end if;
        end if;
        ----------------------------------------------------------------------------------------------------
      elsif (CmdRtAddr_stdv = "11111") then
        -- No need to wait for any interrupts, just exit
        wait for (tword + (tWord * WordLen) + tGAP);

        ----------------------------------------------------------------------------------------------------
      else
        -- wait until the BC generates an IRQ, then run the process to check the results
        WaitForLevel(DiscretesOut.Intr, tGap + tCommand + tNRP + tGap / 2, Timeout, '1');
        if (timeout = false) then
          Log(AlertLogID, "17 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: tNRP IRQ Received and entering BC CHECK", DEBUG);
        end if;
        -- If the IRQ times out, indicate it and exit the process. This is basically a test failure.
        AlertIf(AlertLogID, Timeout, "18 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC did not receive tNRP Intr as expected");
        ----------------------------------------------------------------------------------------------------
        Read(cpu_bus,(reg_busX_status or MilBus_stdv), ReadData);
        AffirmIf(AlertLogId,(ReadData and bitNRP) = bitNRP, "19 ProcessTxDataMessages: " & to_string(CurrentCmdIndex) & " BC: IRQ: bitNRP  " & to_hstring(ReadData), ERROR);
        ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessRxMessages is
    begin
      Log(AlertLogId, to_string(CurrentCmdIndex) & " Processing RX Messages" & " and CmdSubAddr_stdv = " & to_hstring(CmdSubAddr_stdv), DEBUG);
      -- Add RX message processing logic here
      if (CmdSubAddr_stdv = "00000" or CmdSubAddr_stdv = "11111") then
        -- Handle specific MODE RX COMMAND message cases
        ProcessModeRxCommands;
      else
        -- Handle other DATA RX message cases
        ProcessRxDataMessages;
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessTxMessages is
    begin
      Log(AlertLogId, to_string(CurrentCmdIndex) & " RT" & to_string(ThisRtAddr) & ": Processing TX Messages", DEBUG);
      -- Add TX message processing logic here
      if (CmdSubAddr_stdv = "00000" or CmdSubAddr_stdv = "11111") then
        -- Handle specific MODE TX COMMAND message cases
        ProcessModeTxCommands;
      else
        -- Handle other DATA TX message cases
        ProcessTxDataMessages;
      end if;
    end procedure;

    ----------------------------------------------------------------------------------------------------
    -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ----------------------------------------------------------------------------------------------------
  begin
    ----------------------------------------------------------------------------------------------------
    --TODO you dont know which bus is active...so why just wait on outen1 -->   wait until DiscretesOut.OutEn1 = '1';
    BC_Check_Exit <= '0';
    wait for 0 ns;
    for CurrentCmdIndexLoop in 0 to MultiCommandRec.Length - 1 loop
      wait for 100 ns;
      -- v4p formatting off
      log(AlertLogId, LF & 
      "--------------- BEFORE ---------------" & LF & 
      "SB_RT1_CMD: " & to_string(GetFifoCount(SB_RT1_CMD)) & LF & 
      "SB_RT1_DAT: " & to_string(GetFifoCount(SB_RT1_DAT)) & LF & 
      "SB_RT1_TMP: " & to_string(GetFifoCount(SB_RT1_TMP)) & LF & 
      "SB_RT2_CMD: " & to_string(GetFifoCount(SB_RT2_CMD)) & LF & 
      "SB_RT2_DAT: " & to_string(GetFifoCount(SB_RT2_DAT)) & LF & 
      "SB_RT2_TMP: " & to_string(GetFifoCount(SB_RT2_TMP)) & LF & 
      "SB_RT2RT: "   & to_string(GetFifoCount(SB_RT2RT)), DEBUG);
      -- v4p formatting on
      CurCmdIndex <= CurrentCmdIndexLoop;
      CurrentCmdIndex := CurrentCmdIndexLoop;
      wait for 0 ns;
      if (CurrentCmdIndex > 0) then
        CmdRtAddr_stdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex - 1).RtAddr, 5));
        CmdTxnRx_std := std_logic(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex - 1).TxnRx, 1)(0));
        CmdSubAddr_stdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex - 1).SubAddr, 5));
        CmdLen_stdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex - 1).Len, 5));
        PrevCmdWord := CmdRtAddr_stdv & CmdTxnRx_std & CmdSubAddr_stdv & CmdLen_stdv;
        PrevRtAddr_i := MultiCommandRec.Command(CurrentCmdIndex - 1).RtAddr;
      end if;
      CmdRtAddr_stdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex).RtAddr, 5));
      CmdTxnRx_std := std_logic(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex).TxnRx, 1)(0));
      CmdSubAddr_stdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex).SubAddr, 5));
      CmdLen_stdv := std_logic_vector(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex).Len, 5));
      ThisCmdWord := CmdRtAddr_stdv & CmdTxnRx_std & CmdSubAddr_stdv & CmdLen_stdv;
      CmdWord <= ThisCmdWord;
      wait for 0 ns;
      ThisRtAddr := MultiCommandRec.Command(CurrentCmdIndex).RtAddr;
      ----------------------------------------------------------------------------------------------------
      -- Determine active bus, then set a few helper variables
      ----------------------------------------------------------------------------------------------------
      if (MultiCommandRec.Command(CurrentCmdIndex).Rt2RT = '1') then
        RT2RT_DestAddr <= MultiCommandRec.Command(CurrentCmdIndex + 1).RtAddr;
        RT2RT_Busy <= True;
        TransmittingRT <= MultiCommandRec.Command(CurrentCmdIndex + 1).RtAddr;
        ReceivingRT <= MultiCommandRec.Command(CurrentCmdIndex).RtAddr;
        wait for 0 ns;
      end if;
      Log(AlertLogId, "ENTRYENTRYENTRYENTRYENTRY>>>>>>> BC_MULTI_CHECK ENTRY: CMDWORD INDEX:" & to_string(CurCmdIndex) & " CMDWORD: " & to_hstring(CmdWord), DEBUG);
      Toggle(BC_NextCmd);
      wait for 500 ns; -- This is a TB requirement to let the RT process clear the RT_Done signal
      MilBus_stdv := std_logic_vector(shift_left(unsigned(std_logic_vector(to_unsigned(MultiCommandRec.Command(CurrentCmdIndex).MilBus, 16))), 4));
      MilBus_std := '0' when MilBus_stdv = X"0010" else '1';
      MilBus_i := to_integer(MilBus_std) + 1;
      ----------------------------------------------------------------------------------------------------
      -- Normalise the word length, LEN="00000" is actually 32 words
      if (CmdLen_stdv = "00000") then
        WordLen := 32;
      else
        WordLen := to_integer(unsigned(CmdLen_stdv));
      end if;
      -- for mode command, the word length is always 1
      if (CmdSubAddr_stdv = "00000" or CmdSubAddr_stdv = "11111") then
        if (CmdLen_stdv(4) = '1') then
          WordLen := 1;
        else
          WordLen := 0;
        end if;
      end if;
      ----------------------------------------------------------------------------------------------------
      wait for 0 ns;
      ----------------------------------------------------------------------------------------------------
      -- RT TO RT MESSAGE
      ----------------------------------------------------------------------------------------------------
      -- if the BC Checker sees that the current command is for RT2RT, 
      -- it should just exit and handle the RT2RT case on the next command (RT TX)
      if (MultiCommandRec.Command(CurrentCmdIndex).Rt2RT = '1') then
        Log(AlertLogId, "SKIPPINGSKIPPINGSKIPPINGSKIPPING>>>>>>> " & to_string(CurrentCmdIndex) & " BC_MULTI_CHECK: RT2RT CMDWORD: " & to_hstring(CmdWord) & ", skipping to next command", DEBUG);
        wait for tWord;
        next;
      end if;

      ----------------------------------------------------------------------------------------------------
      if (CmdTxnRx_std = '0') then
        ----------------------------------------------------------------------------------------------------
        -- RT RECEIVING
        ----------------------------------------------------------------------------------------------------
        Log(AlertLogId, "BC: RT" & to_string(ThisRtAddr) & " is receiving", DEBUG);
        -- transfer the number of words from TMP SB to actual SB                -- v4p formatting off
        log(AlertLogId, LF & 
        "--------------- BEFORE ---------------" & LF & 
        "SB_RT1_CMD: " & to_string(GetFifoCount(SB_RT1_CMD)) & LF & 
        "SB_RT1_DAT: " & to_string(GetFifoCount(SB_RT1_DAT)) & LF & 
        "SB_RT1_TMP: " & to_string(GetFifoCount(SB_RT1_TMP)) & LF & 
        "SB_RT2_CMD: " & to_string(GetFifoCount(SB_RT2_CMD)) & LF & 
        "SB_RT2_DAT: " & to_string(GetFifoCount(SB_RT2_DAT)) & LF & 
        "SB_RT2_TMP: " & to_string(GetFifoCount(SB_RT2_TMP)) & LF & 
        "SB_RT2RT: " & to_string(GetFifoCount(SB_RT2RT)), DEBUG);
        -- v4p formatting on
        if (WordLen > 0) then
          if (ThisRtAddr = MyRtAddr1) then
            for i in 0 to WordLen - 1 loop
              Pop(SB_RT1_TMP, ReadData);
              Log(AlertLogId, "SB_RT1_DAT, Push DATA " & to_hstring(ReadData), DEBUG);
              Push(SB_RT1_DAT, ReadData);
            end loop;
          elsif (ThisRtAddr = MyRtAddr2) then
            for i in 0 to WordLen - 1 loop
              Pop(SB_RT2_TMP, ReadData);
              Log(AlertLogId, "SB_RT2_DAT, Push DATA " & to_hstring(ReadData), DEBUG);
              Push(SB_RT2_DAT, ReadData);
            end loop;
          elsif (ThisRtAddr = 31) then
            for i in 0 to WordLen - 1 loop
              Pop(SB_RT1_TMP, ReadData);
              Log(AlertLogId, "SB_RT1_DAT, Push DATA " & to_hstring(ReadData), DEBUG);
              Push(SB_RT1_DAT, ReadData);
              Pop(SB_RT2_TMP, ReadData);
              Log(AlertLogId, "SB_RT2_DAT, Push DATA " & to_hstring(ReadData), DEBUG);
              Push(SB_RT2_DAT, ReadData);
            end loop;
          end if;
        end if;
        -- v4p formatting off
        log(AlertLogId, LF & 
        "--------------- AFTER TRANSFER ---------------" & LF & 
        "SB_RT1_CMD: " & to_string(GetFifoCount(SB_RT1_CMD)) & LF & 
        "SB_RT1_DAT: " & to_string(GetFifoCount(SB_RT1_DAT)) & LF & 
        "SB_RT1_TMP: " & to_string(GetFifoCount(SB_RT1_TMP)) & LF & 
        "SB_RT2_CMD: " & to_string(GetFifoCount(SB_RT2_CMD)) & LF & 
        "SB_RT2_DAT: " & to_string(GetFifoCount(SB_RT2_DAT)) & LF & 
        "SB_RT2_TMP: " & to_string(GetFifoCount(SB_RT2_TMP)) & LF & 
        "SB_RT2RT: " & to_string(GetFifoCount(SB_RT2RT)), DEBUG);
        -- v4p formatting on
        ProcessRxMessages;
      else
        ----------------------------------------------------------------------------------------------------
        -- RT TRANSMITTING
        ----------------------------------------------------------------------------------------------------
        Log(AlertLogId, "BC: RT" & to_string(ThisRtAddr) & " is transmitting", DEBUG);
        ProcessTxMessages;
      end if;
      wait for 0 ns;
      --   if (CurCmdIndex < (MultiCommandRec.Length - 1)) then
      --if (CurrentCmdIndexLoop /= (MultiCommandRec.Length - 1)) then
      log(AlertLogId, "======================>>>>>>> BC_MULTI_CHECK: WAITING FOR RT TOGGLES", DEBUG);
      WaitForLevel(RT1_Done, '1');
      WaitForLevel(RT2_Done, '1');
      --end if;
      if (RT2RT_Busy = true) then
        RT2RT_Busy <= false;
      end if;
      Log(AlertLogId, "======================>>>>>>> BC: CMDWORD: " & to_hstring(CmdWord) & " BC_MULTI_CHECK LOOP ITEM DONE", DEBUG);
      -- v4p formatting off
      log(AlertLogId, LF & 
      "--------------- AFTER TRANSFER ---------------" & LF & 
      "SB_RT1_CMD: " & to_string(GetFifoCount(SB_RT1_CMD)) & LF & 
      "SB_RT1_DAT: " & to_string(GetFifoCount(SB_RT1_DAT)) & LF & 
      "SB_RT1_TMP: " & to_string(GetFifoCount(SB_RT1_TMP)) & LF & 
      "SB_RT2_CMD: " & to_string(GetFifoCount(SB_RT2_CMD)) & LF & 
      "SB_RT2_DAT: " & to_string(GetFifoCount(SB_RT2_DAT)) & LF & 
      "SB_RT2_TMP: " & to_string(GetFifoCount(SB_RT2_TMP)) & LF & 
      "SB_RT2RT: " & to_string(GetFifoCount(SB_RT2RT)), DEBUG);
      -- v4p formatting on
    end loop;
    ----------------------------------------------------------------------------------------------------
    -- the next few lines ensures that the RT process exits cleanly to prepare for the next test
    ----------------------------------------------------------------------------------------------------
    BC_Check_Exit <= '1';
    Toggle(BC_NextCmd);
    wait for 0 ns;
    Log(AlertLogId, "======================>>>>>>> BC_MULTI_CHECK EXIT", DEBUG);
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
  end procedure;
  procedure RT_MULTI_CHECK(
             MultiCommandRec :       MultiCommandRec_type;
             MyRtAddr        :       integer;
             OtherRtAddr     :       integer;
             MyBcAddr        :       integer;
      signal CmdWord         : in    std_logic_vector(15 downto 0);
      signal cpu_bus         : inout AddressBus16Type;
      signal DiscretesOut    : in    CoreDiscretesOut_type;
      signal SB_CMD          :       ScoreboardIdType;
      signal SB_DAT          :       ScoreboardIdType;
      signal SB_OTHER_CMD    :       ScoreboardIdType;
      signal SB_OTHER_DAT    :       ScoreboardIdType;
             SB_BC           :       ScoreboardIdType;
             SB_RT2RT        :       ScoreboardIdType;
      --      signal BC_CMD_SEND_Done : inout integer_barrier;
      signal NextCmd         : inout integer_barrier;
      signal CurCmdIndex     : in    integer;
      signal TransmittingRT  : in    integer;
      signal ReceivingRT     : in    integer;
      signal RT2RT_DestAddr  : in    integer;
      signal BC_NextCmd      : in    std_logic;
      signal RT_Done         : out   std_logic;
      signal BC_Exit         : in    std_logic;
      signal RT2RT_Busy      : in    boolean;
      signal BC_Check_Exit   : in    std_logic;
             AlertLogId      :       AlertLogIDType
    ) is
    variable RV                  : RandomPType;
    variable RandomData          : std_logic_vector(15 downto 0);
    variable CmdRtAddr_stdv      : std_logic_vector(4 downto 0);
    variable CmdTxnRx_std        : std_logic;
    variable CmdSubAddr_stdv     : std_logic_vector(4 downto 0);
    variable CmdLen_stdv         : std_logic_vector(4 downto 0);
    variable RxRamAddr           : integer;
    variable TxRamAddr           : integer;
    variable Timeout             : boolean;
    variable MilBus_stdv         : std_logic_vector(15 downto 0);
    variable MilBus_std          : std_logic;
    variable MilBus_i            : integer;
    variable RtAddrStdv          : std_logic_vector(4 downto 0);
    variable SubAddrStdv         : std_logic_vector(4 downto 0);
    variable ReadData            : std_logic_vector(15 downto 0);
    variable LenStdv             : std_logic_vector(4 downto 0);
    variable TxnRxStd            : std_logic;
    variable Rd_reg_status       : std_logic_vector(15 downto 0);
    variable Rd_reg_intr_mask    : std_logic_vector(15 downto 0);
    variable Rd_reg_cmd_rxedX    : std_logic_vector(15 downto 0);
    variable Rd_reg_rx_mode_cmdX : std_logic_vector(15 downto 0);
    variable Rd_reg_busX_mask    : std_logic_vector(15 downto 0);
    variable Rd_reg_busX_status  : std_logic_vector(15 downto 0);
    variable WordLen             : integer; -- the actual number of data words
    variable RT2RT               : boolean;
    variable RT2RT_AddrStdv      : std_logic_vector(15 downto 0);
    variable SubaddrRxed         : std_logic_vector(31 downto 0);
    variable ExpectedSubaddrRxed : std_logic_vector(31 downto 0);
    variable HardwareDataWrap    : boolean := false;
    ----------------------------------------------------------------------------------------------------
    procedure WaitFor_OutenToComplete(
        OutEnHighTime : time := tWord
      ) is
    begin
      if (MilBus_i = 1) then
        WaitForLevel(DiscretesOut.OutEn1, tREP + 2 us, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "OutEn1 did not go HIGH as expected", FAILURE);
        WaitForLevel(DiscretesOut.OutEn1, OutEnHighTime, Timeout, '0');
        AlertIf(AlertLogID, Timeout, "OutEn1 did not go LOW as expected", FAILURE);
      else
        WaitForLevel(DiscretesOut.OutEn2, tREP + 2 us, Timeout, '1');
        AlertIf(AlertLogID, Timeout, "OutEn2 did not go HIGH as expected", FAILURE);
        WaitForLevel(DiscretesOut.OutEn2, OutEnHighTime, Timeout, '0');
        AlertIf(AlertLogID, Timeout, "OutEn2 did not go LOW as expected", FAILURE);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
    procedure ProcessModeRxCommands is
      variable RxModeDataWord : std_logic_vector(15 downto 0);
    begin
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": Processing MODE RX Commands", DEBUG);
      if (CmdLen_stdv(4) = '0') then
        Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": MODE RX Command with no data word", DEBUG);
      else
        Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": MODE RX Command with data word", DEBUG);
        -- need to pop the expected data from the SB_RT1_DAT and comapre with the received command word
        Read(cpu_bus,(reg_mode_data_rxedX or MilBus_stdv), RxModeDataWord);
        Check(SB_DAT, RxModeDataWord);
      end if;
      if (CmdRtAddr_stdv /= "11111") then
        WaitFor_OutenToComplete(tWord + tGAP);
      else
        wait for (tWord + tGAP);
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessRxDataMessages is
    begin
      -- if the sender is not in the network, the message would never arrive, so wait for the NRP interrupt
      log(AlertLogId, "----------------> RT2RT_Busy = " & to_string(RT2RT_Busy), DEBUG);
      log(AlertLogId, "----------------> RT2RT_DestAddr = " & to_string(RT2RT_DestAddr), DEBUG);
      log(AlertLogId, "----------------> CmdRtAddr_stdv = " & to_hstring(CmdRtAddr_stdv), DEBUG);
      if (CmdRtAddr_stdv /= std_logic_vector(to_unsigned(MyRtAddr, 5))) and (CmdRtAddr_stdv /= std_logic_vector(to_unsigned(OtherRtAddr, 5)) and (CmdRtAddr_stdv /= "11111")) then
        log(AlertLogId, "-------1-------->if (CmdRtAddr_stdv /= std_logic_vector(to_unsigned(MyRtAddr, 5))) and (CmdRtAddr_stdv /= std_logic_vector(to_unsigned(OtherRtAddr, 5)) and (CmdRtAddr_stdv /= 11111)) then", DEBUG);
        AffirmIf(AlertLogId,(Rd_reg_busX_status and bitNRP) = bitNRP, "RT" & to_string(MyRtAddr) & " IRQ: bitNRP  " & to_hstring(Rd_reg_busX_status), ERROR);
        ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
      elsif ((RT2RT_DestAddr /= MyRtAddr) and (RT2RT_DestAddr /= OtherRtAddr) and (RT2RT_busy = true)) then -- and (CmdRtAddr_stdv = "11111") and (RT2RT = true)) then
        log(AlertLogId, "-------2-------->---------------->---------------->---------------->---------------->if (CmdRtAddr_stdv /= std_logic_vector(to_unsigned(MyRtAddr, 5))) and (CmdRtAddr_stdv /= std_logic_vector(to_unsigned(OtherRtAddr, 5)) and (CmdRtAddr_stdv = 11111)) then", DEBUG);
        AffirmIf(AlertLogId,(Rd_reg_busX_status and bitNRP) = bitNRP, "RT" & to_string(MyRtAddr) & " IRQ: bitNRP  " & to_hstring(Rd_reg_busX_status), ERROR);
        ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
      else
        Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": Processing RX Data Messages", DEBUG);
        AffirmIf(AlertLogId,(Rd_reg_busX_status and bitDataReceived) = bitDataReceived, "RT" & to_string(MyRtAddr) & "IRQ: DataReceived not received as expected for normal data: IRQ=" & to_hstring(Rd_reg_busX_status));
        ------------- check tha data contents ------------------------------
        for i in 1 to WordLen loop
          RxRamAddr := 2047 + (to_integer(unsigned(CmdSubAddr_stdv)) * 32) + i;
          Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), ReadData);
          Log(AlertLogID, "RT" & to_string(MyRtAddr) & ": Data" & to_string(i) & " = " & to_hstring(ReadData), DEBUG);
          Check(SB_DAT, ReadData);
          if (HardwareDataWrap = true) then
            Push(SB_BC, ReadData);
            Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": SB_BC, Push DataWrap " & to_hstring(ReadData), DEBUG);
          end if;
        end loop;
        -- v4p formatting off
        log(AlertLogId, LF & 
        "--- RT" & to_string(MyRtAddr) & " ------------ AFTER ---------------" & LF & 
        "SB_BC: " & to_string(GetFifoCount(SB_BC)) & LF & 
        "SB_CMD: " & to_string(GetFifoCount(SB_CMD)) & LF & 
        "SB_DAT: " & to_string(GetFifoCount(SB_DAT)) & LF & 
        "SB_OTHER_CMD: " & to_string(GetFifoCount(SB_OTHER_CMD)) & LF & 
        "SB_OTHER_DAT: " & to_string(GetFifoCount(SB_OTHER_DAT)), DEBUG);
        -- v4p formatting on
        -- wait for the status transmission to complete, if broadcast, there is no wait
        if (CmdRtAddr_stdv /= "11111") then
          WaitFor_OutenToComplete(tRep + tStatus);
        end if;
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessModeTxCommands is
    begin
      Log(AlertLogId, "ProcessModeTxCommands RT" & to_string(MyRtAddr) & ": Processing MODE TX Commands", DEBUG);
      if (CmdLen_stdv(4) = '0') then
        Log(AlertLogId, "ProcessModeTxCommands RT" & to_string(MyRtAddr) & ": MODE TX Command with no data word", DEBUG);
      else
        Log(AlertLogId, "ProcessModeTxCommands RT" & to_string(MyRtAddr) & ": MODE TX Command with data word", DEBUG);
        -- for broadcast, no need to wait for teh send of the status word, just exit.
        -- need to wait for the right amount of time to simulate the status and data word being sent
        -- we will use the outen signal to indicate when the status word is sent
        if (CmdRtAddr_stdv = "11111") then
          Log(AlertLogId, "ProcessModeTxCommands RT" & to_string(MyRtAddr) & ":Broadcast, so no status --> exit", DEBUG);
          wait for 100 ns;
        else
          Log(AlertLogId, "ProcessModeTxCommands RT" & to_string(MyRtAddr) & ": wait for Outen to complete the transmission ", DEBUG);
          WaitFor_OutenToComplete(tRep + tStatus + tWord);
        end if;
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessTxDataMessages is
      variable DoneRt2rt : boolean := false;
    begin
      Log(AlertLogId, "1 RT" & to_string(MyRtAddr) & ": Processing TX Data Messages", DEBUG);
      AffirmIf(AlertLogId,(Rd_reg_busX_status and bitDataReq) = bitDataReq, "RT" & to_string(MyRtAddr) & ": IRQ: DataRequest not received as expected for normal data: IRQ=" & to_hstring(Rd_reg_busX_status));
      log(AlertLogId, "2a RT" & to_string(MyRtAddr) & ": TransmittingRT = " & to_string(TransmittingRT), DEBUG);
      log(AlertLogId, "2b RT" & to_string(MyRtAddr) & ": ReceivingRT = " & to_string(ReceivingRT), DEBUG);
      log(AlertLogId, "2c RT" & to_string(MyRtAddr) & ": CmdRtAddr_stdv = " & to_hstring(CmdRtAddr_stdv), DEBUG);
      for i in 0 to WordLen - 1 loop
        TxRamAddr := 1024 + (to_integer(unsigned(CmdSubAddr_stdv)) * 32) + i;
        RandomData := RV.RandSlv(Min => 0, Max => 65525, Size => 16);
        ----------------------------------------------------------------------------------------------------
        -- if the RT2RT is true, then if the cmdaddr is broadcast, push to other RT SB
        -- or if the RT2RT_AddrStdv is not the same as the current RT address
        if (CurCmdIndex > 0) then
          if (MultiCommandRec.Command(CurCmdIndex - 1).Rt2RT = '1') then
            DoneRt2rt := true;
            if (ReceivingRT = 31) then
              Push(SB_OTHER_DAT, RandomData);
              Log(AlertLogId, "3 RT" & to_string(MyRtAddr) & ":1 SB_OTHER_DAT, Push RandomData " & to_hstring(RandomData), DEBUG);
            elsif (ReceivingRT = OtherRtAddr) then
              Push(SB_OTHER_DAT, RandomData);
              Log(AlertLogId, "4a RT" & to_string(MyRtAddr) & ":2 SB_OTHER_DAT, Push RandomData " & to_hstring(RandomData), DEBUG);
              -- elsif (CmdRtAddr_stdv = std_logic_vector(to_unsigned(TransmittingRT, 5))and (ReceivingRT = OtherRtAddr)) then
              --   Push(SB_OTHER_DAT, RandomData);
              --   Log(AlertLogId, "4b RT" & to_string(MyRtAddr) & ":2 SB_OTHER_DAT, Push RandomData " & to_hstring(RandomData), DEBUG);
            end if;
            Push(SB_BC, RandomData);
            Log(AlertLogId, "5 RT" & to_string(MyRtAddr) & ": SB_BC, Push RandomData " & to_hstring(RandomData), DEBUG);
          end if;
        end if;
        ----------------------------------------------------------------------------------------------------
        if (DoneRT2rt = false) then
          if (CmdRtAddr_stdv = "11111") then
            Push(SB_OTHER_DAT, RandomData);
            Log(AlertLogId, "6 RT" & to_string(MyRtAddr) & ":1 SB_OTHER_DAT, Push RandomData " & to_hstring(RandomData), DEBUG);
            -- elsif (to_integer(unsigned(CmdSubAddr_stdv)) = OtherRtAddr) then
            --   Push(SB_OTHER_DAT, RandomData);
            --   Log(AlertLogId, "7 RT" & to_string(MyRtAddr) & ":2 SB_OTHER_DAT, Push RandomData " & to_hstring(RandomData), DEBUG);
          end if;
          -- if hw datawrap is active, then push the data back to the BC scoreboard
          if (HardwareDataWrap = true) then
            -- RxRamAddr := 2048 + (to_integer(unsigned(CmdSubAddr_stdv)) * 32) + i;
            -- Read(cpu_bus, std_logic_vector(to_unsigned(RxRamAddr, 16)), ReadData);
            -- Push(SB_BC, ReadData);
            -- Log(AlertLogId, "7 RT" & to_string(MyRtAddr) & ": SB_BC, Push DataWrap " & to_hstring(ReadData), DEBUG);
          else
            Push(SB_BC, RandomData);
            Log(AlertLogId, "8 RT" & to_string(MyRtAddr) & ": SB_BC, Push RandomData " & to_hstring(RandomData), DEBUG);
          end if;

        end if;
        Write(cpu_bus, std_logic_vector(to_unsigned(TxRamAddr, 16)), RandomData);
      end loop;
        -- v4p formatting off
        log(AlertLogId, LF & 
        "--- RT" & to_string(MyRtAddr) & " ------------ AFTER ---------------" & LF & 
        "SB_BC: " & to_string(GetFifoCount(SB_BC)) & LF & 
        "SB_CMD: " & to_string(GetFifoCount(SB_CMD)) & LF & 
        "SB_DAT: " & to_string(GetFifoCount(SB_DAT)) & LF & 
        "SB_OTHER_CMD: " & to_string(GetFifoCount(SB_OTHER_CMD)) & LF & 
        "SB_OTHER_DAT: " & to_string(GetFifoCount(SB_OTHER_DAT)), DEBUG);
        -- v4p formatting on
      -- Wait for the data to be transmitted
      WaitFor_OutenToComplete(tRep + (tWord * WordLen) + tStatus);
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessRxMessages is
    begin
      Log(AlertLogId, "Processing RX Messages", DEBUG);
      -- Add RX message processing logic here
      if (CmdSubAddr_stdv = "00000" or CmdSubAddr_stdv = "11111") then
        -- Handle specific MODE RX COMMAND message cases
        ProcessModeRxCommands;
      else
        -- Handle other DATA RX message cases
        ProcessRxDataMessages;
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure ProcessTxMessages is
    begin
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": Processing TX Messages", DEBUG);
      -- Add TX message processing logic here
      if (CmdSubAddr_stdv = "00000" or CmdSubAddr_stdv = "11111") then
        -- Handle specific MODE TX COMMAND message cases
        ProcessModeTxCommands;
      else
        -- Handle other DATA TX message cases
        ProcessTxDataMessages;
      end if;
    end procedure;
    ----------------------------------------------------------------------------------------------------
    procedure CheckRxSubAddressRegister is
    begin
      ----------------------------------------------------------------------------------------------------
      -- check the subaddr rx register to see that right bit is set (new functionality for ATQ)
      -- it will set the bit for the subaddress of the receive command.
      ----------------------------------------------------------------------------------------------------
      ExpectedSubaddrRxed := (others => '0');
      ExpectedSubaddrRxed(to_integer(unsigned(CmdSubAddr_stdv))) := '1';
      Read(cpu_bus, reg_subaddr_rx_lsb, SubaddrRxed(15 downto 0));
      Read(cpu_bus, reg_subaddr_rx_msb, SubaddrRxed(31 downto 16));
      AffirmIf(AlertLogId, SubaddrRxed = ExpectedSubaddrRxed, "1Subaddress Rx register incorrect, expected " & to_hstring(ExpectedSubaddrRxed) & ", got " & to_hstring(SubaddrRxed));
      Write(cpu_bus, reg_subaddr_rx_lsb, SubaddrRxed(15 downto 0));
      Write(cpu_bus, reg_subaddr_rx_msb, SubaddrRxed(31 downto 16));
    end procedure;
    ----------------------------------------------------------------------------------------------------
    -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ----------------------------------------------------------------------------------------------------
  begin
    Log(AlertLogId, "RT" & to_string(MyRtAddr) & " PROC WAITING FOR TOGGLE", DEBUG);
    -- i want to pause here until BC NextCmd indicates it is done and moved on to next command
    WaitOnToggle(BC_NextCmd);
    wait for 100 ns;
    --if the BC_Exit is high, it means that hte BC Checker is done, so the main test is done
    -- so exit the proecedrue to the main loop, where the main loop will also chec kthe BC_Exit
    -- and exit to TestDone.
    if (BC_Check_Exit = '1') then
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": BC Check is done, exiting", DEBUG);
      Log(AlertLogId, "EXITEXITEXITEXITEXITEXITEXITEXIT>>>>>>> RT" & to_string(MyRtAddr) & ": Test is done, exiting", DEBUG);
      RT_Done <= '0'; -- non typical test complete exit
      wait for 0 ns;
      return;
    end if;
    ----------------------------------------------------------------------------------------------------
    Log(AlertLogId, "ININININININININININININININININ>>>>>>> RT" & to_string(MyRtAddr) & ": RT_MULTI_CHECK ENTRY: CMDWORD INDEX:" & to_string(CurCmdIndex) & " CMDWORD: " & to_hstring(CmdWord), DEBUG);
    RT_Done <= '0';
    wait for 0 ns;
    ----------------------------------------------------------------------------------------------------
    -- if this message is for this RT or a Broadcast, exit if not
    if (CmdWord(15 downto 11) = std_logic_vector(to_unsigned(MyRtAddr, 5))) or (CmdWord(15 downto 11) = "11111") then
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": Command is for this RT or Broadcast", DEBUG);
    else
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": Command is NOT for this RT or Broadcast, exiting", DEBUG);
      Log(AlertLogId, "EXITEXITEXITEXITEXITEXITEXITEXIT>>>>>>> RT" & to_string(MyRtAddr) & ": CMDWORD: " & to_hstring(CmdWord) & " RT_MULTI_CHECK EXIT", DEBUG);
      RT_Done <= '1';
      wait for 100 ns; -- just to make it visible in the waveform viewer
      -- in this case, the RT will not transmit anything, so just exit with no delay
      return;
    end if;
    if (RT2RT_Busy = true) and (CmdWord(15 downto 11) = "11111") and (MyRtAddr = RT2RT_DestAddr) then
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": Broadcast RT2RT receive setup is for this RT as transmitter, waiting for transmit command", DEBUG);
      wait for tGAP;
      RT_Done <= '1';
      wait for 0 ns;
      return;
    end if;
    ----------------------------------------------------------------------------------------------------
    --TODO  this time of 10ms seems excesive, need to check with spec. The procedure iscalled after the BC
    -- command procedure is done, so the sending should start soon. The longest time it can take to send 
    -- a message is basically the time to send 32 words + gaps + IRQ response time which is about 1ms
    ----------------------------------------------------------------------------------------------------
    WaitForLevel(DiscretesOut.Intr, 1 ms, Timeout, '1');
    if (timeout = false) then
      Log(AlertLogID, "RT" & to_string(MyRtAddr) & ": IRQ Received", DEBUG);
    end if;
    if (timeout = true) and (BC_Exit = '1') then
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": BC Check is done, exiting", DEBUG);
      Log(AlertLogId, "EXITEXITEXITEXITEXITEXITEXITEXIT>>>>>>> RT" & to_string(MyRtAddr) & ": CMDWORD: " & to_hstring(CmdWord) & " RT_MULTI_CHECK EXIT", DEBUG);
      Alert(AlertLogId, "TIMEOUT: RT" & to_string(MyRtAddr) & " did not receive Intr as expected. TEST FAILED, rectify the cause.", FAILURE);
      RT_Done <= '1';
      wait for 0 ns;
      -- if there was a timeout, exit. If this a test failure or should we continues, I think it is a failure to be rectified.
      return;
    end if;

    -- if (Timeout and BC_MULTI_CHECK = '1') then
    --   Log(AlertLogID, "RT" & to_string(MyRtAddr) & ": IRQ Timeout but BC Check is done so exiting", DEBUG);
    --   Log(AlertLogId, "======================>>>>>>> RT" & to_string(MyRtAddr) & ": RT_MULTI_CHECK EXIT", DEBUG);

    --   return;
    -- end if;
    -- AlertIf(AlertLogID, Timeout, "TIMEOUT: RT" & to_string(MyRtAddr) & " did not receive Intr as expected");
    ----------------------------------------------------------------------------------------------------
    -- Determine the active bus
    ----------------------------------------------------------------------------------------------------
    Read(cpu_bus, reg_status, Rd_reg_status);
    MilBus_stdv := getActiveBus(Rd_reg_status);
    MilBus_std := '0' when MilBus_stdv = X"0010" else
                  '1';
    MilBus_i := to_integer(MilBus_std) + 1;
    if (Timeout = TRUE) then
      Log(AlertLogId, "EXITEXITEXITEXITEXITEXITEXITEXIT>>>>>>> RT" & to_string(MyRtAddr) & ": CMDWORD: " & to_hstring(CmdWord) & " RT_MULTI_CHECK EXIT", DEBUG);
      RT_Done <= '1';
      wait for 0 ns;
      return;
    end if;
    ----------------------------------------------------------------------------------------------------
    -- Get the received command to decide on handling methods
    ----------------------------------------------------------------------------------------------------
    Read(cpu_bus, reg_cmd_rxedX or MilBus_stdv, Rd_reg_cmd_rxedX);
    Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": reg_cmd_rxed" & to_string(MilBus_std) & " (0017) = " & to_hstring(Rd_reg_cmd_rxedX), DEBUG);
    printCmdWord(AlertLogId, Rd_reg_cmd_rxedX, MilBus_std);
    CmdRtAddr_stdv := Rd_reg_cmd_rxedX(15 downto 11);
    CmdTxnRx_std := Rd_reg_cmd_rxedX(10);
    CmdSubAddr_stdv := Rd_reg_cmd_rxedX(9 downto 5);
    CmdLen_stdv := Rd_reg_cmd_rxedX(4 downto 0);
    ----------------------------------------------------------------------------------------------------
    -- normalize the length for 32 word case
    ----------------------------------------------------------------------------------------------------
    if (CmdLen_stdv = "00000") then
      WordLen := 32;
    else
      WordLen := to_integer(unsigned(CmdLen_stdv));
    end if;
    Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": WordLen = " & to_string(WordLen), DEBUG);
    ----------------------------------------------------------------------------------------------------
    -- check if Hardware data wrap is enabled
    ----------------------------------------------------------------------------------------------------
    Read(cpu_bus, reg_node_control, ReadData);
    if (ReadData and bitEnableHwDataWrap) = bitEnableHwDataWrap then
      -- check if the received SubAddr is the same as the reg_wrap_subaddr
      Read(cpu_bus, reg_wrap_subaddr, ReadData);
      if (CmdSubAddr_stdv = ReadData(4 downto 0)) then
        HardwareDataWrap := true;
        Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": Hardware Data Wrap is ENABLED for SubAddr " & to_hstring(CmdSubAddr_stdv), DEBUG);
      end if;
    else
      HardwareDataWrap := false;
    end if;
    ----------------------------------------------------------------------------------------------------
    -- determine cause of the interrupt
    ----------------------------------------------------------------------------------------------------
    Read(cpu_bus, reg_busX_status or MilBus_stdv, Rd_reg_busX_status);
    Log(AlertLogId, "RT" & to_string(MyRtAddr) & ": reg_bus" & to_string(MilBus_std) & "_status (001E) = " & to_hstring(Rd_reg_busX_status), DEBUG);
    ClearInterrupts(cpu_bus, MilBus_i, IrqMask, AlertLogId);
    ----------------------------------------------------------------------------------------------------
    -- Initialize the random number generator once per group of messages
    ----------------------------------------------------------------------------------------------------
    RV.InitSeed(T => now);

    ----------------------------------------------------------------------------------------------------
    -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ----------------------------------------------------------------------------------------------------
    if (CmdTxnRx_std = '0') then
      ----------------------------------------------------------------------------------------------------
      -- RT RECEIVING
      ----------------------------------------------------------------------------------------------------
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & " is receiving", DEBUG);
      -- If you get a receive command and the RT2RT bit is set, it could be a broadcast receive or an addressed receive.
      -- The catch is that if it is a broadcast, the node would typically enter the receive functions,
      -- BUT if the next command shows that it is the transmitter, it should not enter the receive mode, but rather exit and wait for next command
      -- TODO I am not sure this logic is correct. If this RT is the receiver, it should just go the receive function, it will just wait a bit longer for data to arrive§
      if (RT2RT = true) then
        if (CmdRtAddr_stdv = "11111") then
          Log(AlertLogId, "RT" & to_string(MyRtAddr) & " is receiving a Broadcast RT2RT", DEBUG);
          -- Check the next command address
          Log(AlertLogId, "RT" & to_string(MyRtAddr) & " RT2RT_DestAddr: " & to_string(RT2RT_DestAddr), DEBUG);
          if (MyRtAddr = RT2RT_DestAddr) then
            Log(AlertLogId, "RT" & to_string(MyRtAddr) & " is the transmitting RT in RT2RT", DEBUG);
            wait for tGAP; -- just wait a bit of time
            Log(AlertLogId, "EXITEXITEXITEXITEXITEXITEXITEXIT>>>>>>> RT" & to_string(MyRtAddr) & ": CMDWORD: " & to_hstring(CmdWord) & "RT_MULTI_CHECK EXIT", DEBUG);
            RT_Done <= '1';
            wait for 0 ns;
            return;
          else
            ProcessRxMessages;
            CheckRxSubAddressRegister;
          end if;
        else
          Log(AlertLogId, "RT" & to_string(MyRtAddr) & " is NOT the destination for this RT2RT, exiting receive", DEBUG);
        end if;
      else
        ProcessRxMessages;
        if (CmdSubAddr_stdv /= "00000" and CmdSubAddr_stdv /= "11111") then
          --TODO there seems to be an issue with the subaddress check for mode commands, need to investigate further
          -- CheckRxSubAddressRegister;
        end if;
      end if;
    else
      ----------------------------------------------------------------------------------------------------
      -- RT TRANSMITTING
      ----------------------------------------------------------------------------------------------------
      Log(AlertLogId, "RT" & to_string(MyRtAddr) & " is transmitting", DEBUG);
      ProcessTxMessages;
    end if;
    Log(AlertLogId, "EXITEXITEXITEXITEXITEXITEXITEXIT>>>>>>> RT" & to_string(MyRtAddr) & ": CMDWORD: " & to_hstring(CmdWord) & "RT_MULTI_CHECK EXIT", DEBUG);
    RT_Done <= '1';
    wait for 0 ns;
    return;
    Log("THIS SHOULD NOT EVER BE PRINTED");

  end procedure;
end package body;
