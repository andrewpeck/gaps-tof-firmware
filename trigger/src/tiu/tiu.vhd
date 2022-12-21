library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity tiu is
  generic (
    TIMESTAMPB : integer := 32;
    GPSB       : integer := 48;
    EVENTCNTB  : integer := 32
    );
  port(

    clock : in std_logic;
    reset : in std_logic;

    -- tiu physical signals
    tiu_busy_i    : in  std_logic;
    tiu_serial_o  : out std_logic;
    tiu_gps_i     : in  std_logic;
    tiu_trigger_o : out std_logic;

    -- config
    send_event_cnt_on_timeout : in std_logic := '1';

    -- mt trigger signals
    trigger_i   : in std_logic;
    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0);
    timestamp_i : in std_logic_vector (TIMESTAMPB-1 downto 0);

    -- outputs

    global_busy_o : out std_logic;

    tiu_gps_valid_o : out std_logic;
    tiu_gps_o       : out std_logic_vector (GPSB-1 downto 0);

    timestamp_o       : out std_logic_vector (TIMESTAMPB-1 downto 0);
    timestamp_valid_o : out std_logic

    );
end tiu;

architecture behavioral of tiu is

  --------------------------------------------------------------------------------
  -- Trigger Logic
  --------------------------------------------------------------------------------

  signal event_cnt             : std_logic_vector (event_cnt_i'range)   := (others => '0');
  constant tiu_trigger_cnt_max : integer                                := 105;
  signal tiu_trigger_cnt       : integer range 0 to tiu_trigger_cnt_max := 0;
  signal ready_for_trigger     : boolean;
  signal tiu_tx_busy           : std_logic                              := '0';
  signal tiu_init_tx           : std_logic                              := '0';
  signal tiu_timeout           : std_logic                              := '0';

  --------------------------------------------------------------------------------
  -- GPS handling
  --------------------------------------------------------------------------------

  constant TIU_HOLDOFF_CNT_MAX : natural                       := 2**20-1;
  signal tiu_falling_cnt       : natural                       := TIU_HOLDOFF_CNT_MAX;
  signal tiu_gps_sr            : std_logic_vector (2 downto 0) := (others => '0');
  signal tiu_falling           : std_logic                     := '0';

  signal tiu_timebyte     : std_logic_vector (7 downto 0)        := (others => '0');
  signal tiu_timebyte_dav : std_logic                            := '0';
  signal tiu_gps_buf      : std_logic_vector (GPSB-8-1 downto 0) := (others => '0');
  signal tiu_byte_cnt     : integer range 0 to tiu_gps_o'length/8;

begin

  global_busy_o <= '0' when ready_for_trigger else '1';

  --------------------------------------------------------------------------------
  -- Trigger Out
  --------------------------------------------------------------------------------

  -- upon receiving a trigger, we should:
  --  1) assert the trigger output
  --  2) wait a for 1.05 us for the ACK signal (busy) to come from the SiLI
  --     - If ACK does not come, timeout and do ???
  --  3) When ACK is received, send the event counter
  --  4) When ACK is deasserted, ready for the next trigger

  ready_for_trigger <= tiu_tx_busy = '0' and
                       tiu_busy_i = '0' and
                       tiu_trigger_o = '0' and
                       tiu_timeout = '0' and
                       tiu_trigger_cnt = 0;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_init_tx   <= '0';
      tiu_trigger_o <= '0';
      tiu_timeout   <= '0';

      -- start a trigger
      if (ready_for_trigger and trigger_i = '1') then
        tiu_trigger_o   <= '1';
        tiu_trigger_cnt <= tiu_trigger_cnt_max;
        event_cnt       <= event_cnt_i;

      -- when the busy/ack is received, deassert the trigger output and start the
      -- event count serializer
      elsif (tiu_trigger_o = '1' and tiu_busy_i = '1') then
        tiu_init_tx     <= '1';
        tiu_trigger_o   <= '0';
        tiu_trigger_cnt <= 0;

      -- still waiting for the busy
      elsif (tiu_trigger_o = '1' and tiu_trigger_cnt > 0) then
        tiu_trigger_cnt <= tiu_trigger_cnt - 1;
        tiu_trigger_o   <= '1';

      -- timeout
      elsif (tiu_trigger_o = '1' and tiu_trigger_cnt = 0) then
        tiu_trigger_cnt <= 0;
        tiu_trigger_o   <= '0';
        tiu_timeout     <= '1';

        if (send_event_cnt_on_timeout = '1') then
          tiu_init_tx <= '1';
        end if;

      -- else:
      --  + waiting for busy to be deasserted
      --  + ???
      else
        tiu_trigger_cnt <= 0;
        tiu_trigger_o   <= '0';
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
      trg_i       => tiu_init_tx,
      event_cnt_i => event_cnt,
      busy_o      => tiu_tx_busy
      );

  --------------------------------------------------------------------------------
  -- Timestamp In
  --------------------------------------------------------------------------------

  gps_uart_inst : entity work.tiny_uart
    generic map (
      WLS    => 8,           -- word length select; number of data bits     [ integer ]
      CLK    => 100_000_000, -- master clock frequency in Hz                [ integer ]
      BPS    => 9600,        -- transceive baud rate in Bps                 [ integer ]
      SBS    => 1,           -- Stop bit select, only one/two stopbit       [ integer ]
      PI     => true,        -- Parity inhibit, true: inhibit               [ boolean ]
      EPE    => true,        -- Even parity enable, true: even, false: odd  [ boolean ]
      DEBU   => 3,           -- Number of debouncer stages                  [ integer ]
      TXIMPL => false,       -- implement UART TX path                      [ boolean ]
      RXIMPL => true)        -- implement UART RX path                      [ boolean ]
    port map (
      R    => reset,
      C    => clock,
      TXD  => open,
      RXD  => tiu_gps_i,
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

      tiu_gps_valid_o <= '0';

      -- synchronize the byte counter to the falling edge of the pulse
      if (tiu_falling = '1') then

        tiu_byte_cnt <= 0;

      elsif (tiu_timebyte_dav = '1') then

        if (tiu_byte_cnt < 5) then
          tiu_byte_cnt <= tiu_byte_cnt + 1;
          tiu_gps_buf(8*(tiu_byte_cnt+1)-1 downto 8*tiu_byte_cnt)
            <= tiu_timebyte;
        else
          tiu_byte_cnt    <= 0;
          tiu_gps_o       <= tiu_timebyte & tiu_gps_buf;
          tiu_gps_valid_o <= '1';
        end if;
      end if;

    end if;
  end process;


  -- on the falling edge of the tiu GPS signal, latch the timestamp
  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_gps_sr(0) <= tiu_gps_i;

      for I in 1 to tiu_gps_sr'length-1 loop
        tiu_gps_sr(I) <= tiu_gps_sr(I-1);
      end loop;

      tiu_falling <= '0';

      if (tiu_falling_cnt = 0 and tiu_gps_sr(2) = '1' and tiu_gps_sr(1) = '0') then
        tiu_falling     <= '1';
        tiu_falling_cnt <= TIU_HOLDOFF_CNT_MAX;
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
