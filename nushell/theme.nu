export-env {
    use themes/nu-themes/tokyo-night.nu
    tokyo-night set color_config

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
            "default"
        }
    }

    $env.config.color_config.string = $theme_show_color
}

$env.config.color_config.separator = "dark_gray_dimmed"
$env.config.color_config.leading_trailing_space_bg = {bg: dark_gray}
$env.config.color_config.header = {fg: default attr: b}

$env.config.table.mode = "rounded"
$env.config.table.header_on_separator = true
$env.config.table.trim.truncating_suffix = "…"

$env.config.highlight_resolved_externals = true
