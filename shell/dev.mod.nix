inputs: {
  universal.home =
    { pkgs, ... }:
    {
      packages = with pkgs; [
        ripgrep
        fd
        gh
        git
        bat
        fzf
        zoxide
        bottom
        fastfetch
        socat
        pastel
        moor
        eza
        jq
        just
        dust
        moreutils
        trash-cli
        vivid
      ];
      file.home.".gitconfig".text = ''
        [credential "https://github.com"]
        	helper = 
        	helper = !/etc/profiles/per-user/arakhor/bin/gh auth git-credential
        [credential "https://gist.github.com"]
        	helper = 
        	helper = !/etc/profiles/per-user/arakhor/bin/gh auth git-credential
        [user]
        	name = arakhor
        	email = arakhor@pm.me
      '';

    };

  universal.preserveHome.directories = [ ".local/share/zoxide" ];
}
