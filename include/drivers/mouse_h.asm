; SPDX-FileCopyrightText: 2026 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

;   Byte 0: Buttons and flags (see MOUSE_BTN_* below)
;   Bytes 1-2: X movement, 16-bit signed movement
;   Bytes 3-4: Y movement, 16-bit signed movement

    IFNDEF MOUSE_H
    DEFINE MOUSE_H

    ; Mouse driver shall be present with name "MOUS". Packets can be obtained by 
    ; calling `read`, with a buffer of at least 3 bytes.
    ; The packets are always three bytes, organized as described:
    DEFC MOUSE_STATE_OFF  = 0
    DEFC MOUSE_X_AXIS_OFF = 1
    DEFC MOUSE_Y_AXIS_OFF = 3
    
    ; Bitfield for the state byte
    DEFC MOUSE_STATE_BTN_LEFT     = 1 << 0  ; Left button pressed
    DEFC MOUSE_STATE_BTN_RIGHT    = 1 << 1  ; Right button pressed
    DEFC MOUSE_STATE_BTN_MIDDLE   = 1 << 2  ; Middle button pressed

    ENDIF
