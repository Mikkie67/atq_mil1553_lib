-- VHDL Entity mil1553_tb.test_man_dec.symbol
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library osvvm_common;
context osvvm_common.OsvvmCommonContext;

library osvvm;
context osvvm.OsvvmContext;

library mil1553_tb;
context mil1553_tb.mil1553_context;
entity test_man_dec is
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

  -- Declarations
end entity;

--
-- VHDL Architecture mil1553_tb.test_man_dec.struct
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library at_gen_lib;
library mil1553_tb;

architecture struct of test_man_dec is

  -- Architecture declarations
  signal TbID : AlertLogIDType;

  -- Internal signal declarations
  signal LastEdge    : std_logic;
  signal NegEdge     : std_logic;
  signal PosEdge     : std_logic;
  signal RegN        : std_logic_vector(1 downto 0);
  signal RegP        : std_logic_vector(1 downto 0);
  signal SyncNegEdge : std_logic;
  signal SyncOutN    : std_logic;
  signal SyncOutP    : std_logic;
  signal TxWord      : std_logic_vector(16 downto 0);
  signal nSyncOutP   : std_logic;
  signal ClrNoiseErr       : std_logic;
  signal ClrParityErr      : std_logic;
  signal ERP_tmr           : std_logic;
  signal CmdEdge           : std_logic;
  signal Cmd_nData         : std_logic;
  signal EarlyReplyRx      : std_logic;
  signal Err_Noise         : integer;
  signal Err_Parity        : integer;
  signal ManDecState       : std_logic_vector(4 downto 0);
  signal NewWord           : std_logic;
  signal OutWord           : std_logic_vector(15 downto 0);
  signal UnexpectedEdgeCnt : std_logic_vector(15 downto 0);
  signal SyncPosEdge       : std_logic;


  -- Component Declarations
  component synchroniser
    port (
      AsyncIn : in  std_logic;
      clk     : in  std_logic;
      nReset  : in  std_logic;
      SyncOut : out std_logic
    );
  end component;
  component test_man_dec_fsm
    generic (
      gBitFreq1    : natural := 100000000;
      gClkInFreq1  : natural := 100000000;
      gOverSample1 : natural := 4
    );
    port (
      Clk               : in  std_logic;
      ERP_tmr           : in  std_logic;
      NegEdge           : in  std_logic;
      PosEdge           : in  std_logic;
      SyncOutN          : in  std_logic;
      SyncOutP          : in  std_logic;
      TxWord            : in  std_logic_vector(16 downto 0);
      nReset            : in  std_logic;
      CmdEdge           : out std_logic;
      Cmd_nData         : out std_logic;
      EarlyReplyRx      : out std_logic;
      Err_Noise         : out integer;
      Err_Parity        : out integer;
      LastEdge          : out std_logic;
      ManDecState       : out std_logic_vector(4 downto 0);
      NewWord           : out std_logic;
      OutWord           : out std_logic_vector(15 downto 0);
      SyncNegEdge       : out std_logic;
      SyncPosEdge       : out std_logic;
      UnexpectedEdgeCnt : out std_logic_vector(15 downto 0)
    );
  end component;

  -- Optional embedded configurations
  -- pragma synthesis_off
  for all: synchroniser use entity at_gen_lib.synchroniser;
    for all: test_man_dec_fsm use entity mil1553_tb.test_man_dec_fsm;
      -- pragma synthesis_on

    begin
      -- Architecture concurrent statements
      BusMonitorRec.CmdnData <= Cmd_nData;
      BusMonitorRec.LastEdge <= LastEdge;
      BusMonitorRec.NewWord <= NewWord;
      BusMonitorRec.OutWord <= OutWord;
      BusMonitorRec.SyncNegEdge <= SyncNegEdge;
      BusMonitorRec.SyncPosEdge <= SyncPosEdge;
         -- HDL Embedded Text Block 1 eInv1
      -- eInv1 1   
      nSyncOutP <= not SyncOutP;

      -- HDL Embedded Text Block 2 ebEdgeDetect

      -- ebEdgeDetect 2     
      process (nReset, Clk)
      begin
        if (nReset = '0') then
          PosEdge <= '0';
          NegEdge <= '0';
          RegN <= "11";
          RegP <= "00";
        elsif (clk'event and clk = '1') then
          RegN <= RegN(0) & nSyncOutP; --used to be SyncOutN
          RegP <= RegP(0) & SyncOutP;
          NegEdge <= '0';
          PosEdge <= '0';
          if (RegP = "01" and RegN(0) = '0') then
            PosEdge <= '1';
          elsif (RegN = "01" and RegP(0) = '0') then
            NegEdge <= '1';
            -- elsif (RegP = "01" and RegN(1) = '1') then
            --    PosEdge <= '1';
            -- elsif (RegP = "10" and RegN(1) = '1') then
            --   NegEdge <= '1';
          end if;
        end if;
      end process;

      -- HDL Embedded Text Block 3 eb1
      -- Inter message gap measurement process
      -- This process measures the time (in nanoseconds) between the LastEdge of a message and the SyncNegEdge of the next message.
      gap1: process
        variable timeOfLastEdge : time := 0 ns;
        variable timeOfGap      : time := 0 ns;
        variable CommandWord   : std_logic_vector(15 downto 0);
      begin
        TbID <= GetAlertLogID("BUS1_MON");
        loop
          wait until LastEdge = '1';
          if (Cmd_nData = '1') then
            CommandWord := OutWord;
          end if;
          timeOfLastEdge := now;
          wait until SyncNegEdge = '1';
          timeOfGap := now - timeOfLastEdge;
          -- the below command needs to be changed to exclude th eRT2RT 
          --Affirmif(TbID,timeOfGap > 4 us, "Gap between messages is less than 4 us");
          Log(TbID, "Gap from LastEdge of command " & to_hstring(CommandWord) & " to SyncNegEdge measured as " & to_string(now - timeOfLastEdge),DEBUG);
          wait for 0 ns; -- to allow SyncNegEdge to be sampled
          if (SyncNegEdge = '1') then
            -- Report the gap time here if needed
          end if;
        end loop;
      end process;

      -- Instance port mappings.
      SyncInN: synchroniser
      port map (
          AsyncIn => InN,
          clk     => Clk,
          nReset  => nReset,
          SyncOut => SyncOutN
      );
      SyncInP: synchroniser
      port map (
          AsyncIn => InP,
          clk     => Clk,
          nReset  => nReset,
          SyncOut => SyncOutP
      );
      test_man_dec_fsm1: test_man_dec_fsm
      generic map (
          gBitFreq1    => gBitFreq,
          gClkInFreq1  => gClkInFreq,
          gOverSample1 => gOverSample
      )
      port map (
          Clk               => Clk,
          ERP_tmr           => ERP_tmr,
          NegEdge           => NegEdge,
          PosEdge           => PosEdge,
          SyncOutN          => SyncOutN,
          SyncOutP          => SyncOutP,
          TxWord            => TxWord,
          nReset            => nReset,
          CmdEdge           => CmdEdge,
          Cmd_nData         => Cmd_nData,
          EarlyReplyRx      => EarlyReplyRx,
          Err_Noise         => Err_Noise,
          Err_Parity        => Err_Parity,
          LastEdge          => LastEdge,
          ManDecState       => ManDecState,
          NewWord           => NewWord,
          OutWord           => OutWord,
          SyncNegEdge       => SyncNegEdge,
          SyncPosEdge       => SyncPosEdge,
          UnexpectedEdgeCnt => UnexpectedEdgeCnt
      );

    end architecture;
