--
-- VHDL Architecture mil1553_tb.man_enc_vc.rtl
LIBRARY ieee;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  use std.textio.all ;
 
LIBRARY osvvm;
  context osvvm.osvvmcontext;

LIBRARY mil1553_tb;
USE mil1553_tb.ManchesterVC_Pkg.ALL;

ENTITY man_enc_vc IS
   PORT( 
      Enc_Clk             : IN     std_logic;
      Enc_Done            : IN     std_logic;
      Enc_nReset          : IN     std_logic;
      Enc_Cmd_nData       : OUT    std_logic;
      Enc_DataIn          : OUT    std_logic_vector (15 DOWNTO 0);
      Enc_Go              : OUT    std_logic;
      Enc_inj_ParityError : OUT    std_logic;
      Enc_tmr_Blank       : OUT    std_logic;
      Enc_Record          : INOUT  ManchesterEncRecType
   );

-- Declarations

END ENTITY man_enc_vc ;

--
architecture rtl of man_enc_vc is
begin

  EncoderDriver : process
  begin
    -- Initial state
    Enc_Record.Done <= '0';
    Enc_Record.Go   <= '0';

    wait until rising_edge(Enc_Clk);

    while true loop
      -- Wait for a transaction request from test controller
      wait until rising_edge(Enc_Clk) and Enc_Record.Go = '1';

      -- Drive inputs to DUT
      Enc_DataIn       <= Enc_Record.Data;
      Enc_Cmd_nData  <= Enc_Record.Cmd_nData;
      --jean Enc_inj_ParityError  <= Enc_Record.ErrInject;

      -- Pulse DUT Go input for one clock
      Enc_Go <= '1';
      wait until rising_edge(Enc_Clk);
      Enc_Go <= '0';

      -- Wait for DUT to finish
      wait until rising_edge(Enc_Clk) and Enc_Done = '1';

      -- Propagate completion to TestCtrl
      Enc_Record.Done <= '1';
      wait until rising_edge(Enc_Clk);
      Enc_Record.Done <= '0';

    end loop;
  end process;

end rtl;
