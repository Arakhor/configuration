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
            home = "/home/arakhor";
            name = "arakhor";
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

            users =
                let
                    hashedPassword = "$y$j9T$2RCRnlUsztuzTPbLjkPN50$LCDo/lkk9QQUVfNl0Xm7yM85t/uwAato.JlP3pCsLj4";
                in
                {
                    mutableUsers = false;
                    users.root.hashedPassword = hashedPassword;
                    users.${name} = {
                        inherit hashedPassword;
                        isNormalUser = true;
                        description = "arakhor";
                        extraGroups = [ "wheel" ];
                        maid = { };
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
                        ".local"
                        ".local/share"
                        ".cache"
                        ".ssh"
                    ]
            ));

            maid.sharedModules = [
                {

                    _module.args.nixosConfig = config;
                    imports = config.maid-users;
                }
            ];
        };
}
