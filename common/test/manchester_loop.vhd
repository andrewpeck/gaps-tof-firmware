
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity manchester_loop is
  port(

    clk   : in  std_logic;
    clk8x : in  std_logic;
    din   : in  std_logic;
    dout  : out std_logic := '0';
    dav   : out std_logic := '0'

    );
end manchester_loop;

architecture behavioral of manchester_loop is
  signal coded : std_logic := '0';

begin
  manchester_encoder_1 : entity work.manchester_encoder
    port map (
      clk  => clk,
      din  => din,
      dout => coded);
  manchester_decoder_1 : entity work.manchester_decoder
    port map (
      clk  => clk8x,
      din  => coded,
      dout => dout,
      dav  => dav
      );

end behavioral;
