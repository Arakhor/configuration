{
    universal.home =
        { pkgs, ... }:
        {
            packages = with pkgs; [
                nil
                nixd
                npins
                nixfmt-rfc-style
                gitMinimal
            ];
        };
}
