-- TODO: latency depends on the selected phase.. should make it invariant
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity oversample is
  generic (
    SAMPLER : string := "IDDR"
    );
  port(
    clk    : in  std_logic;
    clk90  : in  std_logic;
    clk2x  : in  std_logic;
    inv    : in  std_logic;
    data_i : in  std_logic;
    idle_i : in  std_logic;
    data_o : out std_logic := '0';
    sel_o  : out std_logic_vector(1 downto 0)
    );
end oversample;

architecture behavioral of oversample is

  -- https://docs.xilinx.com/v/u/en-US/xapp1294-4x-oversampling-async-dru

  signal d, dd              : std_logic_vector (3 downto 0) := (others => '0');
  signal e01, e12, e23, e30 : std_logic                     := '0';

  signal sel_next : natural range 0 to 3 := 0;
  signal sel      : natural range 0 to 3 := 0;
begin

  sel_o <= std_logic_vector(to_unsigned(sel, 2));

  assert SAMPLER = "IDDR" or SAMPLER = "FFS"
    report "Invalid oversampler detected" severity error;

  --------------------------------------------------------------------------------
  -- Sampling with IDDR and 400 MHz clock
  --------------------------------------------------------------------------------

  iddr_gen : if (SAMPLER = "IDDR") generate
    signal Q1, Q2             : std_logic;
    signal Q1F, Q2F, Q1R, Q2R : std_logic := '0';
  begin

    id : IDDR
      generic map(
        DDR_CLK_EDGE => "SAME_EDGE_PIPELINED",  -- "OPPOSITE_EDGE", "SAME_EDGE" or "SAME_EDGE_PIPELINED"
        INIT_Q1      => '0',            -- Initial value of Q1: '0' or '1'
        INIT_Q2      => '0',            -- Initial value of Q2: '0' or '1'
        SRTYPE       => "SYNC")         -- Set/Reset type: "SYNC" or "ASYNC"
      port map(
        C  => clk2x,                    -- 1-bit clock input
        CE => '1',                      -- 1-bit clock enable input
        D  => data_i,                   -- 1-bit DDR data input
        R  => '0',                      -- 1-bit reset
        S  => '0',                      -- 1-bit set
        Q1 => Q1,                -- 1-bit output for positive edge of clock
        Q2 => Q2);               -- 1-bit output for negative edge of clock

    process(clk2x)
    begin
      if rising_edge(clk2x) then
        Q1F <= Q1  after 0.1 ns;
        Q2F <= Q2  after 0.1 ns;
        Q1R <= Q1F after 0.1 ns;
        Q2R <= Q2F after 0.1 ns;
      end if;
    end process;

    process(clk)
    begin
      if rising_edge(clk) then
        d <= Q1R & Q2R & Q1F & Q2F after 0.1 ns;
      end if;
    end process;

  end generate;

  --------------------------------------------------------------------------------
  -- Sampling with Flip-flops and 90 degree clock
  --------------------------------------------------------------------------------

  ffs_gen : if (SAMPLER = "FFS") generate

    signal d0, d90, d180, d270             : std_logic := '0';
    signal d0_r, d90_r, d180_r, d270_r     : std_logic := '0';
    signal d0_rr, d90_rr, d180_rr, d270_rr : std_logic := '0';

    attribute SHREG_EXTRACT                        : string;
    attribute SHREG_EXTRACT of d0, d90, d180, d270 : signal is "no";

  begin
    --------------------------------------------------------------------------------
    -- Input 4x oversampling
    --------------------------------------------------------------------------------

    process (clk) is
    begin
      if (rising_edge(clk)) then
        d0 <= data_i after 0.1 ns;
      end if;
      if (falling_edge(clk)) then
        d180 <= data_i after 0.1 ns;
      end if;
    end process;

    process (clk90) is
    begin
      if (rising_edge(clk90)) then
        d90 <= data_i after 0.1 ns;
      end if;
      if (falling_edge(clk90)) then
        d270 <= data_i after 0.1 ns;
      end if;
    end process;

    --------------------------------------------------------------------------------
    -- transfer from the input sampling clocks to the main 200MHz clocks
    -- clk270 goes first to 90 then to 0 to improve S&H times
    --------------------------------------------------------------------------------

    process (clk90) is
    begin
      if (rising_edge(clk90)) then
        d270_r <= d270;
      end if;
    end process;
    process (clk) is
    begin
      if (rising_edge(clk)) then
        d0_r   <= d0;
        d90_r  <= d90;
        d180_r <= d180;
      end if;
    end process;

    process (clk) is
    begin
      if (rising_edge(clk)) then
        d0_rr   <= d0_r;
        d90_rr  <= d90_r;
        d180_rr <= d180_r;
        d270_rr <= d270_r;
      end if;
    end process;

    d(3 downto 0) <= (d270_rr, d180_rr, d90_rr, d0_rr);

  end generate;

  --------------------------------------------------------------------------------
  -- Delay the data signals by 1 clock to align w/ selection logic
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      dd <= d;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Error Conditions
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      e01 <= d(0) xor d(1);
      e12 <= d(1) xor d(2);
      e23 <= d(2) xor d(3);
      e30 <= d(0) xor dd(3);
    --e30 <= dd(3) xor d(0);
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then

      -- case sel is
      --   when 0 =>
      --     if (e30 = '1') then
      --       sel_next <= 1;
      --     elsif (e01 = '1') then
      --       sel_next <= 3;
      --     end if;
      --   when 1 =>
      --     if (e01 = '1') then
      --       sel_next <= 2;
      --     elsif (e12 = '1') then
      --       sel_next <= 0;
      --     end if;
      --   when 2 =>
      --     if (e12 = '1') then
      --       sel_next <= 3;
      --     elsif (e23 = '1') then
      --       sel_next <= 1;
      --     end if;
      --   when 3 =>
      --     if (e23 = '1') then
      --       sel_next <= 0;
      --     elsif (e30 = '1') then
      --       sel_next <= 2;
      --     end if;
      --   when others =>
      --     sel_next <= 0;
      -- end case;


      case sel is
        when 0 =>
          if e01 = '1' then
            sel_next <= 2 after 0.1 ns;
          elsif e30 = '1' then
            sel_next <= 1 after 0.1 ns;
          end if;
        when 1 =>
          if e12 = '1' then
            sel_next <= 0 after 0.1 ns;
          elsif e01 = '1' then
            sel_next <= 3 after 0.1 ns;
          end if;
        when 3 =>
          if e23 = '1' then
            sel_next <= 1 after 0.1 ns;
          elsif e12 = '1' then
            sel_next <= 2 after 0.1 ns;
          end if;
        when 2 =>
          if e30 = '1' then
            sel_next <= 3 after 0.1 ns;
          elsif e23 = '1' then
            sel_next <= 0 after 0.1 ns;
          end if;
        when others => null;
      end case;


    end if;  -- rising_edge(clk)
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then

      -- add some crude logic to make sure we aren't shifting during a datapacket
      if (and_reduce(d) = inv and and_reduce(dd) = inv and idle_i = '1') then
        sel <= sel_next;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Output select
  --------------------------------------------------------------------------------

  data_o <= dd(sel) xor inv;

end behavioral;
