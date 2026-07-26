; SPDX-FileCopyrightText: 2026 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

; PS/2 mouse implementation for the PS/2 extension board port 1.

    INCLUDE "osconfig.asm"
    INCLUDE "errors_h.asm"
    INCLUDE "mmu_h.asm"
    INCLUDE "ps2_ext_h.asm"

    EXTERN mouse_update_state


    SECTION KERNEL_DRV_TEXT


    ; Initialize the PS/2 mouse on extension board port 1.
    ; Parameters:
    ;   None
    ; Returns:
    ;   A - ERR_SUCCESS
    ; Alters:
    ;   A, BC, DE, HL
    PUBLIC mouse_impl_init
mouse_impl_init:
    ; Configure port 1: threshold=3 (full packet), clear FIFO, enable RX + interrupt
    PS2_WRITE_REG (PS2_EXT_REG_RESET, PS2_EXT_RESET_P1_CLR_FIFO)
    PS2_WRITE_REG (PS2_EXT_REG_P1_RX_THRESHOLD, 3)
    ; Enable P1 RX and RX interrupt (read-modify-write to preserve P0)
    PS2_SELECT_REG(PS2_EXT_REG_CTRL)
    in a, (PS2_EXT_DATA_REG)
    or PS2_EXT_CTRL_P1_RX_ENA | PS2_EXT_CTRL_P1_RX_INT_ENA
    out (PS2_EXT_DATA_REG), a
    ; Set sample rate to 40Hz
    ld a, PS2_CMD_SET_RATE
    out (PS2_EXT_PORT1_FIFO), a
    ld a, PS2_RATE_40
    out (PS2_EXT_PORT1_FIFO), a
    ; Enable data reporting on the mouse
    ld a, PS2_CMD_ENA_REPORT
    out (PS2_EXT_PORT1_FIFO), a
    xor a
    ret


    ; No polling on PS/2 mice in stream mode
    PUBLIC mouse_impl_poll
mouse_impl_poll:
    ret

    ; Interrupt handler for PS/2 extension board port 1.
    ; Reads a full 3-byte packet (buttons, X, Y) from the P1 FIFO
    ; and passes it to mouse_update_state for accumulation.
    ; Called from ps2_ext.asm's interrupt_default_handler.
    ; Parameters:
    ;   None
    ; Returns:
    ;   None
    ; Alters:
    ;   A, BC, DE, HL
    PUBLIC mouse_impl_int_handler
mouse_impl_int_handler:
    in a, (PS2_EXT_PORT1_FIFO)  ; buttons
    ld c, a
    in a, (PS2_EXT_PORT1_FIFO)  ; X movement
    ld d, a
    in a, (PS2_EXT_PORT1_FIFO)  ; Y movement
    ; Y axis is inverted, it is positive going up and negative going down, invert it here
    neg
    ld e, a
    ; Some mice return X and Y movement as magnitude values, not two's complement,
    ; we need to perform the conversion here before updating the state
  IF CONFIG_PS2_MOUSE_MOVEMENT_MAGNITUDE
    ; Convert X to a two's complement value
    bit 4, c
    jr z, _mouse_x_positive
    ld a, d
    neg                         ; A = -D
    ld d, a
_mouse_x_positive:

    bit 5, c
    jr z, _mouse_y_positive
    ld a, e
    neg                         ; A = -E
    ld e, a
_mouse_y_positive:

  ENDIF
    ; C = buttons, D = X, E = Y
    jp mouse_update_state
