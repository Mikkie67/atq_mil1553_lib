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

package osvvm_mil1553_testcntrl_component_pkg is
  constant tNRPmin : time := 14 us;
  constant tREPmin : time := 4 us;
  constant tGAPmin : time := 4 us;

  constant tNRPmax : time := 14 us; -- no maximum is specificed in the spec
  constant tREPmax : time := 12 us;
  constant tGAPmax : time := 12 us; -- no maximum is specificed in the spec

  constant tNRP     : time := 14 us;
  constant tREP     : time := 5.3 us;
  constant tGAP     : time := 11 us;
  constant tWord    : time := 20 us;
  constant tCommand : time := 20 us;
  constant tStatus  : time := 20 us;
  -- unconstrained integer array type
  type int_array is array (integer range <>) of integer;

  subtype AddressBus16Type is AddressBusRecType(
      Address(15 downto 0),
      DataToModel(15 downto 0),
      DataFromModel(15 downto 0));
  -- ==============================
  -- mil1553 core Discretes Records
  -- ==============================
  type CoreDiscretesIn_type is record
    MyRtAddr         : std_logic_vector_max(4 downto 0);
    MyRtAddrParity   : std_logic_max;
    nReset           : std_logic_max;
    BitWord          : std_logic_vector_max(15 downto 0);
    ServiceReqVector : std_logic_vector_max(15 downto 0);
    ServiceRequest   : std_logic_max;
    SubsystemFlag    : std_logic_max;
  end record;
  type CoreDiscretesOut_type is record
    OutEn1  : std_logic;
    OutEn2  : std_logic;
    Strobe1 : std_logic;
    Strobe2 : std_logic;
    Intr    : std_logic;
  end record;
  type Command_type is record
    RtAddr  : integer;
    TxnRx   : integer;
    SubAddr : integer;
    Len     : integer;
    MilBus  : integer;
    Rt2RT   : std_logic;
  end record;
  -- constants for the different types of errors
  constant errNone        : integer := 0;
  constant errParity      : integer := 1;
  constant errWordLength  : integer := 2;
  constant errNumWordLen  : integer := 3;
  constant errNoModeData  : integer := 4;
  constant errTxModeData  : integer := 5;
  constant errRT2RTWrdCnt : integer := 6;
  constant errTxCmdContiguousData : integer := 7;

  type Command_array_type is array (0 to 31) of Command_type;
  type MultiCommandRec_type is record
    StartAddr  : integer;
    Length     : integer;
    Command    : Command_array_type;
    ErrInj     : integer;
    ErrWrd     : natural;
    ErrBit     : integer;
    RepeatRate : integer;
  end record;
  type BusMonitorRec_type is record
    SyncNegEdge : std_logic_max;
    SyncPosEdge : std_logic_max;
    LastEdge    : std_logic_max;
    NewWord     : std_logic_max;
    OutWord     : std_logic_vector_max(15 downto 0);
    CmdnData    : std_logic_max;
  end record;

  function getCmdWord(constant Command : Command_type) return std_logic_vector;

  function getActiveBus(
    core_status : std_logic_vector(15 downto 0)
  ) return std_logic_vector;

  procedure printImportantRegisters(
    signal cpu_bus    : inout AddressBus16Type;
           node       : in    string;
           AlertLogID : in    AlertLogIDType
  );

  procedure printStatusWord(
    AlertLogID : in AlertLogIDType;
    StatusWord : in std_logic_vector(15 downto 0);
    LogginType : in LogType := DEBUG
  );

  procedure printCmdWord(
    AlertLogID : in AlertLogIDType;
    CmdWord    : in std_logic_vector(15 downto 0);
    MilBus     : in integer range 1 to 2 := 1
  );
  procedure printCmdWord(
    AlertLogID : in AlertLogIDType;
    CmdWord    : in std_logic_vector(15 downto 0);
    MilBus     : in std_logic
  );
  procedure ReadCheckMask(
    signal cpu_bus    : inout AddressBus16Type;
           address    : in    std_logic_vector(15 downto 0);
           expected   : in    std_logic_vector(15 downto 0);
           mask       : in    std_logic_vector(15 downto 0);
           AlertLogID :       AlertLogIDType
  );
  procedure ClearInterrupts(
    signal cpu_bus    : inout AddressBus16Type;
           MilBus     : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2
           MaskValue  : in    std_logic_vector(15 downto 0);
           AlertLogID : in    AlertLogIDType
  );
  procedure SetCmdProc(
    signal cpu_bus   : inout AddressBus16Type;
           MilBus    : in    integer range 1 to 2 := 1; -- 1 for bus 1, 2 for bus 2;
           StartVal  : in    std_logic_vector(15 downto 0);
           LengthVal : in    std_logic_vector(15 downto 0)
  );
  component Mil1553_dualbus
    port (
      Addr             : in  std_logic_vector(15 downto 0);
      BitWord          : in  std_logic_vector(15 downto 0);
      Cs               : in  std_logic;
      DataIn           : in  std_logic_vector(15 downto 0);
      InN1             : in  std_logic;
      InN2             : in  std_logic;
      InP1             : in  std_logic;
      InP2             : in  std_logic;
      MyRtAddr         : in  std_logic_vector(4 downto 0);
      MyRtAddrParity   : in  std_logic;
      Rd               : in  std_logic;
      ServiceReqVector : in  std_logic_vector(15 downto 0);
      ServiceRequest   : in  std_logic;
      SubsystemFlag    : in  std_logic;
      Wr               : in  std_logic;
      clk              : in  std_logic;
      nResetIn         : in  std_logic;
      DataOut          : out std_logic_vector(15 downto 0);
      DataValid        : out std_logic;
      Intr             : out std_logic;
      OutEn1           : out std_logic;
      OutEn2           : out std_logic;
      OutN1            : out std_logic;
      OutN2            : out std_logic;
      OutP1            : out std_logic;
      OutP2            : out std_logic;
      Strobe1          : out std_logic;
      Strobe2          : out std_logic
    );
  end component;
  component mil1553_core_vc
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
  end component;
  component test_man_dec
    generic (
      gBitFreq    : natural := 1000000;
      gClkInFreq  : natural := 100000000;
      gOverSample : natural := 4
    );
    port (
      nReset        : in  std_logic;
      Clk           : in  std_logic;
      InN           : in  std_logic;
      InP           : in  std_logic;
      BusMonitorRec : out BusMonitorRec_type
    );
  end component;
  component osvvm_Mil1553_dualbus_testctrl
    port (
      -- Global Signal Interface
      nReset            : in    std_logic;
      Clk               : in    std_logic;
      -- Transaction Interfaces
      RT1_cpu_bus       : inout AddressBus16Type;
      RT2_cpu_bus       : inout AddressBus16Type;
      BC_cpu_bus        : inout AddressBus16Type;
      BC1_DiscretesOut  : in    CoreDiscretesOut_type;
      RT1_DiscretesOut  : in    CoreDiscretesOut_type;
      RT2_DiscretesOut  : in    CoreDiscretesOut_type;
      BC1_DiscretesIn   : out   CoreDiscretesIn_type;
      RT1_DiscretesIn   : out   CoreDiscretesIn_type;
      RT2_DiscretesIn   : out   CoreDiscretesIn_type;
      BC_BusMonitorRec  : in    BusMonitorRec_type;
      RT1_BusMonitorRec : in    BusMonitorRec_type;
      RT2_BusMonitorRec : in    BusMonitorRec_type
    );
  end component;

end package;
----------------------------------------------------------------------------------------------------

package body osvvm_mil1553_testcntrl_component_pkg is
  function getCmdWord(constant Command : Command_type) return std_logic_vector is
    variable CmdWord : std_logic_vector(15 downto 0);
  begin
    CmdWord := (others => '0');
    CmdWord(15 downto 11) := std_logic_vector(to_unsigned(Command.RtAddr, 5));
    CmdWord(10) := std_logic(to_unsigned(Command.TxnRx, 1)(0));
    CmdWord(9 downto 5) := std_logic_vector(to_unsigned(Command.SubAddr, 5));
    CmdWord(4 downto 0) := std_logic_vector(to_unsigned(Command.Len, 5));
    return CmdWord;
  end function;

  ----------------------------------------------------------------------------------------------------
  function getActiveBus(
      core_status : std_logic_vector(15 downto 0)
    ) return std_logic_vector is
    variable MilBusStdv : std_logic_vector(15 downto 0);
  begin
    if ((core_status and X"0001") = X"0001") then
      MilBusStdv := X"0010";
    elsif ((core_status and X"0002") = X"0002") then
      MilBusStdv := X"0020";
    else
      MilBusStdv := X"0010";
    end if;
    return MilBusStdv;
  end function;
  ----------------------------------------------------------------------------------------------------
  -- this function read and print a number of important registers for the BC and RT cores
  procedure printImportantRegisters(
      signal cpu_bus    : inout AddressBus16Type;
             node       : in    string;
             AlertLogID : in    AlertLogIDType

    ) is
    variable iData : std_logic_vector(15 downto 0);
  begin
    Read(cpu_bus, reg_intr_mask, iData);
    Log(AlertLogID, node & ": reg_intr_mask (0001)    = " & to_hex_string(iData), DEBUG);
    Read(cpu_bus, reg_bus1_mask, iData);
    Log(AlertLogID, node & ": reg_bus1_mask (001F)    = " & to_hex_string(iData), DEBUG);
    Read(cpu_bus, reg_bus1_status, iData);
    Log(AlertLogID, node & ": reg_bus1_status (001E)  = " & to_hex_string(iData), DEBUG);
    Read(cpu_bus, reg_bus2_mask, iData);
    Log(AlertLogID, node & ": reg_bus2_mask (002F)    = " & to_hex_string(iData), DEBUG);
    Read(cpu_bus, reg_bus2_status, iData);
    Log(AlertLogID, node & ": reg_bus2_status (002E)  = " & to_hex_string(iData), DEBUG);
    Read(cpu_bus, reg_node_control, iData);
    Log(AlertLogID, node & ": reg_node_control (0034)   = " & to_hex_string(iData), DEBUG);
    Read(cpu_bus, reg_gID, iData);
    Log(AlertLogID, node & ": reg_gID (0036)          = " & to_hex_string(iData), DEBUG);
    Read(cpu_bus, reg_fw_version, iData);
    Log(AlertLogID, node & ": reg_fw_version (0037)   = " & to_hex_string(iData), DEBUG);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure printStatusWord(
      AlertLogID : in AlertLogIDType;
      StatusWord : in std_logic_vector(15 downto 0);
      LogginType : in LogType := DEBUG
    ) is
  begin
  -- v4p formatting off
    Log(AlertLogID, LF & 
    "--------------------------" & LF & 
    "-----> STATUS WORD   = " & to_hex_string(StatusWord) & LF & 
    "-----> RtAddr        = " & to_string(to_integer(unsigned(StatusWord(15 downto 11)))) & LF & 
    "-----> Message Error = " & to_string(to_integer(unsigned(StatusWord(10 downto 10)))) & LF & 
    "-----> Instrument    = " & to_string(to_integer(unsigned(StatusWord(9 downto 9)))) & LF & 
    "-----> Service Req   = " & to_string(to_integer(unsigned(StatusWord(8 downto 8)))) & LF & 
    "-----> RtAddr Error  = " & to_string(to_integer(unsigned(StatusWord(7 downto 7)))) & LF & 
    "-----> Reserved6     = " & to_string(to_integer(unsigned(StatusWord(6 downto 6)))) & LF & 
    "-----> Reserved5     = " & to_string(to_integer(unsigned(StatusWord(5 downto 5)))) & LF & 
    "-----> BrdcstRcvd    = " & to_string(to_integer(unsigned(StatusWord(4 downto 4)))) & LF & 
    "-----> Busy          = " & to_string(to_integer(unsigned(StatusWord(3 downto 3)))) & LF & 
    "-----> Sub Sys Flag  = " & to_string(to_integer(unsigned(StatusWord(2 downto 2)))) & LF & 
    "-----> DBC Accept    = " & to_string(to_integer(unsigned(StatusWord(1 downto 1)))) & LF & 
    "-----> Terminal Flag = " & to_string(to_integer(unsigned(StatusWord(0 downto 0)))) & LF & 
    "--------------------------", LogginType);
  -- v4p formatting on
  end procedure;

  procedure printCmdWord(
      AlertLogID : in AlertLogIDType;
      CmdWord    : in std_logic_vector(15 downto 0);
      MilBus     : in integer range 1 to 2 := 1
    ) is
  begin
  -- v4p formatting off
    Log(AlertLogID, LF & 
    "--------------------------" & LF & 
    "-----> CMD WORD = " & to_hex_string(CmdWord) & LF & 
    "-----> RtAddr   = " & to_string(to_integer(unsigned(CmdWord(15 downto 11)))) & LF & 
    "-----> TxnRx    = " & to_string(to_integer(unsigned(CmdWord(10 downto 10)))) & LF & 
    "-----> SubAddr  = " & to_string(to_integer(unsigned(CmdWord(9 downto 5)))) & LF & 
    "-----> Len      = " & to_string(to_integer(unsigned(CmdWord(4 downto 0)))) & LF & 
    "-----> Bus      = " & to_string(MilBus) & LF & 
    "--------------------------", DEBUG);
  -- v4p formatting on
  end procedure;
  procedure printCmdWord(
      AlertLogID : in AlertLogIDType;
      CmdWord    : in std_logic_vector(15 downto 0);
      MilBus     : in std_logic
    ) is
    variable MilBusInt : integer;
  begin
    if (MilBus = '1') then
      MilBusInt := 2;
    else
      MilBusInt := 1;
    end if;
    printCmdWord(AlertLogID, CmdWord, MilBusInt);
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure ReadCheckMask(
      signal cpu_bus    : inout AddressBus16Type;
             address    : in    std_logic_vector(15 downto 0);
             expected   : in    std_logic_vector(15 downto 0);
             mask       : in    std_logic_vector(15 downto 0);
             AlertLogID :       AlertLogIDType
    ) is
    variable iData   : std_logic_vector(15 downto 0);
    variable iResult : std_logic_vector(15 downto 0);
  begin
    Read(cpu_bus, address, iData);
    iResult := (iData and mask);
    AffirmIf(AlertLogID, expected = iResult,
             "Read CHECK MASK Operation, Address: " & to_hex_string(address) & " Operation# X  Expected: " & to_hex_string(expected) & " Mask: " & to_hex_string(Mask) & " Masked: " & to_hex_string(iResult) & " Raw Received:" & to_hex_string(iData));
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure ClearInterrupts(
      signal cpu_bus    : inout AddressBus16Type;
             MilBus     : in    integer range 1 to 2 := 1;
             MaskValue  : in    std_logic_vector(15 downto 0);
             AlertLogID : in    AlertLogIDType
    ) is
  begin
    if MilBus = 1 then
      Write(cpu_bus, reg_bus1_mask, MaskValue);
      Write(cpu_bus, reg_bus1_status, X"FFFF"); -- Clear all latched interrupts
      ReadCheckMask(cpu_bus, reg_bus1_status, X"0000", MaskValue, AlertLogID);
    elsif MilBus = 2 then
      Write(cpu_bus, reg_bus2_mask, MaskValue);
      Write(cpu_bus, reg_bus2_status, X"FFFF"); -- Clear all latched interrupts
      ReadCheckMask(cpu_bus, reg_bus2_status, X"0000", MaskValue, AlertLogID);
    else
      -- Default to bus 1 if invalid value
      Write(cpu_bus, reg_bus1_mask, MaskValue);
      Write(cpu_bus, reg_bus1_status, X"FFFF"); -- Clear all latched interrupts
      ReadCheckMask(cpu_bus, reg_bus1_status, X"0000", MaskValue, AlertLogID);
    end if;
  end procedure;
  ----------------------------------------------------------------------------------------------------
  procedure SetCmdProc(
      signal cpu_bus   : inout AddressBus16Type;
             MilBus    : in    integer range 1 to 2 := 1;
             StartVal  : in    std_logic_vector(15 downto 0);
             LengthVal : in    std_logic_vector(15 downto 0)
    ) is
  begin
    if MilBus = 1 then
      Write(cpu_bus, reg_cmd_proc_start1, StartVal);
      Write(cpu_bus, reg_cmd_proc_length1, LengthVal);
    elsif MilBus = 2 then
      Write(cpu_bus, reg_cmd_proc_start2, StartVal);
      Write(cpu_bus, reg_cmd_proc_length2, LengthVal);
    else
      -- Default to bus 1 if invalid value
      Write(cpu_bus, reg_cmd_proc_start1, StartVal);
      Write(cpu_bus, reg_cmd_proc_length1, LengthVal);
    end if;
  end procedure;

end package body;
