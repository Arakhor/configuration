# Parse text as nix expression
export def "from nix" []: string -> any {
    nix eval --json -f - | from json
}

# Convert table data into a nix expression
export def "to nix" [
    --raw (-r) # don't format the result
    --indent (-i): int = 4 # specify indentation width
]: any -> string {
    to json --raw
    | str replace --all "''$" $"(char single_quote)(char single_quote)$"
    | nix eval --expr $"builtins.fromJSON ''($in)''"
    | if not $raw { nixfmt - $"--indent=($indent)" } else { $in }
    | collect
    | metadata set --content-type application/nix
}
