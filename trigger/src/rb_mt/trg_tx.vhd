library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity trg_tx is
  generic(
    EN_MASK   : natural range 0 to 1 := 1; -- 1 to send a channel mask; 0 for only eventcnt
    EVENTCNTB : natural              := 32;
    MASKCNTB  : natural              := 16
    );
  port(

    clock    : in  std_logic;
    reset    : in  std_logic;
    serial_o : out std_logic;

    trg_i    : in std_logic;
    resync_i : in std_logic;

    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0);
    ch_mask_i   : in std_logic_vector (MASKCNTB-1 downto 0)

    );
end trg_tx;

architecture rtl of trg_tx is

  constant LENGTH : natural := EVENTCNTB + EN_MASK * MASKCNTB;

  type state_t is (IDLE_state, SYNC_state, TRG_state, DATA_state);
  signal state         : state_t   := IDLE_state;
  signal state_bit_cnt : natural   := 0;
  signal trg           : std_logic := '0';

  signal packet_buf : std_logic_vector (LENGTH-1 downto 0) := (others => '0');

begin

  assert EN_MASK = 0 or EN_MASK = 1 report "EN_MASK must be 0 or 1" severity error;

  process (clock)
  begin

    if (rising_edge(clock)) then

      serial_o <= '0';
      case state is

        when IDLE_state =>

          if (trg_i = '1') then
            serial_o <= '1';
            state    <= TRG_state;
            if (EN_MASK = 1) then
              packet_buf <= ch_mask_i & event_cnt_i;
            else
              packet_buf <= event_cnt_i;
            end if;
          elsif (resync_i = '1') then
            serial_o <= '1';
            state    <= SYNC_state;
          end if;

        when SYNC_state =>
          serial_o <= '0';
          state    <= IDLE_state;

        when TRG_state =>
          serial_o <= '1';
          state    <= DATA_state;

        when DATA_state =>

          if (state_bit_cnt = LENGTH - 1) then
            state         <= IDLE_state;
            state_bit_cnt <= 0;
          else
            state_bit_cnt <= state_bit_cnt + 1;
          end if;

          serial_o <= packet_buf(LENGTH-1-state_bit_cnt);

      end case;

      if (reset = '1') then
        state    <= IDLE_state;
        serial_o <= '0';
      end if;

    end if;
  end process;

end rtl;
