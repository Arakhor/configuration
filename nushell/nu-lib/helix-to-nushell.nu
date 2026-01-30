# Helix to Nushell color mapping constants
const COLOR_MAP = {
    default: default
    black: black
    red: red
    green: green
    yellow: yellow
    blue: blue
    magenta: magenta
    cyan: cyan
    gray: dark_gray
    light-red: light_red
    light-green: light_green
    light-yellow: light_yellow
    light-blue: light_blue
    light-magenta: light_magenta
    light-cyan: light_cyan
    light-gray: light_gray
    white: white
}

# Helix to Nushell modifier mapping constants
const MODIFIER_MAP = {
    bold: bold
    dim: dimmed
    italic: italic
    underlined: underline
    slow_blink: blink
    rapid_blink: blink
    reversed: reverse
    hidden: hidden
    crossed_out: strikethrough
}

# Nushell color_config key to Helix scopes mapping constants
const SCOPE_MAP = {
    # Syntax highlighting shapes
    shape_string: string
    shape_string_interpolation: punctuation.special
    shape_raw_string: string
    shape_record: punctuation.bracket
    shape_list: punctuation.bracket
    shape_table: punctuation.bracket
    shape_bool: constant.builtin.boolean
    shape_int: constant.numeric.integer
    shape_float: constant.numeric.float
    shape_range: constant.numeric
    shape_binary: constant.numeric
    shape_datetime: constant.numeric
    shape_custom: type
    shape_nothing: constant.builtin
    shape_literal: constant
    shape_operator: keyword.operator
    shape_filepath: string.special.path
    shape_directory: string.special.path
    shape_globpattern: string.regexp
    shape_garbage: error
    shape_variable: variable.other.member
    shape_vardecl: keyword.storage
    shape_matching_brackets: ui.cursor.match
    shape_internalcall: function.builtin
    shape_external: function
    shape_external_resolved: function.special
    shape_externalarg: variable.parameter
    shape_match_pattern: string.special.regexp
    shape_block: punctuation.bracket
    shape_signature: type.parameter
    shape_keyword: keyword
    shape_closure: punctuation.bracket
    shape_pipe: keyword.control
    shape_redirection: keyword.control
    shape_flag: variable.parameter

    # Type colors (output values)
    bool: constant.builtin.boolean
    int: constant.numeric.integer
    string: string
    float: constant.numeric.float
    glob: string.regexp
    closure: function
    binary: constant
    custom: type
    nothing: constant.builtin # nu-lint-ignore: nothing_outside_signature
    datetime: constant.numeric
    filesize: constant.numeric
    list: punctuation.bracket
    record: punctuation.bracket
    duration: constant.numeric
    range: constant.numeric
    cell-path: variable.other.member
    block: constant

    # UI elements
    hints: ui.virtual.inlay-hint
    search_result: ui.selection.primary
    header: markup.heading.1
    separator: ui.virtual.indent-guide
    row_index: ui.linenr
    empty: ui.text.inactive
    leading_trailing_space_bg: diagnostic.hint

    # Banner colors
    banner_foreground: markup.quote
    banner_highlight1: markup.heading.1
    banner_highlight2: markup.heading.2

    foreground: ui.text
    background: ui.background
    cursor: ui.cursor.priimary
}

# Get Helix runtime themes directory
def get-runtime-dir []: nothing -> path {
    let local_repo = $"($nu.data-dir)/helix-themes"

    # Determine repo path
    if not (($local_repo | path exists) and ($"($local_repo)/.git" | path exists)) {
        # Check if git is available
        try {
            mkdir $local_repo
            git clone --depth 1 --filter=blob:none --sparse https://github.com/helix-editor/helix.git $local_repo
            git -C $local_repo sparse-checkout set runtime/themes
            git -C $local_repo checkout
        }
    }

    $"($local_repo)/runtime/themes"
}

# Resolve theme path by name (searches runtime and user directories)
def resolve-theme-path-by-name [repo: path]: [
    string -> record
] {
    let theme_name = $in

    let user_dir = $"($nu.home-dir)/.config/helix/themes"
    let runtime_dir = $repo

    try { ls $runtime_dir }
    | try { merge (ls $user_dir) }
    | get name
    | path parse
    | uniq-by stem
    | where stem == $theme_name
    | get -o 0
    | if ($in | is-not-empty) {
        [$in.parent / $in.stem . $in.extension]
        | str join
    } else {
        error make "Theme not found"
    }
}

def parse-values [
    palette: record
]: [
    record -> record
    string -> string
    list -> string
] {
    let value = $in

    $value
    | match ($value | describe -d | get type) {
        string => {
            match $value {
                $x if $palette has $x => { $palette | get -o $x }
                $x if $COLOR_MAP has $x => { $COLOR_MAP | get -o $x }
                _ => $value
            }
        }
        list => {
            $value
            | each {|item| if $MODIFIER_MAP has $item { $MODIFIER_MAP | get -o $item } else $item }
            | str join ,
        }
        record => {
            match ($value | columns) {
                $x if $x has modifiers => { rename --column {modifiers: attr} }
                $x if $x has underline => { merge {attr: ($value.attr? | default [] | append underline)} }
                _ => $value
            }
            | reject -o underline modifiers
            | update cells {|cell| $cell | parse-values $palette }
        }
    }
}

def parse-theme [repo: path]: [
    string -> record
    path -> record
    record -> record
] {
    let value = $in
    match ($value | describe -d | get type) {
        record => $value
        string => { $value | resolve-theme-path-by-name $repo | try { open $in } }
        path => { try { open $value } }
    }
    | try { parse-values $in.palette }
}

def parse-scopes []: record -> record {
    let theme = $in

    def parse-scope [
        theme: record
    ]: string -> record {
        let scope = $in

        if $theme has $scope {
            $theme
            | get -o $scope
        } else if $scope != "" {
            $scope
            | split words
            | drop
            | str join .
            | parse-scope $theme
        } else {
            "default"
        }
    }

    $SCOPE_MAP
    | update cells {|scope| $scope | parse-scope $theme }
}

# Remove background color from specified keys
def remove-background-from-keys [keys: list]: record -> record {
    let color_config = $in

    $color_config
    | update cells --columns $keys {|cell| if ($cell | describe -d | get type) == record { reject -o bg } }
}

# Resolve a Helix theme to a Nushell color_config
#
# Converts a Helix theme (as a record, file path, or theme name) to a Nushell
# color_config record with proper color name translation, modifier translation,
# and scope mapping.
@category config
@search-terms theme color helix
@example "Use a theme name" { helix-to-nushell gruvbox }
@example "Use a file path" { helix-to-nushell /path/to/theme.toml }
@example "Pipe a theme record" { open theme.toml | helix-to-nushell }
@example "Specify custom Helix repo path" { helix-to-nushell tokyo_night --repo /path/to/helix/repo }
export def main [
    theme?: string # Theme name or file path
    --repo (-r): string # Optional path to Helix repository root
]: [
    path -> record
    string -> record
    record -> record
    nothing -> record
] {
    let runtime_dir = if $repo != null { $repo } else { get-runtime-dir }

    try {
        $theme
        | parse-theme $runtime_dir
        | parse-scopes
        | remove-background-from-keys [separator header row_index]
    }
}
