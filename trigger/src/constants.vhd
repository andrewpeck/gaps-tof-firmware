package constants is

  constant NUM_DSI  : natural := 5;

  --
  constant NUM_RBS         : positive := 10*NUM_DSI; -- number of readout boards in the system
  constant NUM_RB_CHANNELS : positive := 8;          -- number of channels per rb
  constant NUM_RB_OUTPUTS  : positive := NUM_RBS*1;  -- number of output links

  --
  constant NUM_LTS         : positive := NUM_DSI*5;                     -- 25 number of lt boards in the system
  constant NUM_LT_BITS     : positive := 8;                             --
  constant NUM_LT_MT_PRI   : positive := 2 * NUM_LTS;                   -- 50 number of links in the system
  constant NUM_LT_MT_AUX   : positive := 1 * NUM_LTS;                   -- 25 number of links in the system
  constant NUM_LT_MT_ALL   : positive := NUM_LT_MT_PRI + NUM_LT_MT_AUX; -- number of links in the system
  constant TOT_LT_CHANNELS : positive := NUM_LT_BITS*NUM_LT_MT_PRI/2;   -- 200

  constant EVENTCNTB : positive := 32;

end package constants;
