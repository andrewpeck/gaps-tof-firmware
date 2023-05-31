library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.types_pkg.all;
use work.mt_types.all;
use work.constants.all;
use work.components.all;

entity rb_map is
  port(
    clock          : in  std_logic;
    hits_bitmap_i  : in  channel_bitmask_t := (others => '0');
    rb_ch_bitmap_o : out std_logic_vector (NUM_RBS*8-1 downto 0)
    );
end rb_map;

architecture behavioral of rb_map is
begin

  --rb_ch_bitmap_o(319 downto 0) <= hits_bitmap_i(199 downto 0);

  --START: autoinsert mapping

  rb_ch_bitmap_o(  0) <= hits_bitmap_i(  0); -- rb={:board 1, :ch 1} ltb={:board 1, :ch 1}
  rb_ch_bitmap_o(  8) <= hits_bitmap_i(  2); -- rb={:board 2, :ch 1} ltb={:board 1, :ch 3}
  rb_ch_bitmap_o(  2) <= hits_bitmap_i(  4); -- rb={:board 1, :ch 3} ltb={:board 1, :ch 5}
  rb_ch_bitmap_o( 10) <= hits_bitmap_i(  6); -- rb={:board 2, :ch 3} ltb={:board 1, :ch 7}
  rb_ch_bitmap_o(  4) <= hits_bitmap_i(  8); -- rb={:board 1, :ch 5} ltb={:board 1, :ch 9}
  rb_ch_bitmap_o( 17) <= hits_bitmap_i(  9); -- rb={:board 3, :ch 2} ltb={:board 2, :ch 2}
  rb_ch_bitmap_o( 12) <= hits_bitmap_i( 10); -- rb={:board 2, :ch 5} ltb={:board 1, :ch 11}
  rb_ch_bitmap_o( 25) <= hits_bitmap_i( 11); -- rb={:board 4, :ch 2} ltb={:board 2, :ch 4}
  rb_ch_bitmap_o( 14) <= hits_bitmap_i( 12); -- rb={:board 2, :ch 7} ltb={:board 1, :ch 13}
  rb_ch_bitmap_o( 19) <= hits_bitmap_i( 13); -- rb={:board 3, :ch 4} ltb={:board 2, :ch 6}
  rb_ch_bitmap_o(  6) <= hits_bitmap_i( 14); -- rb={:board 1, :ch 7} ltb={:board 1, :ch 15}
  rb_ch_bitmap_o( 27) <= hits_bitmap_i( 15); -- rb={:board 4, :ch 4} ltb={:board 2, :ch 8}
  rb_ch_bitmap_o( 32) <= hits_bitmap_i( 16); -- rb={:board 5, :ch 1} ltb={:board 3, :ch 1}
  rb_ch_bitmap_o( 21) <= hits_bitmap_i( 17); -- rb={:board 3, :ch 6} ltb={:board 2, :ch 10}
  rb_ch_bitmap_o( 40) <= hits_bitmap_i( 18); -- rb={:board 6, :ch 1} ltb={:board 3, :ch 3}
  rb_ch_bitmap_o( 29) <= hits_bitmap_i( 19); -- rb={:board 4, :ch 6} ltb={:board 2, :ch 12}
  rb_ch_bitmap_o( 34) <= hits_bitmap_i( 20); -- rb={:board 5, :ch 3} ltb={:board 3, :ch 5}
  rb_ch_bitmap_o( 31) <= hits_bitmap_i( 21); -- rb={:board 4, :ch 8} ltb={:board 2, :ch 14}
  rb_ch_bitmap_o( 42) <= hits_bitmap_i( 22); -- rb={:board 6, :ch 3} ltb={:board 3, :ch 7}
  rb_ch_bitmap_o( 23) <= hits_bitmap_i( 23); -- rb={:board 3, :ch 8} ltb={:board 2, :ch 16}
  rb_ch_bitmap_o( 48) <= hits_bitmap_i( 24); -- rb={:board 7, :ch 1} ltb={:board 4, :ch 1}
  rb_ch_bitmap_o( 44) <= hits_bitmap_i( 24); -- rb={:board 6, :ch 5} ltb={:board 3, :ch 9}
  rb_ch_bitmap_o( 56) <= hits_bitmap_i( 26); -- rb={:board 8, :ch 1} ltb={:board 4, :ch 3}
  rb_ch_bitmap_o( 36) <= hits_bitmap_i( 26); -- rb={:board 5, :ch 5} ltb={:board 3, :ch 11}
  rb_ch_bitmap_o( 50) <= hits_bitmap_i( 28); -- rb={:board 7, :ch 3} ltb={:board 4, :ch 5}
  rb_ch_bitmap_o( 46) <= hits_bitmap_i( 28); -- rb={:board 6, :ch 7} ltb={:board 3, :ch 13}
  rb_ch_bitmap_o( 58) <= hits_bitmap_i( 30); -- rb={:board 8, :ch 3} ltb={:board 4, :ch 7}
  rb_ch_bitmap_o( 38) <= hits_bitmap_i( 30); -- rb={:board 5, :ch 7} ltb={:board 3, :ch 15}
  rb_ch_bitmap_o( 64) <= hits_bitmap_i( 32); -- rb={:board 9, :ch 1} ltb={:board 5, :ch 1}
  rb_ch_bitmap_o( 60) <= hits_bitmap_i( 32); -- rb={:board 8, :ch 5} ltb={:board 4, :ch 9}
  rb_ch_bitmap_o( 72) <= hits_bitmap_i( 34); -- rb={:board 10, :ch 1} ltb={:board 5, :ch 3}
  rb_ch_bitmap_o( 52) <= hits_bitmap_i( 34); -- rb={:board 7, :ch 5} ltb={:board 4, :ch 11}
  rb_ch_bitmap_o( 74) <= hits_bitmap_i( 36); -- rb={:board 10, :ch 3} ltb={:board 5, :ch 5}
  rb_ch_bitmap_o( 62) <= hits_bitmap_i( 36); -- rb={:board 8, :ch 7} ltb={:board 4, :ch 13}
  rb_ch_bitmap_o( 66) <= hits_bitmap_i( 38); -- rb={:board 9, :ch 3} ltb={:board 5, :ch 7}
  rb_ch_bitmap_o( 54) <= hits_bitmap_i( 38); -- rb={:board 7, :ch 7} ltb={:board 4, :ch 15}
  rb_ch_bitmap_o( 76) <= hits_bitmap_i( 40); -- rb={:board 10, :ch 5} ltb={:board 5, :ch 9}
  rb_ch_bitmap_o( 80) <= hits_bitmap_i( 40); -- rb={:board 11, :ch 1} ltb={:board 6, :ch 1}
  rb_ch_bitmap_o( 68) <= hits_bitmap_i( 42); -- rb={:board 9, :ch 5} ltb={:board 5, :ch 11}
  rb_ch_bitmap_o( 88) <= hits_bitmap_i( 42); -- rb={:board 12, :ch 1} ltb={:board 6, :ch 3}
  rb_ch_bitmap_o( 78) <= hits_bitmap_i( 44); -- rb={:board 10, :ch 7} ltb={:board 5, :ch 13}
  rb_ch_bitmap_o( 90) <= hits_bitmap_i( 44); -- rb={:board 12, :ch 3} ltb={:board 6, :ch 5}
  rb_ch_bitmap_o( 70) <= hits_bitmap_i( 46); -- rb={:board 9, :ch 7} ltb={:board 5, :ch 15}
  rb_ch_bitmap_o( 82) <= hits_bitmap_i( 46); -- rb={:board 11, :ch 3} ltb={:board 6, :ch 7}
  rb_ch_bitmap_o( 92) <= hits_bitmap_i( 48); -- rb={:board 12, :ch 5} ltb={:board 6, :ch 9}
  rb_ch_bitmap_o( 84) <= hits_bitmap_i( 50); -- rb={:board 11, :ch 5} ltb={:board 6, :ch 11}
  rb_ch_bitmap_o( 94) <= hits_bitmap_i( 52); -- rb={:board 12, :ch 7} ltb={:board 6, :ch 13}
  rb_ch_bitmap_o( 86) <= hits_bitmap_i( 54); -- rb={:board 11, :ch 7} ltb={:board 6, :ch 15}
  rb_ch_bitmap_o(120) <= hits_bitmap_i( 56); -- rb={:board 16, :ch 1} ltb={:board 8, :ch 1}
  rb_ch_bitmap_o(112) <= hits_bitmap_i( 58); -- rb={:board 15, :ch 1} ltb={:board 8, :ch 3}
  rb_ch_bitmap_o(122) <= hits_bitmap_i( 60); -- rb={:board 16, :ch 3} ltb={:board 8, :ch 5}
  rb_ch_bitmap_o(103) <= hits_bitmap_i( 61); -- rb={:board 13, :ch 8} ltb={:board 7, :ch 14}
  rb_ch_bitmap_o(114) <= hits_bitmap_i( 62); -- rb={:board 15, :ch 3} ltb={:board 8, :ch 7}
  rb_ch_bitmap_o(124) <= hits_bitmap_i( 64); -- rb={:board 16, :ch 5} ltb={:board 8, :ch 9}
  rb_ch_bitmap_o(129) <= hits_bitmap_i( 65); -- rb={:board 17, :ch 2} ltb={:board 9, :ch 2}
  rb_ch_bitmap_o(116) <= hits_bitmap_i( 66); -- rb={:board 15, :ch 5} ltb={:board 8, :ch 11}
  rb_ch_bitmap_o(137) <= hits_bitmap_i( 67); -- rb={:board 18, :ch 2} ltb={:board 9, :ch 4}
  rb_ch_bitmap_o(127) <= hits_bitmap_i( 69); -- rb={:board 16, :ch 8} ltb={:board 8, :ch 14}
  rb_ch_bitmap_o(131) <= hits_bitmap_i( 69); -- rb={:board 17, :ch 4} ltb={:board 9, :ch 6}
  rb_ch_bitmap_o(119) <= hits_bitmap_i( 71); -- rb={:board 15, :ch 8} ltb={:board 8, :ch 16}
  rb_ch_bitmap_o(139) <= hits_bitmap_i( 71); -- rb={:board 18, :ch 4} ltb={:board 9, :ch 8}
  rb_ch_bitmap_o(145) <= hits_bitmap_i( 73); -- rb={:board 19, :ch 2} ltb={:board 10, :ch 2}
  rb_ch_bitmap_o(133) <= hits_bitmap_i( 73); -- rb={:board 17, :ch 6} ltb={:board 9, :ch 10}
  rb_ch_bitmap_o(153) <= hits_bitmap_i( 75); -- rb={:board 20, :ch 2} ltb={:board 10, :ch 4}
  rb_ch_bitmap_o(141) <= hits_bitmap_i( 75); -- rb={:board 18, :ch 6} ltb={:board 9, :ch 12}
  rb_ch_bitmap_o(147) <= hits_bitmap_i( 77); -- rb={:board 19, :ch 4} ltb={:board 10, :ch 6}
  rb_ch_bitmap_o(155) <= hits_bitmap_i( 79); -- rb={:board 20, :ch 4} ltb={:board 10, :ch 8}
  rb_ch_bitmap_o(149) <= hits_bitmap_i( 81); -- rb={:board 19, :ch 6} ltb={:board 10, :ch 10}
  rb_ch_bitmap_o(157) <= hits_bitmap_i( 83); -- rb={:board 20, :ch 6} ltb={:board 10, :ch 12}
  rb_ch_bitmap_o(161) <= hits_bitmap_i( 83); -- rb={:board 21, :ch 2} ltb={:board 11, :ch 4}
  rb_ch_bitmap_o(177) <= hits_bitmap_i( 89); -- rb={:board 23, :ch 2} ltb={:board 12, :ch 2}
  rb_ch_bitmap_o(179) <= hits_bitmap_i( 91); -- rb={:board 23, :ch 4} ltb={:board 12, :ch 4}
  rb_ch_bitmap_o(181) <= hits_bitmap_i( 93); -- rb={:board 23, :ch 6} ltb={:board 12, :ch 6}
  rb_ch_bitmap_o(183) <= hits_bitmap_i( 95); -- rb={:board 23, :ch 8} ltb={:board 12, :ch 8}
  rb_ch_bitmap_o(191) <= hits_bitmap_i( 97); -- rb={:board 24, :ch 8} ltb={:board 12, :ch 10}
  rb_ch_bitmap_o(189) <= hits_bitmap_i( 99); -- rb={:board 24, :ch 6} ltb={:board 12, :ch 12}
  rb_ch_bitmap_o(187) <= hits_bitmap_i(101); -- rb={:board 24, :ch 4} ltb={:board 12, :ch 14}
  rb_ch_bitmap_o(185) <= hits_bitmap_i(103); -- rb={:board 24, :ch 2} ltb={:board 12, :ch 16}
  rb_ch_bitmap_o(218) <= hits_bitmap_i(108); -- rb={:board 28, :ch 3} ltb={:board 14, :ch 5}
  rb_ch_bitmap_o(199) <= hits_bitmap_i(109); -- rb={:board 25, :ch 8} ltb={:board 13, :ch 14}
  rb_ch_bitmap_o(210) <= hits_bitmap_i(110); -- rb={:board 27, :ch 3} ltb={:board 14, :ch 7}
  rb_ch_bitmap_o(220) <= hits_bitmap_i(112); -- rb={:board 28, :ch 5} ltb={:board 14, :ch 9}
  rb_ch_bitmap_o(212) <= hits_bitmap_i(114); -- rb={:board 27, :ch 5} ltb={:board 14, :ch 11}
  rb_ch_bitmap_o(222) <= hits_bitmap_i(116); -- rb={:board 28, :ch 7} ltb={:board 14, :ch 13}
  rb_ch_bitmap_o(235) <= hits_bitmap_i(117); -- rb={:board 30, :ch 4} ltb={:board 15, :ch 6}
  rb_ch_bitmap_o(214) <= hits_bitmap_i(118); -- rb={:board 27, :ch 7} ltb={:board 14, :ch 15}
  rb_ch_bitmap_o(227) <= hits_bitmap_i(119); -- rb={:board 29, :ch 4} ltb={:board 15, :ch 8}
  rb_ch_bitmap_o(241) <= hits_bitmap_i(121); -- rb={:board 31, :ch 2} ltb={:board 16, :ch 2}
  rb_ch_bitmap_o(237) <= hits_bitmap_i(121); -- rb={:board 30, :ch 6} ltb={:board 15, :ch 10}
  rb_ch_bitmap_o(249) <= hits_bitmap_i(123); -- rb={:board 32, :ch 2} ltb={:board 16, :ch 4}
  rb_ch_bitmap_o(229) <= hits_bitmap_i(123); -- rb={:board 29, :ch 6} ltb={:board 15, :ch 12}
  rb_ch_bitmap_o(243) <= hits_bitmap_i(125); -- rb={:board 31, :ch 4} ltb={:board 16, :ch 6}
  rb_ch_bitmap_o(239) <= hits_bitmap_i(125); -- rb={:board 30, :ch 8} ltb={:board 15, :ch 14}
  rb_ch_bitmap_o(251) <= hits_bitmap_i(127); -- rb={:board 32, :ch 4} ltb={:board 16, :ch 8}
  rb_ch_bitmap_o(231) <= hits_bitmap_i(127); -- rb={:board 29, :ch 8} ltb={:board 15, :ch 16}
  rb_ch_bitmap_o(245) <= hits_bitmap_i(129); -- rb={:board 31, :ch 6} ltb={:board 16, :ch 10}
  rb_ch_bitmap_o(253) <= hits_bitmap_i(131); -- rb={:board 32, :ch 6} ltb={:board 16, :ch 12}
  rb_ch_bitmap_o(257) <= hits_bitmap_i(131); -- rb={:board 33, :ch 2} ltb={:board 17, :ch 4}
  rb_ch_bitmap_o(247) <= hits_bitmap_i(133); -- rb={:board 31, :ch 8} ltb={:board 16, :ch 14}
  rb_ch_bitmap_o(255) <= hits_bitmap_i(135); -- rb={:board 32, :ch 8} ltb={:board 16, :ch 16}
  rb_ch_bitmap_o(289) <= hits_bitmap_i(145); -- rb={:board 37, :ch 2} ltb={:board 19, :ch 2}
  rb_ch_bitmap_o(291) <= hits_bitmap_i(147); -- rb={:board 37, :ch 4} ltb={:board 19, :ch 4}
  rb_ch_bitmap_o(293) <= hits_bitmap_i(149); -- rb={:board 37, :ch 6} ltb={:board 19, :ch 6}
  rb_ch_bitmap_o(295) <= hits_bitmap_i(151); -- rb={:board 37, :ch 8} ltb={:board 19, :ch 8}
  rb_ch_bitmap_o(303) <= hits_bitmap_i(153); -- rb={:board 38, :ch 8} ltb={:board 19, :ch 10}
  rb_ch_bitmap_o(301) <= hits_bitmap_i(155); -- rb={:board 38, :ch 6} ltb={:board 19, :ch 12}
  rb_ch_bitmap_o(299) <= hits_bitmap_i(157); -- rb={:board 38, :ch 4} ltb={:board 19, :ch 14}
  rb_ch_bitmap_o(297) <= hits_bitmap_i(159); -- rb={:board 38, :ch 2} ltb={:board 19, :ch 16}
  --END: autoinsert mapping

end behavioral;
