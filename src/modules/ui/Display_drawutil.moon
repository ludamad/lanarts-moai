-- Shortcuts for MOAI functions

import fillRect, drawRect from MOAIDraw
import setPenColor from MOAIGfxDevice

return {
	fillRect: (x1,y1,x2,y2, color) -> 
		setPenColor(unpack(color))
		fillRect(x1,y1,x2,y2)

	drawRect: (x1,y1,x2,y2, color) -> 
		setPenColor(unpack(color))
		drawRect(x1,y1,x2,y2)
}