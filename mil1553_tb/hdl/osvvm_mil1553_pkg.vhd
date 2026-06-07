library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package osvvm_mil1553_pkg is
  -- General constants
  constant IrqMask : std_logic_vector(15 downto 0) := X"00FA";

  -- Register address constants
  constant reg_status              : std_logic_vector(15 downto 0) := X"0000";
  constant reg_intr_mask           : std_logic_vector(15 downto 0) := X"0001";
  constant reg_clear_bits          : std_logic_vector(15 downto 0) := X"0002";
  constant reg_tmr_1us             : std_logic_vector(15 downto 0) := X"0003";
  constant reg_tmr_GAP             : std_logic_vector(15 downto 0) := X"0004";
  constant reg_tmr_NRP             : std_logic_vector(15 downto 0) := X"0005";
  constant reg_tmr_REP             : std_logic_vector(15 downto 0) := X"0006";
  constant reg_tmr_SAF             : std_logic_vector(15 downto 0) := X"0007";
  constant reg_legal_subaddr1      : std_logic_vector(15 downto 0) := X"0008";
  constant reg_legal_subaddr2      : std_logic_vector(15 downto 0) := X"0009";
  constant reg_legal_rx_mode1      : std_logic_vector(15 downto 0) := X"000A";
  constant reg_legal_rx_mode2      : std_logic_vector(15 downto 0) := X"000B";
  constant reg_legal_tx_mode1      : std_logic_vector(15 downto 0) := X"000C";
  constant reg_legal_tx_mode2      : std_logic_vector(15 downto 0) := X"000D";
  constant reg_legal_brdcst_mode1  : std_logic_vector(15 downto 0) := X"000E";
  constant reg_legal_brdcst_mode2  : std_logic_vector(15 downto 0) := X"000F";
  constant reg_status_rxed1        : std_logic_vector(15 downto 0) := X"0010";
  constant reg_mode_cmd_rxed1      : std_logic_vector(15 downto 0) := X"0011";
  constant reg_mode_data_rxed1     : std_logic_vector(15 downto 0) := X"0012";
  constant reg_rx_mode_cmd1        : std_logic_vector(15 downto 0) := X"0013";
  constant reg_tx_control1         : std_logic_vector(15 downto 0) := X"0014";
  constant reg_cmd_proc_start1     : std_logic_vector(15 downto 0) := X"0015";
  constant reg_cmd_proc_length1    : std_logic_vector(15 downto 0) := X"0016";
  constant reg_cmd_rxed1           : std_logic_vector(15 downto 0) := X"0017";
  constant reg_24                  : std_logic_vector(15 downto 0) := X"0018";
  constant reg_bus1_DatSyncErr     : std_logic_vector(15 downto 0) := X"0019";
  constant reg_bus1_CmdSyncErr     : std_logic_vector(15 downto 0) := X"001A";
  constant reg_bus1_EarlyEdgeErr   : std_logic_vector(15 downto 0) := X"001B";
  constant reg_bus1_LateEdgeErr    : std_logic_vector(15 downto 0) := X"001C";
  constant reg_bus1_ParityErr      : std_logic_vector(15 downto 0) := X"001D";
  constant reg_bus1_status         : std_logic_vector(15 downto 0) := X"001E";
  constant reg_bus1_mask           : std_logic_vector(15 downto 0) := X"001F";
  constant reg_status_rxed2        : std_logic_vector(15 downto 0) := X"0020";
  constant reg_mode_cmd_rxed2      : std_logic_vector(15 downto 0) := X"0021";
  constant reg_mode_data_rxed2     : std_logic_vector(15 downto 0) := X"0022";
  constant reg_rx_mode_cmd2        : std_logic_vector(15 downto 0) := X"0023";
  constant reg_tx_control2         : std_logic_vector(15 downto 0) := X"0024";
  constant reg_cmd_proc_start2     : std_logic_vector(15 downto 0) := X"0025";
  constant reg_cmd_proc_length2    : std_logic_vector(15 downto 0) := X"0026";
  constant reg_cmd_rxed2           : std_logic_vector(15 downto 0) := X"0027";
  constant reg_unexpected_edge_err : std_logic_vector(15 downto 0) := X"0028";
  constant reg_bus2_DatSyncErr     : std_logic_vector(15 downto 0) := X"0029";
  constant reg_bus2_CmdSyncErr     : std_logic_vector(15 downto 0) := X"002A";
  constant reg_bus2_EarlyEdgeErr   : std_logic_vector(15 downto 0) := X"002B";
  constant reg_bus2_LateEdgeErr    : std_logic_vector(15 downto 0) := X"002C";
  constant reg_bus2_ParityErr      : std_logic_vector(15 downto 0) := X"002D";
  constant reg_bus2_status         : std_logic_vector(15 downto 0) := X"002E";
  constant reg_bus2_mask           : std_logic_vector(15 downto 0) := X"002F";
  constant Timestamp3_MSB          : std_logic_vector(15 downto 0) := X"0030";
  constant Timestamp2              : std_logic_vector(15 downto 0) := X"0031";
  constant Timestamp1              : std_logic_vector(15 downto 0) := X"0032";
  constant Timestamp0_LSB          : std_logic_vector(15 downto 0) := X"0033";
  constant reg_node_control        : std_logic_vector(15 downto 0) := X"0034";
  constant reg_err_inj_data        : std_logic_vector(15 downto 0) := X"0035";
  constant reg_gID                 : std_logic_vector(15 downto 0) := X"0036";
  constant reg_fw_version          : std_logic_vector(15 downto 0) := X"0037";
  constant reg_rt_addr             : std_logic_vector(15 downto 0) := X"0038";
  constant reg_repeat_rate         : std_logic_vector(15 downto 0) := X"0039";
  constant reg_wrap_subaddr        : std_logic_vector(15 downto 0) := X"003A";
  constant reg_rt_vectorword       : std_logic_vector(15 downto 0) := X"003B";
  constant reg_rt_bit              : std_logic_vector(15 downto 0) := X"003C";
  constant reg_sw_rt_addr          : std_logic_vector(15 downto 0) := X"003D";
  constant reg_subaddr_rx_msb      : std_logic_vector(15 downto 0) := X"003E";
  constant reg_subaddr_rx_lsb      : std_logic_vector(15 downto 0) := X"003F";
  -- some generic register definitions where the MilBus can just be added to create the correct register
  constant reg_statusword_rxedX  : std_logic_vector(15 downto 0) := X"0000";
  constant reg_mode_cmd_rxedX    : std_logic_vector(15 downto 0) := X"0001";
  constant reg_mode_data_rxedX   : std_logic_vector(15 downto 0) := X"0002";
  constant reg_rx_mode_cmdX      : std_logic_vector(15 downto 0) := X"0003";
  constant reg_tx_controlX       : std_logic_vector(15 downto 0) := X"0004";
  constant reg_cmd_proc_startX   : std_logic_vector(15 downto 0) := X"0005";
  constant reg_cmd_proc_lengthX  : std_logic_vector(15 downto 0) := X"0006";
  constant reg_cmd_rxedX         : std_logic_vector(15 downto 0) := X"0007";
  constant reg_24X               : std_logic_vector(15 downto 0) := X"0008";
  constant reg_busX_DatSyncErr   : std_logic_vector(15 downto 0) := X"0009";
  constant reg_busX_CmdSyncErr   : std_logic_vector(15 downto 0) := X"000A";
  constant reg_busX_EarlyEdgeErr : std_logic_vector(15 downto 0) := X"000B";
  constant reg_busX_LateEdgeErr  : std_logic_vector(15 downto 0) := X"000C";
  constant reg_busX_ParityErr    : std_logic_vector(15 downto 0) := X"000D";
  constant reg_busX_status       : std_logic_vector(15 downto 0) := X"000E";
  constant reg_busX_mask         : std_logic_vector(15 downto 0) := X"000F";
  -- next two constants are used with the "x" defined register above
  constant MilBus1 : std_logic_vector(15 downto 0) := X"0010";
  constant MilBus2 : std_logic_vector(15 downto 0) := X"0020";

  -- bit definitions for some of the registers
  -- reg_node_control
  constant bitBusBusy             : std_logic_vector(15 downto 0) := X"8000";
  constant bitBrdcstEn            : std_logic_vector(15 downto 0) := X"4000";
  constant bitDbcEn               : std_logic_vector(15 downto 0) := X"2000";
  constant bitActiveBus           : std_logic_vector(15 downto 0) := X"1000";
  constant bitUseBcRepeat         : std_logic_vector(15 downto 0) := X"0800";
  constant bitBcRepeatStop        : std_logic_vector(15 downto 0) := X"0400";
  constant bitBcRepeatStart       : std_logic_vector(15 downto 0) := X"0200";
  constant bitEnableHwDataWrap    : std_logic_vector(15 downto 0) := X"0100";
  constant bitUse_reg_vector_word : std_logic_vector(15 downto 0) := X"0080";
  constant bitUse_reg_BIT         : std_logic_vector(15 downto 0) := X"0040";
  constant bitIS_RT               : std_logic_vector(15 downto 0) := X"0020";
  constant bitSetTerminalFlag     : std_logic_vector(15 downto 0) := X"0010";
  constant bitUseSwRtAddr         : std_logic_vector(15 downto 0) := X"0008";
  constant bitDebugRAM            : std_logic_vector(15 downto 0) := X"0004";
  constant bitRstCore2            : std_logic_vector(15 downto 0) := X"0002";
  constant bitRstCore1            : std_logic_vector(15 downto 0) := X"0001";
  -- reg_busX_status and mask
  constant bitstat_rsvd7     : std_logic_vector(15 downto 0) := X"8000";
  constant bitstat_rsvd6     : std_logic_vector(15 downto 0) := X"4000";
  constant bitstat_rsvd5     : std_logic_vector(15 downto 0) := X"2000";
  constant bitstat_rsvd4     : std_logic_vector(15 downto 0) := X"1000";
  constant bitstat_rsvd3     : std_logic_vector(15 downto 0) := X"0800";
  constant bitstat_rsvd2     : std_logic_vector(15 downto 0) := X"0400";
  constant bitstat_rsvd1     : std_logic_vector(15 downto 0) := X"0200";
  constant bitstat_rsvd0     : std_logic_vector(15 downto 0) := X"0100";
  constant bitModeCmd        : std_logic_vector(15 downto 0) := X"0080";
  constant bitDataReq        : std_logic_vector(15 downto 0) := X"0040";
  constant bitDataReceived   : std_logic_vector(15 downto 0) := X"0020";
  constant bitStatusRxedFlag : std_logic_vector(15 downto 0) := X"0010";
  constant bitSAF            : std_logic_vector(15 downto 0) := X"0008";
  constant bitREP            : std_logic_vector(15 downto 0) := X"0004";
  constant bitNRP            : std_logic_vector(15 downto 0) := X"0002";
  constant bitGAP            : std_logic_vector(15 downto 0) := X"0001";
  -- reg_tx_control1/2
  constant bitRT2RT       : std_logic_vector(15 downto 0) := X"8000";
  constant bitSendMessage : std_logic_vector(15 downto 0) := X"4000";
  -- reg_status_rxedl1/2
  constant bitRtAddr4      : std_logic_vector(15 downto 0) := X"8000";
  constant bitRtAddr3      : std_logic_vector(15 downto 0) := X"4000";
  constant bitRTAddr2      : std_logic_vector(15 downto 0) := X"2000";
  constant bitRtAddr1      : std_logic_vector(15 downto 0) := X"1000";
  constant bitRtAddr0      : std_logic_vector(15 downto 0) := X"0800";
  constant bitMessageError : std_logic_vector(15 downto 0) := X"0400";
  constant bitInstrument   : std_logic_vector(15 downto 0) := X"0200";
  constant bitServiceReq   : std_logic_vector(15 downto 0) := X"0100";
  constant bitRTAddrError  : std_logic_vector(15 downto 0) := X"0080";
  constant bitReserved6    : std_logic_vector(15 downto 0) := X"0040";
  constant bitReserved5    : std_logic_vector(15 downto 0) := X"0020";
  constant bitBrdcstRxed   : std_logic_vector(15 downto 0) := X"0010";
  constant bitBusy         : std_logic_vector(15 downto 0) := X"0008";
  constant bitSubSysFlag   : std_logic_vector(15 downto 0) := X"0004";
  constant bitDBCAcpt      : std_logic_vector(15 downto 0) := X"0002";
  constant bitTerminalFlag : std_logic_vector(15 downto 0) := X"0001";
  -- reg_rx_cmd1/2
  constant bitOtherTxOff   : std_logic_vector(15 downto 0) := X"1000";
  constant bitInhibitTF    : std_logic_vector(15 downto 0) := X"0800";
  constant bitDBC_accepted : std_logic_vector(15 downto 0) := X"0400";
  constant bitSynchronize  : std_logic_vector(15 downto 0) := X"0200";
  constant bitInitiateBIT  : std_logic_vector(15 downto 0) := X"0100";

  constant txMC_DBC             : integer := 0;  -- Mode Code for DBC transmit
  constant txMC_Synchronize     : integer := 1;  -- Mode Code for Synchronize
  constant txMC_TransmitStatus  : integer := 2;  -- Mode Code for Transmit Status
  constant txMC_InitiateBIT     : integer := 3;  -- Mode Code for Initiate BIT
  constant txMC_TxShutdown      : integer := 4;  -- Mode Code for Transmitter shutdown
  constant txMC_TxShutdownOvr   : integer := 5;  -- Mode Code for Transmitter shutdown override
  constant txMC_TerminalFlagInh : integer := 6;  -- Mode Code for Terminal Flag Inhibit
  constant txMC_TerminalFlagOvr : integer := 7;  -- Mode Code for Terminal Flag Inhibit override
  constant txMC_ResetRt         : integer := 8;  -- Mode Code for Reset RT
  constant txMC_TransmitVector  : integer := 16; -- Mode Code for Transmit Vector word
  constant txMC_TransmitLastCmd : integer := 18; -- Mode Code for Transmit Last Command
  constant txMC_TransmitBit     : integer := 19; -- Mode Code for Transmit BIT

  constant rxMC_Synchronize   : integer := 17; -- Mode Code for Synchronize
  constant rxMC_TxShutdown    : integer := 20; -- Mode Code for Selected Transmitter shutdown
  constant rxMC_TxShutdownOvr : integer := 21; -- Mode Code for Selected Transmitter shutdown override

  -- String constants for register names (max length = 23: "reg_unexpected_edge_err")
  constant s_reg_status              : string(1 to 23) := "reg_status             ";
  constant s_reg_intr_mask           : string(1 to 23) := "reg_intr_mask          ";
  constant s_reg_clear_bits          : string(1 to 23) := "reg_clear_bits         ";
  constant s_reg_tmr_1us             : string(1 to 23) := "reg_tmr_1us            ";
  constant s_reg_tmr_GAP             : string(1 to 23) := "reg_tmr_GAP            ";
  constant s_reg_tmr_NRP             : string(1 to 23) := "reg_tmr_NRP            ";
  constant s_reg_tmr_REP             : string(1 to 23) := "reg_tmr_REP            ";
  constant s_reg_tmr_SAF             : string(1 to 23) := "reg_tmr_SAF            ";
  constant s_reg_legal_subaddr1      : string(1 to 23) := "reg_legal_subaddr1     ";
  constant s_reg_legal_subaddr2      : string(1 to 23) := "reg_legal_subaddr2     ";
  constant s_reg_legal_rx_mode1      : string(1 to 23) := "reg_legal_rx_mode1     ";
  constant s_reg_legal_rx_mode2      : string(1 to 23) := "reg_legal_rx_mode2     ";
  constant s_reg_legal_tx_mode1      : string(1 to 23) := "reg_legal_tx_mode1     ";
  constant s_reg_legal_tx_mode2      : string(1 to 23) := "reg_legal_tx_mode2     ";
  constant s_reg_legal_brdcst_mode1  : string(1 to 23) := "reg_legal_brdcst_mode1 ";
  constant s_reg_legal_brdcst_mode2  : string(1 to 23) := "reg_legal_brdcst_mode2 ";
  constant s_reg_status_rxed1        : string(1 to 23) := "reg_status_rxed1       ";
  constant s_reg_mode_cmd_rxed1      : string(1 to 23) := "reg_mode_cmd_rxed1     ";
  constant s_reg_mode_data_rxed1     : string(1 to 23) := "reg_mode_data_rxed1    ";
  constant s_reg_rx_mode_cmd1        : string(1 to 23) := "reg_rx_mode_cmd1       ";
  constant s_reg_tx_control1         : string(1 to 23) := "reg_tx_control1        ";
  constant s_reg_cmd_proc_start1     : string(1 to 23) := "reg_cmd_proc_start1    ";
  constant s_reg_cmd_proc_length1    : string(1 to 23) := "reg_cmd_proc_length1   ";
  constant s_reg_cmd_rxed1           : string(1 to 23) := "reg_cmd_rxed1          ";
  constant s_reg_24                  : string(1 to 23) := "reg_24                 ";
  constant s_reg_bus1_DatSyncErr     : string(1 to 23) := "reg_bus1_DatSyncErr    ";
  constant s_reg_bus1_CmdSyncErr     : string(1 to 23) := "reg_bus1_CmdSyncErr    ";
  constant s_reg_bus1_EarlyEdgeErr   : string(1 to 23) := "reg_bus1_EarlyEdgeErr  ";
  constant s_reg_bus1_LateEdgeErr    : string(1 to 23) := "reg_bus1_LateEdgeErr   ";
  constant s_reg_bus1_ParityErr      : string(1 to 23) := "reg_bus1_ParityErr     ";
  constant s_reg_bus1_status         : string(1 to 23) := "reg_bus1_status        ";
  constant s_reg_bus1_mask           : string(1 to 23) := "reg_bus1_mask          ";
  constant s_reg_status_rxed2        : string(1 to 23) := "reg_status_rxed2       ";
  constant s_reg_mode_cmd_rxed2      : string(1 to 23) := "reg_mode_cmd_rxed2     ";
  constant s_reg_mode_data_rxed2     : string(1 to 23) := "reg_mode_data_rxed2    ";
  constant s_reg_rx_mode_cmd2        : string(1 to 23) := "reg_rx_mode_cmd2       ";
  constant s_reg_tx_control2         : string(1 to 23) := "reg_tx_control2        ";
  constant s_reg_cmd_proc_start2     : string(1 to 23) := "reg_cmd_proc_start2    ";
  constant s_reg_cmd_proc_length2    : string(1 to 23) := "reg_cmd_proc_length2   ";
  constant s_reg_cmd_rxed2           : string(1 to 23) := "reg_cmd_rxed2          ";
  constant s_reg_unexpected_edge_err : string(1 to 23) := "reg_unexpected_edge_err";
  constant s_reg_bus2_DatSyncErr     : string(1 to 23) := "reg_bus2_DatSyncErr    ";
  constant s_reg_bus2_CmdSyncErr     : string(1 to 23) := "reg_bus2_CmdSyncErr    ";
  constant s_reg_bus2_EarlyEdgeErr   : string(1 to 23) := "reg_bus2_EarlyEdgeErr  ";
  constant s_reg_bus2_LateEdgeErr    : string(1 to 23) := "reg_bus2_LateEdgeErr   ";
  constant s_reg_bus2_ParityErr      : string(1 to 23) := "reg_bus2_ParityErr     ";
  constant s_reg_bus2_status         : string(1 to 23) := "reg_bus2_status        ";
  constant s_reg_bus2_mask           : string(1 to 23) := "reg_bus2_mask          ";
  constant s_Timestamp3_MSB          : string(1 to 23) := "Timestamp3_MSB         ";
  constant s_Timestamp2              : string(1 to 23) := "Timestamp2             ";
  constant s_Timestamp1              : string(1 to 23) := "Timestamp1             ";
  constant s_Timestamp0_LSB          : string(1 to 23) := "Timestamp0_LSB         ";
  constant s_reg_node_control        : string(1 to 23) := "reg_node_control       ";
  constant s_reg_err_inj_data        : string(1 to 23) := "reg_err_inj_data       ";
  constant s_reg_gID                 : string(1 to 23) := "reg_gID                ";
  constant s_reg_fw_version          : string(1 to 23) := "reg_fw_version         ";
  constant s_reg_rt_addr             : string(1 to 23) := "reg_rt_addr            ";
  constant s_reg_repeat_rate         : string(1 to 23) := "reg_repeat_rate        ";
  constant s_reg_wrap_subaddr        : string(1 to 23) := "reg_wrap_subaddr       ";
  constant s_reg_rt_vectorword       : string(1 to 23) := "reg_rt_vectorword      ";
  constant s_reg_rt_bit              : string(1 to 23) := "reg_rt_bit             ";
  constant s_reg_sw_rt_addr          : string(1 to 23) := "reg_sw_rt_addr         ";
  constant s_reg_subaddr_rx_msb      : string(1 to 23) := "reg_subaddr_rx_msb     ";
  constant s_reg_subaddr_rx_lsb      : string(1 to 23) := "reg_subaddr_rx_lsb     ";

  -- Array of register name strings, indexed by register address (0-based)
  type reg_string_array_t is array (natural range <>) of string(1 to 23);
  constant reg_string_array : reg_string_array_t := (
    s_reg_status,
    s_reg_intr_mask,
    s_reg_clear_bits,
    s_reg_tmr_1us,
    s_reg_tmr_GAP,
    s_reg_tmr_NRP,
    s_reg_tmr_REP,
    s_reg_tmr_SAF,
    s_reg_legal_subaddr1,
    s_reg_legal_subaddr2,
    s_reg_legal_rx_mode1,
    s_reg_legal_rx_mode2,
    s_reg_legal_tx_mode1,
    s_reg_legal_tx_mode2,
    s_reg_legal_brdcst_mode1,
    s_reg_legal_brdcst_mode2,
    s_reg_status_rxed1,
    s_reg_mode_cmd_rxed1,
    s_reg_mode_data_rxed1,
    s_reg_rx_mode_cmd1,
    s_reg_tx_control1,
    s_reg_cmd_proc_start1,
    s_reg_cmd_proc_length1,
    s_reg_cmd_rxed1,
    s_reg_24,
    s_reg_bus1_DatSyncErr,
    s_reg_bus1_CmdSyncErr,
    s_reg_bus1_EarlyEdgeErr,
    s_reg_bus1_LateEdgeErr,
    s_reg_bus1_ParityErr,
    s_reg_bus1_status,
    s_reg_bus1_mask,
    s_reg_status_rxed2,
    s_reg_mode_cmd_rxed2,
    s_reg_mode_data_rxed2,
    s_reg_rx_mode_cmd2,
    s_reg_tx_control2,
    s_reg_cmd_proc_start2,
    s_reg_cmd_proc_length2,
    s_reg_cmd_rxed2,
    s_reg_unexpected_edge_err,
    s_reg_bus2_DatSyncErr,
    s_reg_bus2_CmdSyncErr,
    s_reg_bus2_EarlyEdgeErr,
    s_reg_bus2_LateEdgeErr,
    s_reg_bus2_ParityErr,
    s_reg_bus2_status,
    s_reg_bus2_mask,
    s_Timestamp3_MSB,
    s_Timestamp2,
    s_Timestamp1,
    s_Timestamp0_LSB,
    s_reg_node_control,
    s_reg_err_inj_data,
    s_reg_gID,
    s_reg_fw_version,
    s_reg_rt_addr,
    s_reg_repeat_rate,
    s_reg_wrap_subaddr,
    s_reg_rt_vectorword,
    s_reg_rt_bit,
    s_reg_sw_rt_addr,
    s_reg_subaddr_rx_msb,
    s_reg_subaddr_rx_lsb
  );
  constant c_default_reg_status : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_intr_mask : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_clear_bits : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_tmr_1us : std_logic_vector(15 downto 0) := X"0063";
  constant c_default_reg_tmr_GAP : std_logic_vector(15 downto 0) := X"018F";
  constant c_default_reg_tmr_NRP : std_logic_vector(15 downto 0) := X"0577";
  constant c_default_reg_tmr_REP : std_logic_vector(15 downto 0) := X"0195";
  constant c_default_reg_tmr_SAF : std_logic_vector(15 downto 0) := X"031F";
  constant c_default_reg_legal_subaddr1 : std_logic_vector(15 downto 0) := X"FFFF";
  constant c_default_reg_legal_subaddr2 : std_logic_vector(15 downto 0) := X"FFFF";
  constant c_default_reg_legal_rx_mode1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_legal_rx_mode2 : std_logic_vector(15 downto 0) := X"0032";
  constant c_default_reg_legal_tx_mode1 : std_logic_vector(15 downto 0) := X"01FF";
  constant c_default_reg_legal_tx_mode2 : std_logic_vector(15 downto 0) := X"000D";
  constant c_default_reg_legal_brdcst_mode1 : std_logic_vector(15 downto 0) := X"01FA";
  constant c_default_reg_legal_brdcst_mode2 : std_logic_vector(15 downto 0) := X"0032";
  constant c_default_reg_status_rxed1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_mode_cmd_rxed1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_mode_data_rxed1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_rx_mode_cmd1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_tx_control1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_cmd_proc_start1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_cmd_proc_length1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_cmd_rxed1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_24 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus1_DatSyncErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus1_CmdSyncErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus1_EarlyEdgeErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus1_LateEdgeErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus1_ParityErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus1_status : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus1_mask : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_status_rxed2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_mode_cmd_rxed2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_mode_data_rxed2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_rx_mode_cmd2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_tx_control2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_cmd_proc_start2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_cmd_proc_length2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_cmd_rxed2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_unexpected_edge_err : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus2_DatSyncErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus2_CmdSyncErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus2_EarlyEdgeErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus2_LateEdgeErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus2_ParityErr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus2_status : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_bus2_mask : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_Timestamp3_MSB : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_Timestamp2 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_Timestamp1 : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_Timestamp0_LSB : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_node_control : std_logic_vector(15 downto 0) := X"8103";
  constant c_default_reg_err_inj_data : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_gID : std_logic_vector(15 downto 0) := X"BEEF";
  constant c_default_reg_fw_version : std_logic_vector(15 downto 0) := X"0203";
  constant c_default_reg_rt_addr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_repeat_rate : std_logic_vector(15 downto 0) := X"0014";
  constant c_default_reg_wrap_subaddr : std_logic_vector(15 downto 0) := X"001E";
  constant c_default_reg_rt_vectorword : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_rt_bit : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_sw_rt_addr : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_subaddr_rx_msb : std_logic_vector(15 downto 0) := X"0000";
  constant c_default_reg_subaddr_rx_lsb : std_logic_vector(15 downto 0) := X"0000";

  -- Array of default register values, indexed by register address (0-based)
  type reg_default_array_t is array (natural range <>) of std_logic_vector(15 downto 0);
  constant reg_default_array : reg_default_array_t := (
    c_default_reg_status,
    c_default_reg_intr_mask,
    c_default_reg_clear_bits,
    c_default_reg_tmr_1us,
    c_default_reg_tmr_GAP,
    c_default_reg_tmr_NRP,
    c_default_reg_tmr_REP,
    c_default_reg_tmr_SAF,
    c_default_reg_legal_subaddr1,
    c_default_reg_legal_subaddr2,
    c_default_reg_legal_rx_mode1,
    c_default_reg_legal_rx_mode2,
    c_default_reg_legal_tx_mode1,
    c_default_reg_legal_tx_mode2,
    c_default_reg_legal_brdcst_mode1,
    c_default_reg_legal_brdcst_mode2,
    c_default_reg_status_rxed1,
    c_default_reg_mode_cmd_rxed1,
    c_default_reg_mode_data_rxed1,
    c_default_reg_rx_mode_cmd1,
    c_default_reg_tx_control1,
    c_default_reg_cmd_proc_start1,
    c_default_reg_cmd_proc_length1,
    c_default_reg_cmd_rxed1,
    c_default_reg_24,
    c_default_reg_bus1_DatSyncErr,
    c_default_reg_bus1_CmdSyncErr,
    c_default_reg_bus1_EarlyEdgeErr,
    c_default_reg_bus1_LateEdgeErr,
    c_default_reg_bus1_ParityErr,
    c_default_reg_bus1_status,
    c_default_reg_bus1_mask,
    c_default_reg_status_rxed2,
    c_default_reg_mode_cmd_rxed2,
    c_default_reg_mode_data_rxed2,
    c_default_reg_rx_mode_cmd2,
    c_default_reg_tx_control2,
    c_default_reg_cmd_proc_start2,
    c_default_reg_cmd_proc_length2,
    c_default_reg_cmd_rxed2,
    c_default_reg_unexpected_edge_err,
    c_default_reg_bus2_DatSyncErr,
    c_default_reg_bus2_CmdSyncErr,
    c_default_reg_bus2_EarlyEdgeErr,
    c_default_reg_bus2_LateEdgeErr,
    c_default_reg_bus2_ParityErr,
    c_default_reg_bus2_status,
    c_default_reg_bus2_mask,
    c_default_Timestamp3_MSB,
    c_default_Timestamp2,
    c_default_Timestamp1,
    c_default_Timestamp0_LSB,
    c_default_reg_node_control,
    c_default_reg_err_inj_data,
    c_default_reg_gID,
    c_default_reg_fw_version,
    c_default_reg_rt_addr,
    c_default_reg_repeat_rate,
    c_default_reg_wrap_subaddr,
    c_default_reg_rt_vectorword,
    c_default_reg_rt_bit,
    c_default_reg_sw_rt_addr,
    c_default_reg_subaddr_rx_msb,
    c_default_reg_subaddr_rx_lsb
  );
end package;

package body osvvm_mil1553_pkg is

end package body;
