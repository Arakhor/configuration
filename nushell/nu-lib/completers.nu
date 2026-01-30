def external-completer [spans: list<string>]: nothing -> nothing {
    # if the current command is an alias, get it's expansion
    let expanded_alias = scope aliases
        | where name == ($spans | first)
        | get -o 0.expansion

    # overwrite
    let spans = if $expanded_alias != null {
        # put the first word of the expanded alias first in the span
        $spans
        | skip 1
        | prepend ($expanded_alias | split row " " | take 1)
    } else {
        $spans
    }

    let nix_completer = {|spans: list<string>|
        let current_arg = $spans | length | $in - 1
        with-env {NIX_GET_COMPLETIONS: $current_arg} { $spans | skip 1 | nix ...$in }
        | lines
        | skip 1
        | parse "{value}\t{description}"
    }

    let carapace_completer = {|spans: list<string>|
        carapace ($spans | first) nushell ...$spans
        | try { from json }
        | if ($in | default [] | any {|| $in.display | str starts-with ERR }) { null } else { $in }
    }

    match ($spans | first) {
        nix => $nix_completer
        _ => $carapace_completer
    } | do $in $spans
}
