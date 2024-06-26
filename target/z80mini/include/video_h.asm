; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

    IFNDEF VIDEO_H
    DEFINE VIDEO_H

    INCLUDE "drivers/video_text_h.asm"
    INCLUDE "osconfig.asm"

    MACRO LABEL_IF cond, lab
        IF cond
            PUBLIC lab
            lab:
        ENDIF
    ENDM

    ; Screen flags bit (maximum 8)
    DEFC SCREEN_SCROLL_ENABLED = 0
    DEFC SCREEN_CURSOR_VISIBLE = 1
    DEFC SCREEN_TEXT_640       = 2
    DEFC SCREEN_TEXT_320       = 3
    DEFC SCREEN_TILE_640       = 4
    DEFC SCREEN_TILE_320       = 5

    ; Flag helpers
    DEFC SCREEN_TEXT_MODE_MASK = (1 << SCREEN_TEXT_640) | (1 << SCREEN_TEXT_320)

    ; Colors used by default
    DEFC DEFAULT_CHARS_COLOR     = 0x0f ; Black background, white foreground
    DEFC DEFAULT_CHARS_COLOR_INV = 0xf0

    ; Physical address of the FPGA video
    DEFC IO_VIDEO_PHYS_ADDR_START  = CONFIG_TEXT_ADDRESS
    DEFC IO_VIDEO_PHYS_ADDR_TEXT   = IO_VIDEO_PHYS_ADDR_START
    DEFC IO_VIDEO_PHYS_ADDR_COLORS = CONFIG_ATTR_ADDRESS

    ; Virtual address of the text VRAM
    DEFC IO_VIDEO_VIRT_TEXT_VRAM = 0x4000   ; Always mapped to page 1

    ; Macros for video chip I/O registers and memory mapping
    DEFC IO_VIDEO_SET_CHAR   = 0x80
    DEFC IO_VIDEO_SET_MODE   = 0x83
    DEFC IO_VIDEO_SCROLL_Y   = 0x85
    DEFC IO_VIDEO_SET_COLOR  = 0x86
    DEFC IO_MAP_VIDEO_MEMORY = 0x84
    DEFC MAP_VRAM            = 0x00
    DEFC MAP_SPRITE_RAM      = 0x01

    ; Video modes
    DEFC TEXT_MODE_640 = 1;
    DEFC TILE_MODE_640 = 3;

    ; Macros for text-mode
    DEFC IO_VIDEO_X_PHY = 128
    DEFC IO_VIDEO_Y_PHY = 32
    DEFC IO_VIDEO_X_MAX = 80
    DEFC IO_VIDEO_Y_MAX = 30
    DEFC IO_VIDEO_WIDTH = 640
    DEFC IO_VIDEO_HEIGHT = 480

    DEFC IO_VIDEO_MAX_CHAR = IO_VIDEO_X_MAX * IO_VIDEO_Y_MAX
    DEFC BIG_SPRITES_PER_LINE = IO_VIDEO_WIDTH / 16
    DEFC BIG_SPRITES_PER_COL = IO_VIDEO_HEIGHT / 16

    ENDIF
