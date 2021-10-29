package constants is

  --
  constant NUM_RBS         : positive := 40;         -- number of readout boards in the system
  constant NUM_RB_CHANNELS : positive := 8;          -- number of channels per rb
  constant NUM_RB_OUTPUTS  : positive := NUM_RBS*1;  -- number of output links

  --
  constant NUM_LTS         : positive := 20;                         -- number of lt boards in the system
  constant NUM_LT_CHANNELS : positive := 16;                         -- number of hit channels per lt
  constant NUM_LT_MT_LINKS : positive := 2;                          -- number of links per mt
  constant NUM_LT_INPUTS   : positive := NUM_LT_MT_LINKS * NUM_LTS;  -- number of links in the system
  constant NUM_LT_CLOCKS   : positive := NUM_LTS;                    --
  constant NUM_LT_BITS     : positive := 16; --

  constant EVENTCNTB : positive := 48;

  --
  --constant MODE : string := "IDDR"; -- FF or IDDR or OVERSAMPLE

end package constants;
