library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

library work;

entity sem_wrapper is
port(
    clk_i               : in std_logic;

    correction_o        : out std_logic;
    classification_o    : out std_logic;
    uncorrectable_o     : out std_logic;

    heartbeat_o         : out std_logic;
    initialization_o    : out std_logic;
    observation_o       : out std_logic;
    essential_o         : out std_logic;

    sump                : out std_logic
);
end sem_wrapper;

architecture behavioral of sem_wrapper is

    signal fecc_crcerr              : std_logic;
    signal fecc_eccerr              : std_logic;
    signal fecc_eccerrsingle        : std_logic;
    signal fecc_syndromevalid       : std_logic;
    signal fecc_syndrome            : std_logic_vector(12 downto 0);
    signal fecc_far                 : std_logic_vector(25 downto 0);
    signal fecc_synbit              : std_logic_vector(4 downto 0);
    signal fecc_synword             : std_logic_vector(6 downto 0);

    signal icap_o                   : std_logic_vector(31 downto 0);
    signal icap_i                   : std_logic_vector(31 downto 0);
    signal icap_busy                : std_logic;
    signal icap_csb                 : std_logic;
    signal icap_rdwrb               : std_logic;

    signal one : std_logic := '1';
    signal zero : std_logic := '0'; 

    signal rx_data : std_logic_vector(7 downto 0) := (others => '0');

    signal sump_vector : std_logic_vector (10 downto 0);

begin

    sump <= or_reduce(sump_vector);

    sem_inst : entity work.sem_core

    PORT MAP (
        status_heartbeat      => heartbeat_o,
        status_initialization => initialization_o,
        status_observation    => observation_o,
        status_correction     => correction_o,
        status_classification => classification_o,
        status_essential      => essential_o,
        status_uncorrectable  => uncorrectable_o,
        monitor_txdata        => sump_vector(7 downto 0),
        monitor_txwrite       => sump_vector(8),
        monitor_txfull        => zero,
        monitor_rxdata        => rx_data,
        monitor_rxread        => sump_vector(9),
        monitor_rxempty       => one,
        icap_o                => icap_o,
        icap_csib             => icap_csb,
        icap_rdwrb            => icap_rdwrb,
        icap_i                => icap_i,
        icap_clk              => clk_i,
        icap_request          => sump_vector(10),
        icap_grant            => one,
        fecc_crcerr           => fecc_crcerr,
        fecc_eccerr           => fecc_eccerr,
        fecc_eccerrsingle     => fecc_eccerrsingle,
        fecc_syndromevalid    => fecc_syndromevalid,
        fecc_syndrome         => fecc_syndrome,
        fecc_far              => fecc_far (25 downto 0),
        fecc_synbit           => fecc_synbit,
        fecc_synword          => fecc_synword
    );

    ICAPE2_inst : ICAPE2
    generic map (
        DEVICE_ID         => X"03651093", -- Specifies the pre-programmed Device ID value to be used for simulation purposes.
        ICAP_WIDTH        => "X32",       -- Specifies the input and output data width.
        SIM_CFG_FILE_NAME => "NONE"       -- Specifies the Raw Bitstream (RBT) file to be parsed by the simulation model.
    )
    port map (
        o     => icap_o,    -- 32-bit output: configuration data output bus
        clk   => clk_i,     -- 1-bit input: clock input
        csib  => icap_csb,  -- 1-bit input: active-low icap enable
        i     => icap_i,    -- 32-bit input: configuration data input bus
        rdwrb => icap_rdwrb -- 1-bit input: read/write select input
    );

   FRAME_ECCE2_inst : FRAME_ECCE2
   generic map (
      FARSRC => "EFAR",                -- Determines if the output of FAR[25:0] configuration register points
                                       -- to the FAR or EFAR. Sets configuration option register bit CTL0[7].
      FRAME_RBT_IN_FILENAME => "None"  -- This file is output by the ICAP_E2 model and it contains Frame Data
                                       -- information for the Raw Bitstream (RBT) file. The FRAME_ECCE2 model
                                       -- will parse this file, calculate ECC and output any error conditions.
   )
   port map (
      crcerror       => fecc_crcerr,        -- 1-bit output: Output indicating a CRC error.
      eccerror       => fecc_eccerr,        -- 1-bit output: Output indicating an ECC error.
      eccerrorsingle => fecc_eccerrsingle,  -- 1-bit output: Output Indicating single-bit Frame ECC error detected.
      far            => fecc_far,           -- 26-bit output: Frame Address Register Value output.
      synbit         => fecc_synbit,        -- 5-bit output: Output bit address of error.
      syndrome       => fecc_syndrome,      -- 13-bit output: Output location of erroneous bit.
      syndromevalid  => fecc_syndromevalid, -- 1-bit output: Frame ECC output indicating the SYNDROME output is valid.
      synword        => fecc_synword        -- 7-bit output: Word output in the frame where an ECC error has been detected.

   );

end behavioral;
