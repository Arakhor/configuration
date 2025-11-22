$env.config.filesize.unit = "metric"

$env.config.cursor_shape.emacs = "line"
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"

$env.config.edit_mode = "vi"

$env.config.use_kitty_protocol = true

$env.config.show_banner = false

$env.config.history.file_format = "sqlite"
$env.config.history.sync_on_enter = true
$env.config.history.isolation = true
$env.config.history.max_size = 5_000_000

$env.config.datetime_format.normal = '%a, %d %b %Y %H:%M:%S %z' # shows up in displays of variables or other datetime's outside of tables

$env.config.display_errors.termination_signal = false
$env.config.display_errors.exit_code = true

$env.config.menus ++= [
    # Configuration for default nushell menus
    # Note the lack of source parameter
    {
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: {
            layout: columnar
            columns: 4
            col_width: 20 # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2
        }
    }
    {
        name: history_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: list
            page_size: 10
        }
    }
    {
        name: help_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: description
            columns: 4
            col_width: 20 # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
    }
    {
        name: commands_with_description
        only_buffer_difference: true
        marker: "# "
        type: {
            layout: description
            columns: 4
            col_width: 20
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
        source: {|buffer position|
            scope commands
            | where name =~ $buffer
            | each {|it| {value: $it.name description: $it.usage} }
        }
    }
] | each {
    upsert style {
        text: default
        description_text: light_gray_dimmed
        selected_text: {fg: default bg: dark_gray_dimmed attr: b}
        match_text: {attr: u}
        selected_match_text: {bg: dark_gray_dimmed attr: urb}
    }
}



$env.config.keybindings ++= [
    {
        name: cut_line_to_end
        modifier: control
        keycode: char_k
        mode: [emacs vi_insert]
        event: {edit: cuttoend}
    }
    {
        name: cut_line_from_start
        modifier: control
        keycode: char_u
        mode: [emacs vi_insert]
        event: {edit: cutfromstart}
    }
    {
        name: completion_menu_next
        modifier: control
        keycode: char_n
        mode: [emacs vi_normal vi_insert]
        event: {
            until: [
                {send: menu name: completion_menu}
                {send: menunext}
                {edit: complete}
            ]
        }
    }
    {
        name: completion_menu_prev
        modifier: control
        keycode: char_p
        mode: [emacs vi_normal vi_insert]
        event: {
            until: [
                {send: menu name: completion_menu}
                {send: menuprevious}
                {edit: complete}
            ]
        }
    }
    {
        name: completion_menu_complete
        modifier: control
        keycode: char_y
        mode: [emacs vi_normal vi_insert]
        event: {
            send: Enter
        }
    }
    {
        name: job_unfreeze
        modifier: control
        keycode: char_z
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "fg"
        }
    }
    {
        name: yazi
        modifier: control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: 'if "YAZI_ID" not-in $env { yz } else { exit }'
        }
    }
]
