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

  --START: autoinsert mapping

  rb_ch_bitmap_o(116) <= hits_bitmap_i(0);
  rb_ch_bitmap_o(124) <= hits_bitmap_i(1);
  rb_ch_bitmap_o(114) <= hits_bitmap_i(2);
  rb_ch_bitmap_o(122) <= hits_bitmap_i(3);
  rb_ch_bitmap_o(112) <= hits_bitmap_i(4);
  rb_ch_bitmap_o(120) <= hits_bitmap_i(5);
  rb_ch_bitmap_o(255) <= hits_bitmap_i(6);
  rb_ch_bitmap_o(247) <= hits_bitmap_i(7);
  rb_ch_bitmap_o(253) <= hits_bitmap_i(8);
  rb_ch_bitmap_o(245) <= hits_bitmap_i(9);
  rb_ch_bitmap_o(251) <= hits_bitmap_i(10);
  rb_ch_bitmap_o(243) <= hits_bitmap_i(11);
  rb_ch_bitmap_o(145) <= hits_bitmap_i(12);
  rb_ch_bitmap_o(153) <= hits_bitmap_i(13);
  rb_ch_bitmap_o(147) <= hits_bitmap_i(14);
  rb_ch_bitmap_o(155) <= hits_bitmap_i(15);
  rb_ch_bitmap_o(149) <= hits_bitmap_i(16);
  rb_ch_bitmap_o(157) <= hits_bitmap_i(17);
  rb_ch_bitmap_o(218) <= hits_bitmap_i(18);
  rb_ch_bitmap_o(210) <= hits_bitmap_i(19);
  rb_ch_bitmap_o(220) <= hits_bitmap_i(20);
  rb_ch_bitmap_o(212) <= hits_bitmap_i(21);
  rb_ch_bitmap_o(222) <= hits_bitmap_i(22);
  rb_ch_bitmap_o(214) <= hits_bitmap_i(23);
  rb_ch_bitmap_o(127) <= hits_bitmap_i(24);
  rb_ch_bitmap_o(119) <= hits_bitmap_i(25);
  rb_ch_bitmap_o(141) <= hits_bitmap_i(26);
  rb_ch_bitmap_o(133) <= hits_bitmap_i(27);
  rb_ch_bitmap_o(139) <= hits_bitmap_i(28);
  rb_ch_bitmap_o(131) <= hits_bitmap_i(29);
  rb_ch_bitmap_o(137) <= hits_bitmap_i(30);
  rb_ch_bitmap_o(129) <= hits_bitmap_i(31);
  rb_ch_bitmap_o(191) <= hits_bitmap_i(32);
  rb_ch_bitmap_o(183) <= hits_bitmap_i(33);
  rb_ch_bitmap_o(189) <= hits_bitmap_i(34);
  rb_ch_bitmap_o(181) <= hits_bitmap_i(35);
  rb_ch_bitmap_o(187) <= hits_bitmap_i(36);
  rb_ch_bitmap_o(179) <= hits_bitmap_i(37);
  rb_ch_bitmap_o(185) <= hits_bitmap_i(38);
  rb_ch_bitmap_o(177) <= hits_bitmap_i(39);
  rb_ch_bitmap_o(249) <= hits_bitmap_i(40);
  rb_ch_bitmap_o(241) <= hits_bitmap_i(41);
  rb_ch_bitmap_o(235) <= hits_bitmap_i(42);
  rb_ch_bitmap_o(227) <= hits_bitmap_i(43);
  rb_ch_bitmap_o(237) <= hits_bitmap_i(44);
  rb_ch_bitmap_o(229) <= hits_bitmap_i(45);
  rb_ch_bitmap_o(239) <= hits_bitmap_i(46);
  rb_ch_bitmap_o(231) <= hits_bitmap_i(47);
  rb_ch_bitmap_o(303) <= hits_bitmap_i(48);
  rb_ch_bitmap_o(295) <= hits_bitmap_i(49);
  rb_ch_bitmap_o(301) <= hits_bitmap_i(50);
  rb_ch_bitmap_o(293) <= hits_bitmap_i(51);
  rb_ch_bitmap_o(299) <= hits_bitmap_i(52);
  rb_ch_bitmap_o(291) <= hits_bitmap_i(53);
  rb_ch_bitmap_o(297) <= hits_bitmap_i(54);
  rb_ch_bitmap_o(289) <= hits_bitmap_i(55);
  rb_ch_bitmap_o(161) <= hits_bitmap_i(56);
  rb_ch_bitmap_o(199) <= hits_bitmap_i(57);
  rb_ch_bitmap_o(257) <= hits_bitmap_i(58);
  rb_ch_bitmap_o(103) <= hits_bitmap_i(59);
  rb_ch_bitmap_o( 12) <= hits_bitmap_i(60);
  rb_ch_bitmap_o(  4) <= hits_bitmap_i(61);
  rb_ch_bitmap_o( 10) <= hits_bitmap_i(62);
  rb_ch_bitmap_o(  2) <= hits_bitmap_i(63);
  rb_ch_bitmap_o(  8) <= hits_bitmap_i(64);
  rb_ch_bitmap_o(  0) <= hits_bitmap_i(65);
  rb_ch_bitmap_o( 17) <= hits_bitmap_i(66);
  rb_ch_bitmap_o( 25) <= hits_bitmap_i(67);
  rb_ch_bitmap_o( 19) <= hits_bitmap_i(68);
  rb_ch_bitmap_o( 27) <= hits_bitmap_i(69);
  rb_ch_bitmap_o( 21) <= hits_bitmap_i(70);
  rb_ch_bitmap_o( 29) <= hits_bitmap_i(71);
  rb_ch_bitmap_o( 14) <= hits_bitmap_i(72);
  rb_ch_bitmap_o(  6) <= hits_bitmap_i(73);
  rb_ch_bitmap_o( 32) <= hits_bitmap_i(74);
  rb_ch_bitmap_o( 40) <= hits_bitmap_i(75);
  rb_ch_bitmap_o( 34) <= hits_bitmap_i(76);
  rb_ch_bitmap_o( 42) <= hits_bitmap_i(77);
  rb_ch_bitmap_o( 70) <= hits_bitmap_i(78);
  rb_ch_bitmap_o( 78) <= hits_bitmap_i(79);
  rb_ch_bitmap_o( 68) <= hits_bitmap_i(80);
  rb_ch_bitmap_o( 76) <= hits_bitmap_i(81);
  rb_ch_bitmap_o( 66) <= hits_bitmap_i(82);
  rb_ch_bitmap_o( 74) <= hits_bitmap_i(83);
  rb_ch_bitmap_o( 72) <= hits_bitmap_i(84);
  rb_ch_bitmap_o( 64) <= hits_bitmap_i(85);
  rb_ch_bitmap_o( 54) <= hits_bitmap_i(86);
  rb_ch_bitmap_o( 62) <= hits_bitmap_i(87);
  rb_ch_bitmap_o( 52) <= hits_bitmap_i(88);
  rb_ch_bitmap_o( 60) <= hits_bitmap_i(89);
  rb_ch_bitmap_o( 31) <= hits_bitmap_i(90);
  rb_ch_bitmap_o( 23) <= hits_bitmap_i(91);
  rb_ch_bitmap_o( 48) <= hits_bitmap_i(92);
  rb_ch_bitmap_o( 56) <= hits_bitmap_i(93);
  rb_ch_bitmap_o( 50) <= hits_bitmap_i(94);
  rb_ch_bitmap_o( 58) <= hits_bitmap_i(95);
  rb_ch_bitmap_o( 86) <= hits_bitmap_i(96);
  rb_ch_bitmap_o( 94) <= hits_bitmap_i(97);
  rb_ch_bitmap_o( 84) <= hits_bitmap_i(98);
  rb_ch_bitmap_o( 92) <= hits_bitmap_i(99);
  rb_ch_bitmap_o( 82) <= hits_bitmap_i(100);
  rb_ch_bitmap_o( 90) <= hits_bitmap_i(101);
  rb_ch_bitmap_o( 88) <= hits_bitmap_i(102);
  rb_ch_bitmap_o( 80) <= hits_bitmap_i(103);
  rb_ch_bitmap_o( 38) <= hits_bitmap_i(104);
  rb_ch_bitmap_o( 46) <= hits_bitmap_i(105);
  rb_ch_bitmap_o( 36) <= hits_bitmap_i(106);
  rb_ch_bitmap_o( 44) <= hits_bitmap_i(107);
  --END: autoinsert mapping

end behavioral;
