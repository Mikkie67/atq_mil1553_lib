# Shared NVC setup for individual AS4111A Manchester decoder tests.
SetVHDLVersion 2008
SetSimulatorResolution ns
SetInteractiveMode true
TestSuite Mil1553

build ../../../OsvvmLibraries/osvvm/osvvm.pro
build ../../../OsvvmLibraries/Common/Common.pro

library at_gen_lib
analyze ../../../at_gen_lib/hdl/AT_Gen_Lib_pkg.vhd
analyze ../../../at_gen_lib/hdl/synchroniser_rtl.vhd

library mil1553_lib
SetCoverageAnalyzeEnable true
analyze ../../hdl/man_dec_fsm_fsm.vhd
analyze ../../hdl/manchester_decoder_struct.vhd
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
analyze ../hdl/man_dec_testctrl_entity.vhd
analyze ../hdl/man_dec_vc_rtl.vhd
analyze ../hdl/test_man_dec_fsm_fsm2.vhd
analyze ../hdl/test_man_dec_struct.vhd
analyze ../hdl/osvvm_manchester_decoder_tb_struct.vhd

SetCoverageSimulateEnable true
