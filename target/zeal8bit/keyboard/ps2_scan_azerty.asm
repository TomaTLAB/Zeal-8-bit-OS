; The tables MUST be defined in this order:
;   - base_scan
;   - extascii_scan (optional, depends on CONFIG_LAYOUT_USE_EXTENDED_ASCII)
;   - upper_scan
;   - alt_scan
  
 IF CONFIG_LAYOUT_USE_EXTENDED_ASCII
    ; Extended ASCII characters
    DEFC KEY_E_ACUTE      = 0x82   ; é
    DEFC KEY_E_GRAVE      = 0x8A   ; è
    DEFC KEY_A_GRAVE      = 0x85   ; à
    DEFC KEY_C_CEDILLA    = 0x87   ; ç
    DEFC KEY_U_GRAVE      = 0x97   ; ù
    DEFC KEY_U_GRAVE_ALT  = 0x97   ; ù
    
    DEFC KEY_DOUBLE_LT    = 0xAE   ; «
    DEFC KEY_DOUBLE_GT    = 0xAF   ; »
    
    DEFC KEY_SUP2         = 0xFD   ; ²
    DEFC KEY_CURRENCY     = 0x9D   ; ¤
    
    DEFC KEY_SECTION      = 0x15   ; §
    DEFC KEY_DEGREE       = 0xF8   ; °
    DEFC KEY_POUND        = 0x9C   ; £
    DEFC KEY_MICRO        = 0xE6   ; µ
 ELSE
    DEFC KEY_E_ACUTE      = 'e'    ; replaces é
    DEFC KEY_E_GRAVE      = 'e'    ; replaces è
    DEFC KEY_A_GRAVE      = 'a'    ; replaces à
    DEFC KEY_C_CEDILLA    = 'c'    ; replaces ç
    DEFC KEY_U_GRAVE      = 'u'    ; replaces ù
    DEFC KEY_U_GRAVE_ALT  = 'u'    ; replaces ù (AltGr variant)
    DEFC KEY_DOUBLE_LT    = '<'    ; replaces «
    DEFC KEY_SUP2         = '2'    ; replaces ²
    DEFC KEY_DOUBLE_GT    = '>'    ; replaces »
    DEFC KEY_CURRENCY     = '$'    ; replaces ¤
    DEFC KEY_SECTION      = '#'    ; replaces §
    DEFC KEY_DEGREE       = 'o'    ; replaces °
    DEFC KEY_POUND        = 'L'    ; replaces £
    DEFC KEY_MICRO        = 'u'    ; replaces µ
 ENDIF

base_scan:
    DEFB 0, KB_F9, 0, KB_F5, KB_F3, KB_F1, KB_F2, KB_F12, 0, KB_F10, KB_F8, KB_F6, KB_F4, '\t', KEY_SUP2, 0
    DEFB 0, KB_LEFT_ALT, KB_LEFT_SHIFT, 0, KB_LEFT_CTRL, 'a', '&', 0, 0, 0, 'w', 's', 'q', 'z', KEY_E_ACUTE, 0
    DEFB 0, 'c', 'x', 'd', 'e', '\'', '"', 0, 0, ' ', 'v', 'f', 't', 'r', '(', 0
    DEFB 0, 'n', 'b', 'h', 'g', 'y', '-', 0, 0, 0, ',', 'j', 'u', KEY_E_GRAVE, '_', 0
    DEFB 0, ';', 'k', 'i', 'o', KEY_A_GRAVE, KEY_C_CEDILLA, 0, 0, ':', '!', 'l', 'm', 'p', ')', 0
    DEFB 0, 0, KEY_U_GRAVE, 0, '^', '=', 0, 0, KB_CAPS_LOCK, KB_RIGHT_SHIFT, '\n', '$', 0, '*'

 IF CONFIG_LAYOUT_USE_EXTENDED_ASCII
extascii_scan:
    DEFB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0
    DEFB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0
    DEFB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    DEFB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0
    DEFB 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0
    DEFB 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1
 ENDIF

upper_scan:
    DEFB 0, KB_F9, 0, KB_F5, KB_F3, KB_F1, KB_F2, KB_F12, 0, KB_F10, KB_F8, KB_F6, KB_F4, '\t', '~', 0
    DEFB 0, KB_LEFT_ALT, KB_LEFT_SHIFT, 0, KB_LEFT_CTRL, 'A', '1', 0, 0, 0, 'W', 'S', 'Q', 'Z', '2', 0
    DEFB 0, 'C', 'X', 'D', 'E', '4', '3', 0, 0, ' ', 'V', 'F', 'T', 'R', '5', 0
    DEFB 0, 'N', 'B', 'H', 'G', 'Y', '6', 0, 0, 0, '?', 'J', 'U', '7', '8', 0
    DEFB 0, '.', 'K', 'I', 'O', '0', '9', 0, 0, '/', KEY_SECTION, 'L', 'M', 'P', KEY_DEGREE, 0
    DEFB 0, 0, '%', 0, KEY_DOUBLE_GT, '+', 0, 0, KB_CAPS_LOCK, KB_RIGHT_SHIFT, '\n', KEY_POUND, 0, KEY_MICRO

alt_scan:
    DEFB 0, KB_F9, 0, KB_F5, KB_F3, KB_F1, KB_F2, KB_F12, 0, KB_F10, KB_F8, KB_F6, KB_F4, '\t', KEY_SUP2, 0
    DEFB 0, KB_LEFT_ALT, KB_LEFT_SHIFT, 0, KB_LEFT_CTRL, 'a', '&', 0, 0, 0, 'w', 's', 'q', 'z', '~', 0
    DEFB 0, 'c', 'x', 'd', 'e', '{', '#', 0, 0, ' ', 'v', 'f', 't', 'r', '[', 0
    DEFB 0, 'n', 'b', 'h', 'g', 'y', '|', 0, 0, 0, ',', 'j', 'u', '`', '\\', 0
    DEFB 0, ';', 'k', 'i', 'o', '@', '^', 0, 0, ':', '!', 'l', 'm', 'p', ']', 0
    DEFB 0, 0, KEY_U_GRAVE_ALT, 0, KEY_DOUBLE_LT, '}', 0, 0, KB_CAPS_LOCK, KB_RIGHT_SHIFT, '\n', KEY_CURRENCY, 0, '*'
