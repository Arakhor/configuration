{
    system ? builtins.currentSystem,
    flake ? builtins.getFlake (toString ./.),
}:

let
    pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
in
pkgs.mkShell {
    packages = with pkgs; [
        disko
        facter
        age
        ssh-to-age
    ];
}
