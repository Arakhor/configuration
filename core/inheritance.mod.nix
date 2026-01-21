{ profiles, ... }:
{
    xps.imports = builtins.concatLists [
        profiles.universal.modules
        profiles.graphical.modules
    ];

    zeph.imports = builtins.concatLists [
        profiles.universal.modules
        profiles.graphical.modules
        profiles.gaming.modules
    ];
}
