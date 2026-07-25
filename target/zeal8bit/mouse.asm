; SPDX-FileCopyrightText: 2026 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

; Abstraction layer for the mouse driver.
; Each implementation (PS/2, etc.) provides:
;   mouse_impl_init
;   mouse_impl_int_handler  (called from the PS/2 ext interrupt handler)
;
; PS/2 mouse packets are 3 bytes (buttons, X, Y). The port threshold is
; set to 3 so the interrupt fires only when a full packet is available.
; No byte-level FIFO is needed — a single 3-byte buffer suffices.

    INCLUDE "osconfig.asm"
    INCLUDE "errors_h.asm"
    INCLUDE "drivers_h.asm"
    INCLUDE "utils_h.asm"
    INCLUDE "mmu_h.asm"

    EXTERN mouse_impl_init


    SECTION KERNEL_DRV_TEXT

    ; Initialize the mouse driver.
    PUBLIC mouse_init
mouse_init:
    call mouse_impl_init
    xor a
    ld (mouse_packet_ready), a
    ret

mouse_deinit:
mouse_open:
mouse_close:
    xor a
    ret

mouse_seek:
mouse_ioctl:
mouse_write:
    ld a, ERR_NOT_SUPPORTED
    ret


    ; Read a mouse packet (3 bytes: buttons, X, Y).
    ; Parameters:
    ;   DE - Destination buffer.
    ;   BC - Size to read in bytes (must be >= 3)
    ;   A  - DRIVER_OP_NO_OFFSET
    ; Returns:
    ;   A  - ERR_SUCCESS
    ;   BC - 3 if a packet was available, 0 otherwise
    ; Alters:
    ;   A, BC, DE, HL
mouse_read:
    ld a, b
    or a
    ; If B is not 0, we can proceed directly    
    jr nz, _mouse_read_ok
    ; Check if C is < 3, return 0 in that case
    ld a, c
    cp 3
    jr c, _mouse_read_empty
_mouse_read_ok:
    ; Check if a full packet is available
    ld a, (mouse_packet_ready)
    or a
    jr z, _mouse_read_empty
    ; Copy the 3-byte packet to the user buffer
    ld hl, mouse_packet
    ldi
    ldi
    ldi
    ld bc, 3
    xor a
    ; Reset the ready state since A is 0
    ld (mouse_packet_ready), a
    ret
_mouse_read_empty:
    ld bc, 0
    xor a
    ret


    SECTION DRIVER_BSS
    PUBLIC mouse_packet
    PUBLIC mouse_packet_ready
mouse_packet: DEFS 3
mouse_packet_ready: DEFS 1


    SECTION KERNEL_DRV_VECTORS
mouse_driver:
NEW_DRIVER_STRUCT("MOUS", \
                  mouse_init, \
                  mouse_read, mouse_write, \
                  mouse_open, mouse_close, \
                  mouse_seek, mouse_ioctl, \
                  mouse_deinit)
