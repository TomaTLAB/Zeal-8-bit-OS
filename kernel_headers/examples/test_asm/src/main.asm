; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: CC0-1.0

    ; Include the Zeal 8-bit OS header file, containing all the syscalls macros.
    INCLUDE "zos_sys.asm"
    
    ; Make the code start at 0x4000, as requested by the kernel
    ORG 0x4000

    ; We can start the code here, directly, no need to create a routine, but let's keep it clean.
_start:
    ld de, 0x8000
    ld bc, 0x0000
    ld h, 0x04
    MAP()


	ld hl, _text
    ld de, 0x8000
	ld bc, 0x1000
    ldir

	ld hl, _attr
    ld de, 0x9000
	ld bc, 0x1000
    ldir

	ld hl, _char
    ld de, 0xA000
	ld bc, 0x1000
    ldir

    ld hl, 0x9fff
    ld (hl), 0x0F

	ld hl, _text1
    ld de, 0x8000 + 2048
	ld bc, _text - _text1
    ldir

    ld hl, 0x9fff
    ld (hl), 0xE2

	ld hl, _text1
    ld de, 0x8000 + 2048 + _text - _text1
	ld bc, _text - _text1
    ldir

    ld hl, 0x9fff
    ld (hl), 0x5B

	ld hl, _text1
    ld de, 0x8000 + 2048 + 256
	ld bc, _text - _text1
    ldir

_end:
    ; We MUST execute EXIT() syscall at the end of any program.
    ; Exit code is stored in H, it is 0 if everything went fine.
        ; Return success
    xor a
    ld h, a
    EXIT()

    ; Define a label before and after the message, so that we can get the length of the string
    ; thanks to `_message_end - _message`.
_text1: 
    DEFM "Auto attribute test  "
_text: 
    DEFM "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
    DEFS 48, 0xFF
    DEFM "1         2         3         4         5         6         7         8        E"
    DEFS 48, 0xFF
    DEFM "2 Hello world! Blah... Blah...Blah...Blah...Blah..."
    DEFS 48, 0x20
_attr: 
    DEFS 256, 0x0F

    DEFS 64, 0x01
    DEFS 64, 0x02
    DEFS 64, 0x03
    DEFS 64, 0x04
    DEFS 64, 0x05
    DEFS 64, 0x06
    DEFS 64, 0x07
    DEFS 64, 0x08
    DEFS 64, 0x09
    DEFS 64, 0x0A
    DEFS 64, 0x0B
    DEFS 64, 0x0C
    DEFS 64, 0x0D
    DEFS 64, 0x0E
    DEFS 64, 0x0F

    DEFS 64, 0x10
    DEFS 64, 0x12
    DEFS 64, 0x13
    DEFS 64, 0x14
    DEFS 64, 0x15
    DEFS 64, 0x16
    DEFS 64, 0x17
    DEFS 64, 0x18
    DEFS 64, 0x19
    DEFS 64, 0x1A
    DEFS 64, 0x1B
    DEFS 64, 0x1C
    DEFS 64, 0x1D
    DEFS 64, 0x1E
    DEFS 64, 0x1F

    DEFS 64, 0x20
    DEFS 64, 0x21
    DEFS 64, 0x23
    DEFS 64, 0x24
    DEFS 64, 0x25
    DEFS 64, 0x26
    DEFS 64, 0x27
    DEFS 64, 0x28
    DEFS 64, 0x29
    DEFS 64, 0x2A
    DEFS 64, 0x2B
    DEFS 64, 0x2C
    DEFS 64, 0x2D
    DEFS 64, 0x2E
    DEFS 64, 0x2F
_char:
    INCBIN "font.bin"
