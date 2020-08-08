library work;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

-- TODO: CRC
--
-- TODO: handle the case that we get a trigger but both DRS chips are busy

-- Each daq block handles one trigger data stream, and is assumed busy during readout
-- Instantiate as many daq blocks as needed to deal with the trigger rate
-- some higher level arbitrator should dole out triggers to the daq blocks as needed
--
-- Two separate paths is preferred. I think having two separate processes per DRS4 makes the most sense
--
entity daq is
  port(
    clock : in std_logic;
    reset : in std_logic;

    -- Trigger info
    trigger_i   : in std_logic;
    event_cnt_i : in std_logic_vector (31 downto 0);
    mask_i      : in std_logic_vector (15 downto 0);

    -- status
    sync_err_i  : in std_logic;
    dna_i       : in std_logic_vector (63 downto 0);
    timestamp_i : in std_logic_vector (47 downto 0);

    drs_busy_i  : in std_logic;
    drs_data_i  : in std_logic_vector (15 downto 0);
    drs_valid_i : in std_logic;

    data_o  : out std_logic_vector (15 downto 0);  -- receive 16 bits / bx
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
  -- | STATUS    | [15:0] | [0]=sync_err                                   |
  -- |           |        | [15:1]=reserved                                |
  -- |-----------+--------+------------------------------------------------|
  -- | LEN       | [15:0] | length of packet, need to precalculate         |
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
  -- | PAYLOAD   |        | 0 to 36864 bytes                               |
  -- |           |        |                                                |
  -- |           |        | bits [13:0] = ADC data                         |
  -- |           |        | bits [15:14] parity                            |
  -- |-----------+--------+------------------------------------------------|
  -- | CRC32     | [31:0] | Packet CRC (excluding Trailer)                 |
  -- |-----------+--------+------------------------------------------------|
  -- | TAIL      | [15:0] | 0x5555                                         |
  -- |-----------+--------+------------------------------------------------|

  type state_t is (IDLE_state, ERR_state, HEAD_state, STATUS_state, LENGTH_state, DNA_state, ID_state, CHMASK_state, EVENT_CNT_state, TIMESTAMP_state, PAYLOAD_state, CRC32_state, TAIL_state);
  signal state : state_t := IDLE_state;

  constant HEAD : std_logic_vector (15 downto 0) := x"AAAA";
  constant TAIL : std_logic_vector (15 downto 0) := x"5555";

  signal data  : std_logic_vector (15 downto 0) := (others => '0');
  signal crc32 : std_logic_vector (31 downto 0) := (others => '0');

  signal status        : std_logic_vector (15 downto 0) := (others => '0');
  signal packet_length : std_logic_vector (15 downto 0) := (others => '0');
  signal id            : std_logic_vector (15 downto 0) := (others => '0');
  signal mask          : std_logic_vector (15 downto 0) := (others => '0');
  signal event_cnt     : std_logic_vector (31 downto 0) := (others => '0');
  signal timestamp     : std_logic_vector (47 downto 0) := (others => '0');

  signal state_word_cnt : integer := 0;

  signal dav : boolean := false;

  function count_ones(slv : std_logic_vector) return natural is
    variable n_ones : natural := 0;
  begin
    for i in slv'range loop
      if slv(i) = '1' then
        n_ones := n_ones + 1;
      end if;
    end loop;
    return n_ones;
  end function count_ones;

  function get_payload_size (roi_size : integer; ch_mask : std_logic_vector)
    return integer is
    variable num_channels : integer;
  begin
    -- size of each readout * number of readouts + 9th channel (if the packet is not empty)
    return ((count_ones(ch_mask)+to_integer(unsigned'( '0' & or_reduce(ch_mask))))*roi_size);
  end function;

  impure function get_packet_size (payload_size : integer)
    return integer is
    variable num_channels : integer;
  begin
    return (HEAD'length / 16
            + status'length / 16
            + packet_length'length / 16
            + dna_i'length / 16
            + mask'length / 16
            + event_cnt'length / 16
            + timestamp'length / 16
            + payload_size
            + crc32'length / 16
            + tail'length / 16
            );
  end function;

begin

  busy_o <= '0' when state = IDLE_state else '1';

  -- TODO: assign these
  status        <= (others => '0');
  id            <= (others => '0');

  -- stable copies of trigger parameters
  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (state = IDLE_state and trigger_i = '1') then
        mask      <= mask_i;
        event_cnt <= event_cnt_i;
        timestamp <= timestamp_i;
        -- FIXME, this 1024 should be changed to the size of the ROI
        packet_length <= std_logic_vector(to_unsigned(get_packet_size(get_payload_size(1024, mask_i)),packet_length'length));
      end if;
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

            if (trigger_i = '1') then
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

            state <= DNA_state;

            data <= packet_length;
            dav  <= true;

          when DNA_state =>

            if (state_word_cnt = dna_i'length / 16 - 1) then
              state          <= ID_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= dna_i((state_word_cnt +1)* 16 -1 downto (state_word_cnt)* 16);
            dav  <= true;

          when ID_state =>

            state <= CHMASK_state;

            data <= id;
            dav  <= true;

          when CHMASK_state =>

            state <= EVENT_CNT_state;

            data <= mask;
            dav  <= true;

          when EVENT_CNT_state =>

            if (state_word_cnt = event_cnt'length / 16 - 1) then
              state          <= TIMESTAMP_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= event_cnt((state_word_cnt +1)* 16 -1 downto (state_word_cnt)* 16);
            dav  <= true;

          when TIMESTAMP_state =>

            if (state_word_cnt = timestamp'length / 16 - 1) then
              state          <= PAYLOAD_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= timestamp ((state_word_cnt +1)* 16 -1 downto (state_word_cnt)* 16);
            dav  <= true;


          when PAYLOAD_state =>

            -- TODO: need the guts of the thing
            state <= CRC32_state;


          when CRC32_state =>

            if (state_word_cnt = CRC32'length / 16 - 1) then
              state          <= TAIL_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data <= crc32 ((state_word_cnt +1)* 16 -1 downto (state_word_cnt)* 16);
            dav  <= true;

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

end behavioral;
