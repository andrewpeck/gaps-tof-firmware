library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ipbus is

  constant IPB_MASTERS      : integer := 1;
  constant IPB_SLAVES       : integer := 3;
  constant C_NUM_IPB_SLAVES : integer := IPB_SLAVES;

  constant IPB_ADDR_SIZE : integer := 32;

  -- Wishbone options

  constant IPB_TIMEOUT : integer := 200_000;

  -- Wishbone errors

  constant IPB_NO_ERR : std_logic_vector(3 downto 0) := x"0";

  constant IPB_ERR_BUS     : std_logic_vector(3 downto 0) := x"D";
  constant IPB_ERR_SLAVE   : std_logic_vector(3 downto 0) := x"E";
  constant IPB_ERR_TIMEOUT : std_logic_vector(3 downto 0) := x"F";

  constant IPB_ERR_I2C_CHIPID : std_logic_vector(3 downto 0) := x"1";
  constant IPB_ERR_I2C_REG    : std_logic_vector(3 downto 0) := x"2";
  constant IPB_ERR_I2C_ACK    : std_logic_vector(3 downto 0) := x"3";

  -- IPbus slave index definition

  -- START: IPBUS_SLAVES :: DO NOT EDIT
    type t_ipb_slv is record
                     MT   : integer;
                    SPI   : integer;
                    I2C   : integer;
    end record;
    -- IPbus slave index definition
    constant IPB_SLAVE : t_ipb_slv := (
                     MT  => 0,
                    SPI  => 1,
                    I2C  => 2    );
  -- END: IPBUS_SLAVES :: DO NOT EDIT

  constant IPB_REQ_BITS : integer := 49;

-- The signals going from master to slaves
  type ipb_wbus is
  record
    ipb_addr   : std_logic_vector(IPB_ADDR_SIZE - 1 downto 0);
    ipb_wdata  : std_logic_vector(31 downto 0);
    ipb_strobe : std_logic;
    ipb_write  : std_logic;
  end record;

  type ipb_wbus_array is array(natural range <>) of ipb_wbus;

-- The signals going from slaves to master
  type ipb_rbus is
  record
    ipb_rdata : std_logic_vector(31 downto 0);
    ipb_ack   : std_logic;
    ipb_err   : std_logic;
  end record;

  type ipb_rbus_array is array(natural range <>) of ipb_rbus;

  constant IPB_RBUS_NULL : ipb_rbus := ((others => '0'), '0', '0');
  constant IPB_WBUS_NULL : ipb_wbus := ((others => '0'), (others => '0'), '0', '0');

  function ipb_addr_sel(signal addr : in std_logic_vector(IPB_ADDR_SIZE-1 downto 0)) return integer;

  type ipb_mac_cfg is (EXTERNAL, INTERNAL);
  type ipb_ip_cfg is (EXTERNAL, INTERNAL);

end ipbus;

package body ipbus is

  --== Address decoder ==--

  function ipb_addr_sel(signal addr : in std_logic_vector(IPB_ADDR_SIZE-1 downto 0)) return integer is
    variable sel : integer;
  begin

    -- lowest  bits are used by the wishbone splitters as individual register addresses
    -- highest are used as the module ID (wishbone slave #)

    -- START: IPBUS_ADDR_SEL :: DO NOT EDIT
        if   (std_match(addr(15 downto 0), std_logic_vector(to_unsigned(IPB_SLAVE.             MT,     4))  & "------------")) then sel := IPB_SLAVE.MT;
        elsif(std_match(addr(15 downto 0), std_logic_vector(to_unsigned(IPB_SLAVE.            SPI,     4))  & "------------")) then sel := IPB_SLAVE.SPI;
        elsif(std_match(addr(15 downto 0), std_logic_vector(to_unsigned(IPB_SLAVE.            I2C,     4))  & "------------")) then sel := IPB_SLAVE.I2C;
    -- END: IPBUS_ADDR_SEL :: DO NOT EDIT
    else sel                                                                                                     := 99;
    end if;

    return sel;
  end ipb_addr_sel;

end ipbus;
