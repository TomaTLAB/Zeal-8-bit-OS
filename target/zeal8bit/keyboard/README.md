## Keyboard layout tables

This directory contains keyboard layout definitions used by the kernel keyboard driver to translate hardware scan codes into characters.

Each layout defines a set of lookup tables indexed directly by the keyboard scan code.

### Scan codes

The driver follows the PS/2 Scancode Set 2. The scan code value is used directly as an index into the lookup tables.


These layout files only represent a subset of contiguous key scancodes. The remaining scans, for the arrow keys and numpad are defined directly in the driver `ps2.asm`.

### Table format

Each translation table contains exactly 94 entries (94 bytes).

The index corresponds directly to the scan code:

```
character = table[scancode]
```

The character value is taken from the enumerations present in the file `driver/keyboard_h.asm`.
If a scan code is not supported, the entry contains 0.

### Table order

Tables must appear in the following order inside the layout file:

* `base_scan`: default character mapping when no modifiers are active.
* `extascii_scan` (optional): see below
* `upper_scan`: character mapping when either `Shift` key is pressed or `Caps Lock` is active.
* `alt_scan`: character mapping when AltGr is pressed. This table typically contains tertiary characters used on layouts such as AZERTY (e.g. {, [, |, @, etc.).


The `extascii_scan` table is present only when `CONFIG_LAYOUT_USE_EXTENDED_ASCII` is enabled in the `menuconfig`. It marks which characters produced by base_scan belong to the extended character set.

* 0 = standard ASCII (0-127)
* 1 = extended character (>127)

This allows the driver to distinguish between normal ASCII characters and characters from the extended set.

### Extended Charset

When enabled, the layout may output characters from the Code Page 437 extended character set (following Zeal 80bit VideoBoard's default font). These include accented characters and additional symbols commonly used
on AZERTY keyboards, such as é, è, à, ç, ù, etc...

If extended ASCII support is disabled, these characters are replaced with simple ASCII approximations to maintain 7-bit compatibility. For example, `é` will be replaced by `e`, `ç` will be replaced by `c`, etc...

### Adding a new layout

To add a new layout:

* Copy an existing layout file.
* Modify the character mappings.
* Keep the table size (94 entries) and order unchanged.
* Ensure modifier tables (upper_scan, alt_scan) remain consistent.
* Add a Kconfig option with the name of your layout.
