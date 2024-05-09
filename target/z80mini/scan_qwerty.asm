base_scan:
        DEFB 0, KB_F9, 0, KB_F5, KB_F3, KB_F1, KB_F2, KB_F12, 0, KB_F10, KB_F8, KB_F6, KB_F4, '\t', '`', 0
        DEFB 0, KB_LEFT_ALT, KB_LEFT_SHIFT, 0, KB_LEFT_CTRL, 'q', '1', 0, 0, 0, 'z', 's', 'a', 'w', '2', 0
        DEFB 0, 'c', 'x', 'd', 'e', '4', '3', 0, 0, ' ', 'v', 'f', 't', 'r', '5', 0
        DEFB 0, 'n', 'b', 'h', 'g', 'y', '6', 0, 0, 0, 'm', 'j', 'u', '7', '8', 0
        DEFB 0, ',', 'k', 'i', 'o', '0', '9', 0, 0, '.', '/', 'l', ';', 'p', '-', 0
        DEFB 0, 0, '\'', 0, '[', '=', 0, 0, KB_CAPS_LOCK, KB_RIGHT_SHIFT, '\n', ']', 0, '\\'
upper_scan:
        DEFB 0, KB_F9, 0, KB_F5, KB_F3, KB_F1, KB_F2, KB_F12, 0, KB_F10, KB_F8, KB_F6, KB_F4, '\t', '~', 0
        DEFB 0, KB_LEFT_ALT, KB_LEFT_SHIFT, 0, KB_LEFT_CTRL, 'Q', '!', 0, 0, 0, 'Z', 'S', 'A', 'W', '@', 0
        DEFB 0, 'C', 'X', 'D', 'E', '$', '#', 0, 0, ' ', 'V', 'F', 'T', 'R', '%', 0
        DEFB 0, 'N', 'B', 'H', 'G', 'Y', '^', 0, 0, 0, 'M', 'J', 'U', '&', '*', 0
        DEFB 0, '<', 'K', 'I', 'O', ')', '(', 0, 0, '>', '?', 'L', ':', 'P', '_', 0
        DEFB 0, 0, '"', 0, '{', '+', 0, 0, KB_CAPS_LOCK, KB_RIGHT_SHIFT, '\n', '}', 0, '|'
base_ru_scan:
        DEFB 0, KB_F9, 0, KB_F5, KB_F3, KB_F1, KB_F2, KB_F12, 0, KB_F10, KB_F8, KB_F6, KB_F4, '\t', 'Ò', 0
        DEFB 0, KB_LEFT_ALT, KB_LEFT_SHIFT, 0, KB_LEFT_CTRL, '©', '1', 0, 0, 0, 'Ô', 'Î', '‰', 'Ê', '2', 0
        DEFB 0, '·', 'Á', '¢', '„', '4', '3', 0, 0, ' ', '¨', '†', '•', '™', '5', 0
        DEFB 0, '‚', '®', '‡', 'Ø', '≠', '6', 0, 0, 0, 'Ï', 'Æ', '£', '7', '8', 0
        DEFB 0, '°', '´', 'Ë', 'È', '0', '9', 0, 0, 'Ó', '.', '§', '¶', 'ß', '-', 0
        DEFB 0, 0, 'Ì', 0, 'Â', '=', 0, 0, KB_CAPS_LOCK, KB_RIGHT_SHIFT, '\n', 'Í', 0, '\\'
upper_ru_scan:
        DEFB 0, KB_F9, 0, KB_F5, KB_F3, KB_F1, KB_F2, KB_F12, 0, KB_F10, KB_F8, KB_F6, KB_F4, '\t', '', 0
        DEFB 0, KB_LEFT_ALT, KB_LEFT_SHIFT, 0, KB_LEFT_CTRL, 'â', '!', 0, 0, 0, 'ü', 'õ', 'î', 'ñ', '"', 0
        DEFB 0, 'ë', 'ó', 'Ç', 'ì', ';', '¸', 0, 0, ' ', 'å', 'Ä', 'Ö', 'ä', '%', 0
        DEFB 0, 'í', 'à', 'ê', 'è', 'ç', ':', 0, 0, 0, 'ú', 'é', 'É', '?', '*', 0
        DEFB 0, 'Å', 'ã', 'ò', 'ô', ')', '(', 0, 0, 'û', ',', 'Ñ', 'Ü', 'á', '_', 0
        DEFB 0, 0, 'ù', 0, 'ï', '+', 0, 0, KB_CAPS_LOCK, KB_RIGHT_SHIFT, '\n', 'ö', 0, '/'
