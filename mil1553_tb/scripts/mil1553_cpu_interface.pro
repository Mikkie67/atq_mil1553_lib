#  File Name:         mil1553_all_suite.pro
#  Revision:          STANDARD VERSION
#
#        Script to compile the MIL1553 models  
#
#  Revision History:
#    Date      Version    Description
#write format wave -window .main_pane.wave.interior.cs.body.pw.wf C:/_ComplianceTesting/sim/wave.do
#.main clear
SetInteractiveMode true
TestSuite Mil1553
#include ../../../at_gen_lib/hdl/at_gen_lib_build.pro

#SetCoverageAnalyzeEnable true
include ../../hdl/mil1553_lib_build.pro
#SetCoverageAnalyzeEnable false

include ../hdl/mil1553_tb_build.pro

SetCoverageSimulateEnable true

TestName mil1553_cpu_interface
analyze ../hdl/mil1553_cpu_interface.vhd
simulate mil1553_tb.osvvm_mil1553_cpu_registers_tb_struct

SetCoverageSimulateEnable false

