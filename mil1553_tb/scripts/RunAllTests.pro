#  File Name:         RunAllTests.pro
#  Revision:          STANDARD VERSION
#
#        Script to compile the MIL1553 models  
#
#  Revision History:
#    Date      Version    Description
#write format wave -window .main_pane.wave.interior.cs.body.pw.wf C:/_ComplianceTesting/sim/wave.do
#.main clear
#SetInteractiveMode true
SetSimulatorOptions "-c -voptargs=-O5 -access +r"
SetVsimOpt "-c -voptargs=-O5 -access +r -onfinish stop -quiet"
SetSimulatorResolution ns

TestSuite Mil1553
include ../../../at_gen_lib/hdl/at_gen_lib_build.pro

SetCoverageAnalyzeEnable true
include ../../hdl/mil1553_lib_build.pro
SetCoverageAnalyzeEnable false

include ../hdl/mil1553_tb_build.pro

SetCoverageSimulateEnable true

#TestName Test1_BC2RT_DIR
#analyze ../hdl/osvvm_mil1553_dualbus_testctrl_test1_DIR.vhd
#simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

#TestName Test2_RT2BC_DIR
#analyze ../hdl/osvvm_mil1553_dualbus_testctrl_test2_DIR.vhd
#simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

#TestName Test3_RT2RT_DIR
#analyze ../hdl/osvvm_mil1553_dualbus_testctrl_test3_DIR.vhd
#simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName Test9_CPU_IF
analyze ../hdl/mil1553_cpu_registers_testctrl_Test9_CPU_IF.vhd
simulate mil1553_tb.osvvm_mil1553_cpu_registers_tb_struct

TestName AS4111A_5_1_1_8_2_PwrOnResponse
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_1_1_8_2_PwrOnResponse.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_1_1_9_TerminalResponse
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_1_1_9_TerminalResponse.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_1_2_1_1_ZeroCross
analyze ../hdl/man_dec_testctrl_AS4111A_5_1_2_1_1_ZeroCross.vhd
simulate mil1553_tb.osvvm_manchester_decoder_tb_struct 


TestName AS4111A_5_2_1_1_1_ResponseToCmdWord
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_1_ResponseToCmdWord.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_1_2_RT2RTRespCmdWord
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_2_RT2RTRespCmdWord.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_2_1_InterMsgGap
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_2_1_InterMsgGap.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_3_ErrorInjection
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_3_ErrorInjection.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_4_SupersedingCommands
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_4_SupersedingCommands.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_5_ReqModeCommands
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_5_ReqModeCommands.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_6_Datawrap
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_6_Datawrap.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_7_RT2RTMsgErrors
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_7_RT2RTMsgErrors.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_8_BusSwitching
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_8_BusSwitching.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_1_9_Unique_Address
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_9_Unique_Address.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_2_1_OptModeCommands
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_1_OptModeCommands.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_2_2_StatusWordBits
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_2_StatusWordBits.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName AS4111A_5_2_2_4_BroadcastModeCommands
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_4_BroadcastModeCommands.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 


#include RunTest1.pro
#include RunTest2.pro
#include RunTest3.pro
#include RunTest4.pro

SetCoverageSimulateEnable false