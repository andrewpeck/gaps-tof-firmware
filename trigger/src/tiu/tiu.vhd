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
    tiu_emulation_mode        : in std_logic;
    tiu_emu_busy_cnt_i        : in std_logic_vector (17 downto 0);

    -- mt trigger signals
    trigger_i   : in std_logic;
    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0);
    timestamp_i : in std_logic_vector (TIMESTAMPB-1 downto 0);

    -- outputs

    tiu_bad_o : out std_logic := '0';

    global_busy_o : out std_logic;

    tiu_gps_valid_o : out std_logic;
    tiu_gps_o       : out std_logic_vector (GPSB-1 downto 0);

    timestamp_o       : out std_logic_vector (TIMESTAMPB-1 downto 0);
    timestamp_valid_o : out std_logic

    );
end tiu;

architecture behavioral of tiu is

  constant CLK_PERIOD          : real    := 1000000.0/real(FREQ);
  constant tiu_trigger_cnt_max : integer := integer(1.05 / CLK_PERIOD);
  constant tiu_busy_cnt_max    : integer := 2**tiu_emu_busy_cnt_i'length-1;

  signal tiu_busy : std_logic := '0';
  signal tiu_gps  : std_logic := '0';

  --------------------------------------------------------------------------------
  -- Trigger Logic
  --------------------------------------------------------------------------------

  signal tiu_trigger       : std_logic                              := '0';
  signal event_cnt         : std_logic_vector (event_cnt_i'range)   := (others => '0');
  signal tiu_trigger_cnt   : integer range 0 to tiu_trigger_cnt_max := 0;
  signal ready_for_trigger : std_logic;
  signal tiu_tx_busy       : std_logic                              := '0';
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

  --------------------------------------------------------------------------------
  -- Emulation
  --------------------------------------------------------------------------------

  signal tiu_emu_busy_cnt : integer range 0 to tiu_busy_cnt_max := 0;
  signal tiu_emu_busy     : std_logic                           := '0';
  signal tiu_emu_byte     : std_logic_vector (7 downto 0)       := (others => '0');
  signal tiu_emu_dav      : std_logic;
  signal tiu_emu_tre      : std_logic;
  signal tiu_emu_thre     : std_logic;
  signal tiu_emu_ready    : std_logic;
  signal tiu_emu_gps      : std_logic;
  signal tiu_emu_word     : std_logic_vector (GPSB-1 downto 0)  := (others => '0');
  signal tiu_emu_byte_cnt : integer range 0 to GPSB/8-1         := 0;

  type busy_state_t is (IDLE, WAITING_FOR_BUSY, BUSY);
  signal tiu_busy_state : busy_state_t := IDLE;

  type gps_rx_state_t is (IDLE, WAIT_FOR_EMPTY, LOAD, WAIT_FOR_BUSY);
  signal gps_rx_state : gps_rx_state_t := IDLE;

  signal pps            : std_logic := '0';
  signal second_cnt     : unsigned (31 downto 0);
  signal sub_second_cnt : integer range 0 to FREQ - 1;

begin

  ila_mt_inst : ila_mt
    port map (
      clk                   => clock,
      probe0(0)             => tiu_busy,
      probe1(0)             => tiu_gps,
      probe2(0)             => tiu_busy_i,
      probe2(1)             => tiu_serial_o,
      probe2(2)             => tiu_gps,
      probe2(3)             => tiu_trigger,
      probe2(4)             => trigger_i,
      probe2(5)             => global_busy_o,
      probe2(6)             => timestamp_valid_o,
      probe2(7)             => tiu_gps_valid_o,
      probe2(55 downto 8)   => tiu_gps_o,
      probe2(57 downto 56)  => std_logic_vector(to_unsigned(gps_rx_state_t'pos(gps_rx_state), 2)),
      probe2(61 downto 58)  => (others => '0'),
      probe2(74 downto 62)  => (others => '0'),
      probe3(3 downto 0)    => std_logic_vector(to_unsigned(tiu_emu_byte_cnt, 4)),
      probe3(4)             => pps,
      probe3(5)             => '0',
      probe3(6)             => '0',
      probe3(7)             => '0',
      probe4(4 downto 0)    => (others => '0'),
      probe4(5)             => tiu_emulation_mode,
      probe4(6)             => tiu_busy,
      probe4(7)             => '0',
      probe5(0)             => tiu_timebyte_dav,
      probe6(0)             => '0',
      probe7(0)             => '0',
      probe8(0)             => '0',
      probe9(1 downto 0)    => (others => '0'),
      probe10(31 downto 0)  => event_cnt,
      probe11(31 downto 0)  => timestamp_o,
      probe12(31 downto 0)  => timestamp_i,
      probe13(0)            => tiu_tx_busy,
      probe13(1)            => tiu_init_tx,
      probe13(2)            => tiu_timeout,
      probe13(3)            => ready_for_trigger,
      probe13(4)            => tiu_tx_busy,
      probe13(5)            => tiu_init_tx,
      probe13(6)            => tiu_timeout,
      probe13(7)            => tiu_falling,
      probe13(15 downto 8)  => tiu_timebyte,
      probe13(19 downto 16) => std_logic_vector(to_unsigned(tiu_byte_cnt, 4)),
      probe13(20)           => tiu_emu_busy,
      probe13(28 downto 21) => tiu_emu_byte,
      probe13(29)           => tiu_emu_dav,
      probe13(30)           => tiu_emu_ready,
      probe13(31)           => tiu_emu_gps,
      probe14(31 downto 0)  => (others => '0')
      );

  tiu_busy <= tiu_emu_busy when tiu_emulation_mode = '1' else tiu_busy_i;
  tiu_gps  <= tiu_emu_gps  when tiu_emulation_mode = '1' else tiu_gps_i;

  --------------------------------------------------------------------------------
  -- Trigger Out
  --------------------------------------------------------------------------------

  -- upon receiving a trigger, we should:
  --  1) assert the trigger output
  --  2) wait a for 1.05 us for the ACK signal (busy) to come from the SiLI
  --     - If ACK does not come, timeout and do ???
  --  3) When ACK is received, send the event counter
  --  4) When ACK is deasserted, ready for the next trigger

  ready_for_trigger <= '1' when tiu_tx_busy = '0' and
                       tiu_busy = '0' and
                       tiu_trigger = '0' and
                       tiu_timeout = '0' and
                       tiu_trigger_cnt = 0 else '0';

  -- or the statemachine derived tiu_trigger signal with the async
  -- source of the trigger so that it is activated 1 clock cycle ahead of the
  -- state machine. this reduces latency by 1 clock. thanks to the OR, once the
  -- state machine takes effect the active hi trigger signal will get taken
  -- over and held high until the ack comes back from the tiu
  tiu_trigger_o <= tiu_trigger or (ready_for_trigger and trigger_i);

  global_busy_o <= not ready_for_trigger;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_init_tx <= '0';
      tiu_trigger <= '0';
      tiu_timeout <= '0';

      -- start a trigger
      if (ready_for_trigger = '1' and trigger_i = '1') then
        tiu_trigger     <= '1';
        tiu_trigger_cnt <= tiu_trigger_cnt_max;
        event_cnt       <= event_cnt_i;

      -- when the busy/ack is received, deassert the trigger output and start the
      -- event count serializer
      elsif (tiu_trigger = '1' and tiu_busy = '1') then
        tiu_init_tx     <= '1';
        tiu_trigger     <= '0';
        tiu_trigger_cnt <= 0;

      -- still waiting for the busy
      elsif (tiu_trigger = '1' and tiu_trigger_cnt > 0) then
        tiu_trigger_cnt <= tiu_trigger_cnt - 1;
        tiu_trigger     <= '1';

      -- timeout
      elsif (tiu_trigger = '1' and tiu_trigger_cnt = 0) then
        tiu_trigger_cnt <= 0;
        tiu_trigger     <= '0';
        tiu_timeout     <= '1';

        if (send_event_cnt_on_timeout = '1') then
          tiu_init_tx <= '1';
        end if;

      -- else:
      --  + waiting for busy to be deasserted
      --  + ???
      else
        tiu_trigger_cnt <= 0;
        tiu_trigger     <= '0';
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
      TXD  => tiu_emu_gps,
      RXD  => tiu_gps,

      RR   => tiu_timebyte,     --! Receiver Holding Register Data Output
      PE   => open,             --! Parity error
      FE   => open,             --! Framing error
      DR   => tiu_timebyte_dav, --! Data Received, one clock cycle high
      TR   => tiu_emu_byte,     --! Transmitter Holding Register Data Input

      THRE => tiu_emu_thre,     --! Transmitter Holding Register Empty
      THRL => tiu_emu_dav,      --! Transmitter Holding Register Load, one clock cycle high
      TRE  => tiu_emu_tre       --! Transmitter Register Empty
      );

  tiu_emu_ready <= tiu_emu_thre and tiu_emu_tre;

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

  -- v2gen : if (v="v2") generate
  --   type ts_state_t is (IDLE, LATCHING);
  --   signal ts_state : ts_state_t := IDLE;
  -- begin

  --   process (clock)
  --   begin
  --     if (rising_edge(clock)) then
  --       case state is

  --         when IDLE =>

  --           if (tiu_falling = '1') then
  --             tiu_byte_cnt <= 0;
  --             ts_state     <= LATCHING;
  --           end if;

  --         when LATCHING =>

  --           if (tiu_timebyte_dav = '1') then

  --             if (tiu_byte_cnt < 5) then
  --               tiu_byte_cnt <= tiu_byte_cnt + 1;
  --               tiu_gps_buf(8*(tiu_byte_cnt+1)-1 downto 8*tiu_byte_cnt)
  --                 <= tiu_timebyte;
  --             else
  --               tiu_byte_cnt    <= 0;
  --               tiu_gps_o       <= tiu_timebyte & tiu_gps_buf;
  --               tiu_gps_valid_o <= '1';
  --               ts_state        <= IDLE;
  --             end if;
  --           end if;

  --         when others =>

  --       end case;

  --       if (reset = '1') then
  --         state <= IDLE;
  --       end if;

  --     end if;
  --   end process;

  -- end generate;

  --------------------------------------------------------------------------------
  -- 1
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

      if (tiu_falling = '1' or (pps = '1' and tiu_emulation_mode = '1')) then
        timestamp_o       <= timestamp_i;
        timestamp_valid_o <= '1';
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- TIU Emulator
  --------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then

      case tiu_busy_state is

        when IDLE =>

          tiu_emu_busy <= '0';

          if (tiu_trigger = '1') then
            tiu_busy_state   <= WAITING_FOR_BUSY;
            tiu_emu_busy_cnt <= 100;
          end if;

        when WAITING_FOR_BUSY =>

          tiu_emu_busy <= '0';

          if (tiu_emu_busy_cnt > 0) then
            tiu_emu_busy_cnt <= tiu_emu_busy_cnt - 1;
          elsif (tiu_emu_busy_cnt = 0) then
            tiu_busy_state   <= BUSY;
            tiu_emu_busy_cnt <= to_integer(unsigned(tiu_emu_busy_cnt_i));
          end if;

        when BUSY =>

          tiu_emu_busy <= '1';

          if (tiu_emu_busy_cnt > 0) then
            tiu_emu_busy_cnt <= tiu_emu_busy_cnt - 1;
          elsif (tiu_emu_busy_cnt = 0) then
            tiu_busy_state <= IDLE;
          end if;

        when others =>

          tiu_busy_state <= IDLE;

      end case;

      if (reset = '1') then
        tiu_busy_state <= IDLE;
      end if;

    end if;
  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then
        second_cnt     <= (others => '0');
        sub_second_cnt <= 0;
        pps            <= '0';
      elsif (sub_second_cnt < FREQ-1) then
        second_cnt     <= second_cnt;
        sub_second_cnt <= sub_second_cnt + 1;
        pps            <= '0';
      else
        second_cnt     <= second_cnt + '1';
        sub_second_cnt <= 0;
        pps            <= '1';
      end if;
    end if;
  end process;

  process (clock)
  begin
    if (rising_edge(clock)) then

      tiu_emu_byte <= (others => '0');
      tiu_emu_dav  <= '0';

      case gps_rx_state is

        when IDLE =>

          if (pps = '1') then
            gps_rx_state     <= WAIT_FOR_EMPTY;
            tiu_emu_byte_cnt <= 0;
            tiu_emu_word     <= x"0000" & std_logic_vector(second_cnt);
          end if;

        when WAIT_FOR_EMPTY =>

          if (tiu_emu_ready = '1') then
            gps_rx_state <= LOAD;
          end if;

        when LOAD =>

          tiu_emu_byte <= tiu_emu_word(8*(1+tiu_emu_byte_cnt)-1 downto
                                       8*tiu_emu_byte_cnt);
          tiu_emu_dav  <= '1';
          gps_rx_state <= WAIT_FOR_BUSY;

        when WAIT_FOR_BUSY =>

          -- it takes a few clocks from the load signal until empty goes low,
          -- so make sure we acknowledge the load then go back to wait for idle
          -- again
          if (tiu_emu_byte_cnt = GPSB/8-1) then
            gps_rx_state <= IDLE;
          elsif (tiu_emu_ready = '0') then
            gps_rx_state     <= WAIT_FOR_EMPTY;
            tiu_emu_byte_cnt <= tiu_emu_byte_cnt + 1;
          end if;

      end case;

      if (reset = '1') then
        gps_rx_state <= IDLE;
      end if;

    end if;
  end process;

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

end behavioral;
