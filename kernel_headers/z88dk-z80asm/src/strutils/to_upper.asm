; SPDX-FileCopyrightText: 2025 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

    SECTION TEXT

    EXTERN is_upper

    ; Convert an ASCII character to upper case
    ; Parameter:
    ;   A - ASCII character
    ; Returns:
    ;   A - Upper case character on success, same character else
    ;   carry flag - Invalid parameter
    ;   not carry flag - Success
    PUBLIC to_upper
to_upper:
    ; Check if it's already an upper char
    call is_upper
    ret nc  ; Already upper, can exit
    cp 'a'
    ret c   ; Error, return
    cp 'z' + 1         ; +1 because p flag is set when result is 0
    jp nc, _to_lower_not_char_ccf
    sub 'a' - 'A'
    scf
_to_lower_not_char_ccf:
    ccf
    ret