; SPDX-FileCopyrightText: 2026 Zeal 8-bit Computer <contact@zeal8bit.com>; David Higgins <zoul0813@me.com>
;
; SPDX-License-Identifier: Apache-2.0

; SNES mouse implementation.
; Bit-bangs PIO lines to read SNES mouse X/Y movement.
; No interrupt, polling based.

    INCLUDE "osconfig.asm"
    INCLUDE "errors_h.asm"
    INCLUDE "pio_h.asm"

    EXTERN mouse_update_state

    ; PIO ports for SNES controller port
    DEFC SNES_PIO_DATA  = IO_PIO_DATA_A
    DEFC SNES_PIO_CTRL  = IO_PIO_CTRL_A

    ; Controller board I/Os
    DEFC SNES_DATA0 = 1 << 0
    DEFC SNES_DATA1 = 1 << 1
    DEFC SNES_LATCH = 1 << 2
    DEFC SNES_CLOCK = 1 << 3

    DEFC SNES_MOUSE_DATA = SNES_DATA1

    SECTION KERNEL_DRV_TEXT


    ; Initialize SNES mouse, since it's using the SNES adapter port on Port A, we must set
    ; the PIO group A to bit control mode.
    PUBLIC mouse_impl_init
mouse_impl_init:
    ld a, IO_PIO_BITCTRL              ; Mode 3 = bit control
    out (SNES_PIO_CTRL), a
    ld a, ~(SNES_CLOCK | SNES_LATCH)  ; bits 0,1 out; bit 2 in
    out (SNES_PIO_CTRL), a
    ld a, SNES_CLOCK                  ; clock high, latch low
    out (SNES_PIO_DATA), a
    ; Set the mouse sensitivity to high
    call toggle_sensitivty
    call toggle_sensitivty
    xor a
    ret


    ; Short delay (>= 8us)
    ; Alters:
    ;   None
snes_delay_8us:
    ; We need to spend at least 80 T-states here
    ex (sp), hl
    ex (sp), hl
    ex (sp), hl
    ex (sp), hl
    ret

    ; Toggle sensitivity to reach the next mode
toggle_sensitivty:
    ; Pulse the clock once when latch is active (1)
    ld a, SNES_LATCH | SNES_CLOCK
    out (SNES_PIO_DATA), a
    call snes_delay_8us
    ; Keep latch high, clock low
    ld a, SNES_LATCH
    out (SNES_PIO_DATA), a
    call snes_delay_8us
    ld a, SNES_LATCH | SNES_CLOCK
    out (SNES_PIO_DATA), a
    call snes_delay_8us
    ; Disable the latch signal
    ld a, SNES_CLOCK
    out (SNES_PIO_DATA), a
    ret


    ; Decode SNES mouse axis into a two's complement value
    ; Parameters:
    ;   A - Raw axis value
    ; Returns:
    ;   A - Two's complement value
    ; Alters:
    ;   A
decode_axis:
    ; Do nothing if the value is postiive
    or a
    ret p
    and 0x7f
    neg
    ret


    ; Receive one byte from the mouse
    ; Parameters:
    ;   -
    ; Returns:
    ;   A - Byte received
    ; Alters:
    ;   A, BC
read_mouse_byte:
    ; C doesn't need to be set, it will be overwritten in the loop
    ld b, 8
_read_mouse_bit:
    ; Read data bit in A and shift it in C
    in a, (SNES_PIO_DATA)
    ; Assumption: SNES_MOUSE_DATA == bit 1
    rrca
    rrca
    ; Bit in carry, shift in C lowest bit
    rl c
    ; Clock once (to prepare the next bit)
    xor a
    out (SNES_PIO_DATA), a
    ld a, SNES_CLOCK
    out (SNES_PIO_DATA), a
    ; Small delay, give time to the mouse (Hyperkin)
    ; Wait at least 8 µs between bit reads.
    call snes_delay_8us
    djnz _read_mouse_bit
    ; Invert the bits as they are "active-low"
    ld a, c
    cpl
    ld c, a
    ret

    ; Poll SNES mouse to get the button state and X/Y movement.
    PUBLIC mouse_impl_poll
mouse_impl_poll:
    ; Pulse latch
    ld a, SNES_LATCH | SNES_CLOCK
    out (SNES_PIO_DATA), a
    call snes_delay_8us
    ld a, SNES_CLOCK
    out (SNES_PIO_DATA), a

    ; read the first byte, which should be 0xff
    call read_mouse_byte

    ; Read the button state
    call read_mouse_byte
    ld h, a

    ; Read Y movement, store in E
    call read_mouse_byte
    call decode_axis
    ld e, a
    call snes_delay_8us

    ; Give some delay to the mouse to output the data
    ; Wait at least 16 µs between the 2nd and 3rd bytes
    call snes_delay_8us
    call snes_delay_8us

    ; Read X movement, store in D
    call read_mouse_byte
    call decode_axis
    ld d, a

    ; Convert the buttons state (H) to the proper format
    ld a, h
    rlca
    rlca
    and 3
    ld c, a

    ; mouse_update_state: C=buttons, D=X, E=Y
    jp mouse_update_state
