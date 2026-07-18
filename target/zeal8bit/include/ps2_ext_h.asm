; SPDX-FileCopyrightText: 2026 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

    IFNDEF PS2_EXT_H
    DEFINE PS2_EXT_H

    INCLUDE "osconfig.asm"

    ; ============================================================
    ; PS/2 extension board — register map (indexed interface v1.0)
    ; ============================================================

    ; Base I/O address
    DEFC PS2_EXT_IO_START = CONFIG_PS2_EXT_IO_ADDR

    ; ---- Bus-level addresses (A1:A0) ----
    DEFC PS2_EXT_IDX_REG       = PS2_EXT_IO_START + 0  ; W: select index, R: current index
    DEFC PS2_EXT_DATA_REG      = PS2_EXT_IO_START + 1  ; R/W: selected register
    DEFC PS2_EXT_PORT0_FIFO    = PS2_EXT_IO_START + 2  ; R: RX FIFO P0, W: TX FIFO P0
    DEFC PS2_EXT_PORT1_FIFO    = PS2_EXT_IO_START + 3  ; R: RX FIFO P1, W: TX FIFO P1

    MACRO PS2_SELECT_REG r
        ld a, r
        out (PS2_EXT_IDX_REG), a
    ENDM

    MACRO PS2_READ_REG r
        ld a, r
        out (PS2_EXT_IDX_REG), a
        in a, (PS2_EXT_DATA_REG)
    ENDM

    MACRO PS2_WRITE_REG r, v
        ld a, r
        out (PS2_EXT_IDX_REG), a
        ld a, v
        out (PS2_EXT_DATA_REG), a
    ENDM

    ; ============================================================
    ; Indexed register map (write index to IDX_REG, then R/W DATA_REG)
    ; ============================================================
    DEFC PS2_EXT_REG_CTRL            = 0x00  ; R/W  Configuration
    DEFC PS2_EXT_REG_STATUS          = 0x01  ; R/W  Read: status, Write: W1C ack/error bits
    DEFC PS2_EXT_REG_VERSION         = 0x02  ; R    Firmware version (0x01 = v1.0)
    DEFC PS2_EXT_REG_RESET           = 0x03  ; W    FIFO clear + MCU reset (WR-only)
    DEFC PS2_EXT_REG_IRQ_STATUS      = 0x04  ; R/W  Read: pending IRQs, Write: W1C clear
    DEFC PS2_EXT_REG_P0_RX_THRESHOLD = 0x08  ; R/W  INT fires when RX count >= threshold (min 1)
    DEFC PS2_EXT_REG_P1_RX_THRESHOLD = 0x09  ; R/W
    DEFC PS2_EXT_REG_P0_ERROR        = 0x0A  ; R    Last non-ACK byte received on port 0
    DEFC PS2_EXT_REG_P1_ERROR        = 0x0B  ; R    Last non-ACK byte received on port 1
    DEFC PS2_EXT_REG_P0_RX_COUNT     = 0x0C  ; R    Bytes in RX FIFO port 0
    DEFC PS2_EXT_REG_P1_RX_COUNT     = 0x0D  ; R    Bytes in RX FIFO port 1
    DEFC PS2_EXT_REG_P0_TX_COUNT     = 0x0E  ; R    Bytes in TX FIFO port 0
    DEFC PS2_EXT_REG_P1_TX_COUNT     = 0x0F  ; R    Bytes in TX FIFO port 1

    ; ============================================================
    ; CTRL register bits (index 0x00)
    ; ============================================================
    DEFC PS2_EXT_CTRL_P0_RX_ENA       = 1 << 0  ; Port 0 receive enable
    DEFC PS2_EXT_CTRL_P1_RX_ENA       = 1 << 1  ; Port 1 receive enable
    DEFC PS2_EXT_CTRL_P0_RX_INT_ENA   = 1 << 2  ; Port 0 RX interrupt enable
    DEFC PS2_EXT_CTRL_P1_RX_INT_ENA   = 1 << 3  ; Port 1 RX interrupt enable
    DEFC PS2_EXT_CTRL_P0_TX_INT_ENA   = 1 << 4  ; Port 0 TX empty interrupt enable
    DEFC PS2_EXT_CTRL_P1_TX_INT_ENA   = 1 << 5  ; Port 1 TX empty interrupt enable
    ; Bits 6-7 reserved

    ; ============================================================
    ; RESET register bits (index 0x03, WR-only)
    ; ============================================================
    DEFC PS2_EXT_RESET_P0_CLR_FIFO    = 1 << 0  ; Clear Port 0 RX/TX FIFOs + latch
    DEFC PS2_EXT_RESET_P1_CLR_FIFO    = 1 << 1  ; Clear Port 1 RX/TX FIFOs + latch
    DEFC PS2_EXT_RESET_SWRST          = 1 << 7  ; MCU software reset

    ; ============================================================
    ; STATUS register bits (index 0x01)
    ;    Read returns live state. Write clears ack/error via W1C
    ;    (bits 0-3 are read-only, bits 4-7 are W1C).
    ; ============================================================
    DEFC PS2_EXT_STATUS_P0_RX_RDY     = 1 << 0  ; Port 0 has data (>= threshold)
    DEFC PS2_EXT_STATUS_P1_RX_RDY     = 1 << 1  ; Port 1 has data (>= threshold)
    DEFC PS2_EXT_STATUS_P0_BSY        = 1 << 2  ; Port 0 is transmitting
    DEFC PS2_EXT_STATUS_P1_BSY        = 1 << 3  ; Port 1 is transmitting
    DEFC PS2_EXT_STATUS_P0_ACK        = 1 << 4  ; Port 0 last TX was ACKed
    DEFC PS2_EXT_STATUS_P1_ACK        = 1 << 5  ; Port 1 last TX was ACKed
    DEFC PS2_EXT_STATUS_P0_ERROR      = 1 << 6  ; Port 0 last TX was NACKed
    DEFC PS2_EXT_STATUS_P1_ERROR      = 1 << 7  ; Port 1 last TX was NACKed

    ; ============================================================
    ; IRQ_STATUS / latch bits (index 0x04)
    ;    Read: which interrupts are pending.
    ;    Write (W1C): writing 1 clears the corresponding latch bit.
    ;    The latch is recalculated each main loop tick.
    ; ============================================================
    DEFC PS2_EXT_IRQ_P0_RX            = 1 << 0  ; Port 0 RX threshold reached
    DEFC PS2_EXT_IRQ_P1_RX            = 1 << 1  ; Port 1 RX threshold reached
    DEFC PS2_EXT_IRQ_P0_TX            = 1 << 2  ; Port 0 TX complete (FIFO empty + not busy)
    DEFC PS2_EXT_IRQ_P1_TX            = 1 << 3  ; Port 1 TX complete

    ; ============================================================
    ; PS/2 protocol constants
    ; ============================================================
    DEFC PS2_CMD_RESET       = 0xFF
    DEFC PS2_CMD_TEST_OK     = 0xAA
    DEFC PS2_CMD_ACK         = 0xFA
    DEFC PS2_CMD_SET_LED     = 0xED
    DEFC PS2_CMD_ENA_REPORT  = 0xF4

    DEFC PS2_LED_SCROLL_LOCK_MSK = 1 << 0
    DEFC PS2_LED_NUM_LOCK_MSK    = 1 << 1
    DEFC PS2_LED_CAPS_LOCK_MSK   = 1 << 2

    ENDIF
