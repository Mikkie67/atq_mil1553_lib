--
-- VHDL Package Header mil1553_tb.ManchesterVC
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
context osvvm.osvvmcontext;

package manchester_vc_pkg is

  -- Constants shared by both VCs
  constant ERROR_WIDTH : integer := 4;

  subtype Man_Dec_ErrorModeType is std_logic_vector(4 downto 1);
  subtype Man_Dec_ErrorModeType_max_c is std_logic_vector_max_c(4 downto 1);

  constant MAN_DEC_WORD_LEN_INDEX  : integer := 4;
  constant MAN_DEC_ZEROCROSS_INDEX : integer := 3;
  constant MAN_DEC_SYNC_INDEX      : integer := 2;
  constant MAN_DEC_PARITY_INDEX    : integer := 1;

  constant MAN_DEC_NO_ERROR        : Man_Dec_ErrorModeType := (others => '0');
  constant MAN_DEC_WORD_LEN_ERROR  : Man_Dec_ErrorModeType := (MAN_DEC_WORD_LEN_INDEX => '1', others => '0');
  constant MAN_DEC_ZEROCROSS_ERROR : Man_Dec_ErrorModeType := (MAN_DEC_ZEROCROSS_INDEX => '1', others => '0');
  constant MAN_DEC_SYNC_ERROR      : Man_Dec_ErrorModeType := (MAN_DEC_SYNC_INDEX => '1', others => '0');
  constant MAN_DEC_PARITY_ERROR    : Man_Dec_ErrorModeType := (MAN_DEC_PARITY_INDEX => '1', others => '0');

  type UnresolvedManDecBusOperationType is (
      -- Default. Used by resolution function for Multiple Driver Detection
      NOT_DRIVEN,
      SEND_CMD,
      SEND_DATA,
      SEND_CMD_AND_DATA,
      SEND_BIT, -- for send bit, the command word is used as qty indicator of bits to send, the data word is ignored is used as a bit pattern.
      SEND_CMDSYNC, -- sned just a command sync
      SEND_DATASYNC, -- send just a data sync
      --
      -- Model Directives
      --
      WAIT_FOR_CLOCK,
      WAIT_FOR_TRANSACTION,
      WAIT_FOR_WRITE_TRANSACTION,
      WAIT_FOR_READ_TRANSACTION,
      GET_TRANSACTION_COUNT,
      GET_WRITE_TRANSACTION_COUNT,
      GET_READ_TRANSACTION_COUNT,
      GET_ALERTLOG_ID,
      -- Model Options
      SET_MODEL_OPTIONS,
      GET_MODEL_OPTIONS,
      -- Resolution function detected Multiple drivers
      MULTIPLE_DRIVER_DETECT -- value used when multiple drivers are present
    );
  type UnresolvedManDecBusOperationVectorType is array (natural range <>) of UnresolvedManDecBusOperationType;
  function resolved_max(s : UnresolvedManDecBusOperationVectorType) return UnresolvedManDecBusOperationType;
  subtype ManDecBusOperationType is resolved_max UnresolvedManDecBusOperationType;

  -- ==============================
  -- Encoder VC Record
  -- ==============================
  type ManchesterEncRecType is record
    Data      : std_logic_vector(15 downto 0);
    Cmd_nData : std_logic;
    ErrInject : std_logic_vector(ERROR_WIDTH - 1 downto 0);
    Go        : std_logic;
    Done      : std_logic;
    SBID      : AlertLogIDType;
  end record;

  -- ==============================
  -- Decoder VC Record
  -- ==============================
  type ManchesterDecRecType is record
    Rdy               : RdyType;
    Ack               : AckType;
    Data              : std_logic_vector_max_c;
    Command           : std_logic_vector_max_c;
    DataIn            : std_logic_vector_max_c;
    CommandIn         : std_logic_vector_max_c;
    NumWords          : integer_max;
    ManDecState       : integer_max;
    UnexpectedEdgeCnt : integer_max;
    ErrorMode         : Man_Dec_ErrorModeType_max_c;
    ErrorBit          : integer_max; -- indicates which bit to create error in. Bit 0 is the sync bit
    TimeOffset        : time_max;
    Operation         : ManDecBusOperationType;
  end record;

  -- ==============================
  -- Encoder Procedures
  -- ==============================
  procedure Send(
    signal   Rec        : inout ManchesterDecRecType;
    constant CmdWord    : in    std_logic_vector(15 downto 0);
    constant DataWord   : in    std_logic_vector(15 downto 0);
    constant CmdBit     : in    integer                := 0;
    constant Operation  : in    ManDecBusOperationType := SEND_CMD;
    constant Errors     : in    Man_Dec_ErrorModeType  := MAN_DEC_NO_ERROR;
    constant NumWords   : in    integer                := 1;
    constant ErrorBit   : in    integer                := 0;
    constant TimeOffset : in    time                   := 0 ns
  );

  -- ==============================
  -- Decoder Procedures
  -- ==============================
  -- procedure Get(
  --   signal   Rec     : inout ManchesterDecRecType;
  --   variable DataOut : out   std_logic_vector(15 downto 0)
  -- );
end package;
--
-- VHDL Package Body mil1553_tb.ManchesterVC
--

package body manchester_vc_pkg is
  function resolved_max(s : UnresolvedManDecBusOperationVectorType) return UnresolvedManDecBusOperationType is
    variable Result : UnresolvedManDecBusOperationType := NOT_DRIVEN;
  begin
    for i in s'range loop
      if s(i) /= NOT_DRIVEN then
        if result = NOT_DRIVEN then
          result := s(i);
        else
          result := MULTIPLE_DRIVER_DETECT;
        end if;
      end if;
    end loop;
    return result;
    --    return maximum(s) ;
  end function;

  procedure Send(
      signal   Rec        : inout ManchesterDecRecType;
      constant CmdWord    : in    std_logic_vector(15 downto 0);
      constant DataWord   : in    std_logic_vector(15 downto 0);
      constant CmdBit     : in    integer                := 0;
      constant Operation  : in    ManDecBusOperationType := SEND_CMD;
      constant Errors     : in    Man_Dec_ErrorModeType  := MAN_DEC_NO_ERROR;
      constant NumWords   : in    integer                := 1;
      constant ErrorBit   : in    integer                := 0;
      constant TimeOffset : in    time                   := 0 ns
    ) is
  begin
    Rec.Command <= SafeResize(CmdWord, Rec.Command'length);
    Rec.Data <= SafeResize(DataWord, Rec.Data'length);
    Rec.ErrorMode <= SafeResize(Errors, Rec.ErrorMode'length);
    Rec.ErrorBit <= CmdBit;
    Rec.Operation <= Operation;
    Rec.NumWords <= NumWords;
    Rec.ErrorBit <= ErrorBit;
    Rec.TimeOffset <= TimeOffset;
    RequestTransaction(Rdy => Rec.Rdy, Ack => Rec.Ack);
  end procedure;

  -- procedure Get(
  --   signal Rec   : inout ManchesterDecRecType;
  --   variable DataOut : out    std_logic_vector(15 downto 0)
  -- ) is
  -- begin
  --   Rec.GetReq <= '1';
  --   wait until Rec.GotData = '1';
  --   DataOut := Rec.ReceivedData;
  --   Rec.GetReq <= '0';
  -- end procedure;
end package body;
