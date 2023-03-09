library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity count1s is
  generic(
    SIZE : positive
    );
  port(
    clock : in  std_logic;
    d     : in  std_logic_vector (SIZE-1 downto 0);
    cnt   : out natural range 0 to SIZE
    );
end count1s;

architecture behavioral of count1s is

  function count_ones(slv : std_logic_vector) return natural is
    variable n_ones : natural := 0;
  begin
    for i in slv'range loop
      if slv(i) = '1' then
        n_ones := n_ones + 1;
      end if;
    end loop;
    return n_ones;
  end function count_ones;

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then
      cnt <= count_ones(d);
    end if;
  end process;

end behavioral;

-- module count_clusters
--   #(
--     parameter OVERFLOW_THRESH = 0,
--     parameter SIZE = 768
--     ) (
--     input             clock,
--     input             latch,
--     input [SIZE-1:0]  vpfs_i,
--     output reg [10:0] cnt_o,
--     output reg        overflow_o
--     );

--    generate
--       if (SIZE==768) begin

--          reg [2 : 0] cnt_s1  [127 : 0]; // count to 6
--          reg [3 : 0] cnt_s2  [63 : 0];  // count to 12
--          reg [4 : 0] cnt_s3  [31 : 0];  // count to 24
--          reg [5 : 0] cnt_s4  [15 : 0];  // count to 48
--          reg [6 : 0] cnt_s5  [ 7 : 0];  // count to 96
--          reg [8 : 0] cnt_s6  [ 3 : 0];  // count to 192
--          reg [9 : 0] cnt_s7  [ 1 : 0];  // count to 768

--          reg [10:0]  cnt; // count to 1536

--          // register inputs
--          // make sure Xilinx doesn't merge these with copies in the cluster finding
--          (*EQUIVALENT_REGISTER_REMOVAL="NO"*)
--          reg [767:0] vpfs;

--          always @(posedge clock) begin
--             if (latch)
--               vpfs    <= vpfs_i;
--          end

--          genvar icnt;

--          for (icnt=0; icnt<(128); icnt=icnt+1) begin: cnt_s1_loop
--             always @(posedge clock)
--               cnt_s1[icnt] <= count1s(vpfs[(icnt+1)*6-1:icnt*6]);
--          end

--          for (icnt=0; icnt<(64); icnt=icnt+1) begin: cnt_s2_loop
--             always @(posedge clock)
--               cnt_s2[icnt] <= cnt_s1[(icnt+1)*2-1] + cnt_s1[icnt*2];
--          end

--          for (icnt=0; icnt<(32); icnt=icnt+1) begin: cnt_s3_loop
--             always @(posedge clock)
--               cnt_s3[icnt] <= cnt_s2[(icnt+1)*2-1] + cnt_s2[icnt*2];
--          end

--          for (icnt=0; icnt<(16); icnt=icnt+1) begin: cnt_s4_loop
--             always @(posedge clock)
--               cnt_s4[icnt] <= cnt_s3[(icnt+1)*2-1] + cnt_s3[icnt*2];
--          end

--          for (icnt=0; icnt<(8); icnt=icnt+1) begin: cnt_s5_loop
--             always @(posedge clock)
--               cnt_s5[icnt] <= cnt_s4[(icnt+1)*2-1] + cnt_s4[icnt*2];
--          end

--          for (icnt=0; icnt<(4); icnt=icnt+1) begin: cnt_s6_loop
--             always @(posedge clock)
--               cnt_s6[icnt] <= cnt_s5[(icnt+1)*2-1] + cnt_s5[icnt*2];
--          end

--          always @(posedge clock) begin
--             cnt_s7[0] <= cnt_s6[0]  + cnt_s6[1]  + cnt_s6[2]  + cnt_s6[3];
--             cnt_s7[1] <= 0;
--          end

--          // delay count by clock to align with overflow
--          always @(posedge clock) begin
--             cnt <= cnt_s7[0] + cnt_s7[1];
--             cnt_o <= cnt;
--             overflow_o <= (cnt > OVERFLOW_THRESH);
--          end

--       end
--    endgenerate

--    generate
--       if (SIZE==1536) begin
--          reg [2:0] cnt_s1 [255:0]; // count to 6
--          reg [3:0] cnt_s2 [127:0]; // count to 12
--          reg [4:0] cnt_s3  [63:0]; // count to 24
--          reg [5:0] cnt_s4  [31:0]; // count to 48
--          reg [6:0] cnt_s5  [15:0]; // count to 96
--          reg [8:0] cnt_s6  [ 7:0]; // count to 192
--          reg [9:0] cnt_s7  [ 1:0]; // count to 768

--          reg [10:0] cnt; // count to 1536

--          // register inputs
--          // make sure xilinx doesn't merge these with copies in the cluster finding
--          (*equivalent_register_removal="no"*)
--          (*shreg_extract="no"*)
--          reg [1535:0] vpfs;

--          always @(posedge clock) begin
--             if (latch)
--               vpfs <= vpfs_i;
--          end

--          genvar icnt;

--          for (icnt=0; icnt<(256); icnt=icnt+1) begin: cnt_s1_loop
--             always @(posedge clock)
--               cnt_s1[icnt] <= count1s(vpfs[(icnt+1)*6-1:icnt*6]);
--          end

--          for (icnt=0; icnt<(128); icnt=icnt+1) begin: cnt_s2_loop
--             always @(posedge clock)
--               cnt_s2[icnt] <= cnt_s1[(icnt+1)*2-1] + cnt_s1[icnt*2];
--          end

--          for (icnt=0; icnt<(64); icnt=icnt+1) begin: cnt_s3_loop
--             always @(posedge clock)
--               cnt_s3[icnt] <= cnt_s2[(icnt+1)*2-1] + cnt_s2[icnt*2];
--          end

--          for (icnt=0; icnt<(32); icnt=icnt+1) begin: cnt_s4_loop
--             always @(posedge clock)
--               cnt_s4[icnt] <= cnt_s3[(icnt+1)*2-1] + cnt_s3[icnt*2];
--          end

--          for (icnt=0; icnt<(16); icnt=icnt+1) begin: cnt_s5_loop
--             always @(posedge clock)
--               cnt_s5[icnt] <= cnt_s4[(icnt+1)*2-1] + cnt_s4[icnt*2];
--          end

--          for (icnt=0; icnt<(8); icnt=icnt+1) begin: cnt_s6_loop
--             always @(posedge clock)
--               cnt_s6[icnt] <= cnt_s5[(icnt+1)*2-1] + cnt_s5[icnt*2];
--          end

--          always @(posedge clock) begin
--             cnt_s7[0] <= cnt_s6[0]  + cnt_s6[1]  + cnt_s6[2]  + cnt_s6[3];
--             cnt_s7[1] <= cnt_s6[4]  + cnt_s6[5]  + cnt_s6[6]  + cnt_s6[7];
--          end

--          always @(posedge clock) begin
--             cnt <=  cnt_s7[0] + cnt_s7[1];
--             cnt_o <= cnt;
--             overflow_o <= (cnt > OVERFLOW_THRESH);
--          end
--       end
--    endgenerate

-- `include "count1s.v"

-- endmodule
