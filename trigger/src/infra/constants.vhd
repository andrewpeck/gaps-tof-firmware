package constants is

  constant NUM_DSI : natural := 5;

  --
  constant NUM_RBS         : positive := 50;  -- number of readout boards in the system
  constant NUM_RB_CHANNELS : positive := 8;   -- number of channels per rb
  constant NUM_RB_OUTPUTS  : positive := 50;  -- number of output links
  constant TOT_RB_CHANNELS : positive := 400; -- total number of RB channels

  --
  constant NUM_LTS         : positive := 25;  -- number of lt boards in the system
  constant NUM_LT_BITS     : positive := 8;   --
  constant NUM_LT_MT_PRI   : positive := 50;  -- number of primary links in the system
  constant NUM_LT_MT_AUX   : positive := 25;  -- number of auxillary links in the system
  constant NUM_LT_MT_ALL   : positive := 75;  -- number of total links in the system
  constant TOT_LT_CHANNELS : positive := 200; -- total number of LT channels

  constant EVENTCNTB : positive := 32;

end package constants;
