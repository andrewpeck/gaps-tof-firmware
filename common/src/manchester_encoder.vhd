library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity manchester_encoder is
  port(
    clk  : in  std_logic;
    din  : in  std_logic;
    dout : out std_logic
    );
end manchester_encoder;

architecture rtl of manchester_encoder is
begin
  dout <= din xor clk;
end rtl;
