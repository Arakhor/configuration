inputs: {
  universal.home =
    { pkgs, ... }:
    {
      packages = with pkgs; [
        # keep-sorted start
        bottom
        dust
        fastfetch
        gh
        git
        jq
        just
        moor
        moreutils
        pastel
        socat
        trash-cli
        vivid
        # keep-sorted end
      ];
      file.home.".gitconfig".text = ''
        [credential "https://github.com"]
        	helper = !/etc/profiles/per-user/arakhor/bin/gh auth git-credential
        [credential "https://gist.github.com"]
        	helper = !/etc/profiles/per-user/arakhor/bin/gh auth git-credential
        [user]
        	name = arakhor
        	email = arakhor@pm.me
      '';
    };
}
