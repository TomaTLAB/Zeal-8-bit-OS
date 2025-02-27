; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

        INCLUDE "errors_h.asm"
        INCLUDE "drivers_h.asm"
        INCLUDE "video_h.asm"
        INCLUDE "utils_h.asm"
        INCLUDE "mmu_h.asm"
        INCLUDE "time_h.asm"
        INCLUDE "strutils_h.asm"

        EXTERN zos_sys_reserve_page_1
        EXTERN zos_sys_restore_pages
        EXTERN zos_sys_remap_de_page_2
        EXTERN zos_vfs_set_stdout

        DEFC ESC_CODE = 0x1b

        SECTION KERNEL_DRV_TEXT
        ; Initialize the video driver.
        ; This is called only once, at boot up
video_init:

        ; Load FONT
        call video_map_start
        ld hl, _rom_font
        ld de, IO_VIDEO_VIRT_TEXT_VRAM + 0x2000
        ld bc, 0x1000
        ldir
        call video_map_end

        ; Initialize the non-0 values here, others are already set to 0 because
        ; they are in the BSS section, including cursor_y and cursor_x.
;        ld hl, IO_VIDEO_VIRT_TEXT_VRAM
;        ld (cursor_pos), hl

        ld a, 1 << SCREEN_SCROLL_ENABLED | 1 << SCREEN_TEXT_640
        ld (screen_flags), a

        ;ld a, TEXT_MODE_640
        ;out (IO_VIDEO_SET_MODE), a

        ;xor a
        ;out (IO_VIDEO_SCROLL_Y), a

        ld a, DEFAULT_CHARS_COLOR
        ;out (IO_VIDEO_SET_COLOR), a
        ld (chars_color), a

        ld a, DEFAULT_CHARS_COLOR_INV
        ld (invert_color), a

        call _video_ioctl_clear_screen

        IF CONFIG_TARGET_STDOUT_VIDEO
        ; Set it at the default stdout
        ld hl, this_struct
        call zos_vfs_set_stdout
        ENDIF ; CONFIG_TARGET_STDOUT_VIDEO

        ; Register the timer-related routines
        IF VIDEO_USE_VBLANK_MSLEEP
        ld bc, video_msleep
        ELSE
        ld bc, 0
        ENDIF
        ld hl, video_set_vblank
        ld de, video_get_vblank

        ; Tail-call to zos_time_init
        jp zos_time_init

        ; Print a message on the video output
        ;MMU_MAP_PHYS_ADDR(MMU_PAGE_1, IO_VIDEO_PHYS_ADDR_TEXT)
video_deinit:
        xor a   ; Success
        ret

        ; Open function, called every time a file is opened on this driver
        ; Note: This function should not attempt to check whether the file exists or not,
        ;       the filesystem will do it. Instead, it should perform any preparation
        ;       (if needed) as multiple reads will occur.
        ; Parameters:
        ;       BC - Name of the file to open
        ;       A  - Flags
        ;       (D  - In case of a driver, dev number opened)
        ; Returns:
        ;       A - ERR_SUCCESS if success, error code else
        ; Alters:
        ;       A, BC, DE, HL (any of them can be altered, caller-saved)
video_open:
        ; Restore the color to default. In the future, we'll also have to restore
        ; the default color palette and charset.
        call video_map_start
        ld a, DEFAULT_CHARS_COLOR
        ld (chars_color), a
        ; Let video chip save this default color
        ;out (IO_VIDEO_SET_COLOR), a
        ;set attribute
        ld de, IO_VIDEO_VIRT_TEXT_VRAM + 0x1FFF ; point to invisible
        ld (de), a
        call video_map_end
        xor a 
        ret

        ; Perform an I/O requested by the user application.
        ; Parameters:
        ;       B - Dev number the I/O request is performed on.
        ;       C - Command number. Driver-dependent.
        ;       DE - 16-bit parameter, also driver-dependent.
        ; Returns:
        ;       A - ERR_SUCCESS on success, error code else
        ;       DE - Driver dependent, NOT PRESERVED
        ; Alters:
        ;       A, BC, DE, HL
video_ioctl:
        ; Check if we are in text mode
        ld a, (screen_flags)
        and SCREEN_TEXT_MODE_MASK
        jp z, _video_not_impl
        ld a, c
        ; Check that C is in the range [0;CMD_COUNT[
        cp CMD_COUNT
        jr nc, _video_invalid_param
        ; Get the label to jump to
        ld hl, _video_ioctl_cmd_table
        rlca    ; A *= 2
        ADD_HL_A()
        ld a, (hl)
        inc hl
        ld h, (hl)
        ld l, a
        jp (hl)
_video_invalid_param:
        ld a, ERR_INVALID_PARAMETER
        ret

        ; Get video driver attributes, including, video modes supported,
        ; colors supported, scrolling supported, current scrolling count,
        ; etc...
_video_ioctl_get_attr:
_video_ioctl_set_attr:
        jp _video_not_impl


        ; Get current mode area size, DE represent a pointer to area_t structure
_video_ioctl_get_area:
        call zos_sys_remap_de_page_2
        ; Only support 80x30 (640x480px) text mode at the moment
        ex de, hl
        ld (hl), IO_VIDEO_X_MAX
        inc hl
        ld (hl), IO_VIDEO_Y_MAX
        inc hl
        ld (hl), IO_VIDEO_MAX_CHAR & 0xff
        inc hl
        ld (hl), IO_VIDEO_MAX_CHAR >> 8
        ex de, hl
        xor a
        ret


        ; Return the cursor position (x,y) in registers D and E respectively
        ; Returns:
        ;   DE - Address to fill with X and Y. The buffer must be at least
        ;        16-bit big.
        ; Alters:
        ;   A, HL, DE
_video_ioctl_get_cursor_xy:
        call zos_sys_remap_de_page_2
        ld hl, cursor_x
        ld a, (hl)
        ld (de), a
        sub IO_VIDEO_X_MAX
        jr nz, _video_ioctl_get_cursor_xy_no_reset
        ld (de), a
_video_ioctl_get_cursor_xy_no_reset:
        inc hl
        inc de
        ld a, (hl)
        ld (de), a
        sub IO_VIDEO_Y_MAX - 1
        ; We have to return 0 in all cases to mark the ioctl as a success
        ld a, 0
        ret nz
        ld (de), a
        ret

        ; Set the position (x,y) of the cursor. If X or Y is bigger than
        ; the maximum, they will be set to the maximum.
        ; Parameters:
        ;   D - New X position
        ;   E - New Y position
        ; Alters:
        ;   A, BC, DE, HL
_video_ioctl_set_cursor_xy:
        push de
        ; Hide the cursor as it is going be to repositioned
        call video_map_start
        call video_hide_cursor
        pop de
        ; Load the maximum Y possible
        ld bc, IO_VIDEO_X_MAX << 8 | IO_VIDEO_Y_MAX
        ; If Y is bigger than IO_VIDEO_Y_MAX, set it to IO_VIDEO_Y_MAX - 1
        ld a, e
        cp c
        jr c, _video_ioctl_set_cursor_y_valid
        ; Set E to the maximum - 1
        ld e, c
        dec e
_video_ioctl_set_cursor_y_valid:
        ; Add the scroll count to E
        ld a, e
;        ld a, (scroll_count)
;        add e
        cp c
        jr c, _video_ioctl_set_cursor_x
        ; No carry occurred, so E is bigger than C
        sub c
_video_ioctl_set_cursor_x:
        ld (cursor_y), a
        rra
        ld h, a
        rra
        and a, 0b10000000
        ld l, a
        ; Do the same adjustment for X
        ld a, d
        cp b
        jr c, _video_ioctl_set_cursor_x_valid
        ld a, b
        dec a
_video_ioctl_set_cursor_x_valid:
        ld (cursor_x), a
        or a, l
        ld l, a
        res 7, h
        set 6, h ;We know it always mapped to page 1
;        ld a, h
;        add a, IO_VIDEO_VIRT_TEXT_VRAM >> 8
;        ld h, a
        ld (cursor_pos), hl
        call video_show_cursor
        call video_map_end
        ; Success, return 0
        xor a
        ret


        ; Set the current background and foreground color.
        ; It is not guaranteed that the color chosen is available.
        ; Parameters:
        ;   D - Background color
        ;   E - Foreground color
        ; Returns:
        ;   A - 0 on success
_video_ioctl_set_colors:
        ; Put both colors in a single byte 0xBF where B is background color
        ; and F is the foreground color
        ld b, 0xf
        ; E &= 0xF
        ld a, e
        and b
        ld e, a
        ; A = ((D & 0xF) << 4) | E
        ld a, d
        and b
        rlca
        rlca
        rlca
        rlca
        or e
        ld (chars_color), a
 ;       out (IO_VIDEO_SET_COLOR), a
        ; Save the inverted colors for the cursor
        rlca
        rlca
        rlca
        rlca
        ld (invert_color), a
        ; If the cursor is visible, we also have to change its color
        ld e, a
        call video_map_start
        ld hl, (cursor_pos)
        set 4, h
        ld (hl), e
        call video_map_end
        ; Success
        xor a
        ret


        ; Clear the screen (with current color) and reposition the cursor.
        ; Parameters:
        ;   None
        ; Returns:
        ;   A - 0 on success
        ; Alters:
        ;   A, BC, DE, HL
_video_ioctl_clear_screen:
        call video_map_start
          ;set attribute
        ld a, (chars_color)
        ld de, IO_VIDEO_VIRT_TEXT_VRAM + 0x1000
        ld (de), a
        ;clear frame buffer
        xor a
        ld hl, IO_VIDEO_VIRT_TEXT_VRAM
        ld (hl), a
        ld de, IO_VIDEO_VIRT_TEXT_VRAM + 1
        ld bc, 0x1000 - 1
        ldir
        ; Reset the absolute cursor to position 0
        ld hl, IO_VIDEO_VIRT_TEXT_VRAM
        ld (cursor_pos), hl
        ; Show the cursor
        ld a, (invert_color)
        set 4, h
        ld (hl), a
        ; Save the new (X,Y) position
        ld hl, 0
        ld (cursor_x), hl
        ld (cursor_y), hl
        call video_map_end
        xor a
        ret

_video_ioctl_cmd_table:
        DEFW _video_ioctl_get_attr
        DEFW _video_ioctl_get_area
        DEFW _video_ioctl_get_cursor_xy
        DEFW _video_ioctl_set_attr
        DEFW _video_ioctl_set_cursor_xy
        DEFW _video_ioctl_set_colors
        DEFW _video_ioctl_clear_screen


        ; Write function, called every time user application needs to output chars
        ; or pixels to the video chip.
        ; Parameters:
        ;       A  - DRIVER_OP_HAS_OFFSET (0) if the stack has a 32-bit offset to pop
        ;            DRIVER_OP_NO_OFFSET  (1) if the stack is clean, nothing to pop.
        ;       DE - Source buffer. Guaranteed to not cross page boundary.
        ;       BC - Size to read in bytes. Guaranteed to be equal to or smaller than 16KB.
        ;
        ;       ! IF AND ONLY IF A IS 0: !
        ;       Top of stack: 32-bit offset. MUST BE POPPED IN THIS FUNCTION.
        ;              [SP]   - Upper 16-bit of offset
        ;              [SP+2] - Lower 16-bit of offset
        ; Returns:
        ;       A  - ERR_SUCCESS if success, error code else
        ;       BC - Number of bytes written
        ; Alters:
        ;       This function can alter any register.
video_write:
        ; Video driver is not registered as a file system, thus A must always
        ; be 1, meaning that the stack is clean, nothing to pop.

        ; We have to map the source buffer to a reachable virtual page.
        ; Page 0 is the current code
        ; Page 1 and 2 are user's RAM
        ; Page 3 is kernel RAM
        ; Let's reserve the page 1 for mapping the video memory, the source buffer
        ; will be reachable, no matter where it is.
        call zos_sys_reserve_page_1
        ; Check return value
        or a
        ret nz
        ; Save the context returned by the previous function
        push hl
        ; FIXME: check if we are in text mode or in graphics mode
        ; At the moment always map the same 16KB containing the char and colors
        MMU_MAP_PHYS_ADDR(MMU_PAGE_1, IO_VIDEO_PHYS_ADDR_TEXT)
        push bc
;        push de
        call video_hide_cursor
;        pop de
        call print_buffer
        call video_show_cursor
        pop bc
        ; Restore the virtual page 1
        pop hl
        call zos_sys_restore_pages
        ; Return success
        xor a
        ret

        ; Read not supported yet.
        ; Same reasons as above, stack is clean
video_read:

        ; Close an opened dev number.
        ; Parameter:
        ;       A  - Opened dev number getting closed
        ; Returns:
        ;       A - ERR_SUCCESS if success, error code else
        ; Alters:
        ;       A, BC, DE, HL
video_close:

        ; Move the abstract cursor to a new position.
        ; The new position is a 32-bit value, it can be absolute or relative
        ; (to the current position or the end), depending on the WHENCE parameter.
        ; Parameters:
        ;       H - Opened dev number getting seeked.
        ;       BCDE - 32-bit offset, signed if whence is SEEK_CUR/SEEK_END.
        ;              Unsigned if SEEK_SET.
        ;       A - Whence. Can be SEEK_CUR, SEEK_END, SEEK_SET.
        ; Returns:
        ;       A - ERR_SUCCESS on success, error code else.
        ;       BCDE - Unsigned 32-bit offset. Resulting offset.
        ; Alters:
        ;       A, BC, DE, HL
video_seek:

_video_not_impl:
        ld a, ERR_NOT_IMPLEMENTED
        ret


        ;======================================================================;
        ;================= S T D O U T     R O U T I N E S ====================;
        ;======================================================================;

        ; Map the video RAM in the second page.
        ; This is used by other drivers that want to show text or manipulate
        ; the text cursor several times, knowing that no read/write on user
        ; buffer will occur. It will let us perform a single map/unmap across
        ; the whole process.
        ; Parameters:
        ;       None
        ; Returns:
        ;       None
        ; Alters:
        ;       A
LABEL_IF(CONFIG_TARGET_STDOUT_VIDEO, stdout_op_start)
        PUBLIC video_map_start
video_map_start:
        MMU_GET_PAGE_NUMBER(MMU_PAGE_1)
        ld (mmu_page_back), a
        ; Map VRAM in the second page (page 1)
        MMU_MAP_PHYS_ADDR(MMU_PAGE_1, IO_VIDEO_PHYS_ADDR_TEXT)
        ret

        ; Same as above, but for restoring the original page
LABEL_IF(CONFIG_TARGET_STDOUT_VIDEO, stdout_op_end)
        PUBLIC video_map_end
video_map_end:
        ld a, (mmu_page_back)
        MMU_SET_PAGE_NUMBER(MMU_PAGE_1)
        ret


        ; Show the cursor, inverted colors.
        ; The routine video_map_start must have been called
        ; beforehand.
        ; Parameters:
        ;       None
        ; Returns:
        ;       None
        ; Alters:
        ;       A, HL
LABEL_IF(CONFIG_TARGET_STDOUT_VIDEO, stdout_show_cursor)
        PUBLIC video_show_cursor
video_show_cursor:
        ld a, (invert_color)
        ; A - Cursor color
video_show_cursor_color:
        ld hl, (cursor_pos)
        set 4, h ; point to attr
        ld (hl), a
        ret

        ; Hide the cursor.
        ; The routine video_map_start must have been called
        ; beforehand.
        ; Parameters:
        ;       None
        ; Returns:
        ;       None
        ; Alters:
        ;       A, HL
LABEL_IF(CONFIG_TARGET_STDOUT_VIDEO, stdout_hide_cursor)
        PUBLIC video_hide_cursor
video_hide_cursor:
        ld a, (chars_color)
        jr video_show_cursor_color

    IF CONFIG_TARGET_STDOUT_VIDEO
        ; Print a buffer from the current cursor position, but without
        ; updating the cursor position at the end of the operation.
        ; The characters in the buffer must all be printable characters,
        ; as they will be copied as-is on the screen.
        ; The buffer must not be in the second memory page.
        ; NOTE: The routine video_map_start must have been called beforehand
        ; Parameters:
        ;       DE - Buffer containing the chars to print
        ;       BC - Buffer size to render
        ; Returns:
        ;       None
        ; Alters:
        ;       A, BC, HL, DE
        PUBLIC stdout_print_buffer
stdout_print_buffer:
        PUBLIC video_print_buffer_from_cursor
video_print_buffer_from_cursor:
        call video_hide_cursor
        ld hl, (cursor_pos)
        push hl
        ld hl, (cursor_x)
        push hl
        call print_buffer
        pop hl
        ld (cursor_x), hl
        pop hl
        ld (cursor_pos), hl
        jr video_show_cursor

        PUBLIC stdout_print_char
stdout_print_char:
        ld b, a
        call video_hide_cursor
        ld a, b
        call print_char
        jr video_show_cursor
    ENDIF ; CONFIG_TARGET_STDOUT_VIDEO

        ; Routine called everytime a V-blank interrupt occurs
        ; Must not alter A
        PUBLIC video_vblank_isr
video_vblank_isr:
        ; Add 16(ms) to the counter
        ld hl, (vblank_count)
        ld de, 16
        add hl, de
        ld (vblank_count), hl
        ret

        ;======================================================================;
        ;================= P R I V A T E   R O U T I N E S ====================;
        ;======================================================================;

        ; Routines to get the vblank count (can be used as a timer)
        ; Parameters:
        ;       None
        ; Returns:
        ;       DE - time_millis_t data type
        ;       A - ERR_SUCCESS
        ; Alters:
        ;       None
video_get_vblank:
        ld de, (vblank_count)
        xor a
        ret

        ; Routines to set the vblank count (can be used as a timer)
        ; Parameters:
        ;       DE - time_millis_t data type
        ; Returns:
        ;       A - ERR_SUCCESS
        ; Alters:
        ;       None
video_set_vblank:
        ld (vblank_count), de
        xor a
        ret

        ; Do not use vblank counter for msleep at the moment, it is less accurate than
        ; the default OS function which counts cycles.
        IF VIDEO_USE_VBLANK_MSLEEP
        ; Routine to sleep at least DE milliseconds
        ; Parameters:
        ;       DE - 16-bit duration
        ; Returns:
        ;       A - ERR_SUCCESS on success, error code else
        ; Alters:
        ;       Can alter any
video_msleep:
        ; Make sure the parameter is no 0
        ld a, d
        or e
        ret z
        ; Before dividing by 16, keep E in C in order to check the remainder.
        ; Indeed, if we were asked to wait 60ms, we have to wait 4*16 = 64, and
        ; not 3*16 = 48
        ld a, e
        and 0xf
        ld b, a
        ; Divide DE by 16
        ld a, e
_video_msleep_no_carry:
        srl d
        rra
        srl d
        rra
        srl d
        rra
        srl d
        rra
        ld e, a
        ; If the remainder is not 0, increment DE by one
        ld a, b
        or a
        jp nz, _video_msleep_inc
        ; If the result is 0 (< 16ms), increment by 1
        or e
        or d
        jr nz, _video_msleep_start
_video_msleep_inc:
        inc de
_video_msleep_start:
        ; TODO: Make sure the VBlank interrupt are still enabled?
        ; Each VBlank ticks counts as 16ms, except the first one, so make sure we ignore it
        ; wait for a change on the tick count.
        ld hl, vblank_count
        ; No need to check the most-significant byte
        ld a, (hl)
_video_msleep_ignore:
        halt
        cp (hl)
        ; We can take our time here, use jr
        jr z, _video_msleep_ignore
        ; A change occurred, clean the count and wait for DE ticks
        ld hl, 0
        ld (vblank_count), hl
_video_msleep_wait:
        xor a
        ld hl, (vblank_count)
        sbc hl, de
        jp c, _video_msleep_wait
        ; Success, A is already 0.
        ret
        ENDIF


        ; Print a buffer on the screen
        ; Parameters:
        ;       DE - Character buffer to print
        ;       BC - Size of the buffer
        ; Alters:
        ;       A, BC, DE, HL
print_buffer:
       ld a, b
       or c
       ret z
       ld a, (de)
       call print_char
       inc de
       dec bc
       jr print_buffer


        ; Print a character at the cursors positions (cursor_x and cursor_y)
        ; The cursors will be updated accordingly. If the end of the screen
        ; is reached, the cursor will go back to the beginning.
        ; New line (\n) will make the cursor jump to the next line.
        ;
        ; Parameter:
        ;       A - ASCII character to output
        ; Returns:
        ;       none
        ; Alters:
        ;       A, HL
        PUBLIC print_char
print_char:
        or a
        ret z   ; NULL-character, don't do anything
        cp '\n'
        jr z, _print_char_newline
        cp '\r'
        jr z, _print_char_carriage_return
        cp '\b'
        jr z, _print_char_backspace
        ; Tabulation is consider a space. Do nothing special.
        ; Get the cursor position
        ld hl, (cursor_pos)
        ld (hl), a              ; Write the ASCII character to VRAM
        inc hl
        ld (cursor_pos), hl     ; Save incremented position
        ; Now, we also need to increment the position-on-current-line byte
        jr _video_adjust_cursor

_print_char_newline:
        ; Before resetting cursor_x, let's make cursor_pos point to next line!
        ; Perform cursor_pos += IO_VIDEO_X_PHY - cursor_x
        ld a, (cursor_x)
        neg
        add IO_VIDEO_X_PHY
        ld hl, (cursor_pos)
        ADD_HL_A()
        ld (cursor_pos), hl
        ld hl, cursor_x
        jr _video_force_adjust_cursor

_print_char_carriage_return:
        ; This is similar to newline, expect that we subtract what has been reached
        ; cursor_x, instead of adding remaining chars
        ld hl, cursor_x
        ; Reset cursor_x now as we are currently pointing to it
        ld (hl), 0
        ld a, (cursor_pos) ; get low byte (7 low bit - x-pos) of absolute cursor
        and a, 0b10000000 ; reset it to 0
        ld (cursor_pos), a ; now save
        ret

_print_char_backspace:
        ; It is unlikely that X is 0 and even more unlikely that Y is too
        ; so save some time for the "best" case and decrement HL here
        ld hl, (cursor_pos)
        dec hl
        ld (cursor_pos), hl
        ; Check if cursor_x is 0
        ld hl, cursor_x
        ld a, (hl)
        ; Decrement cursor_x in case it's not 0 (likely)
        dec (hl)
        ; Check if it was 0 after decrementing
        or a
        ret nz
        ; X was 0, roll it to X maximum
        ld a, IO_VIDEO_X_MAX - 1
        ld (hl), a
        ld hl, (cursor_pos) ;cursor_pos already decremented -> Y part is correct
        ld a, 0b10000000
        and a, l
        or a, IO_VIDEO_X_MAX - 1
        ld l, a
        ld (cursor_pos), hl
        ; Check if cursor_y is also
        ; ASSERT(cursor_y == cursor_x + 1)
        ld hl, cursor_y
        ; Same with cursor_y
        ld a, (hl)
        dec (hl)
        or a
        ret nz
        ; Y is also 0, we have to roll it back, same for cursor_pos
        ld (hl), 0
        ; Also reset the absolute cursor
        ld hl, IO_VIDEO_VIRT_TEXT_VRAM
        ld (cursor_pos), hl
        ret

_video_adjust_cursor:
        ld hl, cursor_x
        ; Check if the current X is out of bound
        ld a, (hl)
        cp IO_VIDEO_X_MAX - 1
        jr z, _video_force_adjust_cursor
        ; Nothing special in the case where X has not reached the end of the screen
        inc (hl)
        ret
_video_force_adjust_cursor:
        ; X reached the end of the line, reset it
        ld (hl), 0
        ; Update Y position to go to the next line (cursor_y + 1 == cursor_x)
        inc hl ; now HL points to cursor_y
        inc (hl) ; inc cursor_y
        ; Set the cursors back to 0 in case we reached the maximum, again
        ld a, (hl)
        cp IO_VIDEO_Y_MAX
        ; Y has reached the maximum, scroll
        jr z, _video_scroll_if_needed
        ; no scroll needed, update absolute cursor
        rra
        ld h, a
        rra
        and a, 0b10000000
        ld l, a
        res 7, h
        set 6, h ;We know it always mapped to page 1
;        ld a, h
;        add a, IO_VIDEO_VIRT_TEXT_VRAM >> 8
;        ld h, a
        ld (cursor_pos), hl
        ret

_video_scroll_if_needed:
        ; Set the cursors (Y & absolute) back to previous (bottom line) as we reached the maximum
        push de
        push bc
        dec a   ; new cursor_y
        ld (hl), a
        ld hl, IO_VIDEO_VIRT_TEXT_VRAM + 0x1000 - IO_VIDEO_X_PHY * 3
        ld (cursor_pos), hl
        ld hl, IO_VIDEO_VIRT_TEXT_VRAM + IO_VIDEO_X_PHY
        ld de, IO_VIDEO_VIRT_TEXT_VRAM
        ld bc, 0x1000 - IO_VIDEO_X_PHY * 2
        ldir
        pop bc
        pop de
        ret

_rom_font:
    INCBIN "font.fnt"


        SECTION DRIVER_BSS
vblank_count:  DEFS 2
cursor_pos:    DEFS 2  ; 2 bytes for cursor position on the screen
cursor_x:      DEFS 1  ; 1 byte for cursor X position (current column)
cursor_y:      DEFS 1  ; 1 byte for cursor Y position, must follow x
scroll_count:  DEFS 1
screen_flags:  DEFS 1
chars_color:   DEFS 1
invert_color:  DEFS 1
mmu_page_back: DEFS 1


        SECTION KERNEL_DRV_VECTORS
this_struct:
NEW_DRIVER_STRUCT("VID0", \
                  video_init, \
                  video_read, video_write, \
                  video_open, video_close, \
                  video_seek, video_ioctl, \
                  video_deinit)
