{
    universal =
        { pkgs, ... }:
        {
            services.openssh = {
                enable = true;
                ports = [ 22 ];
                settings = {
                    PasswordAuthentication = false;
                    KbdInteractiveAuthentication = false;
                    AllowUsers = [
                        "root"
                        "arakhor"
                    ];
                };

                hostKeys = [
                    {
                        path = "/etc/ssh/ssh_host_ed25519_key";
                        type = "ed25519";
                    }
                ];
            };

            services.gnome.gcr-ssh-agent.enable = true;

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
}
