-- Shortcuts for MOAI functions

import fillRect, drawRect, drawText from MOAIDraw
import setPenColor from MOAIGfxDevice

-- Convenience wrapper around fillRect.
-- Takes (bbox, color) or (x1,y1,x2,y2, color)
_fillRect = (x1,y1,x2,y2, color) -> 
	-- Allow first argument to be a table, then treat 2nd argument as a color
	if type(x1) == 'table'
		assert(not x2 and not y2 and not color)
		return _fillRect(x1[1],x1[2],x1[3],x1[4], y1)
	setPenColor(unpack(color))
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

SC = string.char -- for colorEscapeCode
colorEscapeCode = (color) ->
	{r,g,b,a} = color
	-- Change into integers, accounting for the fact that alpha may not be specified
	r,g,b,a = math.floor(r*255), math.floor(g*255), math.floor(b*255), math.floor((a or 1)*255)
	return '\0' .. SC(r) .. SC(g) .. SC(b) .. SC(a)

return {
	fillRect: _fillRect
	drawRect: _drawRect
	drawText: (args) ->
		if args.color
			setPenColor(unpack(args.color))
		O = args.origin or {}
		return MOAIDraw.drawText assert(args.font, "No font!"), args.font_size or nil, 
			assert(args.text, "No text!"), args.x, args.y, args.font_scale or 1, 
			0,0, O[1] or args.origin_x or 0, O[2] or args.origin_y or 0, 
			args.max_width or 0
	drawTexture: _drawTexture
	:colorEscapeCode
}