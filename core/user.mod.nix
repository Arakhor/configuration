{ nix-maid, ... }:
{
    universal =
        {
            lib,
            config,
            ...
        }:
        let
            defaultUserHome = "/home";
            name = "arakhor";
            home = "${defaultUserHome}/${name}";
            hashedPassword = "$y$j9T$2RCRnlUsztuzTPbLjkPN50$LCDo/lkk9QQUVfNl0Xm7yM85t/uwAato.JlP3pCsLj4";
        in
        {
            imports = [
                nix-maid.nixosModules.default
                {
                    options.maid-users = lib.mkOption {
                        type = lib.mkOptionType {
                            name = "nix-maid module";
                            check = _: true;
                            merge =
                                loc:
                                map (def: {
                                    _file = def.file;
                                    imports = [ def.value ];
                                });
                        };
                        default = { };
                    };
                }
            ];

            users = {
                mutableUsers = false;
                users.root.hashedPassword = hashedPassword;
                users.${name} = {
                    inherit name home hashedPassword;
                    isNormalUser = true;
                    description = "Cyryl Smoleński";
                    extraGroups = [ "wheel" ];
                    maid.imports = config.maid-users;
                };
            };

            systemd.tmpfiles.rules = [
                "d ${home} 0700 ${name} ${config.users.users.${name}.group} - -"
                "z ${home} 0700 ${name} ${config.users.users.${name}.group} - -"
                "z ${defaultUserHome} 0755 root root - -"
            ]
            ++ (lib.flatten (
                map
                    (d: [
                        "d ${home}/${d} 0755 ${name} users - -"
                        "z ${home}/${d} 0755 ${name} users - -"
                    ])
                    [
                        ".config"
                        ".cache"
                        ".local"
                        ".local/share"
                        ".local/state"
                        ".ssh"
                    ]
            ));
        };
}
