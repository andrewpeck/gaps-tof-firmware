
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity trg_tx_wrapper is
  generic(
    NUM_RB_CHANNELS : integer := 20;
    EVENTCNTB : integer := 48
    );
  port(

    clock    : in  std_logic;
    reset    : in  std_logic;
    serial_o : out std_logic_vector (NUM_RB_CHANNELS-1 downto 0);

    trg_i    : in std_logic;
    resync_i : in std_logic;

    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0);
    ch_mask_i   : in std_logic_vector (MASKCNTB-1 downto 0) -- FIXME: must have enough inputs for all channels


    );
end trg_tx_wrapper;

architecture behavioral of trg_tx_wrapper is

begin

  tx_gen : for I in 0 to NUM_RBS-1 generate
  begin

    trg_tx_1 : entity work.trg_tx
      generic map (
        EN_MASK   => 1,
        EVENTCNTB => EVENTCNTB,
        MASKCNTB  => NUM_RB_CHANNELS
        )
      port map (
        clock       => clock,
        reset       => reset,
        serial_o    => serial_o(I),
        trg_i       => trg_i,
        resync_i    => resync_i,
        event_cnt_i => event_cnt_i,
        ch_mask_i   => ch_mask_i (
        );

  end generate;

end behavioral;
