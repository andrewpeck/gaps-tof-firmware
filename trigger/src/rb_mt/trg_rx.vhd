-- TODO: add optional 8b10b? manchester?

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity trg_rx is
  generic(
    POSNEG    : natural range 0 to 1 := 0;
    EN_MASK   : natural range 0 to 1 := 1;
    EVENTCNTB : natural              := 32;
    MASKCNTB  : natural              := 16
    );
  port(

    clock    : in std_logic;
    reset    : in std_logic;
    serial_i : in std_logic;

    level_mode : in std_logic;

    pretrg_o : out std_logic;
    trg_o    : out std_logic;
    resync_o : out std_logic;

    event_cnt_o : out std_logic_vector (EVENTCNTB-1 downto 0);
    ch_mask_o   : out std_logic_vector (MASKCNTB-1 downto 0)

    );
end trg_rx;

architecture rtl of trg_rx is

  signal serial, serial_iob : std_logic := '0';

  type state_t is (IDLE_state, CMD_state, MASK_state, OUTPUT_state, EVENTCNT_state);

  signal state         : state_t := IDLE_state;
  signal state_bit_cnt : natural := 0;

  signal eventcnt_buf : std_logic_vector (EVENTCNTB-1 downto 0) := (others => '0');
  signal mask_buf     : std_logic_vector (MASKCNTB-1 downto 0)  := (others => '0');

begin

  pos : if (POSNEG = 1) generate
    process (clock) is
    begin
      if (rising_edge(clock)) then
        serial_iob <= serial_i;
      end if;
    end process;
  end generate;

  neg : if (POSNEG = 0) generate
    process (clock) is
    begin
      if (falling_edge(clock)) then
        serial_iob <= serial_i;
      end if;
    end process;
  end generate;

  process (clock)
  begin

    if (rising_edge(clock)) then

      serial <= serial_iob;

      resync_o <= '0';
      trg_o    <= '0';

      case state is

        when IDLE_state =>

          if (serial = '1') then
            state <= CMD_state;
          end if;

        when CMD_state =>

          if (serial = '1') then
            if (EN_MASK = 0) then
              state <= EVENTCNT_state;
            else
              state <= MASK_state;
            end if;
          else
            resync_o <= '1';
            state    <= IDLE_state;
          end if;

        when MASK_state =>

          if (state_bit_cnt = MASKCNTB - 1) then
            state         <= EVENTCNT_state;
            state_bit_cnt <= 0;
          else
            state_bit_cnt <= state_bit_cnt + 1;
          end if;

          mask_buf(MASKCNTB-1-state_bit_cnt) <= serial;

        when EVENTCNT_state =>

          -- output the pretrigger when the mask is available
          pretrg_o  <= '1';
          ch_mask_o <= mask_buf;

          if (state_bit_cnt = EVENTCNTB - 1) then
            state         <= OUTPUT_state;
            state_bit_cnt <= 0;
          else
            state_bit_cnt <= state_bit_cnt + 1;
          end if;

          eventcnt_buf(EVENTCNTB-1-state_bit_cnt) <= serial;

        when OUTPUT_state =>

          state       <= IDLE_state;
          event_cnt_o <= eventcnt_buf;
          trg_o       <= '1';


      end case;

      if (level_mode = '1') then
        resync_o <= '0';
        trg_o    <= serial;
        pretrg_o <= serial;
      end if;

      if (reset = '1') then
        state    <= IDLE_state;
        resync_o <= '0';
        trg_o    <= '0';
        pretrg_o <= '0';
      end if;

    end if;
  end process;

end rtl;
