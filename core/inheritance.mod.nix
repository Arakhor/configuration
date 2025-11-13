{ profiles, ... }:
{
    xps.imports = profiles.universal.modules ++ profiles.graphical.modules;

}
