# Zeal 8-bit OS kernel header files

In this directory, you will find public header files that is meant to be used in order to compile or assemble programs for Zeal 8-bit OS.

## C header files

Currently, C header files are provided for the following compilers:

* SDCC v4.2.0 and above. The directory `sdcc` contains C header files that can be used with SDCC compiler. Thus, this lets anyone create programs written in C for Zeal 8-bit OS.

For more info, check the `README.md` files contained inside each supported compiler directory.

## Assembly header files

Currently, assembly header files are provided for the following assemblers:

* z88dk-z80asm. The directory `z88dk-z80asm` contains assembly files that are meant to be included inside any z80asm assembly project.
* gnu-as. The direcotry `gnu-as` contains assembly files that are meant to be included in any assembly project that is assembled with `z80-elf` assembler.

## Examples

As its name states, the directory `examples`, contains code samples that can be compiled/assembled for Zeal 8-bit OS.

For more info, check the `README.md` files contained inside each example directory.