library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity mt_rx is
  generic(
    EVENTCNTB : natural := 32;
    MASKCNTB  : natural := 8;
    CMDB      : natural := 4
    );
  port(

    clock    : in std_logic;
    reset    : in std_logic;
    serial_i : in std_logic;
    enable_i : in std_logic;

    trg_o : out std_logic := '0';

    cmd_o       : out std_logic_vector (CMDB-1 downto 0) := (others => '0');
    cmd_valid_o : out std_logic := '0';

    mask_o       : out std_logic_vector (MASKCNTB-1 downto 0) := (others => '0');
    mask_valid_o : out std_logic;

    event_cnt_o       : out std_logic_vector (EVENTCNTB-1 downto 0) := (others => '0');
    event_cnt_valid_o : out std_logic

    );
end mt_rx;

architecture rtl of mt_rx is

  type state_t is (IDLE_state, MASK_state, EVENTCNT_state, CMD_state);

  signal state         : state_t                                   := IDLE_state;
  signal state_bit_cnt : natural range 0 to event_cnt_o'length - 1 := 0;

begin

  process (clock)
  begin

    if (rising_edge(clock)) then

      trg_o             <= '0';
      event_cnt_valid_o <= '0';
      mask_valid_o      <= '0';

      if (enable_i = '1') then

        case state is

          when IDLE_state =>

            -- receive the start bit
            if (serial_i = '1') then
              state <= MASK_state;
              trg_o <= '1';
            end if;

          when MASK_state =>

            if (state_bit_cnt = MASKCNTB - 1) then
              state         <= EVENTCNT_state;
              state_bit_cnt <= 0;
              mask_valid_o  <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            mask_o(MASKCNTB-1-state_bit_cnt) <= serial_i;

          when EVENTCNT_state =>

            if (state_bit_cnt = EVENTCNTB - 1) then
              if (CMDB > 0) then
                state <= CMD_state;
              else
                state <= IDLE_state;
              end if;
              state_bit_cnt     <= 0;
              event_cnt_valid_o <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            event_cnt_o(EVENTCNTB-1-state_bit_cnt) <= serial_i;

          when CMD_state =>

            if (state_bit_cnt = CMDB - 1) then
              state         <= IDLE_state;
              state_bit_cnt <= 0;
              cmd_valid_o   <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            cmd_o(CMDB-1-state_bit_cnt) <= serial_i;

        end case;
      end if;

      if (reset = '1') then
        state             <= IDLE_state;
        event_cnt_valid_o <= '0';
        mask_valid_o      <= '0';
      end if;

    end if;
  end process;

end rtl;
