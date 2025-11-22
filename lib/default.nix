lib: {
  ns = {
    nushell = import ./nushell.nix { inherit lib; };
    dag = import ./dag.nix { inherit lib; };
    types = import ./types.nix { inherit lib; };
    gtk = import ./gtk.nix { inherit lib; };
  };
}
