{
    universal =
        { pkgs, ... }:
        {
            services.openssh = {
                enable = true;
                settings = {
                    PermitRootLogin = "no";
                    AuthenticationMethods = "publickey";
                    PasswordAuthentication = false;
                    KbdInteractiveAuthentication = false;
                };
                authorizedKeysInHomedir = false;

                hostKeys = [
                    {
                        path = "/etc/ssh/ssh_host_ed25519_key";
                        type = "ed25519";
                    }
                ];
            };

            users.users.arakhor.openssh.authorizedKeys.keys = [ ];
            programs.ssh = {
                agentTimeout = null;
                pubkeyAcceptedKeyTypes = [ "ssh-ed25519" ];
                extraConfig = ''
                    AddKeysToAgent yes
                '';
            };

            environment.systemPackages = [ pkgs.sshfs ];

            preserveSystem.files = [
                {
                    file = "/etc/ssh/ssh_host_ed25519_key";
                    how = "symlink";
                    configureParent = true;
                }
                {
                    file = "/etc/ssh/ssh_host_ed25519_key.pub";
                    how = "symlink";
                    configureParent = true;
                }
            ];

            preserveHome.directories = [
                {
                    directory = ".ssh";
                    mode = "0700";
                }
            ];

        };

    graphical = {
        services.gnome.gcr-ssh-agent.enable = true;
    };
}
