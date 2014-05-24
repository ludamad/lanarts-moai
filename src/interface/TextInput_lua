--------------------------------------------------------------------------------
-- Interface component for entering text.
-- This includes stuff like entering name before play, etc.
-- 
-- Parameters (passed by table):
--   initial_repeat_ms: How long to hold before entering repeating mode.
--   next_repeat_ms: Determines spacing between repeats once entering repeating mode.
--   next_backspace_ms: Determines spacing between deletes when holding backspace.
--   no_repeat: Determines spacing between deletes when holding backspace.
--------------------------------------------------------------------------------

local TextField = newtype()

local NO_REPEATING = -1 -- Represents 'normal mode', in constrast to 'repeating mode'.

function TextField:init(args)
    self.initial_repeat_ms = args.initial_repeat_ms or 360
    self.next_repeat_ms = args.next_repeat_ms or 50
    self.next_backspace_ms = args.next_backspace_ms or 30
    self.text = args.text or ""
    self.cursor_position = #self.text
    self.cursor = args.cursor or "|"

    self:_update_representation()
    self:_clear_keystate()
end

--------------------------------------------------------------------------------
-- Private methods
--------------------------------------------------------------------------------

function TextField:_clear_keystate()
    self.current_key = false
    self.current_mod = false
    self.repeat_cooldown = NO_REPEATING
end

function TextField:_update_representation()
    local pre, post = self.text:sub(0, self.cursor_position), self.text:sub(self.cursor_position + 1)
    self.representation = pre .. self.cursor .. post
end

function TextField::_move_cursor(pos)
    if pos < 0 then pos = 0 
    elseif pos > #self.text then pos = #self.text end

    self.cursor_position = pos
    self:_update_representation()
end

--------------------------------------------------------------------------------
-- Public methods
--------------------------------------------------------------------------------

function TextField::set_text(text) 
    self.text = text
    self:_move_cursor(self.cursor_position)
end

function TextField:handle_event(event)
    if event.delete then self:set_text("") end
    if event.delete_one then self:clear() end
    if event.move_left then 
        self:_move_cursor(self.cursor_position - 1)
    end
end

function TextField:empty()
    return (self.text == "")
end

return TextField

INITIAL_REPEAT_MS = 360
NEXT_REPEAT_MS = 50
NEXT_BACKSPACE_MS = 30
NO_REPEAT = -1

class TextField {
public:
        TextField(int max_length, const std::string& default_text = std::string());

        void set_text(const std::string& txt) {
                _text = txt;
        }
    const std::string& text() const {
        return _text;
    }

    bool empty() const {
        return _text.empty();
    }
    void step();
    void clear();
    void clear_keystate();
        bool handle_event(SDL_Event *event);
        int max_length() const {
                return _max_length;
        }
private:
        void _handle_backspace();

        bool _has_repeat_cooldown();
        void _reset_repeat_cooldown(int cooldownms);
        SDLKey _current_key;
        SDLMod _current_mod;

        std::string _text;
        int _max_length;
        int _repeat_cooldown;
        Timer _repeat_timer;
};

return TextField
