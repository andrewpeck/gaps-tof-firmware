-- -*- fill-column: 100; -*-
library work;
use work.types_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity daq is
  generic(
    g_PACKET_PAD    : positive := 32;
    g_WORD_SIZE     : positive := 16;
    g_MSB_FIRST     : boolean  := false;
    g_BIG_ENDIAN : boolean  := false
    );
  port(
    clock : in std_logic;               -- clock of arbitrary frequency
    reset : in std_logic;               -- SYNCHRONOUS reset

    debug_packet_inject_i : in std_logic;  -- assert 1 and it will send a debug (fixed content) packet

    -- Trigger info
    stop_cell_i : in std_logic_vector (9 downto 0);
    trigger_i   : in std_logic;
    fragment_i  : in std_logic;
    event_cnt_i : in std_logic_vector (31 downto 0);
    mask_i      : in std_logic_vector (8 downto 0);

    ack_o : out std_logic;

    gfp_use_eventid_i     : in  std_logic;
    gfp_eventid_i         : in  std_logic_vector (31 downto 0);
    gfp_eventid_valid_i   : in  std_logic;
    gfp_eventid_read_o    : out std_logic;
    gfp_eventid_timeout_o : out std_logic;

    -- status
    temperature_i  : in std_logic_vector (11 downto 0);
    loss_of_lock_i : in std_logic;
    lock_stable    : in std_logic;
    board_id       : in std_logic_vector (7 downto 0);
    sync_err_i     : in std_logic;
    dna_i          : in std_logic_vector (63 downto 0);
    hash_i         : in std_logic_vector (31 downto 0);
    timestamp_i    : in std_logic_vector (47 downto 0);
    roi_size_i     : in std_logic_vector (9 downto 0);
    dtap_i         : in std_logic_vector (15 downto 0);
    drs_temp_i     : in std_logic_vector (15 downto 0);

    drs_busy_i  : in  std_logic;
    drs_data_i  : in  std_logic_vector (13 downto 0);
    drs_valid_i : in  std_logic;
    drs_rden_o  : out std_logic := '0';

    data_o  : out std_logic_vector (g_WORD_SIZE-1 downto 0);  -- receive 16 bits / bx
    valid_o : out std_logic;
    busy_o  : out std_logic;
    ready_o : out std_logic;
    done_o  : out std_logic

    );
end daq;

architecture behavioral of daq is

  type state_t is (IDLE_state, ERR_state, HEAD_state, STATUS_state, LENGTH_state, ROI_state,
                   DNA_state, RSVD0_state, RSVD1_state, RSVD2_state, HASH_state, ID_state,
                   CHMASK_state, WAIT_EVENT_CNT_state, EVENT_CNT_state, DTAP_state, DRS_TEMP_state,
                   TIMESTAMP_state, CALC_CH_CRC_state, CH_CRC_state, CH_HEADER_state, PAYLOAD_state,
                   STOP_CELL_state, CALC_CRC32_state, CRC32_state, TAIL_state, PAD_state,
                   WAIT_state);

  signal state : state_t := IDLE_state;

  constant HEAD : std_logic_vector (g_WORD_SIZE-1 downto 0) := x"AAAA";
  constant TAIL : std_logic_vector (g_WORD_SIZE-1 downto 0) := x"5555";

  signal data            : std_logic_vector (g_WORD_SIZE-1 downto 0) := (others => '0');
  signal packet_crc      : std_logic_vector (31 downto 0)            := (others => '0');
  signal channel_crc     : std_logic_vector (31 downto 0)            := (others => '0');
  signal packet_crc_en   : std_logic                                 := '0';
  signal channel_crc_en  : std_logic                                 := '0';
  signal packet_crc_rst  : std_logic                                 := '1';
  signal channel_crc_rst : std_logic                                 := '1';

  signal dropped  : std_logic := '0';
  signal fragment : std_logic := '0';
  signal debug    : boolean   := false;

  signal status         : std_logic_vector (15 downto 0) := (others => '0');
  signal rsvd0          : std_logic_vector (15 downto 0) := (others => '0');
  signal rsvd1          : std_logic_vector (15 downto 0) := (others => '0');
  signal rsvd2          : std_logic_vector (15 downto 0) := (others => '0');
  signal packet_length  : std_logic_vector (15 downto 0) := (others => '0');
  signal packet_padding : natural range 0 to g_PACKET_PAD;
  signal payload_size   : natural                        := 0;
  signal num_channels   : natural range 0 to 15          := 0;
  signal id             : std_logic_vector (15 downto 0) := (others => '0');

  signal mask          : std_logic_vector (17 downto 0)       := (others => '0');
  signal event_cnt     : std_logic_vector (event_cnt_i'range) := (others => '0');
  -- mux the event count between normal daq and gfp
  signal event_cnt_mux : std_logic_vector (event_cnt_i'range) := (others => '0');

  signal timestamp : std_logic_vector (timestamp_i'range) := (others => '0');
  signal dna       : std_logic_vector (15 downto 0)       := (others => '0');
  signal hash      : std_logic_vector (15 downto 0)       := (others => '0');

  constant DNA_WORDS         : positive := dna'length / g_WORD_SIZE;
  constant TIMESTAMP_WORDS   : positive := timestamp'length / g_WORD_SIZE;
  constant EVENT_CNT_WORDS   : positive := event_cnt'length / g_WORD_SIZE;
  constant PACKET_CRC_WORDS  : positive := packet_crc'length / g_WORD_SIZE;
  constant CHANNEL_CRC_WORDS : positive := channel_crc'length / g_WORD_SIZE;

  signal roi_size : natural range 0 to 1023;

  signal state_word_cnt : natural range 0 to 1024 := 0;
  signal channel_cnt    : natural range 0 to 15   := 0;
  signal channel_id     : natural range 0 to 17   := 0;

  constant EVENTID_TIMEOUT_MAX : natural := 10000000;
  signal gfp_eventid_timeout_counter : natural range 0 to EVENTID_TIMEOUT_MAX := 0;

  constant PAYLOAD_TIMEOUT_MAX: natural := 2**16-1;
  signal payload_timeout_counter : natural range 0 to PAYLOAD_TIMEOUT_MAX := 0;
  signal packet_timed_out : std_logic := '0';

  signal dav : boolean := false;

  -- get the first channel which will be read out from a given channel mask
  function get_first_channel (chmask : std_logic_vector)
    return natural is
  begin
    for I in 0 to chmask'length-1 loop
      if chmask(I) = '1' then
        return I;
      end if;
    end loop;
    return 0;
  end;

  -- get the next channel which will be read out from a given channel mask
  function get_next_channel (ch : natural; chmask : std_logic_vector)
    return natural is
  begin
    for I in 0 to chmask'length-1 loop
      if (I > ch) and chmask(I) = '1' then
        return I;
      end if;
    end loop;
    return 0;
  end;

  --
  function data_sel (msb_first : boolean;
                     size      : natural;
                     total     : natural;
                     cnt       : natural;
                     payload   : std_logic_vector)
    return std_logic_vector is
    variable dout : std_logic_vector (size-1 downto 0);
  begin
    if (msb_first) then
      dout := payload(size*(total-cnt)-1 downto size*(total-cnt-1));
    else
      dout := payload(size*(cnt+1)-1 downto size*cnt);
    end if;
    return dout;
  end;

  function swap_data_bytes (swap : boolean;
                            din  : std_logic_vector (15 downto 0))
    return std_logic_vector is
  begin
    if (swap) then
      return din(7 downto 0) & din(15 downto 8);
    else
      return din;
    end if;
  end;

  impure function get_payload_size (packet_dropped  : std_logic;
                                    packet_roi_size : natural;
                                    ch_mask         : std_logic_vector)
    return natural is
  begin
    -- size of each readout * number of readouts + 9th channel (if the packet is not empty)
    if (packet_dropped = '1') then
      return 0;
    else

      return (
        -- count the number of channels enabled
        -- if /any/ channel is enabled, then add 1 additional channel for 9th channel
        -- e.g. if 0 selected channels, read 0
        --      if 1 selected channels, read 2 (x + 9th)
        --      etc..
        -- Then multiply by roi_size + 1 + 2 (for the crc)

        (count_ones(ch_mask)) * (1+1+packet_roi_size + channel_crc'length / g_WORD_SIZE)
        );
    end if;
  end function;

  -- dma expects multiple of g_PACKET_PAD words... pad the tail with zeroes
  function get_packet_padding (packet_size : natural)
    return natural is
    variable ret : natural;
  begin
    ret := packet_size mod g_PACKET_PAD;
    if (ret = 0) then
      return 0;
    else
      return g_PACKET_PAD-ret;
    end if;
  end function;

  impure function get_packet_size (packet_payload_size : natural)
    return natural is
  begin
    return (
      HEAD'length / g_WORD_SIZE
      + status'length / g_WORD_SIZE
      + packet_length'length / g_WORD_SIZE
      + dna'length / g_WORD_SIZE
      + rsvd0'length / g_WORD_SIZE
      + rsvd1'length / g_WORD_SIZE
      + rsvd2'length / g_WORD_SIZE
      + hash'length / g_WORD_SIZE
      + data'length / g_WORD_SIZE       -- roi
      + data'length / g_WORD_SIZE       -- stop cell
      + id'length / g_WORD_SIZE
      + mask'length / g_WORD_SIZE
      + event_cnt'length / g_WORD_SIZE
      + dtap_i'length / g_WORD_SIZE
      + drs_temp_i'length / g_WORD_SIZE
      + timestamp'length / g_WORD_SIZE
      + packet_payload_size             -- roi counts from 0
      + packet_crc'length / g_WORD_SIZE
      + tail'length / g_WORD_SIZE
      );
  end function;

begin

  packet_crc_en <= if_then_else ((dav and state /= TAIL_state and state /= CRC32_state), '1', '0');
  channel_crc_en <= if_then_else (
    (state = CALC_CH_CRC_state) or
    ((state_word_cnt > 0) and dav and state = PAYLOAD_state), '1', '0');

  process (clock) is
  begin
    if (rising_edge(clock)) then
      packet_crc_rst  <= if_then_else ((state = IDLE_state or state = TAIL_state), '1', '0');
      channel_crc_rst <= if_then_else (((state = CH_CRC_state and state_word_cnt = 0) or state = IDLE_state), '1', '0');
    end if;
  end process;

  packet_crc32 : entity work.crc32
    port map (
      clock  => clock,
      data   => swap_data_bytes(g_BIG_ENDIAN, data),
      reset  => packet_crc_rst,
      enable => packet_crc_en,
      crc    => packet_crc
      );

  channel_crc32 : entity work.crc32
    port map (
      clock  => clock,
      data   => swap_data_bytes(g_BIG_ENDIAN, data),
      enable => channel_crc_en,
      reset  => channel_crc_rst,
      crc    => channel_crc
      );

  busy_o  <= '0' when state = IDLE_state or state = WAIT_state else '1';
  done_o  <= '1' when state = TAIL_state                       else '0';
  ready_o <= '1' when state = IDLE_state                       else '0';

  --------------------------------------------------------------------------------
  -- Packet Formatter
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then

      -- stable copies of trigger parameters
      if (state = IDLE_state and (fragment_i='1' or trigger_i = '1' or debug_packet_inject_i = '1')) then
        if (debug_packet_inject_i = '1') then
          status       <= x"9999";
          id           <= x"4444";
          roi_size     <= 1023;
          debug        <= true;
          dropped      <= '0';
          fragment     <= '0';
          num_channels <= 9;
          mask         <= '0' & x"00" & '1' & x"FF";
          dna          <= x"3210";
          hash         <= x"3210";
          event_cnt    <= x"76543210";
          timestamp    <= x"BA9876543210";
        else

          status(0)           <= fragment_i;
          status(1)           <= drs_busy_i;
          status(2)           <= loss_of_lock_i;
          status(3)           <= lock_stable;
          status(15 downto 4) <= temperature_i;

          id(0)           <= '0';
          id(15 downto 8) <= board_id;
          id (7 downto 1) <= (others => '0');

          roi_size     <= to_int (roi_size_i);
          fragment     <= fragment_i;
          dna          <= dna_i(15 downto 0) xor
                          dna_i(31 downto 16) xor
                          dna_i(47 downto 32) xor
                          dna_i(63 downto 48);
          hash         <= hash_i (27 downto 12);
          debug        <= false;
          dropped      <= drs_busy_i;
          num_channels <= count_ones (mask_i);
          mask         <= "000000000" & mask_i;
          event_cnt    <= event_cnt_i;
          timestamp    <= timestamp_i;
        end if;
      end if;

      -- let this pipeline over 2 clocks
      payload_size   <= get_payload_size(fragment or dropped, roi_size, mask);
      packet_length  <= to_slv(get_packet_size(payload_size), packet_length'length);
      packet_padding <= get_packet_padding(to_integer(unsigned(packet_length)));

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- State Machine
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then

      dav                   <= false;
      data                  <= (others => '0');
      drs_rden_o            <= '0';
      gfp_eventid_timeout_o <= '0';
      ack_o                 <= '0';

      case state is

        when IDLE_state =>

          channel_cnt <= 0;
          channel_id  <= 0;

          packet_timed_out            <= '0';
          payload_timeout_counter     <= 0;
          gfp_eventid_timeout_counter <= 0;

          if (fragment_i = '1' or trigger_i = '1' or debug_packet_inject_i = '1') then
            state <= HEAD_state;
            ack_o <= '1';
          end if;

        when HEAD_state =>

          state <= STATUS_state;

          data <= HEAD;
          dav  <= true;

        when STATUS_state =>

          state <= LENGTH_state;

          data <= status;
          dav  <= true;

        when LENGTH_state =>

          state <= ROI_state;

          data <= packet_length;
          dav  <= true;

        when ROI_state =>

          state <= DNA_state;

          data <= to_slv(roi_size, data'length);
          dav  <= true;

        when DNA_state =>
          state <= RSVD0_state;
          data  <= dna;
          dav   <= true;

        when RSVD0_state =>
          state <= RSVD1_state;
          data  <= x"0000";
          dav   <= true;

        when RSVD1_state =>
          state <= RSVD2_state;
          data  <= x"0000";
          dav   <= true;

        when RSVD2_state =>
          state <= HASH_state;
          data  <= x"0000";
          dav   <= true;

        when HASH_state =>

          state <= ID_state;

          data <= hash;

          dav <= true;

        when ID_state =>

          state <= CHMASK_state;

          data <= id;
          dav  <= true;

        when CHMASK_state =>

          if (gfp_use_eventid_i = '1') then
            state <= WAIT_EVENT_CNT_state;
          else
            state         <= EVENT_CNT_state;
            event_cnt_mux <= event_cnt;
          end if;

          data <= "0000000" & mask (8 downto 0);
          dav  <= true;

          channel_id <= get_first_channel(mask);

        when WAIT_EVENT_CNT_state =>

          gfp_eventid_timeout_counter <= gfp_eventid_timeout_counter + 1;

          if (gfp_eventid_timeout_counter = EVENTID_TIMEOUT_MAX) then
            state                   <= EVENT_CNT_state;
            event_cnt_mux           <= x"FFFFFFFE";
            gfp_eventid_timeout_o   <= '1';
          elsif (gfp_eventid_valid_i = '1') then
            state                   <= EVENT_CNT_state;
            event_cnt_mux           <= gfp_eventid_i;
            gfp_eventid_read_o      <= '1';
          end if;

          dav <= false;

        when EVENT_CNT_state =>

          gfp_eventid_read_o <= '0';
          gfp_eventid_timeout_counter <= 0;

          if (state_word_cnt = event_cnt'length / g_WORD_SIZE - 1) then
            state          <= DTAP_state;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          data <= data_sel(g_MSB_FIRST, g_WORD_SIZE, EVENT_CNT_WORDS, state_word_cnt, event_cnt_mux);
          dav  <= true;

        when DTAP_state =>

          state <= DRS_TEMP_state;

          data <= dtap_i;
          dav  <= true;

        when DRS_TEMP_state =>

          state <= TIMESTAMP_state;

          data <= drs_temp_i;
          dav  <= true;

        when TIMESTAMP_state =>

          if (state_word_cnt = timestamp'length / g_WORD_SIZE - 1) then

            if (fragment = '1' or dropped = '1') then
              state <= CRC32_state;
            else
              state <= CH_HEADER_state;
            end if;

            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          data <= data_sel(g_MSB_FIRST, g_WORD_SIZE, TIMESTAMP_WORDS, state_word_cnt, timestamp);
          dav  <= true;

        when CH_HEADER_state =>

          if (num_channels = 0) then
            state          <= CRC32_state;
            state_word_cnt <= 0;
          else
            state          <= PAYLOAD_state;
            state_word_cnt <= 0;
            drs_rden_o     <= '1';
          end if;

          data <= to_slv (channel_id, data'length);
          dav  <= true;

        when PAYLOAD_state =>

          drs_rden_o <= '1';

          if (packet_timed_out = '1' or debug or drs_valid_i = '1') then
            state_word_cnt          <= state_word_cnt + 1;
            payload_timeout_counter <= 0;
          else
            payload_timeout_counter <= payload_timeout_counter + 1;
          end if;

          if (payload_timeout_counter = PAYLOAD_TIMEOUT_MAX) then
            payload_timeout_counter <= 0;
            packet_timed_out        <= '1';
          elsif (num_channels = 0) then
            state          <= CRC32_state;
            state_word_cnt <= 0;
            drs_rden_o     <= '0';
          elsif (packet_timed_out = '1' or debug or drs_valid_i = '1')
            and (state_word_cnt = roi_size) then
            payload_timeout_counter <= 0;
            state                   <= CALC_CH_CRC_state;
            state_word_cnt          <= 0;
            channel_cnt             <= channel_cnt + 1;
            channel_id              <= get_next_channel(channel_id, mask);
            drs_rden_o              <= '0';
          end if;

          dav  <= false;
          data <= (others => '0');

          if (debug) then
            dav  <= true;
            data <= to_slv(state_word_cnt, g_WORD_SIZE);
          elsif (packet_timed_out = '1' and num_channels > 0) then
            dav  <= true;
            data <= x"fffe";
          elsif (drs_valid_i = '1' and num_channels > 0) then
            data <= xor_reduce(drs_data_i(13 downto 7)) & xor_reduce(drs_data_i(6 downto 0))  -- parity bits
                    & drs_data_i;                                                             -- adc data
            dav <= true;
          end if;

        when CALC_CH_CRC_state =>

          -- need 1 extra clock to calculate the channel crc
          state <= CH_CRC_state;
          dav   <= false;
          data  <= (others => '0');

        when CH_CRC_state =>

          if (state_word_cnt = CHANNEL_CRC'length / 16 - 1) then
            if (channel_cnt = num_channels) then
              state <= STOP_CELL_state;
            else
              state <= CH_HEADER_state;
            end if;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          data <= data_sel(g_MSB_FIRST, g_WORD_SIZE, CHANNEL_CRC_WORDS, state_word_cnt, channel_crc);
          dav  <= true;

        when STOP_CELL_state =>

          -- need 1 extra clock to calculate the crc
          state <= CALC_CRC32_state;
          dav   <= true;
          if (debug) then
            data <= x"7777";
          else
            data <= "000000" & stop_cell_i;
          end if;

        when CALC_CRC32_state =>

          -- need 1 extra clock to calculate the crc
          state <= CRC32_state;
          dav   <= false;
          data  <= (others => '0');

        when CRC32_state =>

          if (state_word_cnt = PACKET_CRC'length / 16 - 1) then
            state          <= TAIL_state;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          data <= data_sel(g_MSB_FIRST, g_WORD_SIZE, PACKET_CRC_WORDS, state_word_cnt, packet_crc);
          dav  <= true;

        when TAIL_state =>

          state <= PAD_state;

          data <= TAIL;
          dav  <= true;

        when PAD_state =>

          if (state_word_cnt = packet_padding - 1) then
            state          <= WAIT_state;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          data <= x"0000";
          dav  <= true;

        when WAIT_state =>

          -- the dma block is fragile and I think it mayb have some dependency on a few idle cycles
          -- between packets, add this here to make sure there is always some small period between
          -- one packet and the next

          if (state_word_cnt = g_PACKET_PAD-1) then
            state          <= IDLE_state;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          data <= x"0000";
          dav  <= true; -- we write one PAD worth of information
                        -- (one DMA transfer's worth) with the busy bit deasserted so that
                        -- the fifo can switch

        when others =>

          state <= IDLE_state;

      end case;

      if (reset = '1') then
        state <= IDLE_state;
      end if;

    end if;

  end process;

  valid_o <= '1' when dav else '0';
  data_o  <= data;

end behavioral;
