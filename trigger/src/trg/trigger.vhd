library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;
use work.constants.all;

entity trigger is
  port(

    clk : in std_logic;

    single_hit_en_i : in std_logic := '1';
    bool_trg_en_i   : in std_logic := '1';

    hits_i : in channel_array_t;

    triggers_o       : out channel_array_t;
    rb_triggers_o    : out std_logic_vector (NUM_RBS-1 downto 0);
    global_trigger_o : out std_logic

    );
end trigger;

architecture behavioral of trigger is

  signal single_hit_triggers  : channel_array_t := (others => '0');
  signal bool_triggers        : channel_array_t := (others => '0');
  signal triggers, triggers_r : channel_array_t := (others => '0');
  signal rb_triggers          : rb_channel_array_t;

  signal rb_ors : std_logic_vector (NUM_RBS-1 downto 0)
    := (others => '0');

begin

  rb_triggers <= reshape(triggers);

  single_hit_trg_gen : for I in 0 to hits_i'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (single_hit_en_i = '1') then
          single_hit_triggers(I) <= hits_i(I);
        else
          single_hit_triggers(I) <= '0';
        end if;
      end if;
    end process;
  end generate;


  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (bool_trg_en_i = '1') then

        bool_triggers(0) <= (hits_i(95) and hits_i(108) and hits_i(79))
                            or (hits_i(260) and hits_i(51) and hits_i(197))
                            or (hits_i(301) and hits_i(161) and hits_i(272))
                            or (hits_i(90) and hits_i(82) and hits_i(89));

        bool_triggers(1) <= (hits_i(241) and hits_i(265) and hits_i(162))
                            or (hits_i(304) and hits_i(22) and hits_i(20))
                            or (hits_i(34) and hits_i(231) and hits_i(87))
                            or (hits_i(110) and hits_i(66) and hits_i(277));

        bool_triggers(2) <= (hits_i(42) and hits_i(0) and hits_i(58))
                            or (hits_i(103) and hits_i(43) and hits_i(162))
                            or (hits_i(243) and hits_i(285) and hits_i(143))
                            or (hits_i(62) and hits_i(287) and hits_i(241));

        bool_triggers(3) <= (hits_i(44) and hits_i(236) and hits_i(314))
                            or (hits_i(264) and hits_i(174) and hits_i(256))
                            or (hits_i(225) and hits_i(313) and hits_i(279))
                            or (hits_i(230) and hits_i(208) and hits_i(240));

        bool_triggers(4) <= (hits_i(246) and hits_i(252) and hits_i(210))
                            or (hits_i(19) and hits_i(111) and hits_i(309))
                            or (hits_i(241) and hits_i(216) and hits_i(19))
                            or (hits_i(166) and hits_i(298) and hits_i(180));

        bool_triggers(5) <= (hits_i(19) and hits_i(208) and hits_i(195))
                            or (hits_i(104) and hits_i(58) and hits_i(184))
                            or (hits_i(206) and hits_i(62) and hits_i(167))
                            or (hits_i(303) and hits_i(238) and hits_i(188));

        bool_triggers(6) <= (hits_i(119) and hits_i(148) and hits_i(269))
                            or (hits_i(94) and hits_i(23) and hits_i(167))
                            or (hits_i(171) and hits_i(93) and hits_i(69))
                            or (hits_i(139) and hits_i(188) and hits_i(15));

        bool_triggers(7) <= (hits_i(91) and hits_i(298) and hits_i(90))
                            or (hits_i(184) and hits_i(95) and hits_i(138))
                            or (hits_i(154) and hits_i(59) and hits_i(80))
                            or (hits_i(38) and hits_i(33) and hits_i(58));

        bool_triggers(8) <= (hits_i(243) and hits_i(159) and hits_i(114))
                            or (hits_i(303) and hits_i(58) and hits_i(219))
                            or (hits_i(122) and hits_i(275) and hits_i(51))
                            or (hits_i(104) and hits_i(247) and hits_i(11));

        bool_triggers(9) <= (hits_i(13) and hits_i(104) and hits_i(30))
                            or (hits_i(105) and hits_i(275) and hits_i(197))
                            or (hits_i(318) and hits_i(91) and hits_i(20))
                            or (hits_i(312) and hits_i(101) and hits_i(144));

        bool_triggers(10) <= (hits_i(109) and hits_i(26) and hits_i(8))
                             or (hits_i(97) and hits_i(164) and hits_i(236))
                             or (hits_i(114) and hits_i(274) and hits_i(5))
                             or (hits_i(83) and hits_i(144) and hits_i(287));

        bool_triggers(11) <= (hits_i(102) and hits_i(114) and hits_i(111))
                             or (hits_i(308) and hits_i(152) and hits_i(258))
                             or (hits_i(288) and hits_i(68) and hits_i(121))
                             or (hits_i(215) and hits_i(315) and hits_i(101));

        bool_triggers(12) <= (hits_i(279) and hits_i(292) and hits_i(137))
                             or (hits_i(236) and hits_i(211) and hits_i(18))
                             or (hits_i(5) and hits_i(138) and hits_i(19))
                             or (hits_i(28) and hits_i(26) and hits_i(274));

        bool_triggers(13) <= (hits_i(102) and hits_i(223) and hits_i(318))
                             or (hits_i(295) and hits_i(19) and hits_i(165))
                             or (hits_i(223) and hits_i(313) and hits_i(68))
                             or (hits_i(117) and hits_i(35) and hits_i(251));

        bool_triggers(14) <= (hits_i(43) and hits_i(83) and hits_i(78))
                             or (hits_i(92) and hits_i(260) and hits_i(154))
                             or (hits_i(308) and hits_i(278) and hits_i(139))
                             or (hits_i(125) and hits_i(62) and hits_i(226));

        bool_triggers(15) <= (hits_i(110) and hits_i(57) and hits_i(51))
                             or (hits_i(291) and hits_i(54) and hits_i(4))
                             or (hits_i(120) and hits_i(104) and hits_i(191))
                             or (hits_i(243) and hits_i(140) and hits_i(226));

        bool_triggers(16) <= (hits_i(61) and hits_i(60) and hits_i(131))
                             or (hits_i(7) and hits_i(188) and hits_i(99))
                             or (hits_i(162) and hits_i(113) and hits_i(192))
                             or (hits_i(269) and hits_i(314) and hits_i(46));

        bool_triggers(17) <= (hits_i(316) and hits_i(131) and hits_i(50))
                             or (hits_i(237) and hits_i(71) and hits_i(85))
                             or (hits_i(142) and hits_i(194) and hits_i(25))
                             or (hits_i(318) and hits_i(191) and hits_i(165));

        bool_triggers(18) <= (hits_i(170) and hits_i(172) and hits_i(269))
                             or (hits_i(278) and hits_i(121) and hits_i(24))
                             or (hits_i(218) and hits_i(312) and hits_i(204))
                             or (hits_i(42) and hits_i(53) and hits_i(116));

        bool_triggers(19) <= (hits_i(118) and hits_i(100) and hits_i(269))
                             or (hits_i(215) and hits_i(110) and hits_i(152))
                             or (hits_i(99) and hits_i(8) and hits_i(233))
                             or (hits_i(127) and hits_i(132) and hits_i(108));

        bool_triggers(20) <= (hits_i(92) and hits_i(163) and hits_i(80))
                             or (hits_i(252) and hits_i(291) and hits_i(266))
                             or (hits_i(149) and hits_i(245) and hits_i(263))
                             or (hits_i(53) and hits_i(70) and hits_i(257));

        bool_triggers(21) <= (hits_i(37) and hits_i(30) and hits_i(237))
                             or (hits_i(106) and hits_i(46) and hits_i(44))
                             or (hits_i(148) and hits_i(86) and hits_i(208))
                             or (hits_i(139) and hits_i(73) and hits_i(91));

        bool_triggers(22) <= (hits_i(239) and hits_i(280) and hits_i(52))
                             or (hits_i(77) and hits_i(25) and hits_i(50))
                             or (hits_i(48) and hits_i(200) and hits_i(2))
                             or (hits_i(95) and hits_i(58) and hits_i(46));

        bool_triggers(23) <= (hits_i(137) and hits_i(67) and hits_i(275))
                             or (hits_i(305) and hits_i(225) and hits_i(310))
                             or (hits_i(89) and hits_i(150) and hits_i(90))
                             or (hits_i(264) and hits_i(296) and hits_i(158));

        bool_triggers(24) <= (hits_i(158) and hits_i(234) and hits_i(1))
                             or (hits_i(301) and hits_i(172) and hits_i(40))
                             or (hits_i(273) and hits_i(148) and hits_i(53))
                             or (hits_i(134) and hits_i(177) and hits_i(110));

        bool_triggers(25) <= (hits_i(123) and hits_i(22) and hits_i(220))
                             or (hits_i(40) and hits_i(40) and hits_i(55))
                             or (hits_i(18) and hits_i(283) and hits_i(180))
                             or (hits_i(260) and hits_i(66) and hits_i(215));

        bool_triggers(26) <= (hits_i(82) and hits_i(37) and hits_i(137))
                             or (hits_i(22) and hits_i(60) and hits_i(106))
                             or (hits_i(264) and hits_i(223) and hits_i(154))
                             or (hits_i(137) and hits_i(294) and hits_i(284));

        bool_triggers(27) <= (hits_i(36) and hits_i(141) and hits_i(21))
                             or (hits_i(39) and hits_i(134) and hits_i(249))
                             or (hits_i(80) and hits_i(314) and hits_i(132))
                             or (hits_i(289) and hits_i(284) and hits_i(48));

        bool_triggers(28) <= (hits_i(38) and hits_i(166) and hits_i(259))
                             or (hits_i(125) and hits_i(102) and hits_i(197))
                             or (hits_i(6) and hits_i(280) and hits_i(167))
                             or (hits_i(126) and hits_i(234) and hits_i(192));

        bool_triggers(29) <= (hits_i(319) and hits_i(244) and hits_i(138))
                             or (hits_i(24) and hits_i(77) and hits_i(71))
                             or (hits_i(297) and hits_i(133) and hits_i(21))
                             or (hits_i(268) and hits_i(142) and hits_i(146));

        bool_triggers(30) <= (hits_i(113) and hits_i(7) and hits_i(260))
                             or (hits_i(214) and hits_i(140) and hits_i(195))
                             or (hits_i(187) and hits_i(142) and hits_i(104))
                             or (hits_i(310) and hits_i(127) and hits_i(19));

        bool_triggers(31) <= (hits_i(278) and hits_i(196) and hits_i(211))
                             or (hits_i(288) and hits_i(81) and hits_i(259))
                             or (hits_i(268) and hits_i(25) and hits_i(129))
                             or (hits_i(70) and hits_i(211) and hits_i(55));

        bool_triggers(32) <= (hits_i(43) and hits_i(246) and hits_i(223))
                             or (hits_i(164) and hits_i(184) and hits_i(253))
                             or (hits_i(94) and hits_i(307) and hits_i(257))
                             or (hits_i(206) and hits_i(290) and hits_i(163));

        bool_triggers(33) <= (hits_i(106) and hits_i(78) and hits_i(232))
                             or (hits_i(170) and hits_i(205) and hits_i(137))
                             or (hits_i(95) and hits_i(60) and hits_i(280))
                             or (hits_i(282) and hits_i(152) and hits_i(300));

        bool_triggers(34) <= (hits_i(5) and hits_i(13) and hits_i(112))
                             or (hits_i(83) and hits_i(303) and hits_i(56))
                             or (hits_i(201) and hits_i(157) and hits_i(184))
                             or (hits_i(71) and hits_i(78) and hits_i(71));

        bool_triggers(35) <= (hits_i(171) and hits_i(284) and hits_i(117))
                             or (hits_i(74) and hits_i(145) and hits_i(301))
                             or (hits_i(180) and hits_i(166) and hits_i(159))
                             or (hits_i(1) and hits_i(79) and hits_i(161));

        bool_triggers(36) <= (hits_i(168) and hits_i(27) and hits_i(218))
                             or (hits_i(303) and hits_i(180) and hits_i(183))
                             or (hits_i(57) and hits_i(85) and hits_i(77))
                             or (hits_i(267) and hits_i(13) and hits_i(99));

        bool_triggers(37) <= (hits_i(262) and hits_i(61) and hits_i(304))
                             or (hits_i(235) and hits_i(75) and hits_i(88))
                             or (hits_i(76) and hits_i(154) and hits_i(287))
                             or (hits_i(62) and hits_i(47) and hits_i(35));

        bool_triggers(38) <= (hits_i(163) and hits_i(61) and hits_i(297))
                             or (hits_i(165) and hits_i(181) and hits_i(255))
                             or (hits_i(129) and hits_i(138) and hits_i(21))
                             or (hits_i(31) and hits_i(163) and hits_i(157));

        bool_triggers(39) <= (hits_i(228) and hits_i(187) and hits_i(153))
                             or (hits_i(53) and hits_i(87) and hits_i(200))
                             or (hits_i(126) and hits_i(213) and hits_i(200))
                             or (hits_i(308) and hits_i(29) and hits_i(236));

        bool_triggers(40) <= (hits_i(292) and hits_i(178) and hits_i(42))
                             or (hits_i(154) and hits_i(8) and hits_i(149))
                             or (hits_i(189) and hits_i(207) and hits_i(88))
                             or (hits_i(199) and hits_i(125) and hits_i(76));

        bool_triggers(41) <= (hits_i(53) and hits_i(44) and hits_i(263))
                             or (hits_i(239) and hits_i(236) and hits_i(247))
                             or (hits_i(95) and hits_i(105) and hits_i(46))
                             or (hits_i(185) and hits_i(241) and hits_i(306));

        bool_triggers(42) <= (hits_i(224) and hits_i(298) and hits_i(45))
                             or (hits_i(281) and hits_i(182) and hits_i(89))
                             or (hits_i(224) and hits_i(54) and hits_i(127))
                             or (hits_i(272) and hits_i(241) and hits_i(10));

        bool_triggers(43) <= (hits_i(58) and hits_i(242) and hits_i(265))
                             or (hits_i(237) and hits_i(190) and hits_i(201))
                             or (hits_i(38) and hits_i(63) and hits_i(137))
                             or (hits_i(18) and hits_i(127) and hits_i(64));

        bool_triggers(44) <= (hits_i(146) and hits_i(222) and hits_i(55))
                             or (hits_i(304) and hits_i(92) and hits_i(10))
                             or (hits_i(238) and hits_i(204) and hits_i(290))
                             or (hits_i(76) and hits_i(91) and hits_i(195));

        bool_triggers(45) <= (hits_i(108) and hits_i(279) and hits_i(72))
                             or (hits_i(91) and hits_i(268) and hits_i(116))
                             or (hits_i(88) and hits_i(147) and hits_i(38))
                             or (hits_i(278) and hits_i(230) and hits_i(134));

        bool_triggers(46) <= (hits_i(241) and hits_i(2) and hits_i(243))
                             or (hits_i(5) and hits_i(134) and hits_i(10))
                             or (hits_i(141) and hits_i(212) and hits_i(201))
                             or (hits_i(245) and hits_i(4) and hits_i(264));

        bool_triggers(47) <= (hits_i(62) and hits_i(169) and hits_i(102))
                             or (hits_i(313) and hits_i(19) and hits_i(278))
                             or (hits_i(165) and hits_i(288) and hits_i(218))
                             or (hits_i(39) and hits_i(24) and hits_i(77));

        bool_triggers(48) <= (hits_i(131) and hits_i(184) and hits_i(253))
                             or (hits_i(90) and hits_i(149) and hits_i(50))
                             or (hits_i(142) and hits_i(237) and hits_i(168))
                             or (hits_i(86) and hits_i(48) and hits_i(259));

        bool_triggers(49) <= (hits_i(266) and hits_i(260) and hits_i(292))
                             or (hits_i(273) and hits_i(59) and hits_i(85))
                             or (hits_i(124) and hits_i(185) and hits_i(57))
                             or (hits_i(116) and hits_i(277) and hits_i(139));

        bool_triggers(50) <= (hits_i(315) and hits_i(27) and hits_i(23))
                             or (hits_i(216) and hits_i(266) and hits_i(162))
                             or (hits_i(266) and hits_i(185) and hits_i(148))
                             or (hits_i(150) and hits_i(71) and hits_i(90));

        bool_triggers(51) <= (hits_i(131) and hits_i(149) and hits_i(195))
                             or (hits_i(317) and hits_i(43) and hits_i(33))
                             or (hits_i(296) and hits_i(144) and hits_i(76))
                             or (hits_i(191) and hits_i(245) and hits_i(126));

        bool_triggers(52) <= (hits_i(95) and hits_i(32) and hits_i(34))
                             or (hits_i(248) and hits_i(7) and hits_i(0))
                             or (hits_i(27) and hits_i(220) and hits_i(54))
                             or (hits_i(80) and hits_i(259) and hits_i(303));

        bool_triggers(53) <= (hits_i(310) and hits_i(283) and hits_i(120))
                             or (hits_i(316) and hits_i(268) and hits_i(218))
                             or (hits_i(122) and hits_i(25) and hits_i(21))
                             or (hits_i(156) and hits_i(231) and hits_i(303));

        bool_triggers(54) <= (hits_i(299) and hits_i(2) and hits_i(209))
                             or (hits_i(49) and hits_i(254) and hits_i(131))
                             or (hits_i(46) and hits_i(248) and hits_i(256))
                             or (hits_i(139) and hits_i(191) and hits_i(137));

        bool_triggers(55) <= (hits_i(215) and hits_i(295) and hits_i(166))
                             or (hits_i(184) and hits_i(30) and hits_i(91))
                             or (hits_i(103) and hits_i(7) and hits_i(93))
                             or (hits_i(62) and hits_i(245) and hits_i(183));

        bool_triggers(56) <= (hits_i(209) and hits_i(99) and hits_i(100))
                             or (hits_i(136) and hits_i(70) and hits_i(259))
                             or (hits_i(267) and hits_i(247) and hits_i(40))
                             or (hits_i(68) and hits_i(200) and hits_i(259));

        bool_triggers(57) <= (hits_i(80) and hits_i(226) and hits_i(248))
                             or (hits_i(164) and hits_i(168) and hits_i(270))
                             or (hits_i(106) and hits_i(313) and hits_i(60))
                             or (hits_i(216) and hits_i(175) and hits_i(230));

        bool_triggers(58) <= (hits_i(99) and hits_i(221) and hits_i(4))
                             or (hits_i(40) and hits_i(253) and hits_i(112))
                             or (hits_i(172) and hits_i(314) and hits_i(292))
                             or (hits_i(33) and hits_i(305) and hits_i(125));

        bool_triggers(59) <= (hits_i(60) and hits_i(222) and hits_i(284))
                             or (hits_i(136) and hits_i(83) and hits_i(45))
                             or (hits_i(209) and hits_i(15) and hits_i(128))
                             or (hits_i(303) and hits_i(205) and hits_i(143));

        bool_triggers(60) <= (hits_i(38) and hits_i(298) and hits_i(138))
                             or (hits_i(79) and hits_i(177) and hits_i(33))
                             or (hits_i(131) and hits_i(305) and hits_i(154))
                             or (hits_i(229) and hits_i(148) and hits_i(62));

        bool_triggers(61) <= (hits_i(312) and hits_i(60) and hits_i(99))
                             or (hits_i(117) and hits_i(237) and hits_i(108))
                             or (hits_i(36) and hits_i(21) and hits_i(302))
                             or (hits_i(64) and hits_i(13) and hits_i(249));

        bool_triggers(62) <= (hits_i(309) and hits_i(226) and hits_i(136))
                             or (hits_i(21) and hits_i(220) and hits_i(306))
                             or (hits_i(200) and hits_i(88) and hits_i(167))
                             or (hits_i(27) and hits_i(286) and hits_i(194));

        bool_triggers(63) <= (hits_i(96) and hits_i(97) and hits_i(279))
                             or (hits_i(132) and hits_i(279) and hits_i(69))
                             or (hits_i(54) and hits_i(26) and hits_i(166))
                             or (hits_i(241) and hits_i(233) and hits_i(255));

        bool_triggers(64) <= (hits_i(238) and hits_i(288) and hits_i(220))
                             or (hits_i(304) and hits_i(307) and hits_i(49))
                             or (hits_i(262) and hits_i(89) and hits_i(248))
                             or (hits_i(250) and hits_i(131) and hits_i(289));

        bool_triggers(65) <= (hits_i(25) and hits_i(95) and hits_i(155))
                             or (hits_i(250) and hits_i(107) and hits_i(93))
                             or (hits_i(37) and hits_i(102) and hits_i(138))
                             or (hits_i(308) and hits_i(179) and hits_i(17));

        bool_triggers(66) <= (hits_i(282) and hits_i(238) and hits_i(48))
                             or (hits_i(103) and hits_i(188) and hits_i(236))
                             or (hits_i(262) and hits_i(120) and hits_i(293))
                             or (hits_i(257) and hits_i(198) and hits_i(292));

        bool_triggers(67) <= (hits_i(89) and hits_i(230) and hits_i(107))
                             or (hits_i(200) and hits_i(256) and hits_i(309))
                             or (hits_i(203) and hits_i(262) and hits_i(175))
                             or (hits_i(269) and hits_i(191) and hits_i(261));

        bool_triggers(68) <= (hits_i(284) and hits_i(303) and hits_i(52))
                             or (hits_i(109) and hits_i(93) and hits_i(13))
                             or (hits_i(51) and hits_i(92) and hits_i(170))
                             or (hits_i(258) and hits_i(174) and hits_i(270));

        bool_triggers(69) <= (hits_i(105) and hits_i(89) and hits_i(17))
                             or (hits_i(52) and hits_i(318) and hits_i(7))
                             or (hits_i(78) and hits_i(106) and hits_i(79))
                             or (hits_i(121) and hits_i(129) and hits_i(251));

        bool_triggers(70) <= (hits_i(0) and hits_i(135) and hits_i(223))
                             or (hits_i(13) and hits_i(314) and hits_i(212))
                             or (hits_i(167) and hits_i(97) and hits_i(200))
                             or (hits_i(219) and hits_i(319) and hits_i(63));

        bool_triggers(71) <= (hits_i(210) and hits_i(161) and hits_i(234))
                             or (hits_i(33) and hits_i(164) and hits_i(218))
                             or (hits_i(136) and hits_i(274) and hits_i(20))
                             or (hits_i(65) and hits_i(304) and hits_i(182));

        bool_triggers(72) <= (hits_i(51) and hits_i(254) and hits_i(287))
                             or (hits_i(98) and hits_i(212) and hits_i(232))
                             or (hits_i(118) and hits_i(186) and hits_i(62))
                             or (hits_i(4) and hits_i(319) and hits_i(33));

        bool_triggers(73) <= (hits_i(259) and hits_i(309) and hits_i(90))
                             or (hits_i(5) and hits_i(202) and hits_i(204))
                             or (hits_i(35) and hits_i(141) and hits_i(227))
                             or (hits_i(190) and hits_i(194) and hits_i(84));

        bool_triggers(74) <= (hits_i(82) and hits_i(12) and hits_i(156))
                             or (hits_i(101) and hits_i(16) and hits_i(63))
                             or (hits_i(232) and hits_i(187) and hits_i(246))
                             or (hits_i(186) and hits_i(317) and hits_i(167));

        bool_triggers(75) <= (hits_i(23) and hits_i(110) and hits_i(311))
                             or (hits_i(197) and hits_i(132) and hits_i(37))
                             or (hits_i(131) and hits_i(135) and hits_i(242))
                             or (hits_i(127) and hits_i(148) and hits_i(253));

        bool_triggers(76) <= (hits_i(229) and hits_i(134) and hits_i(257))
                             or (hits_i(80) and hits_i(303) and hits_i(258))
                             or (hits_i(10) and hits_i(50) and hits_i(19))
                             or (hits_i(293) and hits_i(17) and hits_i(139));

        bool_triggers(77) <= (hits_i(71) and hits_i(315) and hits_i(19))
                             or (hits_i(283) and hits_i(97) and hits_i(117))
                             or (hits_i(224) and hits_i(306) and hits_i(222))
                             or (hits_i(216) and hits_i(42) and hits_i(246));

        bool_triggers(78) <= (hits_i(188) and hits_i(64) and hits_i(104))
                             or (hits_i(215) and hits_i(184) and hits_i(212))
                             or (hits_i(291) and hits_i(315) and hits_i(319))
                             or (hits_i(18) and hits_i(151) and hits_i(304));

        bool_triggers(79) <= (hits_i(81) and hits_i(94) and hits_i(264))
                             or (hits_i(191) and hits_i(118) and hits_i(0))
                             or (hits_i(164) and hits_i(241) and hits_i(88))
                             or (hits_i(310) and hits_i(276) and hits_i(243));

        bool_triggers(80) <= (hits_i(220) and hits_i(44) and hits_i(186))
                             or (hits_i(265) and hits_i(103) and hits_i(29))
                             or (hits_i(288) and hits_i(18) and hits_i(146))
                             or (hits_i(126) and hits_i(127) and hits_i(142));

        bool_triggers(81) <= (hits_i(81) and hits_i(286) and hits_i(292))
                             or (hits_i(315) and hits_i(215) and hits_i(292))
                             or (hits_i(246) and hits_i(290) and hits_i(200))
                             or (hits_i(245) and hits_i(82) and hits_i(137));

        bool_triggers(82) <= (hits_i(1) and hits_i(277) and hits_i(14))
                             or (hits_i(148) and hits_i(36) and hits_i(308))
                             or (hits_i(291) and hits_i(296) and hits_i(96))
                             or (hits_i(195) and hits_i(103) and hits_i(287));

        bool_triggers(83) <= (hits_i(233) and hits_i(87) and hits_i(106))
                             or (hits_i(172) and hits_i(213) and hits_i(270))
                             or (hits_i(155) and hits_i(30) and hits_i(311))
                             or (hits_i(50) and hits_i(81) and hits_i(14));

        bool_triggers(84) <= (hits_i(262) and hits_i(187) and hits_i(60))
                             or (hits_i(210) and hits_i(209) and hits_i(4))
                             or (hits_i(108) and hits_i(227) and hits_i(211))
                             or (hits_i(257) and hits_i(17) and hits_i(17));

        bool_triggers(85) <= (hits_i(155) and hits_i(100) and hits_i(29))
                             or (hits_i(114) and hits_i(7) and hits_i(223))
                             or (hits_i(52) and hits_i(137) and hits_i(264))
                             or (hits_i(13) and hits_i(38) and hits_i(75));

        bool_triggers(86) <= (hits_i(84) and hits_i(235) and hits_i(281))
                             or (hits_i(289) and hits_i(134) and hits_i(310))
                             or (hits_i(217) and hits_i(240) and hits_i(41))
                             or (hits_i(62) and hits_i(178) and hits_i(34));

        bool_triggers(87) <= (hits_i(164) and hits_i(307) and hits_i(144))
                             or (hits_i(96) and hits_i(55) and hits_i(282))
                             or (hits_i(34) and hits_i(181) and hits_i(216))
                             or (hits_i(313) and hits_i(62) and hits_i(162));

        bool_triggers(88) <= (hits_i(127) and hits_i(99) and hits_i(266))
                             or (hits_i(313) and hits_i(232) and hits_i(247))
                             or (hits_i(73) and hits_i(40) and hits_i(275))
                             or (hits_i(33) and hits_i(273) and hits_i(218));

        bool_triggers(89) <= (hits_i(211) and hits_i(98) and hits_i(104))
                             or (hits_i(219) and hits_i(57) and hits_i(206))
                             or (hits_i(28) and hits_i(284) and hits_i(30))
                             or (hits_i(30) and hits_i(107) and hits_i(27));

        bool_triggers(90) <= (hits_i(168) and hits_i(93) and hits_i(294))
                             or (hits_i(221) and hits_i(224) and hits_i(239))
                             or (hits_i(150) and hits_i(316) and hits_i(88))
                             or (hits_i(215) and hits_i(45) and hits_i(41));

        bool_triggers(91) <= (hits_i(171) and hits_i(116) and hits_i(71))
                             or (hits_i(138) and hits_i(32) and hits_i(24))
                             or (hits_i(41) and hits_i(292) and hits_i(88))
                             or (hits_i(141) and hits_i(55) and hits_i(181));

        bool_triggers(92) <= (hits_i(120) and hits_i(27) and hits_i(6))
                             or (hits_i(280) and hits_i(235) and hits_i(116))
                             or (hits_i(275) and hits_i(43) and hits_i(119))
                             or (hits_i(111) and hits_i(281) and hits_i(153));

        bool_triggers(93) <= (hits_i(62) and hits_i(134) and hits_i(222))
                             or (hits_i(102) and hits_i(151) and hits_i(76))
                             or (hits_i(161) and hits_i(72) and hits_i(3))
                             or (hits_i(243) and hits_i(275) and hits_i(291));

        bool_triggers(94) <= (hits_i(108) and hits_i(145) and hits_i(100))
                             or (hits_i(250) and hits_i(155) and hits_i(103))
                             or (hits_i(108) and hits_i(21) and hits_i(161))
                             or (hits_i(105) and hits_i(266) and hits_i(219));

        bool_triggers(95) <= (hits_i(256) and hits_i(265) and hits_i(94))
                             or (hits_i(296) and hits_i(28) and hits_i(23))
                             or (hits_i(227) and hits_i(284) and hits_i(50))
                             or (hits_i(317) and hits_i(89) and hits_i(268));

        bool_triggers(96) <= (hits_i(317) and hits_i(103) and hits_i(37))
                             or (hits_i(298) and hits_i(200) and hits_i(98))
                             or (hits_i(100) and hits_i(260) and hits_i(70))
                             or (hits_i(80) and hits_i(19) and hits_i(41));

        bool_triggers(97) <= (hits_i(212) and hits_i(187) and hits_i(31))
                             or (hits_i(52) and hits_i(172) and hits_i(290))
                             or (hits_i(237) and hits_i(307) and hits_i(181))
                             or (hits_i(149) and hits_i(191) and hits_i(104));

        bool_triggers(98) <= (hits_i(281) and hits_i(310) and hits_i(284))
                             or (hits_i(88) and hits_i(194) and hits_i(271))
                             or (hits_i(123) and hits_i(93) and hits_i(118))
                             or (hits_i(234) and hits_i(32) and hits_i(84));

        bool_triggers(99) <= (hits_i(192) and hits_i(294) and hits_i(95))
                             or (hits_i(315) and hits_i(26) and hits_i(64))
                             or (hits_i(110) and hits_i(292) and hits_i(163))
                             or (hits_i(195) and hits_i(192) and hits_i(270));

        bool_triggers(100) <= (hits_i(314) and hits_i(225) and hits_i(306))
                              or (hits_i(34) and hits_i(95) and hits_i(46))
                              or (hits_i(289) and hits_i(37) and hits_i(49))
                              or (hits_i(10) and hits_i(92) and hits_i(238));

        bool_triggers(101) <= (hits_i(67) and hits_i(248) and hits_i(14))
                              or (hits_i(170) and hits_i(78) and hits_i(96))
                              or (hits_i(215) and hits_i(196) and hits_i(191))
                              or (hits_i(281) and hits_i(164) and hits_i(247));

        bool_triggers(102) <= (hits_i(256) and hits_i(231) and hits_i(2))
                              or (hits_i(112) and hits_i(102) and hits_i(235))
                              or (hits_i(187) and hits_i(306) and hits_i(89))
                              or (hits_i(97) and hits_i(252) and hits_i(282));

        bool_triggers(103) <= (hits_i(198) and hits_i(76) and hits_i(58))
                              or (hits_i(144) and hits_i(312) and hits_i(97))
                              or (hits_i(203) and hits_i(196) and hits_i(214))
                              or (hits_i(68) and hits_i(288) and hits_i(144));

        bool_triggers(104) <= (hits_i(309) and hits_i(203) and hits_i(119))
                              or (hits_i(181) and hits_i(282) and hits_i(235))
                              or (hits_i(10) and hits_i(16) and hits_i(288))
                              or (hits_i(275) and hits_i(212) and hits_i(259));

        bool_triggers(105) <= (hits_i(16) and hits_i(61) and hits_i(270))
                              or (hits_i(2) and hits_i(77) and hits_i(24))
                              or (hits_i(97) and hits_i(129) and hits_i(262))
                              or (hits_i(107) and hits_i(106) and hits_i(242));

        bool_triggers(106) <= (hits_i(207) and hits_i(215) and hits_i(140))
                              or (hits_i(285) and hits_i(49) and hits_i(47))
                              or (hits_i(239) and hits_i(110) and hits_i(261))
                              or (hits_i(303) and hits_i(188) and hits_i(157));

        bool_triggers(107) <= (hits_i(121) and hits_i(51) and hits_i(303))
                              or (hits_i(281) and hits_i(232) and hits_i(44))
                              or (hits_i(27) and hits_i(143) and hits_i(238))
                              or (hits_i(38) and hits_i(233) and hits_i(263));

        bool_triggers(108) <= (hits_i(238) and hits_i(140) and hits_i(116))
                              or (hits_i(166) and hits_i(26) and hits_i(103))
                              or (hits_i(298) and hits_i(277) and hits_i(156))
                              or (hits_i(124) and hits_i(293) and hits_i(116));

        bool_triggers(109) <= (hits_i(61) and hits_i(219) and hits_i(53))
                              or (hits_i(270) and hits_i(225) and hits_i(248))
                              or (hits_i(183) and hits_i(229) and hits_i(256))
                              or (hits_i(281) and hits_i(183) and hits_i(19));

        bool_triggers(110) <= (hits_i(268) and hits_i(94) and hits_i(192))
                              or (hits_i(40) and hits_i(35) and hits_i(64))
                              or (hits_i(153) and hits_i(162) and hits_i(23))
                              or (hits_i(226) and hits_i(171) and hits_i(255));

        bool_triggers(111) <= (hits_i(140) and hits_i(76) and hits_i(9))
                              or (hits_i(314) and hits_i(291) and hits_i(242))
                              or (hits_i(174) and hits_i(16) and hits_i(101))
                              or (hits_i(94) and hits_i(262) and hits_i(3));

        bool_triggers(112) <= (hits_i(301) and hits_i(81) and hits_i(232))
                              or (hits_i(110) and hits_i(10) and hits_i(23))
                              or (hits_i(178) and hits_i(119) and hits_i(112))
                              or (hits_i(152) and hits_i(82) and hits_i(19));

        bool_triggers(113) <= (hits_i(152) and hits_i(4) and hits_i(233))
                              or (hits_i(73) and hits_i(16) and hits_i(257))
                              or (hits_i(207) and hits_i(171) and hits_i(115))
                              or (hits_i(154) and hits_i(248) and hits_i(190));

        bool_triggers(114) <= (hits_i(164) and hits_i(101) and hits_i(247))
                              or (hits_i(152) and hits_i(55) and hits_i(44))
                              or (hits_i(78) and hits_i(120) and hits_i(241))
                              or (hits_i(282) and hits_i(17) and hits_i(107));

        bool_triggers(115) <= (hits_i(70) and hits_i(233) and hits_i(70))
                              or (hits_i(74) and hits_i(253) and hits_i(190))
                              or (hits_i(145) and hits_i(37) and hits_i(311))
                              or (hits_i(312) and hits_i(255) and hits_i(178));

        bool_triggers(116) <= (hits_i(57) and hits_i(184) and hits_i(54))
                              or (hits_i(208) and hits_i(173) and hits_i(10))
                              or (hits_i(259) and hits_i(63) and hits_i(202))
                              or (hits_i(80) and hits_i(140) and hits_i(40));

        bool_triggers(117) <= (hits_i(255) and hits_i(58) and hits_i(156))
                              or (hits_i(293) and hits_i(201) and hits_i(255))
                              or (hits_i(206) and hits_i(42) and hits_i(36))
                              or (hits_i(122) and hits_i(136) and hits_i(180));

        bool_triggers(118) <= (hits_i(242) and hits_i(262) and hits_i(225))
                              or (hits_i(121) and hits_i(114) and hits_i(31))
                              or (hits_i(191) and hits_i(125) and hits_i(309))
                              or (hits_i(314) and hits_i(37) and hits_i(215));

        bool_triggers(119) <= (hits_i(0) and hits_i(101) and hits_i(257))
                              or (hits_i(34) and hits_i(292) and hits_i(145))
                              or (hits_i(95) and hits_i(315) and hits_i(142))
                              or (hits_i(3) and hits_i(39) and hits_i(74));

        bool_triggers(120) <= (hits_i(300) and hits_i(7) and hits_i(0))
                              or (hits_i(102) and hits_i(283) and hits_i(274))
                              or (hits_i(112) and hits_i(222) and hits_i(252))
                              or (hits_i(208) and hits_i(241) and hits_i(177));

        bool_triggers(121) <= (hits_i(300) and hits_i(191) and hits_i(79))
                              or (hits_i(102) and hits_i(41) and hits_i(31))
                              or (hits_i(274) and hits_i(177) and hits_i(311))
                              or (hits_i(259) and hits_i(107) and hits_i(260));

        bool_triggers(122) <= (hits_i(79) and hits_i(218) and hits_i(220))
                              or (hits_i(182) and hits_i(98) and hits_i(101))
                              or (hits_i(243) and hits_i(116) and hits_i(75))
                              or (hits_i(16) and hits_i(137) and hits_i(110));

        bool_triggers(123) <= (hits_i(96) and hits_i(100) and hits_i(115))
                              or (hits_i(161) and hits_i(230) and hits_i(170))
                              or (hits_i(18) and hits_i(249) and hits_i(53))
                              or (hits_i(52) and hits_i(273) and hits_i(298));

        bool_triggers(124) <= (hits_i(157) and hits_i(30) and hits_i(314))
                              or (hits_i(66) and hits_i(149) and hits_i(179))
                              or (hits_i(128) and hits_i(1) and hits_i(83))
                              or (hits_i(130) and hits_i(240) and hits_i(43));

        bool_triggers(125) <= (hits_i(297) and hits_i(209) and hits_i(261))
                              or (hits_i(256) and hits_i(203) and hits_i(2))
                              or (hits_i(30) and hits_i(150) and hits_i(153))
                              or (hits_i(59) and hits_i(92) and hits_i(214));

        bool_triggers(126) <= (hits_i(12) and hits_i(88) and hits_i(85))
                              or (hits_i(304) and hits_i(280) and hits_i(110))
                              or (hits_i(64) and hits_i(20) and hits_i(124))
                              or (hits_i(131) and hits_i(261) and hits_i(292));

        bool_triggers(127) <= (hits_i(191) and hits_i(149) and hits_i(255))
                              or (hits_i(82) and hits_i(66) and hits_i(23))
                              or (hits_i(112) and hits_i(284) and hits_i(94))
                              or (hits_i(8) and hits_i(68) and hits_i(59));

        bool_triggers(128) <= (hits_i(82) and hits_i(252) and hits_i(173))
                              or (hits_i(316) and hits_i(88) and hits_i(318))
                              or (hits_i(63) and hits_i(27) and hits_i(126))
                              or (hits_i(96) and hits_i(125) and hits_i(179));

        bool_triggers(129) <= (hits_i(111) and hits_i(106) and hits_i(59))
                              or (hits_i(131) and hits_i(121) and hits_i(130))
                              or (hits_i(90) and hits_i(297) and hits_i(11))
                              or (hits_i(208) and hits_i(229) and hits_i(223));

        bool_triggers(130) <= (hits_i(231) and hits_i(246) and hits_i(241))
                              or (hits_i(41) and hits_i(279) and hits_i(26))
                              or (hits_i(273) and hits_i(169) and hits_i(228))
                              or (hits_i(153) and hits_i(97) and hits_i(17));

        bool_triggers(131) <= (hits_i(11) and hits_i(116) and hits_i(189))
                              or (hits_i(261) and hits_i(220) and hits_i(188))
                              or (hits_i(298) and hits_i(129) and hits_i(246))
                              or (hits_i(83) and hits_i(316) and hits_i(230));

        bool_triggers(132) <= (hits_i(175) and hits_i(203) and hits_i(164))
                              or (hits_i(252) and hits_i(28) and hits_i(16))
                              or (hits_i(34) and hits_i(66) and hits_i(158))
                              or (hits_i(303) and hits_i(93) and hits_i(131));

        bool_triggers(133) <= (hits_i(76) and hits_i(38) and hits_i(73))
                              or (hits_i(266) and hits_i(208) and hits_i(3))
                              or (hits_i(44) and hits_i(155) and hits_i(103))
                              or (hits_i(43) and hits_i(149) and hits_i(162));

        bool_triggers(134) <= (hits_i(290) and hits_i(6) and hits_i(209))
                              or (hits_i(249) and hits_i(177) and hits_i(143))
                              or (hits_i(176) and hits_i(75) and hits_i(261))
                              or (hits_i(136) and hits_i(25) and hits_i(74));

        bool_triggers(135) <= (hits_i(61) and hits_i(234) and hits_i(167))
                              or (hits_i(144) and hits_i(270) and hits_i(184))
                              or (hits_i(49) and hits_i(178) and hits_i(259))
                              or (hits_i(70) and hits_i(230) and hits_i(83));

        bool_triggers(136) <= (hits_i(159) and hits_i(285) and hits_i(34))
                              or (hits_i(233) and hits_i(78) and hits_i(129))
                              or (hits_i(184) and hits_i(249) and hits_i(208))
                              or (hits_i(134) and hits_i(9) and hits_i(24));

        bool_triggers(137) <= (hits_i(10) and hits_i(234) and hits_i(267))
                              or (hits_i(96) and hits_i(282) and hits_i(172))
                              or (hits_i(222) and hits_i(48) and hits_i(91))
                              or (hits_i(209) and hits_i(314) and hits_i(135));

        bool_triggers(138) <= (hits_i(279) and hits_i(116) and hits_i(304))
                              or (hits_i(145) and hits_i(124) and hits_i(3))
                              or (hits_i(229) and hits_i(16) and hits_i(201))
                              or (hits_i(14) and hits_i(202) and hits_i(251));

        bool_triggers(139) <= (hits_i(68) and hits_i(171) and hits_i(206))
                              or (hits_i(34) and hits_i(295) and hits_i(64))
                              or (hits_i(235) and hits_i(139) and hits_i(41))
                              or (hits_i(153) and hits_i(33) and hits_i(164));

        bool_triggers(140) <= (hits_i(135) and hits_i(287) and hits_i(87))
                              or (hits_i(64) and hits_i(99) and hits_i(166))
                              or (hits_i(68) and hits_i(59) and hits_i(115))
                              or (hits_i(206) and hits_i(96) and hits_i(83));

        bool_triggers(141) <= (hits_i(194) and hits_i(65) and hits_i(57))
                              or (hits_i(230) and hits_i(155) and hits_i(49))
                              or (hits_i(141) and hits_i(64) and hits_i(83))
                              or (hits_i(274) and hits_i(101) and hits_i(309));

        bool_triggers(142) <= (hits_i(215) and hits_i(71) and hits_i(47))
                              or (hits_i(244) and hits_i(57) and hits_i(305))
                              or (hits_i(9) and hits_i(141) and hits_i(201))
                              or (hits_i(265) and hits_i(283) and hits_i(205));

        bool_triggers(143) <= (hits_i(83) and hits_i(30) and hits_i(125))
                              or (hits_i(36) and hits_i(246) and hits_i(59))
                              or (hits_i(304) and hits_i(297) and hits_i(53))
                              or (hits_i(315) and hits_i(272) and hits_i(86));

        bool_triggers(144) <= (hits_i(61) and hits_i(59) and hits_i(145))
                              or (hits_i(133) and hits_i(280) and hits_i(38))
                              or (hits_i(242) and hits_i(116) and hits_i(195))
                              or (hits_i(107) and hits_i(200) and hits_i(283));

        bool_triggers(145) <= (hits_i(153) and hits_i(173) and hits_i(295))
                              or (hits_i(289) and hits_i(70) and hits_i(147))
                              or (hits_i(290) and hits_i(247) and hits_i(109))
                              or (hits_i(82) and hits_i(207) and hits_i(10));

        bool_triggers(146) <= (hits_i(92) and hits_i(272) and hits_i(300))
                              or (hits_i(126) and hits_i(270) and hits_i(114))
                              or (hits_i(64) and hits_i(224) and hits_i(10))
                              or (hits_i(114) and hits_i(79) and hits_i(95));

        bool_triggers(147) <= (hits_i(27) and hits_i(274) and hits_i(123))
                              or (hits_i(150) and hits_i(171) and hits_i(228))
                              or (hits_i(48) and hits_i(87) and hits_i(245))
                              or (hits_i(104) and hits_i(71) and hits_i(146));

        bool_triggers(148) <= (hits_i(230) and hits_i(28) and hits_i(165))
                              or (hits_i(314) and hits_i(37) and hits_i(174))
                              or (hits_i(206) and hits_i(184) and hits_i(213))
                              or (hits_i(291) and hits_i(144) and hits_i(83));

        bool_triggers(149) <= (hits_i(109) and hits_i(98) and hits_i(262))
                              or (hits_i(290) and hits_i(54) and hits_i(173))
                              or (hits_i(70) and hits_i(130) and hits_i(1))
                              or (hits_i(239) and hits_i(203) and hits_i(233));

        bool_triggers(150) <= (hits_i(135) and hits_i(254) and hits_i(55))
                              or (hits_i(10) and hits_i(286) and hits_i(236))
                              or (hits_i(93) and hits_i(266) and hits_i(274))
                              or (hits_i(171) and hits_i(31) and hits_i(246));

        bool_triggers(151) <= (hits_i(8) and hits_i(316) and hits_i(266))
                              or (hits_i(119) and hits_i(242) and hits_i(123))
                              or (hits_i(315) and hits_i(74) and hits_i(155))
                              or (hits_i(241) and hits_i(311) and hits_i(220));

        bool_triggers(152) <= (hits_i(240) and hits_i(288) and hits_i(217))
                              or (hits_i(186) and hits_i(289) and hits_i(244))
                              or (hits_i(99) and hits_i(182) and hits_i(193))
                              or (hits_i(208) and hits_i(28) and hits_i(65));

        bool_triggers(153) <= (hits_i(74) and hits_i(283) and hits_i(159))
                              or (hits_i(40) and hits_i(43) and hits_i(156))
                              or (hits_i(71) and hits_i(206) and hits_i(152))
                              or (hits_i(108) and hits_i(53) and hits_i(290));

        bool_triggers(154) <= (hits_i(232) and hits_i(19) and hits_i(232))
                              or (hits_i(113) and hits_i(9) and hits_i(40))
                              or (hits_i(224) and hits_i(59) and hits_i(89))
                              or (hits_i(291) and hits_i(149) and hits_i(41));

        bool_triggers(155) <= (hits_i(80) and hits_i(98) and hits_i(53))
                              or (hits_i(270) and hits_i(232) and hits_i(148))
                              or (hits_i(233) and hits_i(238) and hits_i(266))
                              or (hits_i(205) and hits_i(310) and hits_i(229));

        bool_triggers(156) <= (hits_i(120) and hits_i(14) and hits_i(58))
                              or (hits_i(218) and hits_i(226) and hits_i(195))
                              or (hits_i(205) and hits_i(12) and hits_i(3))
                              or (hits_i(84) and hits_i(65) and hits_i(67));

        bool_triggers(157) <= (hits_i(193) and hits_i(103) and hits_i(137))
                              or (hits_i(302) and hits_i(58) and hits_i(16))
                              or (hits_i(153) and hits_i(44) and hits_i(85))
                              or (hits_i(70) and hits_i(213) and hits_i(66));

        bool_triggers(158) <= (hits_i(103) and hits_i(131) and hits_i(34))
                              or (hits_i(247) and hits_i(189) and hits_i(238))
                              or (hits_i(286) and hits_i(314) and hits_i(78))
                              or (hits_i(224) and hits_i(313) and hits_i(123));

        bool_triggers(159) <= (hits_i(134) and hits_i(149) and hits_i(84))
                              or (hits_i(107) and hits_i(71) and hits_i(267))
                              or (hits_i(264) and hits_i(306) and hits_i(186))
                              or (hits_i(29) and hits_i(11) and hits_i(221));

        bool_triggers(160) <= (hits_i(307) and hits_i(316) and hits_i(59))
                              or (hits_i(204) and hits_i(13) and hits_i(103))
                              or (hits_i(307) and hits_i(171) and hits_i(287))
                              or (hits_i(146) and hits_i(48) and hits_i(256));

        bool_triggers(161) <= (hits_i(56) and hits_i(230) and hits_i(201))
                              or (hits_i(152) and hits_i(242) and hits_i(203))
                              or (hits_i(114) and hits_i(124) and hits_i(131))
                              or (hits_i(38) and hits_i(300) and hits_i(177));

        bool_triggers(162) <= (hits_i(225) and hits_i(318) and hits_i(126))
                              or (hits_i(234) and hits_i(318) and hits_i(225))
                              or (hits_i(266) and hits_i(126) and hits_i(89))
                              or (hits_i(118) and hits_i(1) and hits_i(110));

        bool_triggers(163) <= (hits_i(291) and hits_i(100) and hits_i(240))
                              or (hits_i(114) and hits_i(189) and hits_i(197))
                              or (hits_i(270) and hits_i(121) and hits_i(124))
                              or (hits_i(280) and hits_i(134) and hits_i(252));

        bool_triggers(164) <= (hits_i(141) and hits_i(154) and hits_i(33))
                              or (hits_i(206) and hits_i(178) and hits_i(217))
                              or (hits_i(233) and hits_i(96) and hits_i(278))
                              or (hits_i(303) and hits_i(107) and hits_i(226));

        bool_triggers(165) <= (hits_i(97) and hits_i(183) and hits_i(130))
                              or (hits_i(259) and hits_i(314) and hits_i(27))
                              or (hits_i(285) and hits_i(202) and hits_i(108))
                              or (hits_i(53) and hits_i(258) and hits_i(152));

        bool_triggers(166) <= (hits_i(27) and hits_i(208) and hits_i(8))
                              or (hits_i(61) and hits_i(227) and hits_i(252))
                              or (hits_i(279) and hits_i(45) and hits_i(298))
                              or (hits_i(13) and hits_i(150) and hits_i(53));

        bool_triggers(167) <= (hits_i(1) and hits_i(281) and hits_i(302))
                              or (hits_i(72) and hits_i(278) and hits_i(274))
                              or (hits_i(0) and hits_i(135) and hits_i(139))
                              or (hits_i(39) and hits_i(217) and hits_i(150));

        bool_triggers(168) <= (hits_i(92) and hits_i(38) and hits_i(3))
                              or (hits_i(284) and hits_i(122) and hits_i(257))
                              or (hits_i(153) and hits_i(172) and hits_i(253))
                              or (hits_i(35) and hits_i(14) and hits_i(207));

        bool_triggers(169) <= (hits_i(153) and hits_i(105) and hits_i(280))
                              or (hits_i(293) and hits_i(190) and hits_i(315))
                              or (hits_i(105) and hits_i(134) and hits_i(219))
                              or (hits_i(113) and hits_i(212) and hits_i(5));

        bool_triggers(170) <= (hits_i(312) and hits_i(211) and hits_i(99))
                              or (hits_i(151) and hits_i(4) and hits_i(14))
                              or (hits_i(127) and hits_i(45) and hits_i(84))
                              or (hits_i(221) and hits_i(293) and hits_i(12));

        bool_triggers(171) <= (hits_i(282) and hits_i(166) and hits_i(269))
                              or (hits_i(246) and hits_i(191) and hits_i(15))
                              or (hits_i(59) and hits_i(113) and hits_i(207))
                              or (hits_i(61) and hits_i(121) and hits_i(134));

        bool_triggers(172) <= (hits_i(209) and hits_i(131) and hits_i(300))
                              or (hits_i(151) and hits_i(110) and hits_i(25))
                              or (hits_i(70) and hits_i(2) and hits_i(160))
                              or (hits_i(135) and hits_i(296) and hits_i(285));

        bool_triggers(173) <= (hits_i(16) and hits_i(227) and hits_i(162))
                              or (hits_i(184) and hits_i(237) and hits_i(57))
                              or (hits_i(249) and hits_i(288) and hits_i(24))
                              or (hits_i(315) and hits_i(308) and hits_i(67));

        bool_triggers(174) <= (hits_i(194) and hits_i(32) and hits_i(29))
                              or (hits_i(165) and hits_i(282) and hits_i(154))
                              or (hits_i(24) and hits_i(166) and hits_i(109))
                              or (hits_i(40) and hits_i(231) and hits_i(91));

        bool_triggers(175) <= (hits_i(179) and hits_i(276) and hits_i(133))
                              or (hits_i(6) and hits_i(89) and hits_i(221))
                              or (hits_i(151) and hits_i(214) and hits_i(8))
                              or (hits_i(280) and hits_i(190) and hits_i(226));

        bool_triggers(176) <= (hits_i(88) and hits_i(235) and hits_i(40))
                              or (hits_i(22) and hits_i(287) and hits_i(58))
                              or (hits_i(313) and hits_i(284) and hits_i(9))
                              or (hits_i(209) and hits_i(85) and hits_i(9));

        bool_triggers(177) <= (hits_i(40) and hits_i(50) and hits_i(278))
                              or (hits_i(195) and hits_i(295) and hits_i(173))
                              or (hits_i(225) and hits_i(55) and hits_i(64))
                              or (hits_i(56) and hits_i(260) and hits_i(41));

        bool_triggers(178) <= (hits_i(89) and hits_i(141) and hits_i(64))
                              or (hits_i(13) and hits_i(6) and hits_i(96))
                              or (hits_i(141) and hits_i(246) and hits_i(311))
                              or (hits_i(134) and hits_i(126) and hits_i(123));

        bool_triggers(179) <= (hits_i(60) and hits_i(80) and hits_i(172))
                              or (hits_i(168) and hits_i(96) and hits_i(55))
                              or (hits_i(68) and hits_i(77) and hits_i(116))
                              or (hits_i(87) and hits_i(221) and hits_i(88));

        bool_triggers(180) <= (hits_i(212) and hits_i(265) and hits_i(133))
                              or (hits_i(6) and hits_i(82) and hits_i(15))
                              or (hits_i(9) and hits_i(109) and hits_i(13))
                              or (hits_i(229) and hits_i(229) and hits_i(61));

        bool_triggers(181) <= (hits_i(86) and hits_i(155) and hits_i(36))
                              or (hits_i(210) and hits_i(261) and hits_i(204))
                              or (hits_i(130) and hits_i(68) and hits_i(182))
                              or (hits_i(92) and hits_i(20) and hits_i(251));

        bool_triggers(182) <= (hits_i(302) and hits_i(245) and hits_i(286))
                              or (hits_i(241) and hits_i(316) and hits_i(26))
                              or (hits_i(47) and hits_i(70) and hits_i(94))
                              or (hits_i(298) and hits_i(316) and hits_i(294));

        bool_triggers(183) <= (hits_i(239) and hits_i(279) and hits_i(271))
                              or (hits_i(90) and hits_i(288) and hits_i(20))
                              or (hits_i(66) and hits_i(99) and hits_i(225))
                              or (hits_i(71) and hits_i(55) and hits_i(90));

        bool_triggers(184) <= (hits_i(23) and hits_i(74) and hits_i(98))
                              or (hits_i(202) and hits_i(74) and hits_i(287))
                              or (hits_i(293) and hits_i(46) and hits_i(22))
                              or (hits_i(289) and hits_i(124) and hits_i(177));

        bool_triggers(185) <= (hits_i(129) and hits_i(62) and hits_i(295))
                              or (hits_i(224) and hits_i(44) and hits_i(271))
                              or (hits_i(156) and hits_i(290) and hits_i(49))
                              or (hits_i(115) and hits_i(253) and hits_i(216));

        bool_triggers(186) <= (hits_i(136) and hits_i(134) and hits_i(61))
                              or (hits_i(217) and hits_i(131) and hits_i(170))
                              or (hits_i(215) and hits_i(149) and hits_i(69))
                              or (hits_i(211) and hits_i(300) and hits_i(6));

        bool_triggers(187) <= (hits_i(16) and hits_i(183) and hits_i(15))
                              or (hits_i(8) and hits_i(203) and hits_i(202))
                              or (hits_i(88) and hits_i(180) and hits_i(134))
                              or (hits_i(7) and hits_i(66) and hits_i(62));

        bool_triggers(188) <= (hits_i(206) and hits_i(67) and hits_i(130))
                              or (hits_i(33) and hits_i(140) and hits_i(268))
                              or (hits_i(5) and hits_i(81) and hits_i(68))
                              or (hits_i(255) and hits_i(129) and hits_i(162));

        bool_triggers(189) <= (hits_i(51) and hits_i(285) and hits_i(181))
                              or (hits_i(207) and hits_i(160) and hits_i(44))
                              or (hits_i(201) and hits_i(238) and hits_i(112))
                              or (hits_i(56) and hits_i(290) and hits_i(167));

        bool_triggers(190) <= (hits_i(51) and hits_i(47) and hits_i(30))
                              or (hits_i(253) and hits_i(195) and hits_i(86))
                              or (hits_i(171) and hits_i(72) and hits_i(183))
                              or (hits_i(189) and hits_i(170) and hits_i(229));

        bool_triggers(191) <= (hits_i(124) and hits_i(7) and hits_i(25))
                              or (hits_i(286) and hits_i(33) and hits_i(206))
                              or (hits_i(118) and hits_i(17) and hits_i(162))
                              or (hits_i(221) and hits_i(250) and hits_i(23));

        bool_triggers(192) <= (hits_i(172) and hits_i(10) and hits_i(224))
                              or (hits_i(296) and hits_i(293) and hits_i(60))
                              or (hits_i(133) and hits_i(55) and hits_i(82))
                              or (hits_i(167) and hits_i(190) and hits_i(262));

        bool_triggers(193) <= (hits_i(41) and hits_i(8) and hits_i(297))
                              or (hits_i(195) and hits_i(206) and hits_i(291))
                              or (hits_i(218) and hits_i(219) and hits_i(179))
                              or (hits_i(171) and hits_i(40) and hits_i(172));

        bool_triggers(194) <= (hits_i(182) and hits_i(271) and hits_i(265))
                              or (hits_i(256) and hits_i(123) and hits_i(200))
                              or (hits_i(310) and hits_i(164) and hits_i(14))
                              or (hits_i(317) and hits_i(40) and hits_i(291));

        bool_triggers(195) <= (hits_i(144) and hits_i(122) and hits_i(36))
                              or (hits_i(263) and hits_i(25) and hits_i(239))
                              or (hits_i(231) and hits_i(217) and hits_i(251))
                              or (hits_i(55) and hits_i(104) and hits_i(256));

        bool_triggers(196) <= (hits_i(21) and hits_i(214) and hits_i(258))
                              or (hits_i(73) and hits_i(306) and hits_i(299))
                              or (hits_i(169) and hits_i(66) and hits_i(268))
                              or (hits_i(215) and hits_i(21) and hits_i(287));

        bool_triggers(197) <= (hits_i(179) and hits_i(48) and hits_i(188))
                              or (hits_i(91) and hits_i(228) and hits_i(108))
                              or (hits_i(66) and hits_i(192) and hits_i(285))
                              or (hits_i(81) and hits_i(30) and hits_i(299));

        bool_triggers(198) <= (hits_i(124) and hits_i(154) and hits_i(4))
                              or (hits_i(27) and hits_i(209) and hits_i(195))
                              or (hits_i(219) and hits_i(124) and hits_i(238))
                              or (hits_i(194) and hits_i(35) and hits_i(100));

        bool_triggers(199) <= (hits_i(6) and hits_i(2) and hits_i(304))
                              or (hits_i(307) and hits_i(41) and hits_i(302))
                              or (hits_i(255) and hits_i(93) and hits_i(136))
                              or (hits_i(258) and hits_i(254) and hits_i(249));

        bool_triggers(200) <= (hits_i(178) and hits_i(316) and hits_i(298))
                              or (hits_i(290) and hits_i(280) and hits_i(278))
                              or (hits_i(11) and hits_i(214) and hits_i(109))
                              or (hits_i(197) and hits_i(246) and hits_i(116));

        bool_triggers(201) <= (hits_i(142) and hits_i(126) and hits_i(244))
                              or (hits_i(235) and hits_i(95) and hits_i(241))
                              or (hits_i(270) and hits_i(130) and hits_i(230))
                              or (hits_i(109) and hits_i(35) and hits_i(40));

        bool_triggers(202) <= (hits_i(50) and hits_i(157) and hits_i(302))
                              or (hits_i(72) and hits_i(182) and hits_i(232))
                              or (hits_i(4) and hits_i(179) and hits_i(305))
                              or (hits_i(134) and hits_i(248) and hits_i(210));

        bool_triggers(203) <= (hits_i(14) and hits_i(85) and hits_i(114))
                              or (hits_i(140) and hits_i(306) and hits_i(28))
                              or (hits_i(186) and hits_i(27) and hits_i(95))
                              or (hits_i(309) and hits_i(316) and hits_i(261));

        bool_triggers(204) <= (hits_i(181) and hits_i(70) and hits_i(279))
                              or (hits_i(283) and hits_i(133) and hits_i(225))
                              or (hits_i(122) and hits_i(144) and hits_i(96))
                              or (hits_i(114) and hits_i(175) and hits_i(164));

        bool_triggers(205) <= (hits_i(196) and hits_i(220) and hits_i(108))
                              or (hits_i(288) and hits_i(40) and hits_i(215))
                              or (hits_i(20) and hits_i(303) and hits_i(115))
                              or (hits_i(78) and hits_i(262) and hits_i(257));

        bool_triggers(206) <= (hits_i(25) and hits_i(36) and hits_i(28))
                              or (hits_i(208) and hits_i(115) and hits_i(84))
                              or (hits_i(270) and hits_i(114) and hits_i(315))
                              or (hits_i(203) and hits_i(48) and hits_i(277));

        bool_triggers(207) <= (hits_i(207) and hits_i(132) and hits_i(195))
                              or (hits_i(150) and hits_i(100) and hits_i(94))
                              or (hits_i(8) and hits_i(147) and hits_i(34))
                              or (hits_i(123) and hits_i(294) and hits_i(71));

        bool_triggers(208) <= (hits_i(189) and hits_i(80) and hits_i(121))
                              or (hits_i(216) and hits_i(232) and hits_i(113))
                              or (hits_i(205) and hits_i(67) and hits_i(201))
                              or (hits_i(164) and hits_i(24) and hits_i(116));

        bool_triggers(209) <= (hits_i(252) and hits_i(162) and hits_i(316))
                              or (hits_i(121) and hits_i(259) and hits_i(95))
                              or (hits_i(218) and hits_i(75) and hits_i(75))
                              or (hits_i(122) and hits_i(114) and hits_i(143));

        bool_triggers(210) <= (hits_i(138) and hits_i(104) and hits_i(61))
                              or (hits_i(121) and hits_i(230) and hits_i(298))
                              or (hits_i(179) and hits_i(98) and hits_i(189))
                              or (hits_i(32) and hits_i(248) and hits_i(272));

        bool_triggers(211) <= (hits_i(80) and hits_i(223) and hits_i(27))
                              or (hits_i(28) and hits_i(210) and hits_i(265))
                              or (hits_i(62) and hits_i(169) and hits_i(94))
                              or (hits_i(80) and hits_i(211) and hits_i(260));

        bool_triggers(212) <= (hits_i(315) and hits_i(3) and hits_i(79))
                              or (hits_i(83) and hits_i(315) and hits_i(179))
                              or (hits_i(106) and hits_i(224) and hits_i(125))
                              or (hits_i(236) and hits_i(246) and hits_i(185));

        bool_triggers(213) <= (hits_i(21) and hits_i(123) and hits_i(22))
                              or (hits_i(244) and hits_i(301) and hits_i(160))
                              or (hits_i(249) and hits_i(182) and hits_i(300))
                              or (hits_i(218) and hits_i(8) and hits_i(190));

        bool_triggers(214) <= (hits_i(216) and hits_i(309) and hits_i(69))
                              or (hits_i(219) and hits_i(289) and hits_i(43))
                              or (hits_i(40) and hits_i(220) and hits_i(132))
                              or (hits_i(54) and hits_i(97) and hits_i(11));

        bool_triggers(215) <= (hits_i(147) and hits_i(32) and hits_i(138))
                              or (hits_i(149) and hits_i(158) and hits_i(29))
                              or (hits_i(199) and hits_i(243) and hits_i(172))
                              or (hits_i(191) and hits_i(145) and hits_i(66));

        bool_triggers(216) <= (hits_i(216) and hits_i(279) and hits_i(196))
                              or (hits_i(55) and hits_i(232) and hits_i(72))
                              or (hits_i(302) and hits_i(27) and hits_i(172))
                              or (hits_i(146) and hits_i(39) and hits_i(234));

        bool_triggers(217) <= (hits_i(289) and hits_i(222) and hits_i(211))
                              or (hits_i(134) and hits_i(32) and hits_i(119))
                              or (hits_i(174) and hits_i(281) and hits_i(116))
                              or (hits_i(118) and hits_i(100) and hits_i(166));

        bool_triggers(218) <= (hits_i(84) and hits_i(283) and hits_i(61))
                              or (hits_i(287) and hits_i(286) and hits_i(23))
                              or (hits_i(143) and hits_i(99) and hits_i(169))
                              or (hits_i(84) and hits_i(107) and hits_i(206));

        bool_triggers(219) <= (hits_i(300) and hits_i(274) and hits_i(24))
                              or (hits_i(300) and hits_i(5) and hits_i(142))
                              or (hits_i(152) and hits_i(158) and hits_i(226))
                              or (hits_i(40) and hits_i(117) and hits_i(144));

        bool_triggers(220) <= (hits_i(16) and hits_i(278) and hits_i(101))
                              or (hits_i(114) and hits_i(219) and hits_i(270))
                              or (hits_i(230) and hits_i(132) and hits_i(284))
                              or (hits_i(294) and hits_i(169) and hits_i(168));

        bool_triggers(221) <= (hits_i(263) and hits_i(247) and hits_i(218))
                              or (hits_i(243) and hits_i(3) and hits_i(298))
                              or (hits_i(99) and hits_i(295) and hits_i(99))
                              or (hits_i(161) and hits_i(52) and hits_i(32));

        bool_triggers(222) <= (hits_i(97) and hits_i(186) and hits_i(217))
                              or (hits_i(157) and hits_i(285) and hits_i(87))
                              or (hits_i(219) and hits_i(167) and hits_i(38))
                              or (hits_i(241) and hits_i(88) and hits_i(270));

        bool_triggers(223) <= (hits_i(71) and hits_i(191) and hits_i(72))
                              or (hits_i(191) and hits_i(105) and hits_i(223))
                              or (hits_i(131) and hits_i(75) and hits_i(53))
                              or (hits_i(264) and hits_i(92) and hits_i(295));

        bool_triggers(224) <= (hits_i(23) and hits_i(264) and hits_i(291))
                              or (hits_i(290) and hits_i(109) and hits_i(95))
                              or (hits_i(129) and hits_i(79) and hits_i(40))
                              or (hits_i(202) and hits_i(165) and hits_i(191));

        bool_triggers(225) <= (hits_i(83) and hits_i(33) and hits_i(212))
                              or (hits_i(159) and hits_i(2) and hits_i(280))
                              or (hits_i(18) and hits_i(175) and hits_i(236))
                              or (hits_i(248) and hits_i(124) and hits_i(221));

        bool_triggers(226) <= (hits_i(95) and hits_i(63) and hits_i(83))
                              or (hits_i(139) and hits_i(144) and hits_i(4))
                              or (hits_i(36) and hits_i(295) and hits_i(3))
                              or (hits_i(299) and hits_i(24) and hits_i(314));

        bool_triggers(227) <= (hits_i(143) and hits_i(19) and hits_i(138))
                              or (hits_i(281) and hits_i(183) and hits_i(79))
                              or (hits_i(123) and hits_i(94) and hits_i(103))
                              or (hits_i(112) and hits_i(99) and hits_i(302));

        bool_triggers(228) <= (hits_i(117) and hits_i(116) and hits_i(29))
                              or (hits_i(214) and hits_i(119) and hits_i(252))
                              or (hits_i(289) and hits_i(177) and hits_i(120))
                              or (hits_i(148) and hits_i(277) and hits_i(37));

        bool_triggers(229) <= (hits_i(44) and hits_i(57) and hits_i(80))
                              or (hits_i(180) and hits_i(233) and hits_i(258))
                              or (hits_i(167) and hits_i(280) and hits_i(225))
                              or (hits_i(183) and hits_i(251) and hits_i(65));

        bool_triggers(230) <= (hits_i(63) and hits_i(154) and hits_i(193))
                              or (hits_i(37) and hits_i(72) and hits_i(142))
                              or (hits_i(301) and hits_i(243) and hits_i(314))
                              or (hits_i(142) and hits_i(39) and hits_i(108));

        bool_triggers(231) <= (hits_i(223) and hits_i(61) and hits_i(218))
                              or (hits_i(307) and hits_i(160) and hits_i(217))
                              or (hits_i(112) and hits_i(184) and hits_i(35))
                              or (hits_i(234) and hits_i(125) and hits_i(293));

        bool_triggers(232) <= (hits_i(149) and hits_i(8) and hits_i(133))
                              or (hits_i(56) and hits_i(237) and hits_i(270))
                              or (hits_i(109) and hits_i(27) and hits_i(214))
                              or (hits_i(285) and hits_i(215) and hits_i(243));

        bool_triggers(233) <= (hits_i(284) and hits_i(225) and hits_i(153))
                              or (hits_i(40) and hits_i(104) and hits_i(32))
                              or (hits_i(3) and hits_i(162) and hits_i(183))
                              or (hits_i(300) and hits_i(227) and hits_i(192));

        bool_triggers(234) <= (hits_i(154) and hits_i(244) and hits_i(151))
                              or (hits_i(15) and hits_i(132) and hits_i(41))
                              or (hits_i(256) and hits_i(282) and hits_i(65))
                              or (hits_i(34) and hits_i(193) and hits_i(256));

        bool_triggers(235) <= (hits_i(13) and hits_i(312) and hits_i(212))
                              or (hits_i(243) and hits_i(282) and hits_i(68))
                              or (hits_i(265) and hits_i(23) and hits_i(26))
                              or (hits_i(166) and hits_i(260) and hits_i(245));

        bool_triggers(236) <= (hits_i(19) and hits_i(42) and hits_i(17))
                              or (hits_i(108) and hits_i(164) and hits_i(33))
                              or (hits_i(49) and hits_i(81) and hits_i(229))
                              or (hits_i(74) and hits_i(9) and hits_i(48));

        bool_triggers(237) <= (hits_i(261) and hits_i(308) and hits_i(24))
                              or (hits_i(138) and hits_i(294) and hits_i(187))
                              or (hits_i(234) and hits_i(315) and hits_i(126))
                              or (hits_i(277) and hits_i(124) and hits_i(218));

        bool_triggers(238) <= (hits_i(44) and hits_i(271) and hits_i(119))
                              or (hits_i(253) and hits_i(315) and hits_i(264))
                              or (hits_i(97) and hits_i(301) and hits_i(262))
                              or (hits_i(311) and hits_i(52) and hits_i(110));

        bool_triggers(239) <= (hits_i(303) and hits_i(55) and hits_i(144))
                              or (hits_i(76) and hits_i(310) and hits_i(95))
                              or (hits_i(126) and hits_i(73) and hits_i(229))
                              or (hits_i(151) and hits_i(38) and hits_i(94));

        bool_triggers(240) <= (hits_i(116) and hits_i(62) and hits_i(130))
                              or (hits_i(172) and hits_i(230) and hits_i(315))
                              or (hits_i(125) and hits_i(86) and hits_i(266))
                              or (hits_i(219) and hits_i(0) and hits_i(21));

        bool_triggers(241) <= (hits_i(150) and hits_i(50) and hits_i(1))
                              or (hits_i(25) and hits_i(42) and hits_i(111))
                              or (hits_i(159) and hits_i(89) and hits_i(239))
                              or (hits_i(60) and hits_i(146) and hits_i(259));

        bool_triggers(242) <= (hits_i(41) and hits_i(221) and hits_i(90))
                              or (hits_i(9) and hits_i(251) and hits_i(226))
                              or (hits_i(309) and hits_i(149) and hits_i(247))
                              or (hits_i(153) and hits_i(135) and hits_i(112));

        bool_triggers(243) <= (hits_i(169) and hits_i(109) and hits_i(3))
                              or (hits_i(158) and hits_i(60) and hits_i(7))
                              or (hits_i(132) and hits_i(123) and hits_i(255))
                              or (hits_i(184) and hits_i(208) and hits_i(312));

        bool_triggers(244) <= (hits_i(163) and hits_i(130) and hits_i(42))
                              or (hits_i(73) and hits_i(185) and hits_i(229))
                              or (hits_i(134) and hits_i(159) and hits_i(223))
                              or (hits_i(302) and hits_i(235) and hits_i(169));

        bool_triggers(245) <= (hits_i(66) and hits_i(170) and hits_i(292))
                              or (hits_i(257) and hits_i(45) and hits_i(84))
                              or (hits_i(29) and hits_i(300) and hits_i(109))
                              or (hits_i(182) and hits_i(37) and hits_i(97));

        bool_triggers(246) <= (hits_i(240) and hits_i(283) and hits_i(42))
                              or (hits_i(149) and hits_i(274) and hits_i(6))
                              or (hits_i(205) and hits_i(22) and hits_i(126))
                              or (hits_i(138) and hits_i(197) and hits_i(220));

        bool_triggers(247) <= (hits_i(319) and hits_i(207) and hits_i(239))
                              or (hits_i(118) and hits_i(150) and hits_i(167))
                              or (hits_i(147) and hits_i(153) and hits_i(12))
                              or (hits_i(92) and hits_i(291) and hits_i(289));

        bool_triggers(248) <= (hits_i(226) and hits_i(146) and hits_i(5))
                              or (hits_i(66) and hits_i(284) and hits_i(65))
                              or (hits_i(77) and hits_i(225) and hits_i(12))
                              or (hits_i(29) and hits_i(305) and hits_i(200));

        bool_triggers(249) <= (hits_i(195) and hits_i(291) and hits_i(5))
                              or (hits_i(311) and hits_i(78) and hits_i(142))
                              or (hits_i(80) and hits_i(201) and hits_i(266))
                              or (hits_i(62) and hits_i(273) and hits_i(125));

        bool_triggers(250) <= (hits_i(76) and hits_i(259) and hits_i(35))
                              or (hits_i(313) and hits_i(20) and hits_i(60))
                              or (hits_i(74) and hits_i(33) and hits_i(57))
                              or (hits_i(268) and hits_i(41) and hits_i(19));

        bool_triggers(251) <= (hits_i(173) and hits_i(154) and hits_i(223))
                              or (hits_i(249) and hits_i(228) and hits_i(311))
                              or (hits_i(269) and hits_i(73) and hits_i(114))
                              or (hits_i(276) and hits_i(191) and hits_i(9));

        bool_triggers(252) <= (hits_i(11) and hits_i(168) and hits_i(265))
                              or (hits_i(56) and hits_i(3) and hits_i(20))
                              or (hits_i(161) and hits_i(131) and hits_i(120))
                              or (hits_i(104) and hits_i(45) and hits_i(205));

        bool_triggers(253) <= (hits_i(0) and hits_i(234) and hits_i(181))
                              or (hits_i(281) and hits_i(174) and hits_i(300))
                              or (hits_i(62) and hits_i(277) and hits_i(187))
                              or (hits_i(100) and hits_i(95) and hits_i(15));

        bool_triggers(254) <= (hits_i(140) and hits_i(188) and hits_i(75))
                              or (hits_i(122) and hits_i(42) and hits_i(198))
                              or (hits_i(140) and hits_i(176) and hits_i(20))
                              or (hits_i(225) and hits_i(162) and hits_i(258));

        bool_triggers(255) <= (hits_i(302) and hits_i(115) and hits_i(60))
                              or (hits_i(254) and hits_i(263) and hits_i(263))
                              or (hits_i(111) and hits_i(309) and hits_i(281))
                              or (hits_i(269) and hits_i(146) and hits_i(241));

        bool_triggers(256) <= (hits_i(27) and hits_i(173) and hits_i(46))
                              or (hits_i(306) and hits_i(313) and hits_i(141))
                              or (hits_i(44) and hits_i(307) and hits_i(62))
                              or (hits_i(317) and hits_i(116) and hits_i(243));

        bool_triggers(257) <= (hits_i(187) and hits_i(307) and hits_i(35))
                              or (hits_i(233) and hits_i(49) and hits_i(237))
                              or (hits_i(23) and hits_i(59) and hits_i(92))
                              or (hits_i(276) and hits_i(215) and hits_i(55));

        bool_triggers(258) <= (hits_i(98) and hits_i(48) and hits_i(184))
                              or (hits_i(55) and hits_i(28) and hits_i(284))
                              or (hits_i(72) and hits_i(45) and hits_i(208))
                              or (hits_i(75) and hits_i(281) and hits_i(120));

        bool_triggers(259) <= (hits_i(83) and hits_i(61) and hits_i(103))
                              or (hits_i(211) and hits_i(115) and hits_i(250))
                              or (hits_i(102) and hits_i(115) and hits_i(214))
                              or (hits_i(197) and hits_i(205) and hits_i(220));

        bool_triggers(260) <= (hits_i(109) and hits_i(281) and hits_i(311))
                              or (hits_i(195) and hits_i(153) and hits_i(114))
                              or (hits_i(299) and hits_i(307) and hits_i(60))
                              or (hits_i(117) and hits_i(283) and hits_i(107));

        bool_triggers(261) <= (hits_i(53) and hits_i(271) and hits_i(307))
                              or (hits_i(268) and hits_i(55) and hits_i(283))
                              or (hits_i(17) and hits_i(132) and hits_i(94))
                              or (hits_i(285) and hits_i(311) and hits_i(72));

        bool_triggers(262) <= (hits_i(113) and hits_i(263) and hits_i(107))
                              or (hits_i(211) and hits_i(55) and hits_i(108))
                              or (hits_i(258) and hits_i(44) and hits_i(289))
                              or (hits_i(40) and hits_i(64) and hits_i(283));

        bool_triggers(263) <= (hits_i(76) and hits_i(155) and hits_i(213))
                              or (hits_i(18) and hits_i(182) and hits_i(184))
                              or (hits_i(205) and hits_i(287) and hits_i(109))
                              or (hits_i(255) and hits_i(236) and hits_i(1));

        bool_triggers(264) <= (hits_i(41) and hits_i(86) and hits_i(61))
                              or (hits_i(289) and hits_i(293) and hits_i(138))
                              or (hits_i(297) and hits_i(144) and hits_i(205))
                              or (hits_i(153) and hits_i(51) and hits_i(103));

        bool_triggers(265) <= (hits_i(286) and hits_i(262) and hits_i(248))
                              or (hits_i(24) and hits_i(64) and hits_i(287))
                              or (hits_i(235) and hits_i(305) and hits_i(247))
                              or (hits_i(11) and hits_i(124) and hits_i(293));

        bool_triggers(266) <= (hits_i(196) and hits_i(30) and hits_i(259))
                              or (hits_i(4) and hits_i(295) and hits_i(239))
                              or (hits_i(174) and hits_i(166) and hits_i(3))
                              or (hits_i(315) and hits_i(18) and hits_i(214));

        bool_triggers(267) <= (hits_i(153) and hits_i(59) and hits_i(250))
                              or (hits_i(192) and hits_i(95) and hits_i(49))
                              or (hits_i(137) and hits_i(230) and hits_i(295))
                              or (hits_i(169) and hits_i(277) and hits_i(278));

        bool_triggers(268) <= (hits_i(313) and hits_i(281) and hits_i(294))
                              or (hits_i(112) and hits_i(185) and hits_i(185))
                              or (hits_i(185) and hits_i(188) and hits_i(168))
                              or (hits_i(298) and hits_i(176) and hits_i(214));

        bool_triggers(269) <= (hits_i(156) and hits_i(213) and hits_i(179))
                              or (hits_i(54) and hits_i(39) and hits_i(122))
                              or (hits_i(17) and hits_i(91) and hits_i(105))
                              or (hits_i(9) and hits_i(58) and hits_i(95));

        bool_triggers(270) <= (hits_i(88) and hits_i(224) and hits_i(91))
                              or (hits_i(140) and hits_i(3) and hits_i(56))
                              or (hits_i(76) and hits_i(134) and hits_i(223))
                              or (hits_i(153) and hits_i(306) and hits_i(294));

        bool_triggers(271) <= (hits_i(62) and hits_i(233) and hits_i(239))
                              or (hits_i(286) and hits_i(111) and hits_i(285))
                              or (hits_i(304) and hits_i(173) and hits_i(155))
                              or (hits_i(102) and hits_i(87) and hits_i(73));

        bool_triggers(272) <= (hits_i(95) and hits_i(165) and hits_i(89))
                              or (hits_i(163) and hits_i(289) and hits_i(278))
                              or (hits_i(188) and hits_i(89) and hits_i(180))
                              or (hits_i(17) and hits_i(276) and hits_i(273));

        bool_triggers(273) <= (hits_i(204) and hits_i(252) and hits_i(265))
                              or (hits_i(244) and hits_i(251) and hits_i(233))
                              or (hits_i(125) and hits_i(309) and hits_i(156))
                              or (hits_i(194) and hits_i(147) and hits_i(106));

        bool_triggers(274) <= (hits_i(249) and hits_i(69) and hits_i(74))
                              or (hits_i(99) and hits_i(64) and hits_i(40))
                              or (hits_i(187) and hits_i(208) and hits_i(134))
                              or (hits_i(231) and hits_i(217) and hits_i(196));

        bool_triggers(275) <= (hits_i(129) and hits_i(307) and hits_i(234))
                              or (hits_i(55) and hits_i(185) and hits_i(56))
                              or (hits_i(183) and hits_i(48) and hits_i(69))
                              or (hits_i(185) and hits_i(280) and hits_i(8));

        bool_triggers(276) <= (hits_i(315) and hits_i(33) and hits_i(212))
                              or (hits_i(246) and hits_i(100) and hits_i(249))
                              or (hits_i(89) and hits_i(83) and hits_i(121))
                              or (hits_i(264) and hits_i(122) and hits_i(209));

        bool_triggers(277) <= (hits_i(60) and hits_i(91) and hits_i(290))
                              or (hits_i(147) and hits_i(214) and hits_i(38))
                              or (hits_i(185) and hits_i(274) and hits_i(194))
                              or (hits_i(47) and hits_i(309) and hits_i(103));

        bool_triggers(278) <= (hits_i(262) and hits_i(35) and hits_i(242))
                              or (hits_i(141) and hits_i(278) and hits_i(223))
                              or (hits_i(147) and hits_i(97) and hits_i(304))
                              or (hits_i(57) and hits_i(137) and hits_i(268));

        bool_triggers(279) <= (hits_i(3) and hits_i(170) and hits_i(233))
                              or (hits_i(244) and hits_i(213) and hits_i(59))
                              or (hits_i(150) and hits_i(76) and hits_i(78))
                              or (hits_i(149) and hits_i(132) and hits_i(26));

        bool_triggers(280) <= (hits_i(147) and hits_i(80) and hits_i(78))
                              or (hits_i(43) and hits_i(284) and hits_i(32))
                              or (hits_i(277) and hits_i(231) and hits_i(17))
                              or (hits_i(43) and hits_i(150) and hits_i(166));

        bool_triggers(281) <= (hits_i(49) and hits_i(77) and hits_i(104))
                              or (hits_i(283) and hits_i(272) and hits_i(53))
                              or (hits_i(156) and hits_i(102) and hits_i(260))
                              or (hits_i(280) and hits_i(203) and hits_i(148));

        bool_triggers(282) <= (hits_i(186) and hits_i(262) and hits_i(16))
                              or (hits_i(64) and hits_i(5) and hits_i(155))
                              or (hits_i(8) and hits_i(101) and hits_i(304))
                              or (hits_i(206) and hits_i(12) and hits_i(277));

        bool_triggers(283) <= (hits_i(269) and hits_i(216) and hits_i(152))
                              or (hits_i(182) and hits_i(132) and hits_i(11))
                              or (hits_i(153) and hits_i(142) and hits_i(264))
                              or (hits_i(257) and hits_i(20) and hits_i(100));

        bool_triggers(284) <= (hits_i(40) and hits_i(70) and hits_i(219))
                              or (hits_i(271) and hits_i(15) and hits_i(256))
                              or (hits_i(127) and hits_i(204) and hits_i(254))
                              or (hits_i(189) and hits_i(104) and hits_i(31));

        bool_triggers(285) <= (hits_i(99) and hits_i(262) and hits_i(252))
                              or (hits_i(180) and hits_i(310) and hits_i(65))
                              or (hits_i(139) and hits_i(271) and hits_i(8))
                              or (hits_i(50) and hits_i(221) and hits_i(61));

        bool_triggers(286) <= (hits_i(105) and hits_i(272) and hits_i(74))
                              or (hits_i(187) and hits_i(38) and hits_i(218))
                              or (hits_i(76) and hits_i(89) and hits_i(205))
                              or (hits_i(24) and hits_i(11) and hits_i(133));

        bool_triggers(287) <= (hits_i(249) and hits_i(32) and hits_i(206))
                              or (hits_i(282) and hits_i(14) and hits_i(23))
                              or (hits_i(80) and hits_i(98) and hits_i(251))
                              or (hits_i(191) and hits_i(99) and hits_i(179));

        bool_triggers(288) <= (hits_i(192) and hits_i(301) and hits_i(277))
                              or (hits_i(303) and hits_i(110) and hits_i(136))
                              or (hits_i(107) and hits_i(143) and hits_i(0))
                              or (hits_i(183) and hits_i(8) and hits_i(48));

        bool_triggers(289) <= (hits_i(123) and hits_i(121) and hits_i(103))
                              or (hits_i(20) and hits_i(138) and hits_i(83))
                              or (hits_i(226) and hits_i(11) and hits_i(240))
                              or (hits_i(210) and hits_i(70) and hits_i(125));

        bool_triggers(290) <= (hits_i(6) and hits_i(17) and hits_i(145))
                              or (hits_i(225) and hits_i(100) and hits_i(128))
                              or (hits_i(3) and hits_i(1) and hits_i(120))
                              or (hits_i(201) and hits_i(85) and hits_i(138));

        bool_triggers(291) <= (hits_i(45) and hits_i(267) and hits_i(44))
                              or (hits_i(225) and hits_i(186) and hits_i(172))
                              or (hits_i(197) and hits_i(150) and hits_i(298))
                              or (hits_i(87) and hits_i(145) and hits_i(32));

        bool_triggers(292) <= (hits_i(129) and hits_i(126) and hits_i(260))
                              or (hits_i(186) and hits_i(0) and hits_i(87))
                              or (hits_i(120) and hits_i(141) and hits_i(208))
                              or (hits_i(244) and hits_i(129) and hits_i(244));

        bool_triggers(293) <= (hits_i(205) and hits_i(223) and hits_i(310))
                              or (hits_i(123) and hits_i(113) and hits_i(268))
                              or (hits_i(28) and hits_i(307) and hits_i(107))
                              or (hits_i(88) and hits_i(278) and hits_i(131));

        bool_triggers(294) <= (hits_i(87) and hits_i(123) and hits_i(288))
                              or (hits_i(188) and hits_i(44) and hits_i(171))
                              or (hits_i(181) and hits_i(172) and hits_i(6))
                              or (hits_i(66) and hits_i(40) and hits_i(166));

        bool_triggers(295) <= (hits_i(110) and hits_i(196) and hits_i(318))
                              or (hits_i(224) and hits_i(290) and hits_i(155))
                              or (hits_i(44) and hits_i(305) and hits_i(130))
                              or (hits_i(230) and hits_i(82) and hits_i(90));

        bool_triggers(296) <= (hits_i(273) and hits_i(74) and hits_i(244))
                              or (hits_i(158) and hits_i(39) and hits_i(297))
                              or (hits_i(52) and hits_i(164) and hits_i(125))
                              or (hits_i(310) and hits_i(208) and hits_i(154));

        bool_triggers(297) <= (hits_i(272) and hits_i(288) and hits_i(117))
                              or (hits_i(225) and hits_i(4) and hits_i(103))
                              or (hits_i(81) and hits_i(1) and hits_i(179))
                              or (hits_i(216) and hits_i(10) and hits_i(38));

        bool_triggers(298) <= (hits_i(261) and hits_i(247) and hits_i(172))
                              or (hits_i(200) and hits_i(63) and hits_i(41))
                              or (hits_i(62) and hits_i(201) and hits_i(237))
                              or (hits_i(160) and hits_i(245) and hits_i(318));

        bool_triggers(299) <= (hits_i(239) and hits_i(293) and hits_i(317))
                              or (hits_i(239) and hits_i(49) and hits_i(309))
                              or (hits_i(282) and hits_i(171) and hits_i(4))
                              or (hits_i(136) and hits_i(159) and hits_i(316));

        bool_triggers(300) <= (hits_i(111) and hits_i(34) and hits_i(31))
                              or (hits_i(65) and hits_i(91) and hits_i(239))
                              or (hits_i(9) and hits_i(81) and hits_i(119))
                              or (hits_i(280) and hits_i(235) and hits_i(92));

        bool_triggers(301) <= (hits_i(38) and hits_i(262) and hits_i(97))
                              or (hits_i(220) and hits_i(152) and hits_i(173))
                              or (hits_i(279) and hits_i(178) and hits_i(196))
                              or (hits_i(305) and hits_i(163) and hits_i(177));

        bool_triggers(302) <= (hits_i(17) and hits_i(296) and hits_i(103))
                              or (hits_i(82) and hits_i(25) and hits_i(171))
                              or (hits_i(254) and hits_i(215) and hits_i(36))
                              or (hits_i(90) and hits_i(64) and hits_i(240));

        bool_triggers(303) <= (hits_i(51) and hits_i(70) and hits_i(66))
                              or (hits_i(250) and hits_i(315) and hits_i(110))
                              or (hits_i(284) and hits_i(59) and hits_i(65))
                              or (hits_i(6) and hits_i(245) and hits_i(57));

        bool_triggers(304) <= (hits_i(313) and hits_i(42) and hits_i(37))
                              or (hits_i(290) and hits_i(172) and hits_i(127))
                              or (hits_i(236) and hits_i(281) and hits_i(170))
                              or (hits_i(310) and hits_i(122) and hits_i(6));

        bool_triggers(305) <= (hits_i(103) and hits_i(280) and hits_i(264))
                              or (hits_i(121) and hits_i(178) and hits_i(203))
                              or (hits_i(172) and hits_i(228) and hits_i(12))
                              or (hits_i(151) and hits_i(289) and hits_i(141));

        bool_triggers(306) <= (hits_i(127) and hits_i(173) and hits_i(80))
                              or (hits_i(211) and hits_i(232) and hits_i(315))
                              or (hits_i(188) and hits_i(299) and hits_i(265))
                              or (hits_i(196) and hits_i(103) and hits_i(115));

        bool_triggers(307) <= (hits_i(67) and hits_i(291) and hits_i(227))
                              or (hits_i(130) and hits_i(43) and hits_i(270))
                              or (hits_i(250) and hits_i(96) and hits_i(69))
                              or (hits_i(26) and hits_i(21) and hits_i(288));

        bool_triggers(308) <= (hits_i(237) and hits_i(3) and hits_i(38))
                              or (hits_i(294) and hits_i(243) and hits_i(0))
                              or (hits_i(115) and hits_i(295) and hits_i(219))
                              or (hits_i(262) and hits_i(170) and hits_i(47));

        bool_triggers(309) <= (hits_i(176) and hits_i(130) and hits_i(282))
                              or (hits_i(292) and hits_i(102) and hits_i(228))
                              or (hits_i(161) and hits_i(66) and hits_i(245))
                              or (hits_i(280) and hits_i(101) and hits_i(8));

        bool_triggers(310) <= (hits_i(54) and hits_i(192) and hits_i(298))
                              or (hits_i(169) and hits_i(162) and hits_i(222))
                              or (hits_i(4) and hits_i(236) and hits_i(182))
                              or (hits_i(294) and hits_i(161) and hits_i(197));

        bool_triggers(311) <= (hits_i(205) and hits_i(95) and hits_i(87))
                              or (hits_i(217) and hits_i(299) and hits_i(178))
                              or (hits_i(109) and hits_i(154) and hits_i(79))
                              or (hits_i(12) and hits_i(74) and hits_i(123));

        bool_triggers(312) <= (hits_i(294) and hits_i(234) and hits_i(24))
                              or (hits_i(275) and hits_i(107) and hits_i(133))
                              or (hits_i(266) and hits_i(245) and hits_i(246))
                              or (hits_i(242) and hits_i(64) and hits_i(228));

        bool_triggers(313) <= (hits_i(95) and hits_i(318) and hits_i(154))
                              or (hits_i(83) and hits_i(204) and hits_i(88))
                              or (hits_i(117) and hits_i(269) and hits_i(269))
                              or (hits_i(255) and hits_i(231) and hits_i(115));

        bool_triggers(314) <= (hits_i(210) and hits_i(29) and hits_i(214))
                              or (hits_i(141) and hits_i(3) and hits_i(230))
                              or (hits_i(115) and hits_i(175) and hits_i(119))
                              or (hits_i(96) and hits_i(180) and hits_i(123));

        bool_triggers(315) <= (hits_i(305) and hits_i(120) and hits_i(51))
                              or (hits_i(104) and hits_i(211) and hits_i(13))
                              or (hits_i(61) and hits_i(232) and hits_i(272))
                              or (hits_i(20) and hits_i(23) and hits_i(262));

        bool_triggers(316) <= (hits_i(19) and hits_i(214) and hits_i(211))
                              or (hits_i(185) and hits_i(191) and hits_i(209))
                              or (hits_i(206) and hits_i(67) and hits_i(38))
                              or (hits_i(295) and hits_i(293) and hits_i(72));

        bool_triggers(317) <= (hits_i(240) and hits_i(39) and hits_i(129))
                              or (hits_i(130) and hits_i(55) and hits_i(247))
                              or (hits_i(197) and hits_i(175) and hits_i(307))
                              or (hits_i(264) and hits_i(302) and hits_i(38));

        bool_triggers(318) <= (hits_i(141) and hits_i(243) and hits_i(234))
                              or (hits_i(117) and hits_i(114) and hits_i(311))
                              or (hits_i(316) and hits_i(272) and hits_i(267))
                              or (hits_i(192) and hits_i(276) and hits_i(171));

        bool_triggers(319) <= (hits_i(54) and hits_i(127) and hits_i(67))
                              or (hits_i(276) and hits_i(224) and hits_i(307))
                              or (hits_i(58) and hits_i(11) and hits_i(286))
                              or (hits_i(290) and hits_i(138) and hits_i(145));
      else
        for I in 0 to hits_i'length-1 loop
          bool_triggers(I) <= '0';
        end loop;
      end if;
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      triggers <= single_hit_triggers or bool_triggers;
    end if;
  end process;

  or_gen : for I in 0 to rb_ors'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        rb_ors(I) <= or_reduce(rb_triggers(I));
      end if;
    end process;
  end generate;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      global_trigger_o <= or_reduce(rb_ors);

      -- delay by 1 clk to align with global trigger
      rb_triggers_o <= rb_ors;
      triggers_r    <= triggers;
      triggers_o    <= triggers_r;
    end if;
  end process;

end behavioral;
