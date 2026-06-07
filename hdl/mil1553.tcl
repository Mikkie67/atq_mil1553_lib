# mil1553_fileset.tcl
# Quartus fileset for a core where this Tcl file lives in the same folder as the VHD/QIP files

# ********************************* IMPORTANT *****************************************************************************
# The assumption is that this tcl script is in the same folder as the mil1553 vhd files (hdl folder)
# further, the assumption for the files fro mthe at_gen_lib is that the mil1553_lib is as the same level as the at_gen_lib
# ********************************* IMPORTANT *****************************************************************************

set this_dir [file dirname [info script]]

set_global_assignment -name VHDL_FILE [file join $this_dir mil1553_pkg.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mil1553_pkg_body.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir man_dec_fsm_fsm.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir ../../at_gen_lib/hdl/synchroniser_rtl.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir manchester_decoder_struct.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir manchester_encoder_fsm.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mil1553_framer_bc_fsm.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mil1553_framer_rt_fsm.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mil1553_framer_struct.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir ../../at_gen_lib/hdl/edge_detect_arc.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir ../../at_gen_lib/hdl/timer_rtl.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mill1553_timers_struct.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mil1553_singlebus_struct.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir cpu_registers_rtl.vhd] -library mil1553_lib
set_global_assignment -name QIP_FILE  [file join $this_dir ../altera_ip/ram_dp_1kx17/ram_dp_1kx17.qip] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir ../../at_gen_lib/hdl/timer_double_struct.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir repeat_timer_struct.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mil1553_cpu_interface_struct.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir select_active_bus_fsm.vhd] -library mil1553_lib
set_global_assignment -name VHDL_FILE [file join $this_dir mill1553_dualbus_struct.vhd] -library mil1553_lib
