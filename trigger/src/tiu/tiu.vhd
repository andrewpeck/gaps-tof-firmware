library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.components.all;

entity tiu is
  generic (
    TIMESTAMPB : integer := 32;
    GPSB       : integer := 48;
    FREQ       : integer := 100_000_000;
    EVENTCNTB  : integer := 32;
    V          : string  := "v1"
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
    tiu_busy_ignore_i         : in std_logic;

    -- mt trigger signals
    pre_trigger_i : in std_logic;
    event_cnt_i   : in std_logic_vector (EVENTCNTB-1 downto 0);
    timestamp_i   : in std_logic_vector (TIMESTAMPB-1 downto 0);

    -- outputs

    tiu_busy_length_o : out std_logic_vector (31 downto 0);

    tiu_bad_o   : out std_logic := '0';
    tiu_stuck_o : out std_logic := '0';

    global_busy_o : out std_logic;

    tiu_gps_valid_o : out std_logic;
    tiu_gps_o       : out std_logic_vector (GPSB-1 downto 0) := (others => '0');

    timestamp_o       : out std_logic_vector (TIMESTAMPB-1 downto 0) := (others => '0');
    timestamp_valid_o : out std_logic

    );
end tiu;

architecture behavioral of tiu is

  constant CLK_PERIOD_US          : real    := 1000000.0/real(FREQ);
  constant tiu_timeout_cnt_max : integer := integer(1.05 / CLK_PERIOD_US); -- 105 cycles

  signal tiu_busy_i_rising, tiu_busy_i_falling : std_logic;
  signal tiu_busy_i_reg : std_logic := '0';
  signal tiu_busy : std_logic := '0';

  signal tiu_ack    : std_logic                    := '0';
  signal tiu_ack_sr : std_logic_vector(3 downto 0) := (others => '0');

  signal tiu_gps  : std_logic := '0';

  type tx_init_state_t is (READY_FOR_TRIGGER, WAIT_FOR_ACK, INIT_TX, WAIT_FOR_TX_DONE, WAIT_FOR_NOT_BUSY);
  signal tx_init_state : tx_init_state_t := READY_FOR_TRIGGER;

  --------------------------------------------------------------------------------
  -- Trigger Logic
  --------------------------------------------------------------------------------

  signal trigger           : std_logic;
  signal pretrigger_latch  : std_logic                              := '0';
  signal ready_to_trigger  : std_logic                              := '0';
  signal event_cnt         : std_logic_vector (event_cnt_i'range)   := (others => '0');
  signal tiu_timeout_cnt   : integer range 0 to tiu_timeout_cnt_max := 0;
  signal tiu_tx_busy       : std_logic;
  signal tiu_tx_done       : std_logic;
  signal tiu_init_tx       : std_logic                              := '0';
  signal tiu_timeout       : std_logic                              := '0';

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

  signal tiu_busy_cnt   : unsigned (31 downto 0);

  constant tiu_stuck_cnt_max : integer := 1_000_000_000;
  signal tiu_stuck_cnt       : unsigned (31 downto 0);

begin

  ila_mt_inst : ila_mt
    port map (
      clk                   => clock,
      probe0(0)             => tiu_busy,
      probe1(0)             => tiu_gps,
      probe2(0)             => tiu_busy_i,
      probe2(1)             => tiu_serial_o,
      probe2(2)             => tiu_gps,
      probe2(3)             => ready_to_trigger,
      probe2(4)             => pre_trigger_i,
      probe2(5)             => global_busy_o,
      probe2(6)             => timestamp_valid_o,
      probe2(7)             => tiu_gps_valid_o,
      probe2(55 downto 8)   => tiu_gps_o,
      probe2(57 downto 56)  => (others => '0'),
      probe2(60 downto 58)  => std_logic_vector(to_unsigned(tx_init_state_t'pos(tx_init_state), 3)),
      probe2(61)            => pretrigger_latch,
      probe2(62)            => ready_to_trigger,
      probe2(63)            => tiu_tx_done,
      probe2(64)            => tiu_timeout,
      probe2(65)            => tiu_timeout,
      probe2(74 downto 66)  => (others => '0'),
      probe3(3 downto 0)    => (others => '0'),
      probe3(4)             => pps,
      probe3(5)             => tiu_ack,
      probe3(6)             => '0',
      probe3(7)             => '0',
      probe4(4 downto 0)    => (others => '0'),
      probe4(5)             => '0',
      probe4(6)             => '0',
      probe4(7)             => '0',
      probe5(0)             => tiu_timebyte_dav,
      probe6(0)             => '0',
      probe7(0)             => '0',
      probe8(0)             => '0',
      probe9(1 downto 0)    => (others => '0'),
      probe10(31 downto 0)  => event_cnt,
      probe11(31 downto 0)  => timestamp_o,
      probe12(31 downto 0)  => timestamp_i,
      probe13(0)            => '0',
      probe13(1)            => tiu_init_tx,
      probe13(2)            => tiu_timeout,
      probe13(3)            => tiu_busy_ignore_i,
      probe13(4)            => tiu_tx_busy,
      probe13(5)            => tiu_gps_i,
      probe13(6)            => tiu_trigger_o,
      probe13(7)            => tiu_falling,
      probe13(15 downto 8)  => tiu_timebyte,
      probe13(19 downto 16) => std_logic_vector(to_unsigned(tiu_byte_cnt, 4)),
      probe13(20)           => '0',
      probe13(28 downto 21) => (others => '0'),
      probe13(29)           => '0',
      probe13(30)           => '0',
      probe13(31)           => '0',
      probe14(31 downto 0)  => (others => '0')
      );

  tiu_busy <= (tiu_busy_i and not tiu_busy_ignore_i);
  tiu_gps  <= tiu_gps_i;
  trigger  <= pre_trigger_i and not tiu_busy;

  --------------------------------------------------------------------------------
  -- ACK Glitch Filter
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      -- if we ignore the busy we are always acknowledged
      tiu_ack_sr(0) <= tiu_busy or tiu_busy_ignore_i;
      for I in 1 to tiu_ack_sr'length-1 loop
        tiu_ack_sr(I) <= tiu_ack_sr(I-1);
      end loop;
      tiu_ack <= and_reduce(tiu_ack_sr);
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Trigger Out
  --------------------------------------------------------------------------------
  -- or the statemachine derived ready_to_trigger signal with the async
  -- source of the trigger so that it is activated 1 clock cycle ahead of the
  -- state machine. this reduces latency by 1 clock. thanks to the OR, once the
  -- state machine takes effect the active hi trigger signal will get taken
  -- over and held high until the ack comes back from the tiu
  tiu_trigger_o    <= pre_trigger_i or pretrigger_latch;
  ready_to_trigger <= '1' when (tx_init_state = READY_FOR_TRIGGER) else '0';
  global_busy_o    <= (not ready_to_trigger) or tiu_busy;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      -- upon receiving a trigger, we should:
      --  1) assert the trigger output
      --  2) wait a for 1.05 us for the ACK signal (busy) to come from the SiLI
      --     - If ACK does not come, timeout and do ???
      --  3) When ACK is received, send the event counter
      --  4) When ACK is deasserted, ready for the next trigger

      tiu_init_tx     <= '0';
      tiu_timeout     <= '0';

      case tx_init_state is

        when READY_FOR_TRIGGER =>

          pretrigger_latch <= '0';

          -- start a trigger
          if (trigger = '1') then
            pretrigger_latch <= '1';
            tiu_timeout_cnt  <= tiu_timeout_cnt_max;
            tx_init_state    <= WAIT_FOR_ACK;
          end if;

        -- when the busy/ack is received, deassert the trigger output and start the
        -- event count serializer
        when WAIT_FOR_ACK =>

          event_cnt <= event_cnt_i;

          -- acknowledgment received
          if tiu_ack = '1' then
            tx_init_state    <= INIT_TX;

          -- still waiting for the ack
          elsif (tiu_timeout_cnt > 0) then
            tiu_timeout_cnt <= tiu_timeout_cnt - 1;

          -- timeout
          elsif (tiu_timeout_cnt = 0) then

            tiu_timeout      <= '1';

            if (send_event_cnt_on_timeout = '1') then
              tx_init_state <= INIT_TX;
            else
              tx_init_state <= READY_FOR_TRIGGER;
            end if;

          end if;

        when INIT_TX =>

          pretrigger_latch <= '0';
          tx_init_state    <= WAIT_FOR_TX_DONE;
          tiu_init_tx      <= '1';

        when WAIT_FOR_TX_DONE =>

          if (tiu_tx_done = '1') then
            tx_init_state <= WAIT_FOR_NOT_BUSY;
          end if;

        when WAIT_FOR_NOT_BUSY =>

          if (tiu_busy = '0') then
            tx_init_state <= READY_FOR_TRIGGER;
          end if;

        when others =>
          tx_init_state   <= READY_FOR_TRIGGER;

      end case;

      if (reset='1') then
        tx_init_state   <= READY_FOR_TRIGGER;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Event Count Out
  --------------------------------------------------------------------------------

  tiu_tx_inst : entity work.tiu_tx
    generic map (
      EVENTCNTB => EVENTCNTB,
      DIV       => 100
      )
    port map (
      clock       => clock,
      reset       => reset,
      serial_o    => tiu_serial_o,
      trg_i       => tiu_init_tx,
      event_cnt_i => event_cnt,
      busy_o      => tiu_tx_busy,
      done_o      => tiu_tx_done
      );

  --------------------------------------------------------------------------------
  -- Timestamp In
  --------------------------------------------------------------------------------

  gps_uart_inst : entity work.tiny_uart
    generic map (
      WLS    => 8,     -- word length select; number of data bits     [ integer ]
      CLK    => FREQ,  -- master clock frequency in Hz                [ integer ]
      BPS    => 9600,  -- transceive baud rate in Bps                 [ integer ]
      SBS    => 1,     -- Stop bit select, only one/two stopbit       [ integer ]
      PI     => true,  -- Parity inhibit, true: inhibit               [ boolean ]
      EPE    => true,  -- Even parity enable, true: even, false: odd  [ boolean ]
      DEBU   => 4,     -- Number of debouncer stages                  [ integer ]
      TXIMPL => true,  -- implement UART TX path                      [ boolean ]
      RXIMPL => true)  -- implement UART RX path                      [ boolean ]
    port map (
      R    => reset,
      C    => clock,
      TXD  => open,
      RXD  => tiu_gps,

      RR   => tiu_timebyte,     --! Receiver Holding Register Data Output
      PE   => open,             --! Parity error
      FE   => open,             --! Framing error
      DR   => tiu_timebyte_dav, --! Data Received, one clock cycle high
      TR   => (others => '0'),  --! Transmitter Holding Register Data Input

      THRE => open,     --! Transmitter Holding Register Empty
      THRL => '0',      --! Transmitter Holding Register Load, one clock cycle high
      TRE  => open      --! Transmitter Register Empty
      );

  --------------------------------------------------------------------------------
  -- Timestamp Latch
  -- TODO: add a timeout, make sure it does not get stuck in some weird state
  -- TODO: convert to an explicit SM
  --------------------------------------------------------------------------------

  v1gen : if (v="v1") generate
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
  end generate;

  --------------------------------------------------------------------------------
  -- Timestamp
  --------------------------------------------------------------------------------

  -- on the falling edge of the tiu GPS signal, latch the timestamp
  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_gps_sr(0) <= tiu_gps;

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

  --------------------------------------------------------------------------------
  -- Monitor
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (tiu_busy_i = '1' and tiu_trigger_o = '0') then
        tiu_bad_o <= '1';
      elsif (tiu_busy_i = '1' and tiu_trigger_o = '1') then
        tiu_bad_o <= '0';
      end if;

      if (reset = '1') then
        tiu_bad_o <= '0';
      end if;

    end if;
  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if tiu_busy_i = '0' then
        tiu_stuck_cnt <= (others => '0');
      elsif (tiu_stuck_cnt < tiu_stuck_cnt_max) then
        tiu_stuck_cnt <= tiu_stuck_cnt + 1;
      end if;

      if (tiu_stuck_cnt = tiu_stuck_cnt_max) then
        tiu_stuck_o <= '1';
      else
        tiu_stuck_o <= '0';
        end if;
    end if;
  end process;

  tiu_busy_i_rising <= tiu_busy_i and not tiu_busy_i_reg;
  tiu_busy_i_falling <= not tiu_busy_i and tiu_busy_i_reg;

  process (clock) is
  begin
    if (rising_edge(clock)) then
      tiu_busy_i_reg <= tiu_busy_i;

      if tiu_busy_i_falling = '1' then
        tiu_busy_length_o <= std_logic_vector(tiu_busy_cnt);
      end if;

      if tiu_busy_i = '1' then
        tiu_busy_cnt <= tiu_busy_cnt + 1;
      elsif tiu_busy_i = '0' then
        tiu_busy_cnt <= (others => '0');
      end if;

    end if;
  end process;


end behavioral;
