PRIORITY_INCREMENT = 100000
return nilprotect {
    -------------------------------------------------------------------------------
    -- Priority constants
    -------------------------------------------------------------------------------

    PRIORITY_BACKGROUND: 5 * PRIORITY_INCREMENT
    PRIORITY_OBJECT: 4* PRIORITY_INCREMENT
    PRIORITY_FOREGROUND: 3 * PRIORITY_INCREMENT
    PRIORITY_INTERFACE: 2 * PRIORITY_INCREMENT
    PRIORITY_CURSOR: 1 * PRIORITY_INCREMENT

    -------------------------------------------------------------------------------
    -- Orientation constants
    -------------------------------------------------------------------------------

    LEFT_TOP: {0,0}
    CENTER_TOP: {0.5,0}
    RIGHT_TOP: {1.0,0}

    LEFT_CENTER: {0,0.5}
    CENTER: {0.5,0.5}
    RIGHT_CENTER: {1.0,0.5}

    LEFT_BOTTOM: {0,1.0}
    CENTER_BOTTOM: {0.5,1.0}
    RIGHT_BOTTOM: {1.0,1.0}

    -------------------------------------------------------------------------------
    -- Color constants
    -------------------------------------------------------------------------------

    COL_GOLD: {1, 0.85, 0}
    COL_YELLOW: {1, 1, 0}
    COL_MUTED_YELLOW: {1, 0.98, 0.275}
    COL_PALE_YELLOW: {1, 0.98, 0.589}

    COL_LIGHT_RED: {1, 0.2, 0.2}
    COL_PALE_RED: {1, 148/255, 120/255}
    COL_RED: {1, 0, 0}

    COL_MUTED_GREEN: {0.2, 1, 0.2}
    COL_PALE_GREEN: {0.7, 1, 0.7}
    COL_DARK_GREEN: {25/255, 50/255, 10/255}
    COL_GREEN: {0, 1, 0}

    COL_BROWN: {0.55, 0.271, 0.074}
    COL_DARK_BROWN: {0.36, 0.25, 0.2}

    COL_LIGHT_BLUE: {0.2, 0.2, 1}
    COL_BLUE: {0, 0, 1}
    COL_BABY_BLUE: {37/255, 207/255, 240/255}
    COL_PALE_BLUE: {0.7, 0.7, 1}
    COL_MAGENTA: {255/255, 0, 144/255}
    COL_CYAN: {0, 255/255, 255/255}

    COL_MEDIUM_PURPLE: {123/255, 104/255, 238/255}

    COL_BLACK: {0, 0, 0}
    COL_DARKER_GRAY: {20/255, 20/255, 20/255}
    COL_DARK_GRAY: {40/255, 40/255, 40/255}
    COL_GRAY: {60/255, 60/255, 60/255}
    COL_MID_GRAY: {120/255, 120/255, 120/255}
    COL_LIGHT_GRAY: {0.7, 0.7, 0.7}
    COL_WHITE: {1, 1, 1}
    COL_INVISIBLE: {0, 0, 0, 0}
}
