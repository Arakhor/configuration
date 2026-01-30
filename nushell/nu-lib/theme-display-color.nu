def relative-luminance [color: string]: nothing -> float {
    def relative-luminance-helper [x: float]: nothing -> float {
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
        | each {|v| relative-luminance-helper ($v / 255) }

    let r = $rgb.0?
    let b = $rgb.1?
    let g = $rgb.2?

    (0.2126 * $r) + (0.7152 * $g) + (0.0722 * $b)
}

def contrast [color1: string color2: string]: nothing -> float {
    let l1 = relative-luminance $color1
    let l2 = relative-luminance $color2

    let lighter = [$l1 $l2] | math max
    let darker = [$l1 $l2] | math min

    ($lighter + 0.05) / ($darker + 0.05)
}

# Takes existing color_config record and returns it modified to display color in tables
export def main []: record -> record {
    let prev = $in
    $prev | merge {
        string: {|str|
            if $str =~ '^#[a-fA-F\d]{6}$' {
                let contrast_black = contrast $str "#000000"
                let contrast_white = contrast $str "#ffffff"
                {
                    bg: $str
                    fg: (if ($contrast_black > $contrast_white) { "black" } else { "white" })
                }
            } else {
                $prev.string
            }
        }
    }
}
