#.main clear
SetVHDLVersion 2008
SetInteractiveMode true
TestSuite Mil1553

SetSimulatorResolution ns

build ../../../OsvvmLibraries/osvvm/osvvm.pro
build ../../../OsvvmLibraries/Common/Common.pro

library mil1553_lib
SetCoverageAnalyzeEnable true
analyze ../../hdl/manchester_encoder_fsm.vhd
SetCoverageAnalyzeEnable false

library mil1553_tb
analyze ../hdl/manchester_encoder_testcntrl_entity.vhd
analyze ../hdl/manchester_encoder_tb_struct.vhd

if {[llength [info commands do]]} {
  include ../../../sim/md5_portable.do ../../../at_gen_lib/hdl at_gen_lib_hdl.md
  include ../../../sim/md5_portable.do ../../hdl mil1553_lib_hdl.md
  include ../../../sim/md5_portable.do ../hdl mil1553_tb_hdl.md
}

SetCoverageSimulateEnable true

TestName mil1553_manchester_encoder_full
analyze ../hdl/mil1553_manchester_encoder_full.vhd
simulate manchester_encoder_tb_struct

SetCoverageSimulateEnable false

