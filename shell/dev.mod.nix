{
    universal =
        { pkgs, ... }:
        {
            environment.systemPackages = with pkgs; [
                # keep-sorted start
                bottom
                dust
                fastfetch
                jq
                just
                moor
                moreutils
                pastel
                socat
                trash-cli
                vivid
                woeusb-ng
                # keep-sorted end
            ];
        };
}
