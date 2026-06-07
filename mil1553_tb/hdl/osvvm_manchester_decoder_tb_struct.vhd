-- VHDL Entity mil1553_tb.osvvm_manchester_decoder_tb.symbol
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library mil1553_lib;
library mil1553_tb;
context mil1553_tb.mil1553_context;

library osvvm;
context osvvm.osvvmcontext;

entity osvvm_manchester_decoder_tb is
  generic (
    gBitFreq    : natural := 1000000;
    gClkInFreq  : natural := 100000000;
    gOverSample : natural := 4
  );
  -- Declarations
end entity;

--
-- VHDL Architecture mil1553_tb.osvvm_manchester_decoder_tb.struct
--

architecture struct of osvvm_manchester_decoder_tb is

  -- Architecture declarations

  -- Internal signal declarations
  signal Clk                : std_logic;
  signal ClrNoiseErr        : std_logic;
  signal ClrParityErr       : std_logic;
  signal CmdEdge            : std_logic;
  signal Cmd_nData          : std_logic;
  signal ERP_tmr            : std_logic;
  signal EarlyReplyRx       : std_logic;
  signal Err_Noise          : integer;
  signal Err_Parity         : integer;
  signal InN                : std_logic;
  signal InP                : std_logic;
  signal NewWord            : std_logic;
  signal OutWord            : std_logic_vector(15 downto 0);
  signal SyncPosEdge        : std_logic;
  signal nReset             : std_logic;

  signal MonBusP1      : std_logic;
  signal MonBusN1      : std_logic;
  signal BusMonitorRec : BusMonitorRec_type;

  -- create signal and contraint the record type
  signal man_dec_bus : ManchesterDecRecType(
    Data(15 downto 0),
    Command(15 downto 0),
    DataIn(15 downto 0),
    CommandIn(15 downto 0)
  );

  -- Component Declarations
  component man_dec_testctrl is
    port (
      BusMonitorRec : inout BusMonitorRec_type;
      man_dec_bus    : inout ManchesterDecRecType
    );
  end component;

  component manchester_decoder
    generic (
      gBitFreq    : natural := 1000000;
      gClkInFreq  : natural := 100000000;
      gOverSample : natural := 4
    );
    port (
      BlankDecoder : IN     std_logic;
      Clk          : IN     std_logic;
      ClrNoiseErr  : IN     std_logic;
      ClrParityErr : IN     std_logic;
      ERP_tmr      : IN     std_logic;
      InN          : IN     std_logic;
      InP          : IN     std_logic;
      nReset       : IN     std_logic;
      CmdEdge      : OUT    std_logic;
      Cmd_nData    : OUT    std_logic;
      DecoderErr   : OUT    std_logic;
      EarlyReplyRx : OUT    std_logic;
      Err_Noise    : OUT    integer;
      NewWord      : OUT    std_logic;
      OutWord      : OUT    std_logic_vector (15 DOWNTO 0);
      ParityErrCnt : OUT    integer;
      SyncPosEdge  : BUFFER std_logic
    );
  end component;
  component man_dec_vc
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
  end component;

begin
      MonBusP1 <=  InP;
      --  when OutEn1_BC = '1' else
      --                OutP1_RT1 when OutEn1_RT1 = '1' else
      --                OutP1_RT2 when OutEn1_RT2 = '1' else
      --                'Z'; 
        MonBusN1 <=  InN;
        --  when OutEn1_BC = '1' else
        --              OutN1_RT1 when OutEn1_RT1 = '1' else
        --              OutN1_RT2 when OutEn1_RT2 = '1' else
        --              'Z';


  -- Instance port mappings.
  manchester_decoder1: manchester_decoder
    generic map (
      gBitFreq    => 1000000,
      gClkInFreq  => 100000000,
      gOverSample => 4
    )
    port map (
      BlankDecoder      => '0',
      Clk               => Clk,
      ClrNoiseErr       => ClrNoiseErr,
      ClrParityErr      => ClrParityErr,
      ERP_tmr           => ERP_tmr,
      InN               => InN,
      InP               => InP,
      nReset            => nReset,
      CmdEdge           => CmdEdge,
      Cmd_nData         => Cmd_nData,
      DecoderErr       => OPEN,
      EarlyReplyRx      => EarlyReplyRx,
      Err_Noise         => Err_Noise,
      NewWord           => NewWord,
      OutWord           => OutWord,
      ParityErrCnt      => OPEN,
  --    UnexpectedEdgeCnt => UnexpectedEdgeCnt1,
  --    ManDecState       => ManDecState1,
      SyncPosEdge       => SyncPosEdge
    );
  man_dec_vc1: man_dec_vc
    port map (
      CmdEdge           => CmdEdge,
      Cmd_nData         => Cmd_nData,
      EarlyReplyRx      => EarlyReplyRx,
      Err_Noise         => Err_Noise,
      Err_Parity        => Err_Parity,
      NewWord           => NewWord,
      OutWord           => OutWord,
      SyncPosEdge       => SyncPosEdge,
      man_dec_bus       => man_dec_bus,
      Clk               => Clk,
      ClrNoiseErr       => ClrNoiseErr,
      ClrParityErr      => ClrParityErr,
      ERP_tmr           => ERP_tmr,
      InN               => InN,
      InP               => InP,
      -- UnexpectedEdgeCnt => UnexpectedEdgeCnt1,
      -- ManDecState       => ManDecState1,
      nReset            => nReset
    );
  bus_mon: test_man_dec
    generic map (
      gBitFreq    => 1000000,
      gClkInFreq  => 100000000,
      gOverSample => 4
    )
    port map (
      Clk           => Clk,
      InN           => MonBusN1,
      InP           => MonBusP1,
      nReset        => nReset,
      BusMonitorRec => BusMonitorRec
    );
  manchester_decoder_testctrl1: man_dec_testctrl
    port map (
      BusMonitorRec => BusMonitorRec,
      man_dec_bus    => man_dec_bus
    );

end architecture;
configuration osvvm_manchester_decoder_tb_struct of osvvm_manchester_decoder_tb is
  for struct
  end for;
end configuration;

