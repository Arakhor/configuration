{
    system ? builtins.currentSystem,
    flake ? builtins.getFlake (toString ./.),
}:

let
    pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
in

pkgs.mkShellNoCC {
    packages = [
        pkgs.gitMinimal
        pkgs.disko
        pkgs.facter
        pkgs.ssh-to-age
        pkgs.age
        pkgs.sops
    ];
}
