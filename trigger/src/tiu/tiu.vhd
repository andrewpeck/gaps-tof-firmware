library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity tiu is
  generic (
    TIMESTAMPB : integer := 32;
    TIMEWORDB  : integer := 48;
    EVENTCNTB  : integer := 32
    );
    port(

      clock : in std_logic;
      reset : in std_logic;

      -- tiu physical signals
      tiu_busy_i     : in  std_logic;
      tiu_serial_o   : out std_logic;
      tiu_timecode_i : in  std_logic;
      tiu_trigger_o  : out std_logic;

      -- mt trigger signals
      trigger_i   : in std_logic;
      event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0);
      timestamp_i : in std_logic_vector (TIMESTAMPB-1 downto 0);


      -- outputs

      global_busy_o : out std_logic;

      tiu_timeword_valid_o : out std_logic;
      tiu_timeword_o       : out std_logic_vector (TIMEWORDB-1 downto 0);

      timestamp_o       : out std_logic_vector (TIMESTAMPB-1 downto 0);
      timestamp_valid_o : out std_logic

      );
end tiu;

architecture behavioral of tiu is

  constant TIU_CNT_MAX : natural := 2**20-1;

  signal waiting_for_tiu_busy : std_logic                     := '0';
  signal tiu_falling_cnt      : natural                       := TIU_CNT_MAX;
  signal tiu_timecode_sr      : std_logic_vector (2 downto 0) := (others => '0');
  signal tiu_falling          : std_logic                     := '0';

  constant tiu_trigger_cnt_max : integer                                := 105;
  signal tiu_trigger_cnt       : integer range 0 to tiu_trigger_cnt_max := 0;

  signal tiu_timebyte       : std_logic_vector (7 downto 0)             := (others => '0');
  signal tiu_timebyte_dav   : std_logic                                 := '0';
  signal tiu_timeword_valid : std_logic                                 := '0';
  signal tiu_timeword       : std_logic_vector (TIMEWORDB-1 downto 0)   := (others => '0');
  signal tiu_timeword_buf   : std_logic_vector (TIMEWORDB-8-1 downto 0) := (others => '0');
  signal tiu_byte_cnt       : integer range 0 to tiu_timeword'length/8;

begin

  global_busy_o <= tiu_busy_i or waiting_for_tiu_busy;

  --------------------------------------------------------------------------------
  -- Trigger Out
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (tiu_trigger_cnt = 0 and trigger_i = '1') then
        waiting_for_tiu_busy <= '1';
        tiu_trigger_cnt      <= tiu_trigger_cnt_max;
        tiu_trigger_o        <= '1';
      elsif (tiu_trigger_cnt > 0) then
        waiting_for_tiu_busy <= '1';
        tiu_trigger_cnt      <= tiu_trigger_cnt - 1;
        tiu_trigger_o        <= '1';
      else
        tiu_trigger_o        <= '0';
        waiting_for_tiu_busy <= '0';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Event Count Out
  --------------------------------------------------------------------------------

  tiu_tx_inst : entity work.tiu_tx
    generic map (
      EVENTCNTB => 32,
      DIV       => 100
      )
    port map (
      clock       => clock,
      reset       => reset,
      serial_o    => tiu_serial_o,
      trg_i       => trigger_i,
      event_cnt_i => event_cnt_i
      );

  --------------------------------------------------------------------------------
  -- Timestamp In
  --------------------------------------------------------------------------------

  timecode_uart_inst : entity work.tiny_uart
    generic map (
      WLS    => 8,           --! word length select; number of data bits     [ integer ]
      CLK    => 100_000_000, --! master clock frequency in Hz                [ integer ]
      BPS    => 9600,        --! transceive baud rate in Bps                 [ integer ]
      SBS    => 1,           --! Stop bit select, only one/two stopbit       [ integer ]
      PI     => true,        --! Parity inhibit, true: inhibit               [ boolean ]
      EPE    => true,        --! Even parity enable, true: even, false: odd  [ boolean ]
      DEBU   => 3,           --! Number of debouncer stages                  [ integer ]
      TXIMPL => false,       --! implement UART TX path                      [ boolean ]
      RXIMPL => true)        --! implement UART RX path                      [ boolean ]
    port map (
      R    => reset,
      C    => clock,
      TXD  => open,
      RXD  => tiu_timecode_i,
      RR   => tiu_timebyte,
      PE   => open,
      FE   => open,
      DR   => tiu_timebyte_dav,
      TR   => (others => '0'),
      THRE => open,
      THRL => '0',
      TRE  => open
      );

  --------------------------------------------------------------------------------
  -- Timestamp Latch
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_timeword_valid <= '0';

      -- synchronize the byte counter to the falling edge of the pulse
      if (tiu_falling = '1') then

        tiu_byte_cnt <= 0;

      elsif (tiu_timebyte_dav = '1') then

        if (tiu_byte_cnt < 5) then
          tiu_byte_cnt <= tiu_byte_cnt + 1;
          tiu_timeword_buf(8*(tiu_byte_cnt+1)-1 downto 8*tiu_byte_cnt)
            <= tiu_timebyte;
        else
          tiu_byte_cnt       <= 0;
          tiu_timeword       <= tiu_timebyte & tiu_timeword_buf;
          tiu_timeword_valid <= '1';
        end if;
      end if;

    end if;
  end process;


  -- on the falling edge of the tiu signal, latch the timestamp
  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_timecode_sr(0) <= tiu_timecode_i;

      for I in 1 to tiu_timecode_sr'length-1 loop
        tiu_timecode_sr(I) <= tiu_timecode_sr(I-1);
      end loop;

      tiu_falling <= '0';

      if (tiu_falling_cnt = 0 and tiu_timecode_sr(2) = '1' and tiu_timecode_sr(1) = '0') then
        tiu_falling     <= '1';
        tiu_falling_cnt <= TIU_CNT_MAX;
      elsif (tiu_falling_cnt > 0) then
        tiu_falling_cnt <= tiu_falling_cnt - 1;
      end if;

      timestamp_valid_o <= '0';

      if (tiu_falling = '1') then
        timestamp_o       <= timestamp_i;
        timestamp_valid_o <= '1';
      end if;

    end if;
  end process;


end behavioral;
