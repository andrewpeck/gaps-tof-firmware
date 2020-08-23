-- -*- fill-column: 100; -*-
library work;
use work.types_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

-- TODO: CRC
--
-- TODO: handle the case that we get a trigger but both DRS chips are busy
--
-- TODO that makes me think also it might be a good feature for the DAQ to be able to inject a debug
-- packet (send a command, it will generate an event with an exact, predictable format, fixed
-- length, fixed event ID, all 9 channels of ADC data filled with just a counter (cell0=0,
-- cell1=1.... cell 1023=1023). It seems useful for debugging the unpacker, testing the DMA, etc.

-- Each daq block handles one trigger data stream, and is assumed busy during readout Instantiate as
-- many daq blocks as needed to deal with the trigger rate some higher level arbitrator should dole
-- out triggers to the daq blocks as needed
--
-- Each daq block handles only 1 DRS chip
--
entity daq is
  generic(
    g_DRS_ID    : integer := 0;
    g_WORD_SIZE : integer := 16
    );
  port(
    clock : in std_logic;               -- clock of arbitrary frequency
    reset : in std_logic;               -- SYNCHRONOUS reset

    debug_packet_inject_i : in std_logic;  -- assert 1 and it will send a debug (fixed content) packet

    -- Trigger info
    trigger_i   : in std_logic;
    event_cnt_i : in std_logic_vector (31 downto 0);
    mask_i      : in std_logic_vector (15 downto 0);

    -- status
    board_id    : in std_logic_vector (7 downto 0);
    sync_err_i  : in std_logic;
    dna_i       : in std_logic_vector (63 downto 0);
    timestamp_i : in std_logic_vector (47 downto 0);
    roi_size_i  : in std_logic_vector (9 downto 0);

    drs_busy_i  : in std_logic;
    drs_data_i  : in std_logic_vector (13 downto 0);
    drs_valid_i : in std_logic;

    data_o  : out std_logic_vector (g_WORD_SIZE-1 downto 0);  -- receive 16 bits / bx
    valid_o : out std_logic;
    busy_o  : out std_logic

    );
end daq;

architecture behavioral of daq is

  -- |-----------+--------+------------------------------------------------|
  -- | Field     | Len    | Description                                    |
  -- |-----------+--------+------------------------------------------------|
  -- | HEAD      | [15:0] | 0xAAAA                                         |
  -- |-----------+--------+------------------------------------------------|
  -- | STATUS    | [15:0] | [0] =sync_err                                  |
  -- |           |        | [1] = drs was busy (lost trigger)              |
  -- |           |        | [15:1]=reserved                                |
  -- |-----------+--------+------------------------------------------------|
  -- | LEN       | [15:0] | length of packet, need to precalculate         |
  -- |-----------+--------+------------------------------------------------|
  -- | ROI       | [15:0] | size of region of interest                     |
  -- |-----------+--------+------------------------------------------------|
  -- | DNA       | [63:0] | Zynq7000 Device DNA                            |
  -- |-----------+--------+------------------------------------------------|
  -- | ID        | [15:0] | [15:8] = readout board ID                      |
  -- |           |        | [7:1] = reserved                               |
  -- |           |        | [0] = drs #0 or #1                             |
  -- |-----------+--------+------------------------------------------------|
  -- | CH_MASK   | [15:0] | Channel Enable Mask '1'=ON                     |
  -- |-----------+--------+------------------------------------------------|
  -- | EVENT_CNT | [31:0] | Event ID Received From Trigger                 |
  -- |-----------+--------+------------------------------------------------|
  -- | TIMESTAMP | [47:0] | # of 33MHz clocks elapsed since resync         |
  -- |-----------+--------+------------------------------------------------|
  -- | PAYLOAD   |        | 0 to XXXX words                                |
  -- |           |        |                                                |
  -- |           |        | HEADER[15:0] = Channel ID                      |
  -- |           |        | data bits [13:0] = ADC data                    |
  -- |           |        | data bits [15:14] parity                       |
  -- |           |        | trailer[31:0] = crc32                          |
  -- |-----------+--------+------------------------------------------------|
  -- | CRC32     | [31:0] | Packet CRC (excluding Trailer)                 |
  -- |-----------+--------+------------------------------------------------|
  -- | TAIL      | [15:0] | 0x5555                                         |
  -- |-----------+--------+------------------------------------------------|

  -- packet processing in python 15% faster by adding a channel header!!
  type state_t is (IDLE_state, ERR_state, HEAD_state, STATUS_state, LENGTH_state, ROI_state,
                   DNA_state, ID_state, CHMASK_state, EVENT_CNT_state, TIMESTAMP_state,
                   CALC_CH_CRC_state, CH_CRC_state, CH_HEADER_state, PAYLOAD_state,
                   CALC_CRC32_state, CRC32_state, TAIL_state);

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

  signal dropped : std_logic := '0';
  signal debug   : boolean   := false;

  signal status        : std_logic_vector (15 downto 0) := (others => '0');
  signal packet_length : std_logic_vector (15 downto 0) := (others => '0');
  signal payload_size  : integer                        := 0;
  signal num_channels  : integer                        := 0;
  signal id            : std_logic_vector (15 downto 0) := (others => '0');

  signal mask      : std_logic_vector (mask_i'range)      := (others => '0');
  signal event_cnt : std_logic_vector (event_cnt_i'range) := (others => '0');
  signal timestamp : std_logic_vector (timestamp_i'range) := (others => '0');
  signal dna       : std_logic_vector (dna_i'range)       := (others => '0');

  constant DNA_WORDS         : integer := dna'length / g_WORD_SIZE;
  constant TIMESTAMP_WORDS   : integer := timestamp'length / g_WORD_SIZE;
  constant EVENT_CNT_WORDS   : integer := event_cnt'length / g_WORD_SIZE;
  constant PACKET_CRC_WORDS  : integer := packet_crc'length / g_WORD_SIZE;
  constant CHANNEL_CRC_WORDS : integer := channel_crc'length / g_WORD_SIZE;

  signal roi_size : integer range 0 to 1023;

  signal state_word_cnt : integer               := 0;
  signal channel_cnt    : integer range 0 to 15 := 0;

  signal dav : boolean := false;

  impure function get_payload_size (drs_id           : integer; packet_dropped : std_logic; packet_roi_size :
                                    integer; ch_mask : std_logic_vector)
    return integer is
    variable id_mask : std_logic_vector (15 downto 0);
  begin
    -- size of each readout * number of readouts + 9th channel (if the packet is not empty)
    if (packet_dropped = '1') then
      return 0;
    else
      if (drs_id = 1) then
        id_mask := x"FF00";
      else
        id_mask := x"00FF";
      end if;
      return (
        -- count the number of channels enabled
        -- if /any/ channel is enabled, then add 1 additional channel for 9th channel
        -- e.g. if 0 selected channels, read 0
        --      if 1 selected channels, read 2 (x + 9th)
        --      etc..
        -- Then multiply by roi_size + 1 + 2 (for the crc)
        ((count_ones(id_mask and ch_mask)) +to_int(or_reduce(id_mask and ch_mask)))
        * (1+1+packet_roi_size + channel_crc'length / g_WORD_SIZE)
        );
    end if;
  end function;

  impure function get_packet_size (packet_payload_size : integer)
    return integer is
  begin
    return (
      HEAD'length / g_WORD_SIZE
      + status'length / g_WORD_SIZE
      + packet_length'length / g_WORD_SIZE
      + dna'length / g_WORD_SIZE
      + data'length / g_WORD_SIZE -- roi
      + id'length / g_WORD_SIZE
      + mask'length / g_WORD_SIZE
      + event_cnt'length / g_WORD_SIZE
      + timestamp'length / g_WORD_SIZE
      + packet_payload_size             -- roi counts from 0
      + packet_crc'length / g_WORD_SIZE
      + tail'length / g_WORD_SIZE
      );
  end function;

begin

  packet_crc_en   <= if_then_else ((dav and state /= TAIL_state and state /= CRC32_state), '1', '0');

  process (clock) is
  begin
    if (rising_edge(clock)) then
      channel_crc_en  <= if_then_else ((dav and state = PAYLOAD_state), '1', '0');
      packet_crc_rst  <= if_then_else ((state = IDLE_state or state = TAIL_state), '1', '0');
      channel_crc_rst <= if_then_else (((state = CH_CRC_state and state_word_cnt = 0) or state = IDLE_state), '1', '0');
    end if;
  end process;

  packet_crc32 : entity work.crc32
    port map (
      clock  => clock,
      data   => data,
      reset  => packet_crc_rst,
      enable => packet_crc_en,
      crc    => packet_crc
      );

  channel_crc32 : entity work.crc32
    port map (
      clock  => clock,
      data   => data,
      enable => channel_crc_en,
      reset  => channel_crc_rst,
      crc    => channel_crc
      );

  busy_o <= '0' when state = IDLE_state else '1';

  process (clock) is
  begin
    if (rising_edge(clock)) then

      -- stable copies of trigger parameters
      if (state = IDLE_state and (trigger_i = '1' or debug_packet_inject_i = '1')) then
        if (debug_packet_inject_i = '1') then
          status       <= x"9999";
          id           <= x"4444";
          roi_size     <= 1023;
          debug        <= true;
          dropped      <= '0';
          num_channels <= 9;
          mask         <= x"00FF";
          dna          <= x"FEDCBA9876543210";
          event_cnt    <= x"76543210";
          timestamp    <= x"BA9876543210";
        else

          status(0)            <= sync_err_i;
          status(1)            <= dropped;
          status (15 downto 2) <= (others => '0');

          id(0)           <= to_sl(g_DRS_ID);
          id(15 downto 8) <= board_id;
          id (7 downto 1) <= (others => '0');

          roi_size     <= to_int (roi_size_i);
          dna          <= dna_i;
          debug        <= false;
          dropped      <= drs_busy_i;
          num_channels <= count_ones (mask_i) + 1;  -- FIXME: need to account for drs ID and mask appropriately
                                                    -- move this to a common function....
          -- ((count_ones(id_mask and ch_mask)) +to_int(or_reduce(id_mask and ch_mask)))
          mask         <= mask_i;
          event_cnt    <= event_cnt_i;
          timestamp    <= timestamp_i;
        end if;
      end if;

      -- let this pipeline over 2 clocks
      payload_size  <= get_payload_size(g_DRS_ID, dropped, roi_size, mask);
      packet_length <= to_slv(get_packet_size(payload_size), packet_length'length);

    end if;
  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      if (reset = '1') then
        state <= IDLE_state;
      else

        dav  <= false;
        data <= (others => '0');

        case state is

          when IDLE_state =>

            if (trigger_i = '1' or debug_packet_inject_i = '1') then
              state <= HEAD_state;
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

            if (state_word_cnt = dna'length / g_WORD_SIZE - 1) then
              state          <= ID_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= dna(g_WORD_SIZE*(DNA_WORDS -state_word_cnt)-1
                        downto g_WORD_SIZE*(DNA_WORDS -state_word_cnt-1));
            dav <= true;

          when ID_state =>

            state <= CHMASK_state;

            data <= id;
            dav  <= true;

          when CHMASK_state =>

            state <= EVENT_CNT_state;

            data <= mask;
            dav  <= true;

          when EVENT_CNT_state =>

            if (state_word_cnt = event_cnt'length / g_WORD_SIZE - 1) then
              state          <= TIMESTAMP_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= event_cnt(g_WORD_SIZE*(EVENT_CNT_WORDS -state_word_cnt)-1
                              downto g_WORD_SIZE*(EVENT_CNT_WORDS -state_word_cnt-1));
            dav <= true;

          when TIMESTAMP_state =>

            if (state_word_cnt = timestamp'length / g_WORD_SIZE - 1) then

              if (dropped = '1') then
                state <= CRC32_state;
              else
                state <= CH_HEADER_state;
              end if;

              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= timestamp(g_WORD_SIZE*(TIMESTAMP_WORDS -state_word_cnt)-1
                              downto g_WORD_SIZE*(TIMESTAMP_WORDS -state_word_cnt-1));
            dav <= true;

          when CH_HEADER_state =>

            if (num_channels = 0) then
              state          <= CRC32_state;
              state_word_cnt <= 0;
            else
              state          <= PAYLOAD_state;
              state_word_cnt <= 0;
            end if;

            data <= to_slv (channel_cnt, data'length);
            dav <= true;

          when PAYLOAD_state =>

            if (debug) then
              state_word_cnt <= state_word_cnt + 1;
            else
              -- FIXME: should be gated by the fifonot full
              state_word_cnt <= state_word_cnt + 1;
            end if;

            if (num_channels = 0) then
              state          <= CRC32_state;
              state_word_cnt <= 0;
            elsif (state_word_cnt = roi_size) then
              state          <= CALC_CH_CRC_state;
              state_word_cnt <= 0;
              channel_cnt    <= channel_cnt + 1;
            end if;

            if (debug) then
              dav  <= true;
              data <= to_slv(state_word_cnt, g_WORD_SIZE);
            elsif (num_channels > 0) then

              -- TODO: need the guts of the thing
              -- dav should connect to !empty output of the adc fifo
              -- if (not fifo_empty) then
              data <= (others => '0');
              dav  <= true;
              --else
              dav  <= false;
              data <= (others => '0');
              -- end if;

            end if;

          when CALC_CH_CRC_state =>

            -- need 1 extra clock to calculate the channel crc
            state <= CH_CRC_state;
            dav   <= false;
            data  <= (others => '0');

          when CH_CRC_state =>

            if (state_word_cnt = CHANNEL_CRC'length / 16 - 1) then
              if (channel_cnt = num_channels) then
                state          <= CALC_CRC32_state;
              else
                state          <= CH_HEADER_state;
              end if;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= channel_crc(g_WORD_SIZE*(CHANNEL_CRC_WORDS -state_word_cnt)-1
                                downto g_WORD_SIZE*(CHANNEL_CRC_WORDS -state_word_cnt-1));
            dav <= true;

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

            data <= packet_crc(g_WORD_SIZE*(PACKET_CRC_WORDS -state_word_cnt)-1
                               downto g_WORD_SIZE*(PACKET_CRC_WORDS -state_word_cnt-1));
            dav <= true;

          when TAIL_state =>

            state <= IDLE_state;

            data <= TAIL;
            dav  <= true;

          when others =>

            state <= IDLE_state;

        end case;

      end if;
    end if;

  end process;

  valid_o <= '1' when dav else '0';
  data_o  <= data;

end behavioral;
