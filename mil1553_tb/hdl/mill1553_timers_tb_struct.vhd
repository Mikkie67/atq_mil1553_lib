-- VHDL Entity mil1553_tb.mill1553_timers_tb.symbol
--



ENTITY mill1553_timers_tb IS
-- Declarations

END ENTITY mill1553_timers_tb ;

--
-- VHDL Architecture mil1553_tb.mill1553_timers_tb.struct
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY mil1553_lib;
LIBRARY mil1553_tb;

ARCHITECTURE struct OF mill1553_timers_tb IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL SyncPosEdge     : std_logic;
   SIGNAL clk             : std_logic;
   SIGNAL nReset          : std_logic;
   SIGNAL reg_tmr_1us     : std_logic_vector(15 DOWNTO 0);
   SIGNAL reg_tmr_ERP     : std_logic_vector(15 DOWNTO 0);
   SIGNAL reg_tmr_GAP     : std_logic_vector(15 DOWNTO 0);
   SIGNAL reg_tmr_NRP     : std_logic_vector(15 DOWNTO 0);
   SIGNAL reg_tmr_REP     : std_logic_vector(15 DOWNTO 0);
   SIGNAL reg_tmr_SAF     : std_logic_vector(15 DOWNTO 0);
   SIGNAL tmr_1us         : std_logic;
   SIGNAL tmr_1us_Start   : std_logic;
   SIGNAL tmr_1us_Stop    : std_logic;
   SIGNAL tmr_25us        : std_logic;
   SIGNAL tmr_25us_Start  : std_logic;
   SIGNAL tmr_25us_Stop   : std_logic;
   SIGNAL tmr_Blank       : std_logic;
   SIGNAL tmr_Blank_Start : std_logic;
   SIGNAL tmr_Blank_Stop  : std_logic;
   SIGNAL tmr_ERP         : std_logic;
   SIGNAL tmr_ERP_Reset   : std_logic;
   SIGNAL tmr_ERP_Stop    : std_logic;
   SIGNAL tmr_ERP_enable  : std_logic;
   SIGNAL tmr_GAP         : std_logic;
   SIGNAL tmr_GAP_Start   : std_logic;
   SIGNAL tmr_GAP_Stop    : std_logic;
   SIGNAL tmr_NRP         : std_logic;
   SIGNAL tmr_NRP_Start   : std_logic;
   SIGNAL tmr_NRP_Stop    : std_logic;
   SIGNAL tmr_REP         : std_logic;
   SIGNAL tmr_REP_Start   : std_logic;
   SIGNAL tmr_REP_Stop    : std_logic;
   SIGNAL tmr_SAF         : std_logic;
   SIGNAL tmr_SAF_Start   : std_logic;
   SIGNAL tmr_SAF_Stop    : std_logic;


   -- Component Declarations
   COMPONENT mill1553_timers
   PORT (
      SyncPosEdge     : IN     std_logic ;
      clk             : IN     std_logic ;
      nReset          : IN     std_logic ;
      reg_tmr_1us     : IN     std_logic_vector (15 DOWNTO 0);
      reg_tmr_ERP     : IN     std_logic_vector (15 DOWNTO 0);
      reg_tmr_GAP     : IN     std_logic_vector (15 DOWNTO 0);
      reg_tmr_NRP     : IN     std_logic_vector (15 DOWNTO 0);
      reg_tmr_REP     : IN     std_logic_vector (15 DOWNTO 0);
      reg_tmr_SAF     : IN     std_logic_vector (15 DOWNTO 0);
      tmr_1us_Start   : IN     std_logic ;
      tmr_1us_Stop    : IN     std_logic ;
      tmr_25us_Start  : IN     std_logic ;
      tmr_25us_Stop   : IN     std_logic ;
      tmr_Blank_Start : IN     std_logic ;
      tmr_Blank_Stop  : IN     std_logic ;
      tmr_ERP_Reset   : IN     std_logic ;
      tmr_ERP_Stop    : IN     std_logic ;
      tmr_ERP_enable  : IN     std_logic ;
      tmr_GAP_Start   : IN     std_logic ;
      tmr_GAP_Stop    : IN     std_logic ;
      tmr_NRP_Start   : IN     std_logic ;
      tmr_NRP_Stop    : IN     std_logic ;
      tmr_REP_Start   : IN     std_logic ;
      tmr_REP_Stop    : IN     std_logic ;
      tmr_SAF_Start   : IN     std_logic ;
      tmr_SAF_Stop    : IN     std_logic ;
      tmr_25us        : OUT    std_logic ;
      tmr_Blank       : OUT    std_logic ;
      tmr_ERP         : OUT    std_logic ;
      tmr_GAP         : OUT    std_logic ;
      tmr_NRP         : OUT    std_logic ;
      tmr_REP         : OUT    std_logic ;
      tmr_SAF         : OUT    std_logic ;
      tmr_1us         : BUFFER std_logic 
   );
   END COMPONENT mill1553_timers;
   COMPONENT mill1553_timers_testcntrl
   PORT (
      tmr_1us         : IN     std_logic;
      tmr_25us        : IN     std_logic;
      tmr_Blank       : IN     std_logic;
      tmr_ERP         : IN     std_logic;
      tmr_GAP         : IN     std_logic;
      tmr_NRP         : IN     std_logic;
      tmr_REP         : IN     std_logic;
      tmr_SAF         : IN     std_logic;
      SyncPosEdge     : OUT    std_logic;
      clk             : OUT    std_logic;
      nReset          : OUT    std_logic;
      reg_tmr_1us     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_ERP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_GAP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_NRP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_REP     : OUT    std_logic_vector (15 DOWNTO 0);
      reg_tmr_SAF     : OUT    std_logic_vector (15 DOWNTO 0);
      tmr_1us_Start   : OUT    std_logic;
      tmr_1us_Stop    : OUT    std_logic;
      tmr_25us_Start  : OUT    std_logic;
      tmr_25us_Stop   : OUT    std_logic;
      tmr_Blank_Start : OUT    std_logic;
      tmr_Blank_Stop  : OUT    std_logic;
      tmr_ERP_Reset   : OUT    std_logic;
      tmr_ERP_Stop    : OUT    std_logic;
      tmr_ERP_enable  : OUT    std_logic;
      tmr_GAP_Start   : OUT    std_logic;
      tmr_GAP_Stop    : OUT    std_logic;
      tmr_NRP_Start   : OUT    std_logic;
      tmr_NRP_Stop    : OUT    std_logic;
      tmr_REP_Start   : OUT    std_logic;
      tmr_REP_Stop    : OUT    std_logic;
      tmr_SAF_Start   : OUT    std_logic;
      tmr_SAF_Stop    : OUT    std_logic
   );
   END COMPONENT mill1553_timers_testcntrl;

   -- Optional embedded configurations
   -- pragma synthesis_off
   FOR ALL : mill1553_timers USE ENTITY mil1553_lib.mill1553_timers;
    -- pragma synthesis_on


BEGIN

   -- Instance port mappings.
   timers1 : mill1553_timers
      PORT MAP (
         SyncPosEdge     => SyncPosEdge,
         clk             => clk,
         nReset          => nReset,
         reg_tmr_1us     => reg_tmr_1us,
         reg_tmr_ERP     => reg_tmr_ERP,
         reg_tmr_GAP     => reg_tmr_GAP,
         reg_tmr_NRP     => reg_tmr_NRP,
         reg_tmr_REP     => reg_tmr_REP,
         reg_tmr_SAF     => reg_tmr_SAF,
         tmr_1us_Start   => tmr_1us_Start,
         tmr_1us_Stop    => tmr_1us_Stop,
         tmr_25us_Start  => tmr_25us_Start,
         tmr_25us_Stop   => tmr_25us_Stop,
         tmr_Blank_Start => tmr_Blank_Start,
         tmr_Blank_Stop  => tmr_Blank_Stop,
         tmr_ERP_Reset   => tmr_ERP_Reset,
         tmr_ERP_Stop    => tmr_ERP_Stop,
         tmr_ERP_enable  => tmr_ERP_enable,
         tmr_GAP_Start   => tmr_GAP_Start,
         tmr_GAP_Stop    => tmr_GAP_Stop,
         tmr_NRP_Start   => tmr_NRP_Start,
         tmr_NRP_Stop    => tmr_NRP_Stop,
         tmr_REP_Start   => tmr_REP_Start,
         tmr_REP_Stop    => tmr_REP_Stop,
         tmr_SAF_Start   => tmr_SAF_Start,
         tmr_SAF_Stop    => tmr_SAF_Stop,
         tmr_25us        => tmr_25us,
         tmr_Blank       => tmr_Blank,
         tmr_ERP         => tmr_ERP,
         tmr_GAP         => tmr_GAP,
         tmr_NRP         => tmr_NRP,
         tmr_REP         => tmr_REP,
         tmr_SAF         => tmr_SAF,
         tmr_1us         => tmr_1us
      );
   testcntrl1 : mill1553_timers_testcntrl
      PORT MAP (
         tmr_1us         => tmr_1us,
         tmr_25us        => tmr_25us,
         tmr_Blank       => tmr_Blank,
         tmr_ERP         => tmr_ERP,
         tmr_GAP         => tmr_GAP,
         tmr_NRP         => tmr_NRP,
         tmr_REP         => tmr_REP,
         tmr_SAF         => tmr_SAF,
         SyncPosEdge     => SyncPosEdge,
         clk             => clk,
         nReset          => nReset,
         reg_tmr_1us     => reg_tmr_1us,
         reg_tmr_ERP     => reg_tmr_ERP,
         reg_tmr_GAP     => reg_tmr_GAP,
         reg_tmr_NRP     => reg_tmr_NRP,
         reg_tmr_REP     => reg_tmr_REP,
         reg_tmr_SAF     => reg_tmr_SAF,
         tmr_1us_Start   => tmr_1us_Start,
         tmr_1us_Stop    => tmr_1us_Stop,
         tmr_25us_Start  => tmr_25us_Start,
         tmr_25us_Stop   => tmr_25us_Stop,
         tmr_Blank_Start => tmr_Blank_Start,
         tmr_Blank_Stop  => tmr_Blank_Stop,
         tmr_ERP_Reset   => tmr_ERP_Reset,
         tmr_ERP_Stop    => tmr_ERP_Stop,
         tmr_ERP_enable  => tmr_ERP_enable,
         tmr_GAP_Start   => tmr_GAP_Start,
         tmr_GAP_Stop    => tmr_GAP_Stop,
         tmr_NRP_Start   => tmr_NRP_Start,
         tmr_NRP_Stop    => tmr_NRP_Stop,
         tmr_REP_Start   => tmr_REP_Start,
         tmr_REP_Stop    => tmr_REP_Stop,
         tmr_SAF_Start   => tmr_SAF_Start,
         tmr_SAF_Stop    => tmr_SAF_Stop
      );

END ARCHITECTURE struct;
      configuration mill1553_timers_tb_struct of mill1553_timers_tb is
        for struct
        end for;
      end configuration;
