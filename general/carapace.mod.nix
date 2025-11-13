{
  universal =
    { pkgs, lib, ... }:
    {
      environment.pathsToLink = [ "/share/fish/vendor_completions.d" ];

      wrappers.carapace = {
        basePackage = pkgs.carapace;
        pathAdd = [ pkgs.fish ];
        env =
          lib.mapAttrs
            (_: value: {
              value = toString value;
              force = false;
            })
            {
              CARAPACE_BRIDGES = "fish, bash";
              CARAPACE_HIDDEN = 1;
              CARAPACE_LENIENT = 1;
              CARAPACE_MATCH = 1; # 0 = case sensitive, 1 = case insensitive
              CARAPACE_ENV = 0; # disable get-env, del-env and set-env commands
            };
      };

      home = {
        packages = [ pkgs.wrapped.carapace ];
      };
    };
}
