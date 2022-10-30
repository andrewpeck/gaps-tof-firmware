package constants is


  constant NUM_DSI  : natural := 5;

  --
  constant NUM_RBS         : positive := 10*NUM_DSI; -- number of readout boards in the system
  constant NUM_RB_CHANNELS : positive := 8;          -- number of channels per rb
  constant NUM_RB_OUTPUTS  : positive := NUM_RBS*1;  -- number of output links

  --
  constant NUM_LTS         : positive := NUM_DSI*5;                  -- number of lt boards in the system
  constant NUM_LT_CHANNELS : positive := 16;                         -- number of hit channels per lt
  constant NUM_LT_MT_LINKS : positive := 3;                          -- number of links per mt
  constant NUM_LT_INPUTS   : positive := NUM_LT_MT_LINKS * NUM_LTS;  -- number of links in the system
  constant NUM_LT_CLOCKS   : positive := NUM_LTS;                    --
  constant NUM_LT_BITS     : positive := 16; --

  constant EVENTCNTB : positive := 32;

  --
  --constant MODE : string := "IDDR"; -- FF or IDDR or OVERSAMPLE

end package constants;
