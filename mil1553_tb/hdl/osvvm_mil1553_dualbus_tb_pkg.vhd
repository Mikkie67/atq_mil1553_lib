context mil1553_context is
  library osvvm_common;
  context osvvm_common.OsvvmCommonContext; -- Address Bus Transactions

  library mil1553_tb;
    use mil1553_tb.CommandLoggerPkg.all; -- Command Logger Package
    use mil1553_tb.manchester_vc_pkg.all; -- Manchester Encoding/Decoding Package
    use mil1553_tb.osvvm_mil1553_pkg.all; -- General constants and register addresses
    use mil1553_tb.osvvm_mil1553_testcntrl_component_pkg.all; -- Test Control Component Package
    use mil1553_tb.osvvm_mil1553_testcntrl_bc2rt_pkg.all;
    use mil1553_tb.osvvm_mil1553_testcntrl_rt2bc_pkg.all;
    use mil1553_tb.osvvm_mil1553_testcntrl_rt2rt_pkg.all;
    use mil1553_tb.osvvm_mil1553_testcntrl_mode_pkg.all;
    use mil1553_tb.osvvm_mil1553_pkg.all; -- General constants and register addresses

end context;
