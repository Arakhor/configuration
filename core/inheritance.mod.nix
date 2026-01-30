{ profiles, ... }:
{
    xps.imports = builtins.concatLists [
        profiles.base.modules
        profiles.universal.modules
        profiles.graphical.modules
    ];

    zeph.imports = builtins.concatLists [
        profiles.base.modules
        profiles.universal.modules
        profiles.graphical.modules
        profiles.gaming.modules
    ];
}
