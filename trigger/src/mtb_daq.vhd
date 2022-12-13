library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;

entity mtb_daq is
  generic(
    g_PACKET_PAD    : positive := 32;
    g_WORD_SIZE     : positive := 16;
    g_DELAY         : integer  := 1;
    g_MSB_FIRST     : boolean  := false;
    g_LITTLE_ENDIAN : boolean  := true
    );
  port(

    -- clock and reset
    clock   : in std_logic;
    reset_i : in std_logic;

    -- this is an array of 25*8 = 200 thresholds, where each threshold is a 2 bit value
    -- 200 thresholds = 400 bits, 16 bits / ltb
    hits_i : in threshold_array_t;

    -- trigger + metadata
    trigger_i         : in std_logic;
    event_cnt_i       : in std_logic_vector (31 downto 0);
    timestamp_i       : in std_logic_vector (31 downto 0);
    timecode_i        : in std_logic_vector (47 downto 0);
    timestamp_valid_i : in std_logic;
    timecode_valid_i  : in std_logic;
    ignore_tiu_i      :    std_logic := '1';

    -- daq outputs
    data_o       : out std_logic_vector (15 downto 0);
    data_valid_o : out std_logic

    );
end mtb_daq;

architecture behavioral of mtb_daq is

  type state_t is (IDLE_state, HEADER_state, EVENT_CNT_state, TIMESTAMP_state, TIMECODE_state,
                   RSVD_state, BOARD_MASK_state, HITS_state, PAD_state, CRC_CALC_state,
                   CRC_state, TRAILER_state);

  signal state : state_t := IDLE_state;

  signal state_word_cnt : natural range 0 to 7 := 0;

  --------------------------------------------------------------------------------
  -- Stable copies of inputs
  --------------------------------------------------------------------------------

  signal timecode_valid  : std_logic;
  signal timestamp_valid : std_logic;
  signal timestamp       : std_logic_vector (timestamp_i'range) := (others => '0');
  signal timecode        : std_logic_vector (timecode_i'range)  := (others => '0');
  signal event_cnt       : std_logic_vector (event_cnt_i'range) := (others => '0');

  --------------------------------------------------------------------------------
  -- Hit Delay Line
  --------------------------------------------------------------------------------

  signal hits     : threshold_array_t;
  signal hits_dly : threshold_array_t;

  type threshold_dly_line_t is array (integer range <>) of threshold_array_t;

  signal hits_dlyline : threshold_dly_line_t (0 to g_DELAY);

  --------------------------------------------------------------------------------
  -- 1 bit / paddle hitmask
  --------------------------------------------------------------------------------

  signal hitmask : std_logic_vector(hits'length-1 downto 0);

  --------------------------------------------------------------------------------
  -- Board masks, 25 bits
  --------------------------------------------------------------------------------

  signal odd_num_channels : std_logic := '0';

  signal board_mask      : std_logic_vector (hits_i'length/8-1 downto 0) := (others => '0');
  signal next_board_mask : std_logic_vector (hits_i'length/8-1 downto 0) := (others => '0');

  signal ltb_sel : natural range 0 to hits_i'length/8 := 0;

  --------------------------------------------------------------------------------
  -- CRC
  --------------------------------------------------------------------------------

  signal crc_en, crc_rst : std_logic;
  signal crc             : std_logic_vector (31 downto 0);

  --------------------------------------------------------------------------------
  -- Timeout
  --------------------------------------------------------------------------------

  constant TIMEOUT_MAX   : natural                        := 2**10-1;
  signal timeout_counter : natural range 0 to TIMEOUT_MAX := 0;
  signal timed_out       : std_logic                      := '0';

  --------------------------------------------------------------------------------
  -- Helper Functions
  --------------------------------------------------------------------------------

  -- choose the least significant set bit
  function calc_ltb_sel (mask : std_logic_vector) return natural is
    alias a : std_logic_vector(mask'length - 1 downto 0) is mask;
  begin
    for I in mask'range loop
      if a(I) = '1' then
        return I;
      end if;
    end loop;
    return mask'length;
  end;

  procedure test_calc_ltb_sel(a : std_logic_vector; b : integer) is
  begin
    assert calc_ltb_sel(a) = b
      report "Error in ltb_sel data=" & to_hstring(a)
      & " sel=" & integer'image(calc_ltb_sel(a))
      & " expect=" & integer'image(b)
      severity error;
  end;

  -- truncate off the least significant two bits
  function calc_next_mask (mask : std_logic_vector (24 downto 0))
    return std_logic_vector is
    alias a    : std_logic_vector(mask'length - 1 downto 0) is mask;
    variable b : signed(mask'length - 1 downto 0);
    variable c : signed(mask'length - 1 downto 0);
  begin

    -- At each clock cycle, the least-significant 1 becomes 0, using a simple
    -- property of integers: subtracting 1 from a number will always affect the
    -- least-significant set 1-bit. Using just arithmetic, with this trick we can
    -- take some starting number, and generate a copy of it that has the
    -- least-significant 1 changed to a zero.
    --
    -- e.g.
    -- let a        = 101100100  // our starting number
    --    ~a        = 010011011  // bitwise inversion
    --     b = ~a+1 = 010011100  // b is exactly the twos complement of a, which we know to be the same as (-a) ! :)
    --    ~b        = 101100011  //
    --     a & b    = 000000100  // one hot of first one set
    --     a &~b    = 101100000  // copy of a with the first non-zero bit set to zero. Voila!
    --
    -- or as a one line expression,
    --     c = a & ~(~a+1), or equivalently
    --     c = a & ~(  -a), or equivalently
    --     c = a & ~({1536{1'b1}}-a), etc., I'm sure there are more.

    b := signed(a);
    c := b and not (-b);
    return std_logic_vector(c);
  end;

  procedure test_calc_next_mask (a : std_logic_vector (24 downto 0);
                                 b : std_logic_vector (24 downto 0)) is
    alias aa : std_logic_vector(a'length - 1 downto 0) is a;
    alias bb : std_logic_vector(b'length - 1 downto 0) is b;
  begin
    assert calc_next_mask(aa) = bb
      report
      "Error " & to_hstring(aa) &
      " returns " & to_hstring(calc_next_mask(aa)) &
      " expect " & to_hstring(bb)
      severity error;
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

  --
  function swap_data_bytes (swap : boolean; din : std_logic_vector (15 downto 0))
    return std_logic_vector is
  begin
    if (swap) then
      return din(7 downto 0) & din(15 downto 8);
    else
      return din;
    end if;
  end;

begin

  test_calc_ltb_sel("0" & x"000000", 25);
  test_calc_ltb_sel("0" & x"000001", 0);
  test_calc_ltb_sel("0" & x"000002", 1);
  test_calc_ltb_sel("0" & x"000004", 2);
  test_calc_ltb_sel("0" & x"800000", 23);

  test_calc_next_mask("0" & x"000000", "0" & x"000000");
  test_calc_next_mask("0" & x"000001", "0" & x"000000");
  test_calc_next_mask("0" & x"000011", "0" & x"000010");
  test_calc_next_mask("0" & x"110000", "0" & x"100000");
  test_calc_next_mask("0" & x"800001", "0" & x"800000");
  test_calc_next_mask("0" & x"00000f", "0" & x"00000e");

  assert swap_data_bytes(true, x"ff00") = x"00ff" severity error;
  assert swap_data_bytes(true, x"00ff") = x"ff00" severity error;
  assert swap_data_bytes(false, x"ff00") = x"ff00" severity error;
  assert swap_data_bytes(false, x"00ff") = x"00ff" severity error;

  --------------------------------------------------------------------------------
  -- Delay Line
  --------------------------------------------------------------------------------

  hits_dlyline(0) <= hits_i;
  hits_dly        <= hits_dlyline(g_DELAY);

  process (clock) is
  begin
    if (rising_edge(clock)) then
      for I in 1 to hits_dlyline'length-1 loop
        hits_dlyline(I) <= hits_dlyline(I-1);
      end loop;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- DAQ State Machine
  --------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then

      crc_en       <= '0';
      crc_rst      <= '0';
      data_valid_o <= '0';
      data_o       <= (others => '0');

      if (state /= IDLE_state and (timecode_valid_i = '1' or ignore_tiu_i = '1')) then
        timecode_valid <= '1';
        timecode       <= timecode_i;
      end if;

      if (state /= IDLE_state and (timestamp_valid_i = '1' or ignore_tiu_i = '1')) then
        timestamp_valid <= '1';
        timestamp       <= timestamp_i;
      end if;

      case state is

        when IDLE_state =>

          timecode_valid  <= '0';
          timestamp_valid <= '0';
          crc_rst         <= '1';

          -- freeze the hitmask, timestamp, timecode, hitmask
          if (trigger_i = '1') then
            state        <= HEADER_state;
            event_cnt    <= event_cnt_i;
            hits         <= hits_dly;
            data_o       <= x"AAAA";
            data_valid_o <= '1';
            crc_en       <= '1';
          end if;

        when HEADER_state =>

          state        <= EVENT_CNT_state;
          data_o       <= x"AAAA";
          data_valid_o <= '1';
          crc_en       <= '1';

          -- pre-calculate the hitmask, will get reduced to the board_mask
          for I in hits_i'range loop
            if (hits_i(I) /= "00") then
              hitmask(I) <= '1';
            else
              hitmask(I) <= '0';
            end if;
          end loop;

        when EVENT_CNT_state =>

          if (state_word_cnt = event_cnt'length / g_WORD_SIZE - 1) then
            state          <= TIMESTAMP_state;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          -- transmit a header, calculate the hitmask
          data_o       <= data_sel(g_MSB_FIRST, g_WORD_SIZE, event_cnt'length/g_WORD_SIZE, state_word_cnt, event_cnt);
          data_valid_o <= '1';
          crc_en       <= '1';

          -- pre-calculate the board mask
          for I in board_mask'range loop
            board_mask(I) <= or_reduce(hitmask((I+1)*8-1 downto I*8));
          end loop;

        when TIMESTAMP_state =>

          -- TODO: add a timeout

          if (timestamp_valid = '1') then
            if (state_word_cnt = timestamp'length / g_WORD_SIZE - 1) then
              state          <= TIMECODE_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data_o       <= data_sel(g_MSB_FIRST, g_WORD_SIZE, timestamp'length/g_WORD_SIZE, state_word_cnt, timestamp);
            data_valid_o <= '1';
            crc_en       <= '1';
          end if;

          -- pre-calculate the next_board_mask
          next_board_mask  <= calc_next_mask(board_mask);
          odd_num_channels <= xor_reduce(board_mask);

        when TIMECODE_state =>

          -- TODO: add a timeout

          if (timecode_valid = '1') then
            if (state_word_cnt = timecode'length / g_WORD_SIZE - 1) then
              state          <= RSVD_state;
              state_word_cnt <= 0;
            else
              state_word_cnt <= state_word_cnt + 1;
            end if;

            data_o       <= data_sel(g_MSB_FIRST, g_WORD_SIZE, timecode'length/g_WORD_SIZE, state_word_cnt, timecode);
            data_valid_o <= '1';
            crc_en       <= '1';
          end if;

          -- pre-calculate the first ltb to read out
          ltb_sel <= calc_ltb_sel(board_mask);

        when RSVD_state =>

          -- add a reserved state to make the timecode round up to 64 bits so
          -- it goes nicely into the 32 bit fifo
          data_o       <= (others => '0');
          data_valid_o <= '1';
          crc_en       <= '1';
          state        <= BOARD_MASK_state;

        when BOARD_MASK_state =>

          if (state_word_cnt = 1) then
            state          <= HITS_state;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          -- transmit a header, calculate the hitmask
          data_o       <= data_sel(g_MSB_FIRST, g_WORD_SIZE, 2, state_word_cnt, board_mask);
          data_valid_o <= '1';
          crc_en       <= '1';

        when HITS_state =>

          if (ltb_sel = board_mask'length) then
            if (odd_num_channels = '1') then
              state <= PAD_state;
            else
              state <= CRC_calc_state;
            end if;
          else

            -- transmit a header, calculate the hitmask
            data_o <= hits(ltb_sel+7) & hits(ltb_sel+6) & hits(ltb_sel+5) & hits(ltb_sel+4) &
                      hits(ltb_sel+3) & hits(ltb_sel+2) & hits(ltb_sel+1) & hits(ltb_sel);
            data_valid_o <= '1';
            crc_en       <= '1';

            ltb_sel         <= calc_ltb_sel(next_board_mask);
            board_mask      <= calc_next_mask(board_mask);
            next_board_mask <= calc_next_mask(next_board_mask);

          end if;

          -- state <= PAD_state;

        when PAD_state =>

          data_o       <= (others => '0');
          data_valid_o <= '1';
          crc_en       <= '1';
          state        <= CRC_CALC_state;

        when CRC_CALC_state =>

          state <= CRC_state;

        when CRC_state =>

          --
          if (state_word_cnt = CRC'length / g_WORD_SIZE - 1) then
            state          <= TRAILER_state;
            state_word_cnt <= 0;
          else
            state_word_cnt <= state_word_cnt + 1;
          end if;

          -- transmit a header, calculate the hitmask
          data_o       <= data_sel(g_MSB_FIRST, g_WORD_SIZE, crc'length/g_WORD_SIZE, state_word_cnt, crc);
          data_valid_o <= '1';
          crc_rst      <= '1';

        when TRAILER_state =>

          if (state_word_cnt = 1) then
            state          <= IDLE_state;
            state_word_cnt <= 0;
          else

            state_word_cnt <= state_word_cnt + 1;

          end if;

          -- transmit a header, calculate the hitmask
          data_o       <= x"5555";
          data_valid_o <= '1';
          crc_en       <= '1';

        when others =>

          state <= IDLE_state;

      end case;

      if (reset_i = '1') then
        state <= IDLE_state;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- CRC
  --------------------------------------------------------------------------------

  packet_crc32 : entity work.crc32
    port map (
      clock  => clock,
      data   => swap_data_bytes(g_LITTLE_ENDIAN, data_o),
      reset  => crc_rst,
      enable => crc_en,
      crc    => crc
      );

end behavioral;
