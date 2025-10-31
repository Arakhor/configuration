{ profiles, ... }:
{
    xps.imports = profiles.universal.modules ++ profiles.personal.modules;

}
