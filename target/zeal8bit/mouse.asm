; SPDX-FileCopyrightText: 2026 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

; Abstraction layer for the mouse driver.
; Each implementation (PS/2, etc.) provides:
;   mouse_impl_init
;   mouse_impl_int_handler  (called from the PS/2 ext interrupt handler)
;
; The generic driver maintains a 5-byte state buffer:
;   Byte 0: Buttons (PS/2 format)
;   Bytes 1-2: Signed 16-bit accumulated X movement
;   Bytes 3-4: Signed 16-bit accumulated Y movement
;
; Implementations call mouse_update_state when a packet arrives.

    INCLUDE "osconfig.asm"
    INCLUDE "errors_h.asm"
    INCLUDE "drivers_h.asm"
    INCLUDE "utils_h.asm"
    INCLUDE "mmu_h.asm"
    INCLUDE "drivers/mouse_h.asm"

    EXTERN mouse_impl_init
    EXTERN mouse_impl_poll


    SECTION KERNEL_DRV_TEXT

    ; Initialize the mouse driver.
    PUBLIC mouse_init
mouse_init:
    call mouse_impl_init
    ; Fall-through
mouse_open:
    xor a
    ld (mouse_state), a
mouse_clear_acc:
    ld hl, 0
    ld (mouse_x_acc), hl
    ld (mouse_y_acc), hl
mouse_deinit:
mouse_close:
    xor a
    ret

mouse_seek:
mouse_ioctl:
mouse_write:
    ld a, ERR_NOT_SUPPORTED
    ret


    ; Accumulate a 3-byte PS/2 mouse packet into the state buffer.
    ; Called by the implementation's interrupt handler.
    ; Parameters:
    ; C - Buttons
    ; D - 8-bit signed X movement
    ; E - 8-bit signed Y movement
    ; Alters:
    ;   A, BC, DE, HL
    PUBLIC mouse_update_state
mouse_update_state:
    ld a, c
    and 7
    ld (mouse_state), a         ; store buttons

    ; Conver X to int16_t and add to accumulator
    ld a, d
    ld c, a
    rlca
    sbc a
    ld b, a
    ld hl, (mouse_x_acc)
    add hl, bc
    ld (mouse_x_acc), hl

    ; Conver Y to int16_t and add to accumulator
    ld a, e
    ld c, a
    rlca
    sbc a
    ld b, a
    ld hl, (mouse_y_acc)
    add hl, bc
    ld (mouse_y_acc), hl
    ret


    ; Read the accumulated mouse state.
    ; Parameters:
    ;   DE - Destination buffer (must be >= 5 bytes).
    ;   BC - Size to read in bytes (must be >= 5).
    ;   A  - DRIVER_OP_NO_OFFSET
    ; Returns:
    ;   A  - ERR_SUCCESS
    ;   BC - 5 if state was available, 0 otherwise
    ; Alters:
    ;   A, BC, DE, HL
mouse_read:
    ld a, b
    or a
    jr nz, _mouse_read_ok
    ld a, c
    cp 5
    jr c, _mouse_read_empty
_mouse_read_ok:
    ; Poll function may alter DE (if implemented)
    push de
    call mouse_impl_poll
    pop de
    ; Copy the 5-byte state to the user buffer
    ld hl, mouse_state
    ld bc, 5
    ldir
    ; Reset X/Y accumulators (keep buttons)
    ld bc, 5
    ; Tail-call
    jr mouse_clear_acc
_mouse_read_empty:
    ld bc, 0
    xor a
    ret


    SECTION DRIVER_BSS
mouse_state: DEFS 1 ; buttons left, right, middle
mouse_x_acc: DEFS 2 ; X movement
mouse_y_acc: DEFS 2 ; Y movement


    SECTION KERNEL_DRV_VECTORS
mouse_driver:
NEW_DRIVER_STRUCT("MOUS", \
                  mouse_init, \
                  mouse_read, mouse_write, \
                  mouse_open, mouse_close, \
                  mouse_seek, mouse_ioctl, \
                  mouse_deinit)
