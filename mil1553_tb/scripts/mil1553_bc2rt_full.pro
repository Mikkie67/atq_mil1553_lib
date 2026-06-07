#  File Name:         mil1553_all_suite.pro
#  Revision:          STANDARD VERSION
#
#        Script to compile the MIL1553 models  
#
#  Revision History:
#    Date      Version    Description
#write format wave -window .main_pane.wave.interior.cs.body.pw.wf C:/_ComplianceTesting/sim/wave.do
SetVHDLVersion 2008
SetSimulatorResolution ns
SetInteractiveMode true
TestSuite Mil1553

build ../../../OsvvmLibraries/osvvm/osvvm.pro
build ../../../OsvvmLibraries/Common/Common.pro
build ../../../at_gen_lib/hdl/at_gen_lib_build.pro

SetCoverageAnalyzeEnable true
include ../../hdl/mil1553_lib_build.pro
SetCoverageAnalyzeEnable false

catch {RemoveLibrary mil1553_tb}
if {[info exists ::osvvm::VhdlLibraryFullPath] && [info exists ::osvvm::VhdlShortVersion]} {
  file delete -force [file join $::osvvm::VhdlLibraryFullPath MIL1553_TB.$::osvvm::VhdlShortVersion]
}
library mil1553_tb
analyze ../hdl/osvvm_command_logger_pkg.vhd
analyze ../hdl/osvvm_mil1553_pkg.vhd
analyze ../hdl/manchester_vc_pkg.vhd
analyze ../hdl/osvvm_mil1553_testcntrl_component_pkg.vhd
analyze ../hdl/osvvm_mil1553_testcntrl_bc2rt_pkg.vhd
analyze ../hdl/osvvm_mil1553_testcntrl_rt2bc_pkg.vhd
analyze ../hdl/osvvm_mil1553_testcntrl_rt2rt_pkg.vhd
analyze ../hdl/osvvm_mil1553_testcntrl_mode_pkg.vhd
analyze ../hdl/osvvm_mil1553_dualbus_tb_pkg.vhd
analyze ../hdl/mil1553_core_vc_rtl.vhd
analyze ../hdl/osvvm_mil1553_dualbus_testctrl_entity.vhd
analyze ../hdl/osvvm_mil1553_dualbus_tb_struct.vhd

SetCoverageSimulateEnable true

TestName mil1553_bc2rt_full
analyze ../hdl/mil1553_bc2rt_full.vhd
simulate osvvm_mil1553_dualbus_tb_struct 

SetCoverageSimulateEnable false
