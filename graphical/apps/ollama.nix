{
    zeph =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        {
            options.services.ollama = with lib; {
                autoStart = mkEnableOption "autostart";

                interfaces = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = ''
                        List of additional interfaces for open-webui to be exposed on.
                    '';
                };
            };
            config = {
                services.ollama = {
                    enable = true;
                    autoStart = true;
                    openFirewall = true;
                    package = pkgs.ollama-cuda;
                    host = "0.0.0.0";
                    port = 11434;
                    loadModels = [
                        "llama3.1"
                        "deepseek-r1:14b-qwen-distill-q4_K_M"
                    ];
                };

                systemd.services = {
                    ollama.wantedBy = lib.mkForce (lib.optional config.services.ollama.autoStart "multi-user.target");
                    ollama-model-loader.wantedBy = lib.mkForce [ "ollama.service" ];
                    open-webui.wantedBy = lib.mkForce [ "ollama.service" ];
                    open-webui.partOf = [ "ollama.service" ];
                };

                services.open-webui = {
                    enable = true;
                    host = "0.0.0.0";
                    port = 11111;
                    environment = {
                        SCARF_NO_ANALYTICS = "True";
                        DO_NOT_TRACK = "True";
                        ANONYMIZED_TELEMETRY = "False";
                        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
                        WEBUI_AUTH = "False";
                    };
                };

                networking.firewall = {
                    allowedTCPPorts = [ 11111 ];
                    interfaces = lib.genAttrs config.services.ollama.interfaces (_: {
                        allowedTCPPorts = [ 11111 ];
                    });
                };

                preserveSystem.directories = [
                    {
                        directory = "/var/lib/private/ollama";
                        user = "nobody";
                        group = "nogroup";
                        mode = "0755";
                    }
                    {
                        directory = "/var/lib/private/open-webui";
                        user = "nobody";
                        group = "nogroup";
                        mode = "0755";
                    }
                ];
            };
        };
}
