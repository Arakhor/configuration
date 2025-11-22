{
  system ? builtins.currentSystem,
  flake ? builtins.getFlake (toString ./.),
}:

let
  pkgs = flake.inputs.nixpkgs.legacyPackages.${system};

  rust-bin = flake.inputs.rust-overlay.lib.mkRustBin { } pkgs;

  rust-nightly-toolchain = rust-bin.selectLatestNightlyWith (
    toolchain:
    toolchain.default.override {
      extensions = [
        "rust-analyzer"
        "rust-src"
      ];
    }
  );
in

pkgs.mkShellNoCC {
  packages = [
    rust-nightly-toolchain
    pkgs.just
    pkgs.gitMinimal
    pkgs.disko
    pkgs.facter
    pkgs.ssh-to-age
  ];
}
