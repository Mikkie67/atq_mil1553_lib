-- VHDL Entity mil1553_tb.test_man_dec_fsm.symbol
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY test_man_dec_fsm IS
   GENERIC( 
      gBitFreq1    : natural := 100000000;
      gClkInFreq1  : natural := 100000000;
      gOverSample1 : natural := 4
   );
   PORT( 
      Clk               : IN     std_logic;
      ERP_tmr           : IN     std_logic;
      NegEdge           : IN     std_logic;
      PosEdge           : IN     std_logic;
      SyncOutN          : IN     std_logic;
      SyncOutP          : IN     std_logic;
      TxWord            : IN     std_logic_vector (16 DOWNTO 0);
      nReset            : IN     std_logic;
      CmdEdge           : OUT    std_logic;
      Cmd_nData         : OUT    std_logic;
      EarlyReplyRx      : OUT    std_logic;
      Err_Noise         : OUT    integer;
      Err_Parity        : OUT    integer;
      LastEdge          : OUT    std_logic;
      ManDecState       : OUT    std_logic_vector (4 DOWNTO 0);
      NewWord           : OUT    std_logic;
      OutWord           : OUT    std_logic_vector (15 DOWNTO 0);
      SyncNegEdge       : OUT    std_logic;
      SyncPosEdge       : OUT    std_logic;
      UnexpectedEdgeCnt : OUT    std_logic_vector (15 DOWNTO 0)
   );

-- Declarations

END ENTITY test_man_dec_fsm ;

--
-- VHDL Architecture mil1553_tb.test_man_dec_fsm.fsm2
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
 
ARCHITECTURE fsm2 OF test_man_dec_fsm IS

   -- Architecture Declarations
   constant PreLoad : integer := (gClkInFreq1 / gBitFreq1)/2-1;
   constant SyncPreLoad : integer := 165;
   constant CmdSyncHighPreLoad : integer := 240;
   constant SamplePreLoad : integer := 65;
   constant SamplePreLoadHalf : integer := 50;
   signal ShiftReg : std_logic_vector(5 downto 0);
   signal Count : integer range 0 to SyncPreload;
   signal BitCount : integer range 0 to 19;
   signal HalfBitCount : integer range 0 to 79;
   signal SampleCount : integer range 0 to CmdSyncHighPreLoad;
   signal DataWord : std_logic_vector(16 downto 0);
   signal DataWordN : std_logic_vector(79 downto 0);
   signal CalcParity : std_logic;
   signal RxParity : std_logic;
   signal UnexpectedEdge : integer := 0;
   signal RT2RT : std_logic;

   TYPE STATE_TYPE IS (
      sBusIdle,
      sCheckCmdSyncLow,
      sGet0Low,
      sGet0High,
      sCheckParityLow,
      sCheckCmdSyncHigh,
      sGet1High,
      sGet1Low,
      sCheckDatSyncLow,
      sCheckDatSyncHigh,
      sCheckParityHigh,
      s0,
      s1,
      s2,
      s3,
      s4,
      s5,
      s6,
      s7,
      s9,
      s8
   );
 
   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE;
   SIGNAL next_state : STATE_TYPE;

   -- Declare any pre-registered internal signals
   SIGNAL CmdEdge_cld : std_logic ;
   SIGNAL Cmd_nData_cld : std_logic ;
   SIGNAL EarlyReplyRx_cld : std_logic ;
   SIGNAL LastEdge_cld : std_logic ;
   SIGNAL NewWord_cld : std_logic ;
   SIGNAL OutWord_cld : std_logic_vector (15 DOWNTO 0);
   SIGNAL SyncNegEdge_cld : std_logic ;
   SIGNAL SyncPosEdge_cld : std_logic ;

BEGIN

   -----------------------------------------------------------------
   clocked_proc : PROCESS ( 
      Clk,
      nReset
   )
   -----------------------------------------------------------------
   BEGIN
      IF (nReset = '0') THEN
         current_state <= sBusIdle;
         -- Default Reset Values
         CmdEdge_cld <= '0';
         Cmd_nData_cld <= '0';
         EarlyReplyRx_cld <= '0';
         LastEdge_cld <= '0';
         NewWord_cld <= '0';
         OutWord_cld <= (others => '1');
         SyncNegEdge_cld <= '0';
         SyncPosEdge_cld <= '0';
         BitCount <= 0;
         CalcParity <= '1';
         Count <= 0;
         DataWord <= (others => '0');
         DataWordN <= (others => '0');
         HalfBitCount <= 0;
         RT2RT <= '0';
         RxParity <= '0';
         SampleCount <= 0;
         ShiftReg <= (others => '0');
         UnexpectedEdge <= 0;
      ELSIF (Clk'EVENT AND Clk = '1') THEN
         current_state <= next_state;
         -- Default Assignment To Internals
         CmdEdge_cld <= '0';
         LastEdge_cld <= '0';
         NewWord_cld <= '0';
         SyncNegEdge_cld <= '0';
         SyncPosEdge_cld <= '0';

         -- Combined Actions
         CASE current_state IS
            WHEN sBusIdle => 
               EarlyReplyRx_cld <= '0';
               IF (PosEdge = '1') THEN 
                  SampleCount <= CmdSyncHighPreLoad;
                  if (ERP_tmr = '0') then
                    EarlyReplyRx_cld <= '1';
                  end if;
               END IF;
            WHEN sCheckCmdSyncLow => 
               IF (PosEdge = '1' and SampleCount > 40) THEN 
                  UnexpectedEdge <= UnexpectedEdge + 1;
               ELSIF (PosEdge = '1') THEN 
                  SampleCount <= SamplePreload;
                  BitCount <= 15;
                  CalcParity <= '0';
               ELSIF (SampleCount = 0) THEN 
                  SampleCount <= SamplePreload;
                  BitCount <= 15;
                  CalcParity <= '1';
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sGet0Low => 
               IF (PosEdge = '1') THEN 
                  SampleCount <= SamplePreload;
               ELSIF (SampleCount = 0) THEN 
                  UnexpectedEdge <= UnexpectedEdge + 1;
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sGet0High => 
               IF (NegEdge = '1' and SampleCount > 40) THEN 
               ELSIF (BitCount = 0 and NegEdge = '1') THEN 
                  SampleCount <= SamplePreLoad;
                  OutWord_cld(BitCount) <= '0';
                  RxParity <= '0';
               ELSIF (NegEdge = '1') THEN 
                  SampleCount <= SamplePreload;
                  OutWord_cld(BitCount) <= '0';
                  BitCount <= BitCount -1;
               ELSIF (BitCount = 0 and SampleCount = 0) THEN 
                  SampleCount <= SamplePreLoad;
                  OutWord_cld(BitCount) <= '0';
                  RxParity <= '1';
               ELSIF (SampleCount = 0) THEN 
                  SampleCount <= SamplePreload -15;
                  OutWord_cld(BitCount) <= '0';
                  BitCount <= BitCount -1;
                  CalcParity <= not CalcParity;
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sCheckParityLow => 
               IF (CalcParity = RxParity and SampleCount = 0 and SyncOutP = '0') THEN 
                  NewWord_cld <= '1';
                  SampleCount <= SyncPreload;
               ELSIF (CalcParity = RxParity and PosEdge = '1' and RxParity = '0') THEN 
                  SampleCount <= SamplePreload;
                  LastEdge_cld <= '1';
               ELSIF (CalcParity = RxParity and SampleCount = 0 and SyncOutP = '1') THEN 
                  NewWord_cld <= '1';
                  SampleCount <= CmdSyncHighPreLoad;
                  RT2RT <= '1';
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sCheckCmdSyncHigh => 
               IF (NegEdge = '1' and SampleCount > 140) THEN 
                  UnexpectedEdge <= UnexpectedEdge + 1;
               ELSIF (NegEdge = '1') THEN 
                  SampleCount <= SyncPreLoad;
                  Cmd_nData_cld <= '1';
                  CmdEdge_cld <= '1';
                  if (RT2RT = '0') then
                  SyncNegEdge_cld <= '1';
                  end if;
                  RT2RT <= '0';
               ELSIF (SampleCount < 80) THEN 
                  UnexpectedEdge <= UnexpectedEdge + 1;
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sGet1High => 
               IF (NegEdge = '1' and SampleCount > 45) THEN 
               ELSIF (NegEdge = '1') THEN 
                  SampleCount <= SamplePreload;
               ELSIF (SampleCount = 0) THEN 
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sGet1Low => 
               IF (BitCount = 0 and PosEdge = '1') THEN 
                  SampleCount <= SamplePreLoad;
                  OutWord_cld(BitCount) <= '1';
                  RxParity <= '1';
               ELSIF (BitCount = 0 and SampleCount = 0) THEN 
                  SampleCount <= SamplePreload;
                  OutWord_cld(BitCount) <= '1';
                  RxParity <= '0';
               ELSIF (PosEdge = '1') THEN 
                  SampleCount <= SamplePreload;
                  OutWord_cld(BitCount) <= '1';
                  CalcParity <=not CalcParity;
                  BitCount <= BitCount -1;
               ELSIF (PosEdge = '1' and SampleCount > 40) THEN 
               ELSIF (SampleCount = 0) THEN 
                  SampleCount <= SamplePreload;
                  OutWord_cld(BitCount) <= '1';
                  --CalcParity <=not CalcParity;
                  BitCount <= BitCount -1;
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sCheckDatSyncLow => 
               IF (PosEdge = '1' and SampleCount > 40) THEN 
               ELSIF (PosEdge = '1') THEN 
                  SampleCount <= SyncPreload;
                  Cmd_nData_cld <= '0';
                  SyncPosEdge_cld <= '1';
               ELSIF (SampleCount = 0) THEN 
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sCheckDatSyncHigh => 
               IF (NegEdge = '1' and SampleCount > 40) THEN 
               ELSIF (NegEdge = '1') THEN 
                  SampleCount <= SamplePreload;
                  BitCount <= 15;
                  CalcParity <= '1';
               ELSIF (SampleCount = 0) THEN 
                  SampleCount <= SamplePreload;
                  BitCount <= 15;
                  CalcParity <= '0';
               ELSE
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN sCheckParityHigh => 
               IF (NegEdge = '1' and SampleCount > 50) THEN 
               ELSIF (CalcParity = RxParity and NegEdge = '1' and RxParity = '0') THEN 
                  NewWord_cld <= '1';
                  SampleCount <= SyncPreload;
               ELSIF (CalcParity = RxParity and SampleCount = 0 and SyncOutP = '1') THEN 
                  NewWord_cld <= '1';
                  SampleCount <= CmdSyncHighPreLoad;
               ELSIF (NegEdge = '1' and RxParity = '0') THEN 
               ELSIF (SampleCount = 0 and (RxParity = '0')) THEN 
                  NewWord_cld <= '1';
               ELSIF (CalcParity = RxParity and NegEdge = '1' and RxParity = '1') THEN 
                  SampleCount <= SamplePreload;
                  LastEdge_cld <= '1';
               ELSIF (SampleCount > 0) THEN 
                  SampleCount  <= SampleCount  -1;
               END IF;
            WHEN s7 => 
               IF (PosEdge = '1' and SampleCount > 40) THEN 
                  UnexpectedEdge <= UnexpectedEdge + 1;
               END IF;
            WHEN s9 => 
               IF ((SampleCount = 0 or PosEdge = '1' ) and RxParity = '1') THEN 
                  NewWord_cld <= '1';
               END IF;
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS clocked_proc;
 
   -----------------------------------------------------------------
   nextstate_proc : PROCESS (all)
   -----------------------------------------------------------------
   BEGIN
      CASE current_state IS
         WHEN sBusIdle => 
            IF (PosEdge = '1') THEN 
               next_state <= sCheckCmdSyncHigh;
            ELSE
               next_state <= sBusIdle;
            END IF;
         WHEN sCheckCmdSyncLow => 
            IF (PosEdge = '1' and SampleCount > 40) THEN 
               next_state <= sBusIdle;
            ELSIF (PosEdge = '1') THEN 
               next_state <= sGet1High;
            ELSIF (SampleCount = 0) THEN 
               next_state <= sGet0Low;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sCheckCmdSyncLow;
            ELSE
               next_state <= sCheckCmdSyncLow;
            END IF;
         WHEN sGet0Low => 
            IF (PosEdge = '1') THEN 
               next_state <= sGet0High;
            ELSIF (SampleCount = 0) THEN 
               next_state <= sBusIdle;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sGet0Low;
            ELSE
               next_state <= sGet0Low;
            END IF;
         WHEN sGet0High => 
            IF (NegEdge = '1' and SampleCount > 40) THEN 
               next_state <= sBusIdle;
            ELSIF (BitCount = 0 and NegEdge = '1') THEN 
               next_state <= sCheckParityLow;
            ELSIF (NegEdge = '1') THEN 
               next_state <= sGet0Low;
            ELSIF (BitCount = 0 and SampleCount = 0) THEN 
               next_state <= sCheckParityHigh;
            ELSIF (SampleCount = 0) THEN 
               next_state <= sGet1High;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sGet0High;
            ELSE
               next_state <= sGet0High;
            END IF;
         WHEN sCheckParityLow => 
            IF (CalcParity = RxParity and SampleCount = 0 and SyncOutP = '0') THEN 
               next_state <= sCheckDatSyncLow;
            ELSIF (CalcParity = RxParity and PosEdge = '1' and RxParity = '0') THEN 
               next_state <= sCheckParityHigh;
            ELSIF (CalcParity = RxParity and SampleCount = 0 and SyncOutP = '1') THEN 
               next_state <= sCheckCmdSyncHigh;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sCheckParityLow;
            ELSE
               next_state <= sCheckParityLow;
            END IF;
         WHEN sCheckCmdSyncHigh => 
            IF (NegEdge = '1' and SampleCount > 140) THEN 
               next_state <= sBusIdle;
            ELSIF (NegEdge = '1') THEN 
               next_state <= sCheckCmdSyncLow;
            ELSIF (SampleCount < 80) THEN 
               next_state <= sBusIdle;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sCheckCmdSyncHigh;
            ELSE
               next_state <= sCheckCmdSyncHigh;
            END IF;
         WHEN sGet1High => 
            IF (NegEdge = '1' and SampleCount > 45) THEN 
               next_state <= sBusIdle;
            ELSIF (NegEdge = '1') THEN 
               next_state <= sGet1Low;
            ELSIF (SampleCount = 0) THEN 
               next_state <= sBusIdle;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sGet1High;
            ELSE
               next_state <= sGet1High;
            END IF;
         WHEN sGet1Low => 
            IF (BitCount = 0 and PosEdge = '1') THEN 
               next_state <= sCheckParityHigh;
            ELSIF (BitCount = 0 and SampleCount = 0) THEN 
               next_state <= sCheckParityLow;
            ELSIF (PosEdge = '1') THEN 
               next_state <= sGet1High;
            ELSIF (PosEdge = '1' and SampleCount > 40) THEN 
               next_state <= sBusIdle;
            ELSIF (SampleCount = 0) THEN 
               next_state <= sGet0Low;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sGet1Low;
            ELSE
               next_state <= sGet1Low;
            END IF;
         WHEN sCheckDatSyncLow => 
            IF (PosEdge = '1' and SampleCount > 40) THEN 
               next_state <= sBusIdle;
            ELSIF (PosEdge = '1') THEN 
               next_state <= sCheckDatSyncHigh;
            ELSIF (SampleCount = 0) THEN 
               next_state <= sBusIdle;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sCheckDatSyncLow;
            ELSE
               next_state <= sCheckDatSyncLow;
            END IF;
         WHEN sCheckDatSyncHigh => 
            IF (NegEdge = '1' and SampleCount > 40) THEN 
               next_state <= sBusIdle;
            ELSIF (NegEdge = '1') THEN 
               next_state <= sGet0Low;
            ELSIF (SampleCount = 0) THEN 
               next_state <= sGet1High;
            ELSE
               next_state <= sCheckDatSyncHigh;
            END IF;
         WHEN sCheckParityHigh => 
            IF (NegEdge = '1' and SampleCount > 50) THEN 
               next_state <= s0;
            ELSIF (CalcParity = RxParity and NegEdge = '1' and RxParity = '0') THEN 
               next_state <= sCheckDatSyncLow;
            ELSIF (CalcParity = RxParity and SampleCount = 0 and SyncOutP = '1') THEN 
               next_state <= sCheckCmdSyncHigh;
            ELSIF (NegEdge = '1' and RxParity = '0') THEN 
               next_state <= s2;
            ELSIF (SampleCount = 0 and (RxParity = '0')) THEN 
               next_state <= s1;
            ELSIF (CalcParity = RxParity and NegEdge = '1' and RxParity = '1') THEN 
               next_state <= sCheckParityLow;
            ELSIF (SampleCount > 0) THEN 
               next_state <= sCheckParityHigh;
            ELSE
               next_state <= sCheckParityHigh;
            END IF;
         WHEN s0 => 
            next_state <= sBusIdle;
         WHEN s1 => 
            next_state <= sBusIdle;
         WHEN s2 => 
            next_state <= sBusIdle;
         WHEN s3 => 
            next_state <= sBusIdle;
         WHEN s4 => 
            next_state <= sBusIdle;
         WHEN s5 => 
            next_state <= sBusIdle;
         WHEN s6 => 
            IF (PosEdge = '1') THEN 
               next_state <= s3;
            ELSIF (SampleCount = 0) THEN 
               next_state <= s3;
            ELSE
               next_state <= s6;
            END IF;
         WHEN s7 => 
            IF (PosEdge = '1' and SampleCount > 40) THEN 
               next_state <= sBusIdle;
            ELSE
               next_state <= s7;
            END IF;
         WHEN s9 => 
            IF ((SampleCount = 0 or PosEdge = '1' ) and RxParity = '1') THEN 
               next_state <= s5;
            ELSE
               next_state <= s9;
            END IF;
         WHEN s8 => 
            IF (PosEdge = '1' and SampleCount > 40) THEN 
               next_state <= s4;
            ELSE
               next_state <= s8;
            END IF;
         WHEN OTHERS =>
            next_state <= sBusIdle;
      END CASE;
   END PROCESS nextstate_proc;
 
   -----------------------------------------------------------------
   -- Default Assignment
   Err_Noise <= 0;
   Err_Parity <= 0;
 
   -- Concurrent Statements
   -- Clocked output assignments
   CmdEdge <= CmdEdge_cld;
   Cmd_nData <= Cmd_nData_cld;
   EarlyReplyRx <= EarlyReplyRx_cld;
   LastEdge <= LastEdge_cld;
   NewWord <= NewWord_cld;
   OutWord <= OutWord_cld;
   SyncNegEdge <= SyncNegEdge_cld;
   SyncPosEdge <= SyncPosEdge_cld;
   UnexpectedEdgeCnt <= std_logic_vector(to_unsigned(UnexpectedEdge,16));
   ManDecState <= std_logic_vector(to_unsigned(STATE_TYPE'pos(current_state), 5));
END ARCHITECTURE fsm2;
