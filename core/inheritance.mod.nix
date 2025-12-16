{ profiles, ... }:
{
  xps.imports = profiles.universal.modules ++ profiles.graphical.modules;
  zeph.imports = profiles.universal.modules ++ profiles.graphical.modules;

}
