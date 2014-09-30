-- Shortcuts for MOAI functions

import fillRect, drawRect, drawText from MOAIDraw
import setPenColor from MOAIGfxDevice
Display = require '@Display_constants'

-- Convenience wrapper around fillRect.
-- Takes (bbox, color) or (x1,y1,x2,y2, color)
_fillRect = (x1,y1,x2,y2, color) -> 
	-- Allow first argument to be a table, then treat 2nd argument as a color
	if type(x1) == 'table'
		assert(not x2 and not y2 and not color)
		return _fillRect(x1[1],x1[2],x1[3],x1[4], y1)
	{r,g,b,a} = color
	setPenColor(r,g,b,a)
	fillRect(x1,y1,x2,y2)

-- Convenience wrapper around drawRect.
-- Takes (bbox, color) or (x1,y1,x2,y2, color)
_drawRect = (x1,y1,x2,y2, color) -> 
	if type(x1) == 'table'
		assert(not x2 and not y2 and not color)
		return _drawRect(x1[1],x1[2],x1[3],x1[4], y1)
	setPenColor(unpack(color))
	drawRect(x1,y1,x2,y2)

_drawTexture = (args) ->
	w,h = args.texture\getSize()
	-- Prefer explicit versions
	w,h = args.w or w, args.h or h
	-- Prefer explicit versions
	ux,uy = (args.ux or 0), (args.uy or 0)
	uw,uh = args.uw or 1, args.uh or 1
	r,g,b,a = args.red, args.green, args.blue, args.alpha
	-- Prefer color version
	r,g,b,a = (args.color[1] or r), (args.color[2] or g), (args.color[3] or b), (args.color[4] or a)
	origin = args.origin or {args.origin_x or 0, args.origin_y or 0}
	-- Calculate coordinates, adjusted for orientation
	{ox, oy} = origin -- Unbox
	x, y = (args.x - w * ox), (args.y - h * oy)

	MOAIDraw.drawTexture args.texture, x, y, x + w, y + h,
		ux, uy, ux + uw, uy + uh, 
		r,g,b,a

_drawTextArgs = (args) ->
	if args.color
		setPenColor(unpack(args.color))
	O = args.origin or {}
	return MOAIDraw.drawText assert(args.font, "No font!"), args.font_size or nil, 
		assert(args.text, "No text!"), args.x, args.y, args.font_scale or 1, 
		0,0, O[1] or args.origin_x or 0, O[2] or args.origin_y or 0, 
		args.max_width or 0

_drawText = (font, text, x, y, color = Display.COL_WHITE, size = nil, origin_x = 0, origin_y = 0, max_width = 0) ->
	-- Table passed?
	if type(font) == "table"
		return _drawTextArgs(font)
	-- Arguments passed directly?
	setPenColor(unpack(color))
	drawText assert(font, "No font!"), size, 
		assert(text, "No text!"), x, y, 1, 
		0,0, origin_x, origin_y, max_width

SC = string.char -- for colorEscapeCode
colorEscapeCode = (color) ->
	{r,g,b,a} = color
	-- Change into integers, accounting for the fact that alpha may not be specified
	r,g,b,a = math.floor(r*255), math.floor(g*255), math.floor(b*255), math.floor((a or 1)*255)
	return '\0' .. SC(r) .. SC(g) .. SC(b) .. SC(a)

-- Reusable object for drawTexture:
_DRAW_TEXTURE_HELPER = {}

_packColor32 = (color) ->
	{r,g,b,a} = color
	a or= 1
	return math.floor(r*255) + math.floor(g*255) * 2^8 + math.floor(b*255) * 2^16 + math.floor(a*255) * 2^24

return {
	fillRect: _fillRect
	packColor32: _packColor32
	drawRect: _drawRect
	drawText: _drawText
	drawTextXCenter: (font, text, x, y, color, size, max_width) ->
		_drawText(font, text, x, y, color, size, 0.5, 0, max_width)
	drawTextCenter: (font, text, x, y, color, size, max_width) ->
		_drawText(font, text, x, y, color, size, 0.5, 0.5, max_width)
	drawTexture: (texture_or_args, x, y, origin = Display.LEFT_TOP) ->
		local args
		if type(texture_or_args) == 'userdata'
			args = _DRAW_TEXTURE_HELPER
			args.x, args.y = x, y
			args.texture = texture_or_args
			args.origin = origin
		else
			args = texture_or_args
		_drawTexture(args)
	:colorEscapeCode
}