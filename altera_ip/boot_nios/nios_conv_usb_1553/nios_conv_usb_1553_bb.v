
module nios_conv_usb_1553 (
	clk_clk,
	clk_50_clk,
	conv_registers_waitrequest,
	conv_registers_readdata,
	conv_registers_readdatavalid,
	conv_registers_burstcount,
	conv_registers_writedata,
	conv_registers_address,
	conv_registers_write,
	conv_registers_read,
	conv_registers_byteenable,
	conv_registers_debugaccess,
	discrete_inputs_export,
	discrete_outputs_export,
	irq_export,
	mil1553_waitrequest,
	mil1553_readdata,
	mil1553_readdatavalid,
	mil1553_burstcount,
	mil1553_writedata,
	mil1553_address,
	mil1553_write,
	mil1553_read,
	mil1553_byteenable,
	mil1553_debugaccess,
	reset_reset_n,
	reset_50_reset_n,
	uart1_waitrequest,
	uart1_readdata,
	uart1_readdatavalid,
	uart1_burstcount,
	uart1_writedata,
	uart1_address,
	uart1_write,
	uart1_read,
	uart1_byteenable,
	uart1_debugaccess,
	uart2_waitrequest,
	uart2_readdata,
	uart2_readdatavalid,
	uart2_burstcount,
	uart2_writedata,
	uart2_address,
	uart2_write,
	uart2_read,
	uart2_byteenable,
	uart2_debugaccess);	

	input		clk_clk;
	input		clk_50_clk;
	input		conv_registers_waitrequest;
	input	[15:0]	conv_registers_readdata;
	input		conv_registers_readdatavalid;
	output	[0:0]	conv_registers_burstcount;
	output	[15:0]	conv_registers_writedata;
	output	[8:0]	conv_registers_address;
	output		conv_registers_write;
	output		conv_registers_read;
	output	[1:0]	conv_registers_byteenable;
	output		conv_registers_debugaccess;
	input	[15:0]	discrete_inputs_export;
	output	[15:0]	discrete_outputs_export;
	input	[15:0]	irq_export;
	input		mil1553_waitrequest;
	input	[15:0]	mil1553_readdata;
	input		mil1553_readdatavalid;
	output	[0:0]	mil1553_burstcount;
	output	[15:0]	mil1553_writedata;
	output	[11:0]	mil1553_address;
	output		mil1553_write;
	output		mil1553_read;
	output	[1:0]	mil1553_byteenable;
	output		mil1553_debugaccess;
	input		reset_reset_n;
	input		reset_50_reset_n;
	input		uart1_waitrequest;
	input	[15:0]	uart1_readdata;
	input		uart1_readdatavalid;
	output	[0:0]	uart1_burstcount;
	output	[15:0]	uart1_writedata;
	output	[8:0]	uart1_address;
	output		uart1_write;
	output		uart1_read;
	output	[1:0]	uart1_byteenable;
	output		uart1_debugaccess;
	input		uart2_waitrequest;
	input	[15:0]	uart2_readdata;
	input		uart2_readdatavalid;
	output	[0:0]	uart2_burstcount;
	output	[15:0]	uart2_writedata;
	output	[8:0]	uart2_address;
	output		uart2_write;
	output		uart2_read;
	output	[1:0]	uart2_byteenable;
	output		uart2_debugaccess;
endmodule
