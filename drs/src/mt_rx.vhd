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
    outclk   : in std_logic;
    reset    : in std_logic;
    serial_i : in std_logic;
    enable_i : in std_logic;

    trg_o         : out std_logic := '0';
    trg_fast_o    : out std_logic := '0';
    fragment_o    : out std_logic := '0';
    fragment_en_i : in  std_logic := '0';

    cmd_o       : out std_logic_vector (CMDB-1 downto 0);
    cmd_valid_o : out std_logic;

    mask_o       : out std_logic_vector (MASKB-1 downto 0);
    mask_valid_o : out std_logic;

    crc_o       : out std_logic_vector (CRCB-1 downto 0);
    crc_calc_o  : out std_logic_vector (CRCB-1 downto 0);
    crc_valid_o : out std_logic := '0';
    crc_ok_o    : out std_logic := '0';

    event_cnt_o       : out std_logic_vector (EVENTCNTB-1 downto 0);
    event_cnt_valid_o : out std_logic;

    fifo_wr_o : out std_logic

    );
end mt_rx;

architecture rtl of mt_rx is

  type state_t is (IDLE_state, DWRITE_state, MASK_state, EVENTCNT_state, CMD_state, CRC_state, WAIT_state);

  signal trg, trg_r, fragment                                      : std_logic := '0';
  signal cmd_valid, mask_valid, crc_valid, event_cnt_valid         : std_logic := '0';
  signal cmd_valid_r, mask_valid_r, crc_valid_r, event_cnt_valid_r : std_logic := '0';

  signal event_cnt : std_logic_vector (EVENTCNTB-1 downto 0) := (others => '0');
  signal crc_rx    : std_logic_vector (CRCB-1 downto 0)      := (others => '0');
  signal mask      : std_logic_vector (MASKB-1 downto 0)     := (others => '0');
  signal cmd       : std_logic_vector (CMDB-1 downto 0)      := (others => '0');

  signal state         : state_t                                   := IDLE_state;
  signal state_bit_cnt : natural range 0 to event_cnt_o'length - 1 := 0;

  signal event_cnt_buf : std_logic_vector (EVENTCNTB-1 downto 0) := (others => '0');
  signal mask_buf      : std_logic_vector (MASKB-1 downto 0)     := (others => '0');
  signal cmd_buf       : std_logic_vector (CMDB-1 downto 0)      := (others => '0');
  signal crc_rx_buf    : std_logic_vector (CRCB-1 downto 0)      := (others => '0');
  signal crc_calc      : std_logic_vector (CRCB-1 downto 0)      := (others => '0');

  signal crc_en  : std_logic := '0';
  signal crc_rst : std_logic := '0';

  signal crc_data : std_logic_vector (42 downto 0) := (others => '0');

  constant WAIT_CNT_MAX : integer                         := 2**12-1;
  signal wait_cnt       : natural range 0 to WAIT_CNT_MAX := 0;

begin

  crc_rst  <= '1' when state = IDLE_state or reset = '1' else '0';
  crc_data <= or_reduce(mask) & mask & event_cnt & cmd;

  crc_inst : entity work.crc
    port map (
      data_in => crc_data,
      crc_en  => crc_en,
      rst     => crc_rst,
      clk     => clock,
      crc_out => crc_calc
      );

  process (clock)
  begin

    crc_en <= '0';

    if (rising_edge(clock)) then

      if (enable_i = '1') then

        trg_fast_o      <= '0';

        case state is

          when IDLE_state =>

            event_cnt_valid <= '0';
            mask_valid      <= '0';
            cmd_valid       <= '0';
            crc_valid       <= '0';
            trg             <= '0';

            state_bit_cnt <= 0;

            -- receive the start bit
            if (serial_i = '1') then
              state <= DWRITE_state;
            end if;

          when DWRITE_state =>

            state <= MASK_state;

            if (serial_i = '1') then
              trg        <= '1';
              trg_fast_o <= '1';
            else
              fragment <= fragment_en_i;
            end if;

          when MASK_state =>

            if (state_bit_cnt = MASKB - 1) then
              mask          <= mask_buf(MASKB-1 downto 1) & serial_i;
              state         <= EVENTCNT_state;
              state_bit_cnt <= 0;
              mask_valid    <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            mask_buf(MASKB-1-state_bit_cnt) <= serial_i;

          when EVENTCNT_state =>

            if (state_bit_cnt = EVENTCNTB - 1) then

              event_cnt <= event_cnt_buf(EVENTCNTB-1 downto 1) & serial_i;

              if (CMDB > 0) then
                state <= CMD_state;
              else
                state <= WAIT_state;
              end if;
              state_bit_cnt   <= 0;
              event_cnt_valid <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            event_cnt_buf (EVENTCNTB-1-state_bit_cnt) <= serial_i;

          when CMD_state =>

            if (state_bit_cnt = CMDB - 1) then

              cmd           <= cmd_buf(CMDB-1 downto 1) & serial_i;
              state_bit_cnt <= 0;
              cmd_valid     <= '1';

              if (CRCB > 0) then
                state <= CRC_state;
              else
                state <= WAIT_state;
              end if;

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
              crc_rx    <= crc_rx_buf(CRCB-1 downto 1) & serial_i;
              state     <= WAIT_state;
              crc_valid <= '1';
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            crc_rx_buf(CRCB-1-state_bit_cnt) <= serial_i;

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
        state           <= IDLE_state;
        event_cnt_valid <= '0';
        mask_valid      <= '0';
        wait_cnt        <= 0;
        state_bit_cnt   <= 0;
      end if;

    end if;
  end process;

  process (outclk) is
  begin
    if (rising_edge(outclk)) then

      fifo_wr_o  <= (fragment or trg) and (event_cnt_valid and not event_cnt_valid_r);
      trg_o      <= trg_fast_o or (trg and not trg_r);
      fragment_o <= fragment_en_i and fragment;

      trg_r             <= trg; 
      event_cnt_valid_r <= event_cnt_valid; 
      mask_valid_r      <= mask_valid;
      cmd_valid_r       <= cmd_valid;
      crc_valid_r       <= crc_valid;

      -- make these rising edge sensitive on the outclk so they are only 1
      -- clock wide and can be used as write enables
      event_cnt_valid_o <= event_cnt_valid and not event_cnt_valid_r;
      mask_valid_o      <= mask_valid and not mask_valid_r;
      cmd_valid_o       <= cmd_valid and not cmd_valid_r;
      crc_valid_o       <= crc_valid and not crc_valid_r;


      event_cnt_o <= event_cnt;
      mask_o      <= mask;
      cmd_o       <= cmd;
      crc_o       <= crc_rx;

      if (crc_valid = '1') then

        if (crc_rx = crc_calc) then
          crc_ok_o <= '1';
        else
          crc_ok_o <= '0';
        end if;
      end if;

    end if;
  end process;

  crc_calc_o <= crc_calc;

end rtl;
