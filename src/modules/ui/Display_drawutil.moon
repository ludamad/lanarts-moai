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

return {
	fillRect: _fillRect
	drawRect: _drawRect
	drawText: (args) ->
		MOAIDraw.drawText args.font, args.font_size or nil, 
			args.text, args.x, args.y, args.font_scale or 1, 
			0,0, args.origin_x or 0, args.origin_y or 0, 
			args.max_width or 0
}