-- VHDL Entity mil1553_tb.mill1553_dualbus_tb.symbol
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY mill1553_dualbus_tb IS
   GENERIC( 
      gRT1_Cmd : string := "RT1_RT2RT_15_ERR.txt";
      gRT1_Log : string := "RT1_MODE_NODATLog.txt";
      gRT2_Cmd : string := "RT2_RT2RT_16_ERR.txt";
      gRT2_Log : string := "RT2_BC2RTLog.txt";
      gBC_Cmd  : string := "BC_RT2RT_ERR.txt";
      gBC_Log  : string := "BC_RT2RTLog.txt"
   );
-- Declarations

END ENTITY mill1553_dualbus_tb ;

--
-- VHDL Architecture mil1553_tb.mill1553_dualbus_tb.struct
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY at_gen_lib;
LIBRARY mil1553_lib;

ARCHITECTURE struct OF mill1553_dualbus_tb IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL Addr1                : std_logic_vector(15 DOWNTO 0);
   SIGNAL Addr2                : std_logic_vector(15 DOWNTO 0);
   SIGNAL BCOutIO              : std_logic_vector(15 DOWNTO 0);
   SIGNAL BC_BitWord           : std_logic_vector(15 DOWNTO 0);
   SIGNAL BC_Cs                : std_logic;
   SIGNAL BC_InN1              : std_logic;
   SIGNAL BC_InN2              : std_logic;
   SIGNAL BC_InP1              : std_logic;
   SIGNAL BC_InP2              : std_logic;
   SIGNAL BC_OutEn1            : std_logic;
   SIGNAL BC_OutEn2            : std_logic;
   SIGNAL BC_OutN1             : std_logic;
   SIGNAL BC_OutN2             : std_logic;
   SIGNAL BC_OutP1             : std_logic;
   SIGNAL BC_OutP2             : std_logic;
   SIGNAL BC_ServiceReqVector  : std_logic_vector(15 DOWNTO 0);
   SIGNAL BC_ServiceRequest    : std_logic;
   SIGNAL BC_Strobe1           : std_logic;
   SIGNAL BC_Strobe2           : std_logic;
   SIGNAL BC_SubsystemFlag     : std_logic;
   SIGNAL Cs1                  : std_logic;
   SIGNAL Cs2                  : std_logic;
   SIGNAL DataIn1              : std_logic_vector(15 DOWNTO 0);
   SIGNAL DataIn2              : std_logic_vector(15 DOWNTO 0);
   SIGNAL DataOut1             : std_logic_vector(15 DOWNTO 0);
   SIGNAL DataOut2             : std_logic_vector(15 DOWNTO 0);
   SIGNAL DataValid            : std_logic;
   SIGNAL DataValid1           : std_logic;
   SIGNAL DataValid2           : std_logic;
   SIGNAL InIO                 : std_logic_vector(15 DOWNTO 0);
   SIGNAL InIO1                : std_logic_vector(15 DOWNTO 0);
   SIGNAL InIO2                : std_logic_vector(15 DOWNTO 0);
   SIGNAL Intr                 : std_logic;
   SIGNAL Intr1                : std_logic;
   SIGNAL Intr2                : std_logic;
   SIGNAL MyBCAddr             : std_logic_vector(4 DOWNTO 0);
   SIGNAL MyBCAddrParity       : std_logic;
   SIGNAL MyRtAddr1            : std_logic_vector(4 DOWNTO 0);
   SIGNAL MyRtAddr2            : std_logic_vector(4 DOWNTO 0);
   SIGNAL MyRtAddrParity1      : std_logic;
   SIGNAL MyRtAddrParity2      : std_logic;
   SIGNAL OutIO1               : std_logic_vector(15 DOWNTO 0);
   SIGNAL OutIO2               : std_logic_vector(15 DOWNTO 0);
   SIGNAL RT1_BitWord          : std_logic_vector(15 DOWNTO 0);
   SIGNAL RT1_InN1             : std_logic;
   SIGNAL RT1_InN2             : std_logic;
   SIGNAL RT1_InP1             : std_logic;
   SIGNAL RT1_InP2             : std_logic;
   SIGNAL RT1_OutEn1           : std_logic;
   SIGNAL RT1_OutEn2           : std_logic;
   SIGNAL RT1_OutN1            : std_logic;
   SIGNAL RT1_OutN2            : std_logic;
   SIGNAL RT1_OutP1            : std_logic;
   SIGNAL RT1_OutP2            : std_logic;
   SIGNAL RT1_ServiceReqVector : std_logic_vector(15 DOWNTO 0);
   SIGNAL RT1_ServiceRequest   : std_logic;
   SIGNAL RT1_Strobe1          : std_logic;
   SIGNAL RT1_Strobe2          : std_logic;
   SIGNAL RT1_SubsystemFlag    : std_logic;
   SIGNAL RT2_BitWord          : std_logic_vector(15 DOWNTO 0);
   SIGNAL RT2_InN1             : std_logic;
   SIGNAL RT2_InN2             : std_logic;
   SIGNAL RT2_InP1             : std_logic;
   SIGNAL RT2_InP2             : std_logic;
   SIGNAL RT2_OutEn1           : std_logic;
   SIGNAL RT2_OutEn2           : std_logic;
   SIGNAL RT2_OutN1            : std_logic;
   SIGNAL RT2_OutN2            : std_logic;
   SIGNAL RT2_OutP1            : std_logic;
   SIGNAL RT2_OutP2            : std_logic;
   SIGNAL RT2_ServiceReqVector : std_logic_vector(15 DOWNTO 0);
   SIGNAL RT2_ServiceRequest   : std_logic;
   SIGNAL RT2_Strobe1          : std_logic;
   SIGNAL RT2_Strobe2          : std_logic;
   SIGNAL RT2_SubsystemFlag    : std_logic;
   SIGNAL Rd1                  : std_logic;
   SIGNAL Rd2                  : std_logic;
   SIGNAL Wr1                  : std_logic;
   SIGNAL Wr2                  : std_logic;
   SIGNAL clk                  : std_logic;
   SIGNAL cpu_Addr             : std_logic_vector(0 TO 15);
   SIGNAL cpu_DataIn           : std_logic_vector(15 DOWNTO 0);
   SIGNAL cpu_DataOut          : std_logic_vector(15 DOWNTO 0);
   SIGNAL cpu_Rd               : std_logic;
   SIGNAL cpu_Wr               : std_logic;
   SIGNAL nReset               : std_logic;
   SIGNAL nResetIn_BC          : std_logic;
   SIGNAL nResetIn_RT1         : std_logic;
   SIGNAL nResetIn_RT2         : std_logic;


   -- Component Declarations
   COMPONENT clock_source
   GENERIC (
      PhaseDelay   : delay_length := 20 ns;
      ClockPeriod  : delay_length := 40 ns;
      gJitterOn    : boolean      := true;
      gJitterDelay : real         := 7.0;
      gJitter_ps   : real         := 10.0
   );
   PORT (
      clk : BUFFER std_logic 
   );
   END COMPONENT clock_source;
   COMPONENT cpu_commands_io
   GENERIC (
      gCpuCommands3 : string := "bus.txt";
      gCpuLog3      : string := "log.txt"
   );
   PORT (
      cpu_DataOut : IN     std_logic_vector (15 DOWNTO 0);
      cpu_Addr    : OUT    std_logic_vector (0 TO 15);
      cpu_DataIn  : OUT    std_logic_vector (15 DOWNTO 0);
      cpu_Rd      : OUT    std_logic ;
      cpu_Wr      : OUT    std_logic ;
      clk         : IN     std_logic ;
      InIO        : IN     std_logic_vector (15 DOWNTO 0);
      OutIO       : OUT    std_logic_vector (15 DOWNTO 0)
   );
   END COMPONENT cpu_commands_io;
   COMPONENT power_on_reset
   GENERIC (
      DelayLength : integer := 10
   );
   PORT (
      Clk    : IN     std_logic ;
      nReset : OUT    std_logic 
   );
   END COMPONENT power_on_reset;
   COMPONENT mill1553_dualbus
   PORT (
      Addr             : IN     std_logic_vector (15 DOWNTO 0);
      BitWord          : IN     std_logic_vector (15 DOWNTO 0);
      Cs               : IN     std_logic ;
      DataIn           : IN     std_logic_vector (15 DOWNTO 0);
      InN1             : IN     std_logic ;
      InN2             : IN     std_logic ;
      InP1             : IN     std_logic ;
      InP2             : IN     std_logic ;
      MyRtAddr         : IN     std_logic_vector (4 DOWNTO 0);
      MyRtAddrParity   : IN     std_logic ;
      Rd               : IN     std_logic ;
      ServiceReqVector : IN     std_logic_vector (15 DOWNTO 0);
      ServiceRequest   : IN     std_logic ;
      SubsystemFlag    : IN     std_logic ;
      Wr               : IN     std_logic ;
      clk              : IN     std_logic ;
      nResetIn         : IN     std_logic ;
      DataOut          : OUT    std_logic_vector (15 DOWNTO 0);
      DataValid        : OUT    std_logic ;
      Intr             : OUT    std_logic ;
      OutEn1           : OUT    std_logic ;
      OutEn2           : OUT    std_logic ;
      OutN1            : OUT    std_logic ;
      OutN2            : OUT    std_logic ;
      OutP1            : OUT    std_logic ;
      OutP2            : OUT    std_logic ;
      Strobe1          : OUT    std_logic ;
      Strobe2          : OUT    std_logic 
   );
   END COMPONENT mill1553_dualbus;

   -- Optional embedded configurations
   -- pragma synthesis_off
   FOR ALL : clock_source USE ENTITY at_gen_lib.clock_source;
   FOR ALL : cpu_commands_io USE ENTITY at_gen_lib.cpu_commands_io;
   FOR BC1 : mill1553_dualbus USE ENTITY mil1553_lib.mill1553_dualbus;
   FOR RT1 : mill1553_dualbus USE ENTITY mil1553_lib.mill1553_dualbus;
   FOR RT2 : mill1553_dualbus USE ENTITY mil1553_lib.mill1553_dualbus;
   FOR ALL : power_on_reset USE ENTITY at_gen_lib.power_on_reset;
   -- pragma synthesis_on


BEGIN
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 Tristatebus
   -- Tristatebus
   RT1_InP1 <= BC_OutP1  when BC_OutEn1  = '1' else   
               RT2_OutP1 when RT2_OutEn1 = '1' else
               RT1_OutP1;-- 'Z';
   RT1_InN1 <= BC_OutN1  when BC_OutEn1  = '1' else   
               RT2_OutN1 when RT2_OutEn1 = '1' else
               RT1_OutN1;-- 'Z';
   
   RT2_InP1 <= BC_OutP1  when BC_OutEn1  = '1' else   
               RT1_OutP1 when RT1_OutEn1 = '1' else
               RT2_OutP1;-- 'Z';
   RT2_InN1 <= BC_OutN1  when BC_OutEn1  = '1' else   
               RT1_OutN1 when RT1_OutEn1 = '1' else
               RT2_OutN1;-- 'Z';
   
   BC_InP1  <= RT1_OutP1 when RT1_OutEn1 = '1' else   
               RT2_OutP1 when RT2_OutEn1 = '1' else
               BC_OutP1;-- 'Z';
   BC_InN1  <= RT1_OutN1 when RT1_OutEn1 = '1' else   
               RT2_OutN1 when RT2_OutEn1 = '1' else
               BC_OutN1;-- 'Z';
   
   RT1_InP2 <= BC_OutP2  when BC_OutEn2  = '1' else   
               RT2_OutP2 when RT2_OutEn2 = '1' else
               RT1_OutP2;-- 'Z';
   RT1_InN2 <= BC_OutN2  when BC_OutEn2  = '1' else   
               RT2_OutN2 when RT2_OutEn2 = '1' else
               RT1_OutN2;-- 'Z';
   
   RT2_InP2 <= BC_OutP2  when BC_OutEn2  = '1' else   
               RT1_OutP2 when RT1_OutEn2 = '1' else
               RT2_OutP2;-- 'Z';
   RT2_InN2 <= BC_OutN2  when BC_OutEn2  = '1' else   
               RT1_OutN2 when RT1_OutEn2 = '1' else
               RT2_OutN2;-- 'Z';
   
   BC_InP2  <= RT1_OutP2 when RT1_OutEn2 = '1' else   
               RT2_OutP2 when RT2_OutEn2 = '1' else
               BC_OutP2;-- 'Z';
   BC_InN2  <= RT1_OutN2 when RT1_OutEn2 = '1' else   
               RT2_OutN2 when RT2_OutEn2 = '1' else
               BC_OutN2;-- 'Z';
   

   -- HDL Embedded Text Block 2 eb2
   InIO(0) <= Intr; 
   InIO(1) <= BC_OutEn1; 
   InIO(2) <= BC_OutEn2; 
   InIO(11) <= OutIO1(15);
   InIO(12) <= OutIO2(15);
   InIO(15 downto 13) <= (others => '0');             
   InIO(10 downto 3) <= (others => '0');    
   nResetIn_BC <= BCOutIo(0);                               

   -- HDL Embedded Text Block 4 Rt1Config
   Cs1 <= '1'; 
   MyRtAddr1   <= "01111";  
   MyRtAddrParity1 <= '1';  
   RT1_SubsystemFlag <= '0';
   RT1_ServiceRequest <= '0';
   RT1_ServiceReqVector <= X"BEE1";
   InIO1(0) <= Intr1; 
   InIO1(1) <= RT1_OutEn1; 
   InIO1(2) <= RT1_OutEn2; 
   InIO1(14 downto 3) <= (others => '0');
   InIO1(15) <= BCOutIO(15);    
   nResetIn_RT1 <= OutIo1(0);    
   
   Cs2 <= '1'; 
   MyRtAddr2   <= "10010";  
   MyRtAddrParity2 <= '1'; 
   RT2_SubsystemFlag <= '0';
   RT2_ServiceRequest <= '0';
   RT2_ServiceReqVector <= X"BEE2";
   InIO2(0) <= Intr2; 
   InIO2(1) <= RT2_OutEn1; 
   InIO2(2) <= Rt2_OutEn2; 
   InIO2(14 downto 3) <= (others => '0');  
   InIO2(15) <= BCOutIO(15);    
   nResetIn_RT2 <= OutIo2(0);      
         
               

   -- HDL Embedded Text Block 6 BCConfig1
   BC_Cs <= '1';  
   MyBCAddr  <= "10010";--"01111";--"11110";   
   MyBCAddrParity <= '1';  
   BC_SubsystemFlag <= '0';
   BC_ServiceRequest <= '0';
   BC_ServiceReqVector <= (others => '0');      
   RT1_BitWord <= X"DEA1";
   RT2_BitWord <= X"DEA2";
   BC_BitWord <= X"DEA0";
               


   -- Instance port mappings.
   U_1 : clock_source
      GENERIC MAP (
         PhaseDelay   => 2 ns,
         ClockPeriod  => 5 ns,
         gJitterOn    => false,
         gJitterDelay => 7.0,
         gJitter_ps   => 10.0
      )
      PORT MAP (
         clk => clk
      );
   BC_cpu_commands : cpu_commands_io
      GENERIC MAP (
         gCpuCommands3 => gBC_cmd,
         gCpuLog3      => gBC_log
      )
      PORT MAP (
         cpu_DataOut => cpu_DataOut,
         cpu_Addr    => cpu_Addr,
         cpu_DataIn  => cpu_DataIn,
         cpu_Rd      => cpu_Rd,
         cpu_Wr      => cpu_Wr,
         clk         => clk,
         InIO        => InIO,
         OutIO       => BCOutIO
      );
   RT1_cpu_commands : cpu_commands_io
      GENERIC MAP (
         gCpuCommands3 => gRT1_cmd,
         gCpuLog3      => gRT1_log
      )
      PORT MAP (
         cpu_DataOut => DataOut1,
         cpu_Addr    => Addr1,
         cpu_DataIn  => DataIn1,
         cpu_Rd      => Rd1,
         cpu_Wr      => Wr1,
         clk         => clk,
         InIO        => InIO1,
         OutIO       => OutIO1
      );
   RT2_cpu_commands : cpu_commands_io
      GENERIC MAP (
         gCpuCommands3 => gRT2_cmd,
         gCpuLog3      => gRT2_log
      )
      PORT MAP (
         cpu_DataOut => DataOut2,
         cpu_Addr    => Addr2,
         cpu_DataIn  => DataIn2,
         cpu_Rd      => Rd2,
         cpu_Wr      => Wr2,
         clk         => clk,
         InIO        => InIO2,
         OutIO       => OutIO2
      );
   U_2 : power_on_reset
      GENERIC MAP (
         DelayLength => 10
      )
      PORT MAP (
         Clk    => clk,
         nReset => nReset
      );
   BC1 : mill1553_dualbus
      PORT MAP (
         Addr             => cpu_Addr,
         BitWord          => BC_BitWord,
         Cs               => BC_Cs,
         DataIn           => cpu_DataIn,
         InN1             => BC_InN1,
         InN2             => BC_InN2,
         InP1             => BC_InP1,
         InP2             => BC_InP2,
         MyRtAddr         => MyBCAddr,
         MyRtAddrParity   => MyBCAddrParity,
         Rd               => cpu_Rd,
         ServiceReqVector => BC_ServiceReqVector,
         ServiceRequest   => BC_ServiceRequest,
         SubsystemFlag    => BC_SubsystemFlag,
         Wr               => cpu_Wr,
         clk              => clk,
         nResetIn         => nResetIn_BC,
         DataOut          => cpu_DataOut,
         DataValid        => DataValid,
         Intr             => Intr,
         OutEn1           => BC_OutEn1,
         OutEn2           => BC_OutEn2,
         OutN1            => BC_OutN1,
         OutN2            => BC_OutN2,
         OutP1            => BC_OutP1,
         OutP2            => BC_OutP2,
         Strobe1          => BC_Strobe1,
         Strobe2          => BC_Strobe2
      );
   RT1 : mill1553_dualbus
      PORT MAP (
         Addr             => Addr1,
         BitWord          => RT1_BitWord,
         Cs               => Cs1,
         DataIn           => DataIn1,
         InN1             => RT1_InN1,
         InN2             => RT1_InN2,
         InP1             => RT1_InP1,
         InP2             => RT1_InP2,
         MyRtAddr         => MyRtAddr1,
         MyRtAddrParity   => MyRtAddrParity1,
         Rd               => Rd1,
         ServiceReqVector => RT1_ServiceReqVector,
         ServiceRequest   => RT1_ServiceRequest,
         SubsystemFlag    => RT1_SubsystemFlag,
         Wr               => Wr1,
         clk              => clk,
         nResetIn         => nResetIn_RT1,
         DataOut          => DataOut1,
         DataValid        => DataValid1,
         Intr             => Intr1,
         OutEn1           => RT1_OutEn1,
         OutEn2           => RT1_OutEn2,
         OutN1            => RT1_OutN1,
         OutN2            => RT1_OutN2,
         OutP1            => RT1_OutP1,
         OutP2            => RT1_OutP2,
         Strobe1          => RT1_Strobe1,
         Strobe2          => RT1_Strobe2
      );
   RT2 : mill1553_dualbus
      PORT MAP (
         Addr             => Addr2,
         BitWord          => RT2_BitWord,
         Cs               => Cs2,
         DataIn           => DataIn2,
         InN1             => RT2_InN1,
         InN2             => RT2_InN2,
         InP1             => RT2_InP1,
         InP2             => RT2_InP2,
         MyRtAddr         => MyRtAddr2,
         MyRtAddrParity   => MyRtAddrParity2,
         Rd               => Rd2,
         ServiceReqVector => RT2_ServiceReqVector,
         ServiceRequest   => RT2_ServiceRequest,
         SubsystemFlag    => RT2_SubsystemFlag,
         Wr               => Wr2,
         clk              => clk,
         nResetIn         => nResetIn_RT2,
         DataOut          => DataOut2,
         DataValid        => DataValid2,
         Intr             => Intr2,
         OutEn1           => RT2_OutEn1,
         OutEn2           => RT2_OutEn2,
         OutN1            => RT2_OutN1,
         OutN2            => RT2_OutN2,
         OutP1            => RT2_OutP1,
         OutP2            => RT2_OutP2,
         Strobe1          => RT2_Strobe1,
         Strobe2          => RT2_Strobe2
      );

END ARCHITECTURE struct;
