----------------------------------------------------------------------------------
-- Soft Reset Module
-- GAPS DRS4 Readout Firmware
-- A. Peck
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity soft_reset is
  port(
    clock : in std_logic;

    reset : in std_logic;

    drs_busy : in std_logic;
    drs_idle : in std_logic;
    daq_busy : in std_logic;
    dma_idle : in std_logic;

    soft_reset_i        :     std_logic;
    soft_reset_done     : out std_logic;
    soft_reset_drs      : out std_logic;
    soft_reset_daq      : out std_logic;
    soft_reset_dma      : out std_logic;
    soft_reset_ptr      : out std_logic;
    soft_reset_buf      : out std_logic;
    soft_reset_trg      : out std_logic;
    soft_reset_drs_en   : in  std_logic;
    soft_reset_daq_en   : in  std_logic;
    soft_reset_dma_en   : in  std_logic;
    soft_reset_ptr_en   : in  std_logic;
    soft_reset_buf_en   : in  std_logic;
    soft_reset_trg_en   : in  std_logic;
    soft_reset_wait_daq : in  std_logic;
    soft_reset_wait_drs : in  std_logic;
    soft_reset_wait_dma : in  std_logic
    );
end;

architecture rtl of soft_reset is

  type soft_rst_state_t is (IDLE, AUTO_RESET, DIS_TRIGGER,
                            WAIT_DRS, WAIT_DAQ, WAIT_DMA,
                            RST_POINTER, FLUSH);

  signal soft_rst_state : soft_rst_state_t;

  constant SOFT_RESET_FLUSH_CNT_MAX : integer := 127;
  signal soft_reset_flush_cnt       : integer range 0 to SOFT_RESET_FLUSH_CNT_MAX;

begin

  --------------------------------------------------------------------------------
  -- Soft Reset
  --
  -- 1) disable triggering
  -- 2) wait for the drs to go idle, reset it
  -- 3) wait for the daq to go idle, reset it
  -- 4) reset the drs->daq skidbuffer
  --
  --------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then

      soft_reset_drs  <= '0';
      soft_reset_daq  <= '0';
      soft_reset_dma  <= '0';
      soft_reset_buf  <= '0';
      soft_reset_ptr  <= '0';
      soft_reset_done <= '0';

      case soft_rst_state is

        when AUTO_RESET =>

          if (reset = '0') then
            soft_rst_state <= DIS_TRIGGER;
          end if;

        when IDLE =>

          soft_reset_done      <= '1';
          soft_reset_flush_cnt <= SOFT_RESET_FLUSH_CNT_MAX;
          soft_reset_trg       <= '0';  -- trigger reset should be held high

          if (soft_reset_i = '1') then
            soft_rst_state <= AUTO_RESET;
          end if;

        when DIS_TRIGGER =>

          soft_rst_state <= WAIT_DRS;
          soft_reset_trg <= soft_reset_trg_en;

        when WAIT_DRS =>

          if (drs_busy = '0' or drs_idle = '1' or soft_reset_wait_drs = '0') then
            soft_rst_state <= WAIT_DAQ;
            soft_reset_drs <= soft_reset_drs_en;
          end if;

        when WAIT_DAQ =>

          if (daq_busy = '0' or soft_reset_wait_daq = '0') then
            soft_rst_state <= WAIT_DMA;
            soft_reset_daq <= soft_reset_daq_en;
          end if;

        when WAIT_DMA =>

          if (dma_idle = '1' or soft_reset_wait_dma = '0') then
            soft_rst_state <= RST_POINTER;
            soft_reset_dma <= soft_reset_dma_en;
          end if;

        when RST_POINTER =>

          if (soft_reset_flush_cnt = 0 and (dma_idle = '1' or soft_reset_wait_dma = '0')) then
            soft_rst_state       <= FLUSH;
            soft_reset_ptr       <= soft_reset_ptr_en;
            soft_reset_flush_cnt <= SOFT_RESET_FLUSH_CNT_MAX;
          else
            soft_reset_flush_cnt <= soft_reset_flush_cnt - 1;
          end if;

        when FLUSH =>

          soft_reset_buf <= soft_reset_buf_en;

          if (soft_reset_flush_cnt = 0) then
            soft_rst_state <= IDLE;
          else
            soft_reset_flush_cnt <= soft_reset_flush_cnt - 1;
          end if;

        when others =>

          soft_rst_state <= IDLE;

      end case;

      if (reset = '1') then
        soft_rst_state <= AUTO_RESET;
      end if;

    end if;
  end process;


end rtl;
