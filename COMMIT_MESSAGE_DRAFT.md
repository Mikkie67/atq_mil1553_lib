# Commit Message Draft

```text
Update MIL1553 DUT robustness and add OSVVM compliance tests

This commit updates the MIL1553 DUT for corrected compliance-test behavior,
improves VHDL/NVC portability, and adds the OSVVM-based MIL-STD-1553 test
environment used for directed, randomized, full, timing, CPU-register, and
AS4111A compliance regression runs.

Important DUT changes:
- Updated the CPU interface version generic from V5.03 to V5.04.
- Changed `reg_err_inj` from an `INOUT` style register path to a driven
  `OUT` using an internal signal, avoiding output-port readback behavior and
  improving NVC compatibility.
- Replaced several `BUFFER` output ports with `OUT` ports and internal signals
  in the Manchester decoder, single-bus wrapper, dual-bus wrapper, and timer
  wrapper. This removes VHDL constructs tolerated by Questa but rejected or
  handled more strictly by NVC.
- Added internal timer outputs in the single-bus and timer wrappers so local
  logic no longer reads directly from output ports.
- Updated the library build script to detect native NVC operation. Questa keeps
  using the mapped Altera RAM model, while native NVC uses the simulator RAM
  model from `sim/mil1553_ram_dp_1kx17_sim.vhd`.
- Removed unused `std_logic_arith` dependencies from structural wrappers.
- Added BC framer handling for the contiguous data error-injection case:
  `Err_inj(3 downto 0) = "0111"` now drives the extra data word path via the
  new `bc2SendContiguousData` state before completing the BC command flow.
- Updated BC word-count handling so error-injection cases still advance the
  word counter consistently during `bc1SendWord1`.
- Updated RT framer message-error/status handling for broadcast and decoder
  error cases:
  - decoder errors now latch the previous status with the Message Error bit set;
  - unexpected broadcast data words assert `MessageError` and update
    `PrevStatus`;
  - broadcast command context is retained in `PrevCmdWord` where required;
  - wrong-address handling explicitly clears the Message Error bit in
    `PrevStatus`;
  - obsolete intermediate state `s0` was removed and equivalent handling was
    folded into the relevant idle/gap transitions.
- Updated the HDS RT framer FSM source to match the HDL RT framer changes.

Testbench and script changes:
- Added a new OSVVM MIL1553 testbench architecture with reusable VC packages,
  command logging, dual-bus/system harnesses, Manchester decoder/encoder tests,
  timer tests, CPU-register tests, and directed/random/full protocol tests.
- Added AS4111A test controllers and `.pro` runners for:
  - 5.1.1.8.2 Power-On Response
  - 5.1.1.9 Terminal Response
  - 5.1.2.1.1 Zero Cross
  - 5.2.1.1.1 Response to Command Word
  - 5.2.1.1.2 RT-to-RT Response Command Word
  - 5.2.1.2.1 Intermessage Gap
  - 5.2.1.3 Error Injection
  - 5.2.1.4 Superseding Commands
  - 5.2.1.5 Required Mode Commands
  - 5.2.1.6 Data Wrap
  - 5.2.1.7 RT-to-RT Message Errors
  - 5.2.1.8 Bus Switching
  - 5.2.1.9 Unique Address
  - 5.2.2.1 Optional Mode Commands
  - 5.2.2.2 Status Word Bits
  - 5.2.2.4 Broadcast Mode Commands
  - 5.2.2.5 Broadcast Error Injection
- Added protocol-level regression runners for BC-to-RT, RT-to-BC, RT-to-RT,
  mode commands, Manchester codec, gap timing, timers, and CPU-interface tests.
- Replaced older monolithic/manual testbench files with the split OSVVM
  test-controller and reusable harness style.
- Added generated HDS/XRF metadata associated with the updated DUT and new
  testbench structures.

Notes:
- The NVC DUT build path expects the simulator RAM model at
  `sim/mil1553_ram_dp_1kx17_sim.vhd` in the compliance/simulation repository.
- HDS `.xrf` and `.sm` metadata changes are included to keep the graphical/HDS
  representation aligned with the HDL.
```

## Current Git Status Summary

Repository checked:

```text
/Users/ivorkruger/Dropbox/_CollaborationGit/ATQ/mil1553_lib
```

Staged change summary from `git diff --cached --stat`:

```text
144 files changed, 36810 insertions(+), 5935 deletions(-)
```

Added-file grouping:

```text
1  mil1553_tb/.gitignore
56 mil1553_tb/hdl
11 mil1553_tb/hds
42 mil1553_tb/scripts
```

Deleted legacy files:

```text
mil1553_tb/hdl/man_enc_vc_rtl.vhd
mil1553_tb/hdl/manchester_decoder_tb_struct.vhd
mil1553_tb/hdl/manchester_decoder_tester_struct.vhd
mil1553_tb/hdl/manchester_testcntrl_test1.vhd
mil1553_tb/hdl/mill1553_dualbus_tb_struct.vhd
mil1553_tb/hdl/mill1553_dualbus_tester_struct.vhd
mil1553_tb/hdl/mill1553_rt_tb_struct.vhd
mil1553_tb/hdl/mill1553_rt_tester_struct.vhd
mil1553_tb/scripts/RunTest_ManCodec.pro
```

## Added Files

```text
mil1553_tb/.gitignore
mil1553_tb/hdl/man_dec_testctrl_AS4111A_5_1_2_1_1_ZeroCross.vhd
mil1553_tb/hdl/man_dec_testctrl_entity.vhd
mil1553_tb/hdl/manchester_encoder_testcntrl_entity.vhd
mil1553_tb/hdl/manchester_vc_pkg.vhd
mil1553_tb/hdl/mil1553_bc2rt_dir.vhd
mil1553_tb/hdl/mil1553_bc2rt_full.vhd
mil1553_tb/hdl/mil1553_bc2rt_rnd.vhd
mil1553_tb/hdl/mil1553_core_vc_rtl.vhd
mil1553_tb/hdl/mil1553_cpu_interface.vhd
mil1553_tb/hdl/mil1553_cpu_registers_testctrl_entity.vhd
mil1553_tb/hdl/mil1553_gap_timing_dir.vhd
mil1553_tb/hdl/mil1553_manchester_decoder_dir.vhd
mil1553_tb/hdl/mil1553_manchester_encoder_full.vhd
mil1553_tb/hdl/mil1553_mode_dir.vhd
mil1553_tb/hdl/mil1553_rt2bc_dir.vhd
mil1553_tb/hdl/mil1553_rt2bc_full.vhd
mil1553_tb/hdl/mil1553_rt2bc_rnd.vhd
mil1553_tb/hdl/mil1553_rt2rt_dir.vhd
mil1553_tb/hdl/mil1553_rt2rt_full.vhd
mil1553_tb/hdl/mil1553_rt2rt_rnd.vhd
mil1553_tb/hdl/mil1553_tb_build.pro
mil1553_tb/hdl/mil1553_timers.vhd
mil1553_tb/hdl/mill1553_timers_tb_struct.vhd
mil1553_tb/hdl/mill1553_timers_testcntrl_entity.vhd
mil1553_tb/hdl/osvvm_command_logger_pkg.vhd
mil1553_tb/hdl/osvvm_manchester_decoder_tb_struct.vhd
mil1553_tb/hdl/osvvm_mil1553_cpu_registers_tb_struct.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_tb_pkg.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_tb_struct.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_1_1_8_2_PwrOnResponse.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_1_1_9_TerminalResponse.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_1_ResponseToCmdWord.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_1_ResponseToCmdWord_DIR.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_2_RT2RTRespCmdWord.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_1_2_RT2RTRespCmdWord_DIR.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_2_1_InterMsgGap.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_3_ErrorInjection.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_4_SupersedingCommands.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_5_ReqModeCommands.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_6_Datawrap.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_7_RT2RTMsgErrors.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_8_BusSwitching.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_1_9_Unique_Address.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_1_OptModeCommands.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_2_StatusWordBits.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_4_BroadcastModeCommands.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_AS4111A_5_2_2_5_BrdCstErrorInjection.vhd
mil1553_tb/hdl/osvvm_mil1553_dualbus_testctrl_entity.vhd
mil1553_tb/hdl/osvvm_mil1553_pkg.vhd
mil1553_tb/hdl/osvvm_mil1553_testcntrl_bc2rt_pkg.vhd
mil1553_tb/hdl/osvvm_mil1553_testcntrl_component_pkg.vhd
mil1553_tb/hdl/osvvm_mil1553_testcntrl_mode_pkg.vhd
mil1553_tb/hdl/osvvm_mil1553_testcntrl_rt2bc_pkg.vhd
mil1553_tb/hdl/osvvm_mil1553_testcntrl_rt2rt_pkg.vhd
mil1553_tb/hdl/test_man_dec_fsm_fsm2.vhd
mil1553_tb/hdl/test_man_dec_struct.vhd
mil1553_tb/hds/.xrf/manchester_decoder_testctrl_entity.xrf
mil1553_tb/hds/.xrf/manchester_encoder_tb_struct.xrf
mil1553_tb/hds/.xrf/mill1553_timers_tb_struct.xrf
mil1553_tb/hds/.xrf/osvvm_manchester_decoder_tb_entity.xrf
mil1553_tb/hds/.xrf/osvvm_manchester_decoder_tb_struct.xrf
mil1553_tb/hds/.xrf/osvvm_mil1553_cpu_registers_tb_struct.xrf
mil1553_tb/hds/.xrf/osvvm_mill1553_dualbus_testctrl_entity.xrf
mil1553_tb/hds/.xrf/rt2bc_flow_flow.xrf
mil1553_tb/hds/.xrf/test_man_dec_fsm_fsm2.xrf
mil1553_tb/hds/.xrf/test_man_dec_struct.xrf
mil1553_tb/hds/.xrf/test_man_dec_tb_struct.xrf
mil1553_tb/scripts/RunTest10.pro
mil1553_tb/scripts/RunTest_AS4111A_5_1_1_8_2_PwrOnResponse.pro
mil1553_tb/scripts/RunTest_AS4111A_5_1_1_9_TerminalResponse.pro
mil1553_tb/scripts/RunTest_AS4111A_5_1_2_1_1_ZeroCross.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_1_1_ResponseToCmdWord.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_1_1_ResponseToCmdWord_DIR.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_1_2_RT2RTRespCmdWord.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_1_2_RT2RTRespCmdWord_DIR.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_2_1_InterMsgGap.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_3_ErrorInjection.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_4_SupersedingCommands.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_5_ReqModeCommands.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_6_Datawrap.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_7_RT2RTMsgErrors.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_8_BusSwitching.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_1_9_Unique_Address.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_2_1_OptModeCommands.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_2_2_StatusWordBits.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_2_4_BroadcastModeCommands.pro
mil1553_tb/scripts/RunTest_AS4111A_5_2_2_5_BrdCstErrorInjection.pro
mil1553_tb/scripts/RunTest_AS4111A_NVC_dualbus_setup.pro
mil1553_tb/scripts/RunTest_AS4111A_NVC_mandec_setup.pro
mil1553_tb/scripts/mil1553_bc2rt_all.pro
mil1553_tb/scripts/mil1553_bc2rt_dir.pro
mil1553_tb/scripts/mil1553_bc2rt_full.pro
mil1553_tb/scripts/mil1553_bc2rt_rnd.pro
mil1553_tb/scripts/mil1553_cpu_interface.pro
mil1553_tb/scripts/mil1553_gap_timing_dir.pro
mil1553_tb/scripts/mil1553_lib_hdl.md
mil1553_tb/scripts/mil1553_manchester_decoder_dir.pro
mil1553_tb/scripts/mil1553_manchester_encoder_full.pro
mil1553_tb/scripts/mil1553_mode_dir.pro
mil1553_tb/scripts/mil1553_rt2bc_all.pro
mil1553_tb/scripts/mil1553_rt2bc_dir.pro
mil1553_tb/scripts/mil1553_rt2bc_full.pro
mil1553_tb/scripts/mil1553_rt2bc_rnd.pro
mil1553_tb/scripts/mil1553_rt2rt_all.pro
mil1553_tb/scripts/mil1553_rt2rt_dir.pro
mil1553_tb/scripts/mil1553_rt2rt_full.pro
mil1553_tb/scripts/mil1553_rt2rt_rnd.pro
mil1553_tb/scripts/mil1553_tb_hdl.md
mil1553_tb/scripts/mil1553_timers.pro
```
