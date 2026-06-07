#  File Name:         mil1553_all_suite.pro
#  Revision:          STANDARD VERSION
#
#        Script to compile the MIL1553 models  
#
#  Revision History:
#    Date      Version    Description
#write format wave -window .main_pane.wave.interior.cs.body.pw.wf C:/_ComplianceTesting/sim/wave.do
SetSimulatorResolution ns

TestSuite Mil1553

SetCoverageAnalyzeEnable true
include ../../hdl/mil1553_lib_build.pro
SetCoverageAnalyzeEnable false

include ../hdl/mil1553_tb_build.pro

SetCoverageSimulateEnable true

TestName mil1553_rt2bc_dir
analyze ../hdl/mil1553_rt2bc_dir.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName mil1553_rt2bc_rnd
analyze ../hdl/mil1553_rt2bc_rnd.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

TestName mil1553_rt2bc_full
analyze ../hdl/mil1553_rt2bc_full.vhd
simulate mil1553_tb.osvvm_mil1553_dualbus_tb_struct 

SetCoverageSimulateEnable false

