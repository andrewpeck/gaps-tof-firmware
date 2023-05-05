----------------------------------------------------------------------------------
-- GAPS Time of Flight
-- A. Peck
-- Trigger Rx
----------------------------------------------------------------------------------
-- Serializes a trigger link from MT to RB
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity rb_tx is
  generic(
    EVENTCNTB  : natural := 32;
    MASKCNTB   : natural := 8;
    CMDB       : natural := 2;
    CRCB       : natural := 8;
    MANCHESTER : boolean := true
    );
  port(

    clock    : in  std_logic;
    reset    : in  std_logic;
    serial_o : out std_logic;

    resync_i : in std_logic;

    trg_i : in std_logic;

    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0);
    ch_mask_i   : in std_logic_vector (MASKCNTB-1 downto 0)

    );
end rb_tx;

architecture rtl of rb_tx is

  constant LENGTH : natural := CRCB + CMDB + EVENTCNTB + MASKCNTB + 1;

  type state_t is (IDLE_state, DATA_state);
  signal state         : state_t   := IDLE_state;
  signal state_bit_cnt : natural   := 0;
  signal trg           : std_logic := '0';

  signal packet_buf : std_logic_vector (LENGTH-1 downto 0) := (others => '0');

  signal serial_data : std_logic := '0';

  signal cmd : std_logic_vector(CMDB-1 downto 0);

  signal crc_en  : std_logic                          := '0';
  signal crc_rst : std_logic                          := '0';
  signal crc     : std_logic_vector (CRCB-1 downto 0) := (others => '0');

begin

  process (resync_i) is
  begin
    if (resync_i = '1') then
      cmd <= "11";
    else
      cmd <= "00";
    end if;
  end process;

  crc_rst <= '1' when state = IDLE_state or reset = '1' else '0';

  crc_inst : entity work.crc
    port map (
      data_in => packet_buf(packet_buf'length-1 downto 8),
      crc_en  => crc_en,
      rst     => crc_rst,
      clk     => clock,
      crc_out => crc
      );

  process (clock)
  begin

    if (rising_edge(clock)) then

      serial_data <= '0';
      crc_en      <= '0';

      case state is

        when IDLE_state =>

          state_bit_cnt <= 0;

          if (trg_i = '1') then
            serial_data <= '1';
            state       <= DATA_state;
            packet_buf  <= or_reduce(ch_mask_i) & ch_mask_i & event_cnt_i & cmd & x"00";
            crc_en      <= '1';
          end if;

        when DATA_state =>

          packet_buf(7 downto 0) <= crc;

          if (state_bit_cnt = LENGTH - 1) then
            state         <= IDLE_state;
            state_bit_cnt <= 0;
          else
            state_bit_cnt <= state_bit_cnt + 1;
          end if;

          serial_data <= packet_buf(LENGTH-1-state_bit_cnt);

      end case;

      if (reset = '1') then
        state <= IDLE_state;
      end if;

    end if;
  end process;

  gen_manchester : if (MANCHESTER) generate
    serial_o <= serial_data xor clock;
  end generate;

  gen_nomanchester : if (not MANCHESTER) generate
    serial_o <= serial_data;
  end generate;

end rtl;
