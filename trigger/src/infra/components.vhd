library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package components is

  component ila_trigger
    port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(7 downto 0);
      probe1  : in std_logic_vector(7 downto 0);
      probe2  : in std_logic_vector(3 downto 0);
      probe3  : in std_logic_vector(31 downto 0);
      probe4  : in std_logic_vector(199 downto 0)
    );
  end component;

  component ila_200
    port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(0 downto 0);
      probe1  : in std_logic_vector(0 downto 0);
      probe2  : in std_logic_vector(7 downto 0);
      probe3  : in std_logic_vector(1 downto 0);
      probe4  : in std_logic_vector(1 downto 0);
      probe5  : in std_logic_vector(1 downto 0);
      probe6  : in std_logic_vector(1 downto 0);
      probe7  : in std_logic_vector(1 downto 0);
      probe8  : in std_logic_vector(1 downto 0);
      probe9  : in std_logic_vector(1 downto 0);
      probe10 : in std_logic_vector(1 downto 0)
    );
  end component;

  component vio_prbs is
    port (
      clk        : IN  STD_LOGIC;
      probe_in0  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      probe_in1  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in2  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in3  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in4  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in5  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in6  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in7  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in8  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in9  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in10 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in11 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in12 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in13 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in14 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in15 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in16 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in17 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in18 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in19 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in20 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in21 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in22 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in23 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in24 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in25 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in26 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in27 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in28 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in29 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in30 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in31 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in32 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in33 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in34 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in35 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in36 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in37 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in38 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in39 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in40 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in41 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in42 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in43 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in44 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in45 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in46 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in47 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in48 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in49 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in50 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in51 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in52 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in53 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in54 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in55 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in56 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in57 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in58 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in59 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in60 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in61 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in62 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in63 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in64 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in65 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in66 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in67 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in68 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in69 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in70 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in71 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in72 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in73 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in74 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in75 : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
      probe_in76 : IN  STD_LOGIC_VECTOR(74 DOWNTO 0);
      probe_in77 : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe_out1 : OUT STD_LOGIC_VECTOR(74 DOWNTO 0);
      probe_out2 : OUT STD_LOGIC_VECTOR(49 DOWNTO 0);
      probe_out3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe_out4 : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
      probe_out5 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      probe_out6 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      probe_out7 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
      );
  end component vio_prbs;

  component ila_mt is
  port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(0 downto 0);
      probe1  : in std_logic_vector(0 downto 0);
      probe2  : in std_logic_vector(74 downto 0);
      probe3  : in std_logic_vector(7 downto 0);
      probe4  : in std_logic_vector(7 downto 0);
      probe5  : in std_logic_vector(0 downto 0);
      probe6  : in std_logic_vector(0 downto 0);
      probe7  : in std_logic_vector(0 downto 0);
      probe8  : in std_logic_vector(0 downto 0);
      probe9  : in std_logic_vector(1 downto 0);
      probe10 : in std_logic_vector(31 downto 0);
      probe11 : in std_logic_vector(31 downto 0);
      probe12 : in std_logic_vector(31 downto 0);
      probe13 : in std_logic_vector(31 downto 0);
      probe14 : in std_logic_vector(31 downto 0)
      );
  end component ila_mt;

  component ila_prbs is
  port (
      clk     : in std_logic;
      probe0  : in std_logic_vector(0 downto 0);
      probe1  : in std_logic_vector(0 downto 0);
      probe2  : in std_logic_vector(74 downto 0);
      probe3  : in std_logic_vector(7 downto 0);
      probe4  : in std_logic_vector(7 downto 0);
      probe5  : in std_logic_vector(0 downto 0);
      probe6  : in std_logic_vector(0 downto 0);
      probe7  : in std_logic_vector(0 downto 0);
      probe8  : in std_logic_vector(0 downto 0);
      probe9  : in std_logic_vector(1 downto 0);
      probe10 : in std_logic_vector(31 downto 0);
      probe11 : in std_logic_vector(31 downto 0);
      probe12 : in std_logic_vector(31 downto 0);
      probe13 : in std_logic_vector(31 downto 0);
      probe14 : in std_logic_vector(31 downto 0)
      );
  end component ila_prbs;

  component cylon1 is
    port (
      clock : in  std_logic;
      rate  : in  std_logic_vector (1 downto 0);
      q     : out std_logic_vector (3 downto 0)
      );
  end component;

end package components;
