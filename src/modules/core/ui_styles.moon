res = require 'resources'
import COL_BLACK, COL_GREEN, COL_RED, COL_BLUE, COL_PALE_RED, COL_GOLD, COL_PALE_BLUE, COL_MUTED_GREEN, COL_WHITE from require "@ui_colors"

make_bmstyle = (font, col) -> 
    return with MOAITextStyle.new()
        \setColor(unpack(col))
        \setFont(res.get_bmfont(font))

make_liber = (col) -> make_bmstyle 'Liberation-Mono-12.fnt', col

make_style = (font, col, size) ->
    return with MOAITextStyle.new()
        \setColor(unpack(col))
        \setFont(res.get_font('MateSC-Regular.ttf'))

return {
    liber_black12: make_liber COL_BLACK
    liber_white12: make_liber COL_WHITE
    liber_pale_red12: make_liber COL_PALE_RED
    liber_muted_green12: make_liber COL_MUTED_GREEN
    liber_gold12: make_liber COL_GOLD
    liber_pale_blue: make_liber COL_PALE_BLUE
    liber_red12: make_liber COL_RED
    mate_pale_red20: make_style 'MateSC-Regular.ttf', COL_PALE_RED, 20
    -- mate_pale_red20: make_style 'MateSC-Regular.ttf', COL_PALE_RED, 20
    -- mate_pale_red20: make_style 'MateSC-Regular.ttf', COL_PALE_RED, 20
    -- mate_pale_red20: make_style 'MateSC-Regular.ttf', COL_PALE_RED, 12
}
