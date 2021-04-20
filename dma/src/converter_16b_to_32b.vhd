------------------------------------------------------------
--  
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;
entity converter_16b_to_32b is 
  generic (
	dwidth_i	: integer := 16;
	dwidth_o	: integer := 32
  );
  port (
    CLK_IN     : in  std_logic; 
    RST_IN     : in  std_logic;
    d_i        : in  std_logic_vector(dwidth_i-1 downto 0);
    wr_i 	   : in  std_logic;
	d_last_i   : in  std_logic;
	
	d_o        : out std_logic_vector(dwidth_o-1 downto 0);
	wr_o 	   : out std_logic;
    d_last_o   : out std_logic
	);
end converter_16b_to_32b;

architecture converter_16b_to_32b of converter_16b_to_32b is
 
signal	din_r1			: std_logic_vector(dwidth_i-1 downto 0);
signal	din_r2			: std_logic_vector(dwidth_i-1 downto 0);
signal	din_r3			: std_logic_vector(dwidth_o-1 downto 0); 

signal	valid_r1			: std_logic;
signal	valid_r2			: std_logic;
signal	valid_r3			: std_logic;
signal	valid_r4			: std_logic;

signal	last_r1			: std_logic;
signal	last_r2			: std_logic;
signal	last_r3			: std_logic;
signal	last_r4			: std_logic;

constant n_taps			: integer := ((dwidth_o/dwidth_i) - 1); 
constant n_taps_bits    : integer := integer(log2(real(dwidth_o/dwidth_i)));

signal  n_taps_counter		: std_logic_vector( (n_taps) - 1 downto 0) := (others => '0');

signal  n_taps_reg		: std_logic_vector(n_taps - 1 downto 0) := (others => '0');

signal start_converter  : std_logic := '0';


begin

	
	d_o  <= din_r3;
	wr_o <= valid_r3;
	
	d_last_o <= last_r3;
	
	process(CLK_IN)
	begin
		if(rising_edge(CLK_IN)) then
			if RST_IN = '0'  then
				din_r1 <= (others => '0');
				din_r2 <= (others => '0');
				din_r3 <= (others => '0');
				 
				last_r1  <= '0';
				last_r2  <= '0';
				last_r3  <= '0';
 			else
				din_r1 <= d_i;
				din_r2 <= din_r1;
				din_r3 <= din_r2 & din_r1; 
				  
				last_r1 <= d_last_i;
				last_r2 <= last_r1;
				last_r3 <= last_r2;	
 				
			end if;
		end if;
	end process;

	process(CLK_IN)
	begin
		if(rising_edge(CLK_IN)) then
			if RST_IN = '0'  then   
				n_taps_counter  <= (others => '0'); 
				valid_r1	<= '0';
				valid_r2	<= '0';
				valid_r3	<= '0';
				valid_r4  <= '0';
			else   
				valid_r1 <= wr_i;
			
				if(wr_i= '1' and valid_r1 = '0') then 
				   start_converter <= '1';
				elsif(last_r1 = '1') then
                    start_converter <= '0'; 
				else 
				    start_converter <= start_converter;
				end if;
				
				if(start_converter = '1') then
                    n_taps_counter <= std_logic_vector(unsigned(n_taps_counter) + 1);
                    
                    if(n_taps_counter(n_taps_bits-1) = '1') then
                        valid_r2 <= '1';
                        n_taps_counter <= (others => '0');
                    else
                        valid_r2 <= '0';
                    end if;
                    
                    valid_r3 <= valid_r2;
                    valid_r4 <= valid_r3; 
	            else 
	                n_taps_counter <= (others => '0');	
                    valid_r2 <= '0';
                    valid_r3 <= valid_r2;
	                valid_r4 <= valid_r3; 
	            
	            end if;			
				 
			end if;
		end if;
	end process; 
  
end converter_16b_to_32b; 