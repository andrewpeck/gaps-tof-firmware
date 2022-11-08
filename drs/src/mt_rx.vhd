library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity mt_rx is
  generic(
    EVENTCNTB : natural := 32;
    MASKB     : natural := 8;
    CRCB      : natural := 8;
    CMDB      : natural := 2
    );
  port(

    clock    : in std_logic;
    reset    : in std_logic;
    serial_i : in std_logic;
    enable_i : in std_logic;

    trg_o      : out std_logic := '0';
    fragment_o : out std_logic := '0';

    cmd_o       : out std_logic_vector (CMDB-1 downto 0) := (others => '0');
    cmd_valid_o : out std_logic                          := '0';

    mask_o       : out std_logic_vector (MASKB-1 downto 0) := (others => '0');
    mask_valid_o : out std_logic;

    crc_o       : out std_logic_vector (CRCB-1 downto 0) := (others => '0');
    crc_calc_o  : out std_logic_vector (CRCB-1 downto 0) := (others => '0');
    crc_valid_o : out std_logic;
    crc_ok_o    : out std_logic;

    event_cnt_o       : out std_logic_vector (EVENTCNTB-1 downto 0) := (others => '0');
    event_cnt_valid_o : out std_logic

    );
end mt_rx;

architecture rtl of mt_rx is

  type state_t is (IDLE_state, DWRITE_state, MASK_state, EVENTCNT_state, CMD_state, CRC_state, WAIT_state);

  signal state         : state_t                                   := IDLE_state;
  signal state_bit_cnt : natural range 0 to event_cnt_o'length - 1 := 0;

  signal event_cnt_buf : std_logic_vector (EVENTCNTB-1 downto 0) := (others => '0');
  signal mask_buf      : std_logic_vector (MASKB-1 downto 0)     := (others => '0');
  signal cmd_buf       : std_logic_vector (CMDB-1 downto 0)      := (others => '0');
  signal crc_buf       : std_logic_vector (CRCB-1 downto 0)      := (others => '0');
  signal crc           : std_logic_vector (CRCB-1 downto 0)      := (others => '0');

  signal crc_en  : std_logic := '0';
  signal crc_rst : std_logic := '0';

  signal crc_data : std_logic_vector (42 downto 0) := (others => '0');

  constant WAIT_CNT_MAX : integer                         := 2**12-1;
  signal wait_cnt       : natural range 0 to WAIT_CNT_MAX := 0;

begin

  crc_rst  <= '1' when state = IDLE_state or reset = '1' else '0';
  crc_data <= or_reduce(mask_o) & mask_o & event_cnt_o & cmd_o;

  crc_inst : entity work.crc
    port map (
      data_in => crc_data,
      crc_en  => crc_en,
      rst     => crc_rst,
      clk     => clock,
      crc_out => crc
      );

  process (clock)
  begin

    if (rising_edge(clock)) then

      trg_o             <= '0';
      fragment_o        <= '0';
      event_cnt_valid_o <= '0';
      mask_valid_o      <= '0';
      cmd_valid_o       <= '0';
      crc_valid_o       <= '0';
      crc_en            <= '0';

      if (enable_i = '1') then

        case state is

          when IDLE_state =>

            state_bit_cnt <= 0;

            -- receive the start bit
            if (serial_i = '1') then
              state <= DWRITE_state;
            end if;

          when DWRITE_state =>

            state <= MASK_state;

            if (serial_i = '1') then
              trg_o <= '1';
            else
              fragment_o <= '1';
            end if;

          when MASK_state =>

            if (state_bit_cnt = MASKB - 1) then
              mask_o        <= mask_buf(MASKB-1 downto 1) & serial_i;
              state         <= EVENTCNT_state;
              state_bit_cnt <= 0;
              mask_valid_o  <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            mask_buf(MASKB-1-state_bit_cnt) <= serial_i;

          when EVENTCNT_state =>

            if (state_bit_cnt = EVENTCNTB - 1) then

              event_cnt_o <= event_cnt_buf(EVENTCNTB-1 downto 1) & serial_i;

              if (CMDB > 0) then
                state <= CMD_state;
              else
                state <= WAIT_state;
              end if;
              state_bit_cnt     <= 0;
              event_cnt_valid_o <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            event_cnt_buf (EVENTCNTB-1-state_bit_cnt) <= serial_i;

          when CMD_state =>

            if (state_bit_cnt = CMDB - 1) then

              cmd_o <= cmd_buf(CMDB-1 downto 1) & serial_i;

              if (CRCB > 0) then
                state <= CRC_state;
              else
                state <= WAIT_state;
              end if;
              state_bit_cnt <= 0;
              cmd_valid_o   <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            cmd_buf(CMDB-1-state_bit_cnt) <= serial_i;

          when CRC_state =>

            -- enable for only one clock cycle, just pick something
            if (state_bit_cnt = 1) then
              crc_en <= '1';
            end if;

            if (state_bit_cnt = CRCB - 1) then
              crc_o         <= crc_buf(CRCB-1 downto 1) & serial_i;
              state         <= WAIT_state;
              state_bit_cnt <= 0;
              crc_valid_o   <= '1';

              if (crc_buf(CRCB-1 downto 1) & serial_i = crc) then
                crc_ok_o   <= '1';
                crc_calc_o <= crc;
              else
                crc_ok_o   <= '0';
                crc_calc_o <= crc;
              end if;

            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            crc_buf(CRCB-1-state_bit_cnt) <= serial_i;

          when WAIT_state =>

            if (wait_cnt = WAIT_CNT_MAX - 1) then
              wait_cnt <= 0;
              state    <= IDLE_state;
            else
              wait_cnt <= wait_cnt + 1;
            end if;

        end case;
      end if;

      if (reset = '1') then
        state             <= IDLE_state;
        event_cnt_valid_o <= '0';
        mask_valid_o      <= '0';
        wait_cnt          <= 0;
        state_bit_cnt     <= 0;
      end if;

    end if;
  end process;

end rtl;
