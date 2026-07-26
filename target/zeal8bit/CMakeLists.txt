# Source files common to MMU and no-MMU configurations
set(srcs
    pio.asm
    i2c.asm
    interrupt_vect.asm
    eeprom.asm
)

# Optional MMU support
if(CONFIG_KERNEL_TARGET_HAS_MMU)
    list(APPEND srcs mmu.asm)
endif()

# Only include the romdisk driver if enabled in the menuconfig
if (CONFIG_ENABLE_ROMDISK)
    list(APPEND srcs romdisk.asm)
endif()

# PS/2 extension board driver (shared between keyboard and mouse).
# Must be initialized before the keyboard driver below.
if(CONFIG_TARGET_ENABLE_PS2_EXTENSION_BOARD)
    list(APPEND srcs ps2_ext.asm)
endif()

# Keyboard driver, appended after ps2_ext so it's initialized second.
list(APPEND srcs keyboard.asm)

# Conditional keyboard source
if(CONFIG_TARGET_KEYBOARD_PS2)
    list(APPEND srcs keyboard/ps2.asm)
else()
    list(APPEND srcs keyboard/parl.asm)
endif()

# Mouse driver
if(CONFIG_TARGET_ENABLE_MOUSE)
    list(APPEND srcs mouse.asm)
    if(CONFIG_TARGET_MOUSE_PS2)
        list(APPEND srcs mouse/ps2.asm)
    endif()
    if(CONFIG_TARGET_MOUSE_SNES)
        list(APPEND srcs mouse/snes.asm)
    endif()
endif()

# Conditionally prepend uart.asm if it's stdout
if(CONFIG_TARGET_STDOUT_UART)
    # Insert at the beginning
    list(INSERT srcs 0 uart.asm)
else()
    list(APPEND srcs uart.asm)
endif()

# Same logic for video
if(CONFIG_TARGET_STDOUT_VIDEO)
    list(INSERT srcs 0 video.asm)
elseif(CONFIG_TARGET_ENABLE_VIDEO)
    list(APPEND srcs video.asm)
endif()

# Optional CF/TF support
if(CONFIG_TARGET_ENABLE_COMPACTFLASH)
    list(APPEND srcs compactflash.asm)
endif()

if(CONFIG_TARGET_ENABLE_TFCARD)
    list(APPEND srcs tf.asm)
endif()

# Register all the files and the include directories
zos_target_add(SRCS ${srcs}
               LINKERSCRIPT "linker.asm"
               INCLUDE "./" "./include")
