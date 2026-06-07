	component nios_conv_usb_1553 is
		port (
			clk_clk                      : in  std_logic                     := 'X';             -- clk
			clk_50_clk                   : in  std_logic                     := 'X';             -- clk
			conv_registers_waitrequest   : in  std_logic                     := 'X';             -- waitrequest
			conv_registers_readdata      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- readdata
			conv_registers_readdatavalid : in  std_logic                     := 'X';             -- readdatavalid
			conv_registers_burstcount    : out std_logic_vector(0 downto 0);                     -- burstcount
			conv_registers_writedata     : out std_logic_vector(15 downto 0);                    -- writedata
			conv_registers_address       : out std_logic_vector(8 downto 0);                     -- address
			conv_registers_write         : out std_logic;                                        -- write
			conv_registers_read          : out std_logic;                                        -- read
			conv_registers_byteenable    : out std_logic_vector(1 downto 0);                     -- byteenable
			conv_registers_debugaccess   : out std_logic;                                        -- debugaccess
			discrete_inputs_export       : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			discrete_outputs_export      : out std_logic_vector(15 downto 0);                    -- export
			irq_export                   : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			mil1553_waitrequest          : in  std_logic                     := 'X';             -- waitrequest
			mil1553_readdata             : in  std_logic_vector(15 downto 0) := (others => 'X'); -- readdata
			mil1553_readdatavalid        : in  std_logic                     := 'X';             -- readdatavalid
			mil1553_burstcount           : out std_logic_vector(0 downto 0);                     -- burstcount
			mil1553_writedata            : out std_logic_vector(15 downto 0);                    -- writedata
			mil1553_address              : out std_logic_vector(11 downto 0);                    -- address
			mil1553_write                : out std_logic;                                        -- write
			mil1553_read                 : out std_logic;                                        -- read
			mil1553_byteenable           : out std_logic_vector(1 downto 0);                     -- byteenable
			mil1553_debugaccess          : out std_logic;                                        -- debugaccess
			reset_reset_n                : in  std_logic                     := 'X';             -- reset_n
			reset_50_reset_n             : in  std_logic                     := 'X';             -- reset_n
			uart1_waitrequest            : in  std_logic                     := 'X';             -- waitrequest
			uart1_readdata               : in  std_logic_vector(15 downto 0) := (others => 'X'); -- readdata
			uart1_readdatavalid          : in  std_logic                     := 'X';             -- readdatavalid
			uart1_burstcount             : out std_logic_vector(0 downto 0);                     -- burstcount
			uart1_writedata              : out std_logic_vector(15 downto 0);                    -- writedata
			uart1_address                : out std_logic_vector(8 downto 0);                     -- address
			uart1_write                  : out std_logic;                                        -- write
			uart1_read                   : out std_logic;                                        -- read
			uart1_byteenable             : out std_logic_vector(1 downto 0);                     -- byteenable
			uart1_debugaccess            : out std_logic;                                        -- debugaccess
			uart2_waitrequest            : in  std_logic                     := 'X';             -- waitrequest
			uart2_readdata               : in  std_logic_vector(15 downto 0) := (others => 'X'); -- readdata
			uart2_readdatavalid          : in  std_logic                     := 'X';             -- readdatavalid
			uart2_burstcount             : out std_logic_vector(0 downto 0);                     -- burstcount
			uart2_writedata              : out std_logic_vector(15 downto 0);                    -- writedata
			uart2_address                : out std_logic_vector(8 downto 0);                     -- address
			uart2_write                  : out std_logic;                                        -- write
			uart2_read                   : out std_logic;                                        -- read
			uart2_byteenable             : out std_logic_vector(1 downto 0);                     -- byteenable
			uart2_debugaccess            : out std_logic                                         -- debugaccess
		);
	end component nios_conv_usb_1553;

	u0 : component nios_conv_usb_1553
		port map (
			clk_clk                      => CONNECTED_TO_clk_clk,                      --              clk.clk
			clk_50_clk                   => CONNECTED_TO_clk_50_clk,                   --           clk_50.clk
			conv_registers_waitrequest   => CONNECTED_TO_conv_registers_waitrequest,   --   conv_registers.waitrequest
			conv_registers_readdata      => CONNECTED_TO_conv_registers_readdata,      --                 .readdata
			conv_registers_readdatavalid => CONNECTED_TO_conv_registers_readdatavalid, --                 .readdatavalid
			conv_registers_burstcount    => CONNECTED_TO_conv_registers_burstcount,    --                 .burstcount
			conv_registers_writedata     => CONNECTED_TO_conv_registers_writedata,     --                 .writedata
			conv_registers_address       => CONNECTED_TO_conv_registers_address,       --                 .address
			conv_registers_write         => CONNECTED_TO_conv_registers_write,         --                 .write
			conv_registers_read          => CONNECTED_TO_conv_registers_read,          --                 .read
			conv_registers_byteenable    => CONNECTED_TO_conv_registers_byteenable,    --                 .byteenable
			conv_registers_debugaccess   => CONNECTED_TO_conv_registers_debugaccess,   --                 .debugaccess
			discrete_inputs_export       => CONNECTED_TO_discrete_inputs_export,       --  discrete_inputs.export
			discrete_outputs_export      => CONNECTED_TO_discrete_outputs_export,      -- discrete_outputs.export
			irq_export                   => CONNECTED_TO_irq_export,                   --              irq.export
			mil1553_waitrequest          => CONNECTED_TO_mil1553_waitrequest,          --          mil1553.waitrequest
			mil1553_readdata             => CONNECTED_TO_mil1553_readdata,             --                 .readdata
			mil1553_readdatavalid        => CONNECTED_TO_mil1553_readdatavalid,        --                 .readdatavalid
			mil1553_burstcount           => CONNECTED_TO_mil1553_burstcount,           --                 .burstcount
			mil1553_writedata            => CONNECTED_TO_mil1553_writedata,            --                 .writedata
			mil1553_address              => CONNECTED_TO_mil1553_address,              --                 .address
			mil1553_write                => CONNECTED_TO_mil1553_write,                --                 .write
			mil1553_read                 => CONNECTED_TO_mil1553_read,                 --                 .read
			mil1553_byteenable           => CONNECTED_TO_mil1553_byteenable,           --                 .byteenable
			mil1553_debugaccess          => CONNECTED_TO_mil1553_debugaccess,          --                 .debugaccess
			reset_reset_n                => CONNECTED_TO_reset_reset_n,                --            reset.reset_n
			reset_50_reset_n             => CONNECTED_TO_reset_50_reset_n,             --         reset_50.reset_n
			uart1_waitrequest            => CONNECTED_TO_uart1_waitrequest,            --            uart1.waitrequest
			uart1_readdata               => CONNECTED_TO_uart1_readdata,               --                 .readdata
			uart1_readdatavalid          => CONNECTED_TO_uart1_readdatavalid,          --                 .readdatavalid
			uart1_burstcount             => CONNECTED_TO_uart1_burstcount,             --                 .burstcount
			uart1_writedata              => CONNECTED_TO_uart1_writedata,              --                 .writedata
			uart1_address                => CONNECTED_TO_uart1_address,                --                 .address
			uart1_write                  => CONNECTED_TO_uart1_write,                  --                 .write
			uart1_read                   => CONNECTED_TO_uart1_read,                   --                 .read
			uart1_byteenable             => CONNECTED_TO_uart1_byteenable,             --                 .byteenable
			uart1_debugaccess            => CONNECTED_TO_uart1_debugaccess,            --                 .debugaccess
			uart2_waitrequest            => CONNECTED_TO_uart2_waitrequest,            --            uart2.waitrequest
			uart2_readdata               => CONNECTED_TO_uart2_readdata,               --                 .readdata
			uart2_readdatavalid          => CONNECTED_TO_uart2_readdatavalid,          --                 .readdatavalid
			uart2_burstcount             => CONNECTED_TO_uart2_burstcount,             --                 .burstcount
			uart2_writedata              => CONNECTED_TO_uart2_writedata,              --                 .writedata
			uart2_address                => CONNECTED_TO_uart2_address,                --                 .address
			uart2_write                  => CONNECTED_TO_uart2_write,                  --                 .write
			uart2_read                   => CONNECTED_TO_uart2_read,                   --                 .read
			uart2_byteenable             => CONNECTED_TO_uart2_byteenable,             --                 .byteenable
			uart2_debugaccess            => CONNECTED_TO_uart2_debugaccess             --                 .debugaccess
		);

