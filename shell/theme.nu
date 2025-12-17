$env.config.use_ansi_coloring = true

try {
    use modules/capture-foreign-env
    dircolors -b
    | capture-foreign-env
    | load-env
}

export-env {
    def relative_luminance [color] {
        def relative_luminance_helper [x: float] {
            if $x <= 0.03928 {
                $x / 12.92
            } else {
                ((($x + 0.055) / 1.055) ** 2.4)
            }
        }

        let rgb = $color
        | str trim -c '#' --left
        | split chars
        | window 2 --stride 2
        | each { str join }
        | into int --radix 16
        | each {|v| relative_luminance_helper ($v / 255) }

        let r = $rgb.0
        let b = $rgb.1
        let g = $rgb.2

        (0.2126 * $r) + (0.7152 * $g) + (0.0722 * $b)
    }

    def contrast [color1 color2] {
        let l1 = relative_luminance $color1
        let l2 = relative_luminance $color2

        let lighter = [$l1 $l2] | math max
        let darker = [$l1 $l2] | math min

        ($lighter + 0.05) / ($darker + 0.05)
    }

    let theme_show_color = {|str|
        if $str =~ '^#[a-fA-F\d]{6}$' {
            let contrast_black = contrast $str "#000000"
            let contrast_white = contrast $str "#ffffff"

            {bg: $str fg: (if ($contrast_black > $contrast_white) { "black" } else { "white" })}
        } else {
            {fg: green attr: b}
        }
    }

    $env.config.color_config.string = $theme_show_color
}

$env.config.color_config.header = {fg: light_blue attr: bi}
$env.config.color_config.separator = "dark_gray"
$env.config.color_config.row_index = "teal"
$env.config.color_config.filesize = {||
    if $in == 0b {
        "dark_gray"
    } else if $in < 1mb {
        "white"
    } else { "purple" }
}
$env.config.color_config.datetime = {||
    (date now) - $in | if $in < 3day {
        {fg: "purple" attr: b}
    } else if $in < 1wk {
        'white'
    } else { 'dark_gray' }
}
$env.config.color_config.bool = {|| if $in { "green" } else { "red" } }
$env.config.color_config.leading_trailing_space_bg = {bg: dark_gray}
$env.config.color_config.shape_variable = "blue"
$env.config.color_config.shape_int = "light_magenta"
$env.config.color_config.shape_float = "light_magenta"
$env.config.color_config.shape_garbage = {fg: red attr: u}
$env.config.color_config.shape_string = {fg: green attr: b}

$env.config.table.mode = "rounded"
$env.config.table.header_on_separator = true
$env.config.table.trim.truncating_suffix = "…"
$env.config.table.missing_value_symbol = "󰟢"

$env.config.footer_mode = "auto"
$env.config.table.index_mode = "auto"

$env.config.highlight_resolved_externals = true

use nu-batteries [ text ]

$env.config.hooks.display_output = {
    metadata access {|meta|
        match $meta.content_type? {
            "application/x-nuscript" | "application/x-nuon" | "text/x-nushell" => { nu-highlight }
            "application/json" => { ^bat -Ppf --language=json }
            "application/xml" => { ^bat -Ppf --language=xml }
            "application/yaml" => { ^bat -Ppf --language=yaml }
            "application/nix" => { ^bat -Ppf --language=nix }
            "text/csv" => { ^bat -Ppf --language=csv }
            "text/tab-separated-values" => { ^bat -Ppf --language=tsv }
            "text/x-toml" => { ^bat -Ppf --language=toml }
            "text/markdown" => { ^bat -Ppf --language=markdown }
            _ => { }
        }
    }
    | if (term size).columns >= 120 { table -e } else { table -t compact }
}

# alias the built in ls command so we don't shadow it
alias ls-builtin = ls

# List the filenames, sizes, and modification times of items in a directory.
@category filesystem
@search-terms dir
@example "List the files in the current directory" { ls }
@example "List visible files in a subdirectory" { ls subdir }
@example "List visible files with full path in the parent directory" { ls -f .. }
@example "List Rust files" { ls *.rs }
@example "List files and directories whose name do not contain 'bar'" { ls | where name !~ bar }
@example "List the full path of all dirs in your home directory" { ls -a ~ | where type == dir }
@example "List only the names (not paths) of all dirs in your home directory which have not been modified in 7 days" { ls -as ~ | where type == dir and modified < ((date now) - 7day) }
@example "Recursively list all files and subdirectories under the current directory using a glob pattern" { ls -a **/* }
@example "Recursively list *.rs and *.toml files using the glob command" { ls ...(glob "**/*.{rs,toml}") }
@example "List given paths and show directories themselves" { ['/path/to/directory' '/path/to/file'] | each {|| ls -D $in } | flatten }
def ls [
    --all (-a) # Show hidden files
    --long (-l) # Get all available columns for each entry (slower; columns are platform-dependent)
    --short-names (-s) # Only print the file names, and not the path
    --full-paths (-f) # display paths as absolute paths
    --du (-d) # Display the apparent directory size ("disk usage") in place of the directory metadata size
    --directory (-D) # List the specified directory itself instead of its contents
    --mime-type (-m) # Show mime-type in type column instead of 'file' (based on filenames only; files' contents are not examined)
    --threads (-t) # Use multiple threads to list contents. Output will be non-deterministic.
    ...pattern: glob # The glob pattern to use.
]: [nothing -> table] {
    let pattern = if ($pattern | is-empty) { ['.'] } else { $pattern }
    (
        ls-builtin
        --all=$all
        --long=$long
        --short-names=$short_names
        --full-paths=$full_paths
        --du=$du
        --directory=$directory
        --mime-type=$mime_type
        --threads=$threads
        ...$pattern
        | move type --first
        | sort-by type name
    )
}
