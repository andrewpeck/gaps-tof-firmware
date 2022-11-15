library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package components is

  component device_dna
    port(
      clock : in  std_logic;
      reset : in  std_logic;
      dna   : out std_logic_vector
      );
  end component;

  component drs
    port(
      clock                    : in  std_logic;
      reset                    : in  std_logic;
      diagnostic_mode          : in  std_logic;
      trigger_i                : in  std_logic;
      posneg_i                 : in  std_logic;
      adc_data_i               : in  std_logic_vector;
      drs_ctl_spike_removal    : in  std_logic;
      drs_ctl_roi_mode         : in  std_logic;
      drs_ctl_dmode            : in  std_logic;
      drs_ctl_adc_latency      : in  std_logic_vector;
      drs_ctl_sample_count_max : in  std_logic_vector;
      drs_ctl_config           : in  std_logic_vector;
      drs_ctl_standby_mode     : in  std_logic;
      drs_ctl_transp_mode      : in  std_logic;
      drs_ctl_start            : in  std_logic;
      drs_ctl_reinit           : in  std_logic;
      drs_ctl_configure_drs    : in  std_logic;
      drs_ctl_chn_config       : in  std_logic_vector;
      drs_ctl_readout_mask_i   : in  std_logic_vector;
      drs_ctl_wait_vdd_clocks  : in  std_logic_vector;
      drs_srout_i              : in  std_logic;
      drs_addr_o               : out std_logic_vector;
      drs_nreset_o             : out std_logic;
      drs_denable_o            : out std_logic;
      drs_dwrite_o             : out std_logic;
      drs_rsrload_o            : out std_logic;
      drs_srclk_en_o           : out std_logic;
      drs_srin_o               : out std_logic;
      drs_on_o                 : out std_logic;
      drs_stop_cell_o          : out std_logic_vector(9 downto 0);
      fifo_wdata_o             : out std_logic_vector;
      fifo_wen_o               : out std_logic;
      readout_complete         : out std_logic;
      busy_o                   : out std_logic;
      idle_o                   : out std_logic
      );
  end component;

  component clock_wizard
    port (
      -- Clock out ports
      drs_clk   : out std_logic;
      trg_clk   : out std_logic;
      trg_clk8x : out std_logic;
      daq_clk   : out std_logic;
      -- Status and control signals
      locked    : out std_logic;
      -- Clock in ports
      clk_in1   : in  std_logic
      );
  end component;

  component cylon1 is
    port (
      clock : in  std_logic;
      rate  : in  std_logic_vector (1 downto 0);
      q     : out std_logic_vector (3 downto 0)
      );
  end component;

end package components;
