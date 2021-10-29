package constants is

  --
  constant NUM_RBS         : positive := 40;
  constant NUM_RB_CHANNELS : positive := 8;
  constant NUM_RB_OUTPUTS  : positive := NUM_RBS;

  --
  constant NUM_LT_CHANNELS : positive := 16;
  constant NUM_LTS         : positive := 20;
  constant NUM_LT_MT_LINKS : positive := 4;
  constant NUM_LT_INPUTS   : positive := NUM_LT_MT_LINKS * NUM_LTS;
  constant NUM_LT_CLOCKS   : positive := NUM_LTS;
  constant NUM_LT_BITS     : positive := 16;

  constant EVENTCNTB : positive := 48;

  --
  --constant MODE : string := "IDDR"; -- FF or IDDR or OVERSAMPLE

end package constants;
