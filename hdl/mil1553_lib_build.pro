# set the library in vsim that hte files following files will be analyzed to
# Point to the existing compiled library directory
set Mil1553NativeNvc [expr {[llength [info commands vmap]] == 0}]

if {!$Mil1553NativeNvc} {
  set Mil1553LibBuildDir [file dirname [file normalize [info script]]]
  set Mil1553ProjectRoot [file normalize [file join $Mil1553LibBuildDir ../..]]
  vmap altera_mf [file join $Mil1553ProjectRoot altera_sim_libs altera_mf]
}
library mil1553_lib
analyze mil1553_pkg.vhd
analyze mil1553_pkg_body.vhd
analyze repeat_timer_struct.vhd
analyze man_dec_fsm_fsm.vhd
analyze manchester_decoder_struct.vhd
analyze manchester_encoder_fsm.vhd
analyze mil1553_framer_bc_fsm.vhd
analyze mil1553_framer_rt_fsm.vhd
analyze mil1553_framer_struct.vhd
analyze mill1553_timers_struct.vhd 
analyze cpu_registers_rtl.vhd
if {$Mil1553NativeNvc} {
  analyze ../../sim/mil1553_ram_dp_1kx17_sim.vhd
} else {
  analyze ram_dp_1kx17.vhd
}
analyze mil1553_cpu_interface_struct.vhd
analyze mil1553_singlebus_struct.vhd
analyze select_active_bus_fsm.vhd
analyze mill1553_dualbus_struct.vhd
