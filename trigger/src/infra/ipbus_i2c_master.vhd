-- ipbus_i2c_master
--
-- Wrapper for opencores i2c wishbone slave
--
-- Dave Newbold, Jan 2012
-- Fixed by ap 2023

library ieee;
use ieee.std_logic_1164.all;
use work.ipbus.all;

library unisim;
use unisim.vcomponents.all;

entity ipbus_i2c_master is
  port(
    clk : in std_logic;
    rst : in std_logic;

    ipb_in  : in  ipb_wbus;
    ipb_out : out ipb_rbus;

    scl_pad : inout std_logic;
    sda_pad : inout std_logic

    );

end ipbus_i2c_master;

architecture rtl of ipbus_i2c_master is

  signal stb, ack : std_logic;

  signal scl_pad_i  : std_logic;
  signal scl_pad_o  : std_logic;
  signal scl_padoen : std_logic;
  signal sda_pad_i  : std_logic;
  signal sda_pad_o  : std_logic;
  signal sda_padoen : std_logic;

begin


  scl_3st : IOBUF
    port map(
      T  => not scl_padoen,
      I  => scl_pad_o,
      O  => scl_pad_i,
      IO => scl_pad
      );

  sda_3st : IOBUF
    port map(
      T  => not sda_padoen,
      I  => sda_pad_o,
      O  => sda_pad_i,
      IO => sda_pad
      );

  stb <= ipb_in.ipb_strobe and not ack;

  i2c : entity work.i2c_master_top port map(
    wb_clk_i     => clk,
    wb_rst_i     => rst,
    arst_i       => '1',
    wb_adr_i     => ipb_in.ipb_addr(2 downto 0),
    wb_dat_i     => ipb_in.ipb_wdata(7 downto 0),
    wb_dat_o     => ipb_out.ipb_rdata(7 downto 0),
    wb_we_i      => ipb_in.ipb_write,
    wb_stb_i     => stb,
    wb_cyc_i     => '1',
    wb_ack_o     => ack,
    scl_pad_i    => scl_pad_i,          -- serial clock line input
    scl_pad_o    => scl_pad_o,          -- serial clock line output
    scl_padoen_o => scl_padoen,         -- serial clock line output enable
    sda_pad_i    => sda_pad_i,
    sda_pad_o    => sda_pad_o,
    sda_padoen_o => sda_padoen

    );

  ipb_out.ipb_rdata(31 downto 8) <= (others => '0');
  ipb_out.ipb_ack                <= ack;
  ipb_out.ipb_err                <= '0';

end rtl;
