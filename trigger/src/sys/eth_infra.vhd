library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.ipbus.all;

entity eth_infra is
  generic(
    C_DEBUG : boolean := false
    );
  port (

    clock : in std_logic;
    reset : in std_logic;

    gtx_clk   : in std_logic;           -- 125MHz
    gtx_clk90 : in std_logic;

    -- RGMII interface
    rgmii_rx_clk : in  std_logic;
    rgmii_rxd    : in  std_logic_vector(3 downto 0);
    rgmii_rx_ctl : in  std_logic;
    rgmii_tx_clk : out std_logic;
    rgmii_txd    : out std_logic_vector(3 downto 0);
    rgmii_tx_ctl : out std_logic;

    mac_addr : in std_logic_vector(47 downto 0);  -- MAC address
    ip_addr  : in std_logic_vector(31 downto 0);  -- IP address

    -- IPbus (from / to slaves)
    ipb_in  : in  ipb_rbus;
    ipb_out : out ipb_wbus
    );
end eth_infra;


architecture rtl of eth_infra is

  component eth_mac_1g_rgmii_fifo
    generic (
      -- target ("SIM", "GENERIC", "XILINX", "ALTERA")
      TARGET            : string;
      -- IODDR style ("IODDR"; "IODDR2")
      -- Use IODDR for Virtex-4; Virtex-5; Virtex-6; 7 Series; Ultrascale
      -- Use IODDR2 for Spartan-6
      IODDR_STYLE       : string;
      -- Clock input style ("BUFG"; "BUFR"; "BUFIO"; "BUFIO2")
      -- Use BUFR for Virtex-6; 7-series
      -- Use BUFG for Virtex-5; Spartan-6; Ultrascale
      -- anything else just passes the rx clock through,
      -- for pre-buffered clocks
      CLOCK_INPUT_STYLE : string;
      -- Use 90 degree clock for RGMII transmit ("TRUE"; "FALSE")
      USE_CLK90         : string;
      ENABLE_PADDING    : integer;
      MIN_FRAME_LENGTH  : integer
      );
    port (
      gtx_clk   : in  std_logic;
      gtx_clk90 : in  std_logic;
      gtx_rst   : in  std_logic;

      logic_clk :  in  std_logic;
      logic_rst :  in  std_logic;

      -- AXI input
      tx_axis_tdata  : in  std_logic_vector(7 downto 0);
      tx_axis_tkeep  : in  std_logic;
      tx_axis_tvalid : in  std_logic;
      tx_axis_tready : out std_logic;
      tx_axis_tlast  : in  std_logic;
      tx_axis_tuser  : in  std_logic;

      -- AXI output
      rx_axis_tdata  : out std_logic_vector(7 downto 0);
      rx_axis_tkeep  : out std_logic;
      rx_axis_tvalid : out std_logic;
      rx_axis_tready : in  std_logic;
      rx_axis_tlast  : out std_logic;
      rx_axis_tuser  : out std_logic;

      -- RGMII interface
      rgmii_rx_clk : in  std_logic;
      rgmii_rxd    : in  std_logic_vector(3 downto 0);
      rgmii_rx_ctl : in  std_logic;
      rgmii_tx_clk : out std_logic;
      rgmii_txd    : out std_logic_vector(3 downto 0);
      rgmii_tx_ctl : out std_logic;

      -- Status
      tx_error_underflow : out std_logic;
      rx_error_bad_frame : out std_logic;
      rx_error_bad_fcs   : out std_logic;
      speed              : out std_logic_vector(1 downto 0);

      -- Configuration
      ifg_delay : in std_logic_vector (7 downto 0)
      );
  end component;

  signal rx_clk : std_logic;
  signal rx_rst : std_logic;

  signal tx_clk : std_logic;
  signal tx_rst : std_logic;

  signal tx_axis_tdata  : std_logic_vector(7 downto 0);
  signal tx_axis_tvalid : std_logic;
  signal tx_axis_tready : std_logic;
  signal tx_axis_tlast  : std_logic;
  signal tx_axis_tuser  : std_logic;
  signal rx_axis_tdata  : std_logic_vector(7 downto 0);
  signal rx_axis_tvalid : std_logic;
  signal rx_axis_tlast  : std_logic;
  signal rx_axis_tuser  : std_logic;

  signal tx_error_underflow : std_logic := '0';
  signal rx_error_bad_frame : std_logic := '0';
  signal rx_error_bad_fcs   : std_logic := '0';
  signal speed              : std_logic_vector(1 downto 0);
  signal ifg_delay          : std_logic_vector (7 downto 0);

  signal gtx_rst_r0, gtx_rst_r1, gtx_rst_r2 : std_logic := '1';
  signal gtx_rst                            : std_logic := '1';

  attribute shreg_extract : string;
  attribute shreg_extract of gtx_rst_r0 : signal is "false";
  attribute shreg_extract of gtx_rst_r1 : signal is "false";
  attribute shreg_extract of gtx_rst_r2 : signal is "false";
  attribute shreg_extract of gtx_rst    : signal is "false";

begin

  process (gtx_clk) is
  begin
    if (rising_edge(gtx_clk)) then
      gtx_rst_r0 <= reset;
      gtx_rst_r1 <= gtx_rst_r0;
      gtx_rst_r2 <= gtx_rst_r1;
      gtx_rst    <= gtx_rst_r2;
    end if;
  end process;
  eth_mac_1g_rgmii_inst : eth_mac_1g_rgmii_fifo
    generic map (
      TARGET            => "XILINX",
      IODDR_STYLE       => "IODDR",
      CLOCK_INPUT_STYLE => "BUFR",
      USE_CLK90         => "TRUE",
      ENABLE_PADDING    => 1,
      MIN_FRAME_LENGTH  => 64
      )
    port map (

      gtx_clk   => gtx_clk,
      gtx_clk90 => gtx_clk90,
      gtx_rst   => gtx_rst,

      logic_clk => clock,
      logic_rst => reset,

      -- tx_axis_tkeep  => (others => '0'),
      tx_axis_tdata  => tx_axis_tdata,
      tx_axis_tvalid => tx_axis_tvalid,
      tx_axis_tready => tx_axis_tready,
      tx_axis_tlast  => tx_axis_tlast,
      tx_axis_tuser  => tx_axis_tuser,
      tx_axis_tkeep  => '0',

      rx_axis_tdata  => rx_axis_tdata,
      rx_axis_tvalid => rx_axis_tvalid,
      rx_axis_tlast  => rx_axis_tlast,
      rx_axis_tuser  => rx_axis_tuser,
      rx_axis_tready => '1',
      rx_axis_tkeep  => open,

      rgmii_rx_clk => rgmii_rx_clk,
      rgmii_rxd    => rgmii_rxd,
      rgmii_rx_ctl => rgmii_rx_ctl,

      rgmii_tx_clk => rgmii_tx_clk,
      rgmii_txd    => rgmii_txd,
      rgmii_tx_ctl => rgmii_tx_ctl,

      tx_error_underflow => open,
      rx_error_bad_frame => open,
      rx_error_bad_fcs   => open,
      speed              => open,
      ifg_delay          => std_logic_vector(to_unsigned(12, 8))
      );


  ipbus_inst : entity work.ipbus_ctrl
    port map(
      mac_clk    => clock,
      rst_macclk => reset,
      ipb_clk    => clock,
      rst_ipb    => reset,

      mac_rx_data  => rx_axis_tdata,
      mac_rx_valid => rx_axis_tvalid,
      mac_rx_last  => rx_axis_tlast,
      mac_rx_error => rx_error_bad_frame or rx_error_bad_fcs,
      mac_tx_data  => tx_axis_tdata,
      mac_tx_valid => tx_axis_tvalid,
      mac_tx_last  => tx_axis_tlast,
      mac_tx_error => tx_error_underflow,
      mac_tx_ready => tx_axis_tready,
      ipb_out      => ipb_out,
      ipb_in       => ipb_in,
      mac_addr     => mac_addr,
      ip_addr      => ip_addr,
      pkt          => open
      );

end rtl;
