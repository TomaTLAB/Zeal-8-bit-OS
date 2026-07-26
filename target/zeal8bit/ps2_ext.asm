; SPDX-FileCopyrightText: 2026 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

; Driver for the PS/2 extension board.
; Handles board detection, version printing, and MCU reset.
; Must be initialized before the keyboard (and optionally mouse) drivers.
; The CMakeLists.txt ensures this file is compiled first.

    INCLUDE "osconfig.asm"
    INCLUDE "utils_h.asm"
    INCLUDE "errors_h.asm"
    INCLUDE "drivers_h.asm"
    INCLUDE "log_h.asm"
    INCLUDE "mmu_h.asm"
    INCLUDE "ps2_ext_h.asm"
    INCLUDE "strutils_h.asm"
    INCLUDE "interrupt_h.asm"

    DEFC PS2_EXT_IRQ_P0_RX_BIT = 0
    DEFC PS2_EXT_IRQ_P1_RX_BIT = 1

  IF CONFIG_PS2_EXT_KEYBOARD_PORT0
    EXTERN keyboard_ext_int_handler
  ENDIF
  IF CONFIG_PS2_EXT_MOUSE_PORT1
    EXTERN mouse_impl_int_handler
  ENDIF


    SECTION KERNEL_DRV_TEXT


    ; Driver init — called by zos_drivers_init during boot.
    ; Detects the board, prints the firmware version, and resets the MCU.
    ; Parameters:
    ;   None
    ; Returns:
    ;   A - ERR_SUCCESS on success, error code else
    ; Alters:
    ;   A, BC, DE, HL
    PUBLIC ps2_ext_init
ps2_ext_init:
    ; Try to read the version of the PS/2 extension board
    PS2_READ_REG(PS2_EXT_REG_VERSION)
    ; If the version is 0, the board is not connected
    or a
    jr z, _ps2_ext_not_plugged
    ; Save version in B
    ld b, a
    ; Print the PS/2 firmware version
    ALLOC_STACK_256 ()
    push bc
    ex de, hl
    ld hl, ps2_firmware_version_msg
    call strformat
    ex de, hl
    call zos_log_info
    FREE_STACK_256 ()
    ; TODO: Perform a full MCU reset if needed.
    ; PS2_WRITE_REG(PS2_EXT_REG_RESET, PS2_EXT_RESET_SWRST)
    ; Not a user driver
    ld a, ERR_DRIVER_HIDDEN
    ret

_ps2_ext_not_plugged:
    ld hl, ps2_ext_not_detected_msg
    call zos_log_warning
    ld a, ERR_FAILURE
    ret


ps2_firmware_version_msg:
    DEFM "PS/2 board firmware v", FORMAT_U8_DEC, ".0\n", 0
ps2_ext_not_detected_msg: DEFM "PS/2 board not plugged in\n", 0


    ; Extension board interrupt handler.
    ; Reads IRQ_STATUS and dispatches to the appropriate port handlers.
    PUBLIC interrupt_default_handler
interrupt_default_handler:
    push af
    push bc
    push de
    push hl
    ; Map kernel RAM to access driver BSS
    MMU_GET_PAGE_NUMBER(MMU_PAGE_3)
    ld d, a
    MMU_MAP_KERNEL_RAM(MMU_PAGE_3)
    ; Read IRQ status to see which port triggered
    PS2_READ_REG(PS2_EXT_REG_IRQ_STATUS)
    ld e, a                         ; save in E for clearing later
  IF CONFIG_PS2_EXT_KEYBOARD_PORT0
    bit PS2_EXT_IRQ_P0_RX_BIT, e
    call nz, keyboard_ext_int_handler
  ENDIF
  IF CONFIG_PS2_EXT_MOUSE_PORT1 && CONFIG_TARGET_MOUSE_PS2
    bit PS2_EXT_IRQ_P1_RX_BIT, e
    push de
    call nz, mouse_impl_int_handler
    pop de
  ENDIF
    ; Clear the IRQ bits that were handled (W1C)
    PS2_WRITE_REG(PS2_EXT_REG_IRQ_STATUS, e)
    ; Restore page 3 and exit
    ld a, d
    MMU_SET_PAGE_NUMBER(MMU_PAGE_3)
    pop hl
    pop de
    pop bc
    pop af
    ei
    reti


; ---- Stub callbacks (this is not a user-facing device) ----

ps2_ext_read:
ps2_ext_write:
ps2_ext_open:
ps2_ext_close:
ps2_ext_seek:
ps2_ext_ioctl:
ps2_ext_deinit:
    ld a, ERR_NOT_SUPPORTED
    ret


    SECTION KERNEL_DRV_VECTORS
ps2_ext_driver:
NEW_DRIVER_STRUCT("PS2E", \
                  ps2_ext_init, \
                  ps2_ext_read, ps2_ext_write, \
                  ps2_ext_open, ps2_ext_close, \
                  ps2_ext_seek, ps2_ext_ioctl, \
                  ps2_ext_deinit)
