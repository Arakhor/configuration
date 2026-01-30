{
    # TODO: override writers so that they use nightly nushell + my libraries
    universal.nixpkgs.overlays = [
        (final: prev: {
            runNuCommand =
                name: env: command:
                final.runCommand name env (final.writers.writeNu name command);
            runNuCommandLocal =
                name: env: command:
                final.runCommandLocal name env (final.writers.writeNu name command);
            runNuCommandCC =
                name: env: command:
                final.runCommandCC name env (final.writers.writeNu name command);
            writeNuScript = name: contents: final.writers.writeNu name contents;
            writeNuScriptBin = name: contents: final.writers.writeNuBin name contents;
            writeNushellApplication =
                args:
                final.writeShellApplication (
                    args
                    // {
                        text = final.writers.writeNu args.name args.text;
                    }
                );
        })
    ];
}
