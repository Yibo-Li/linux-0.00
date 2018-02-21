# Makefile for the simple example kernel.
AS86	=as86 -0 -a
LD86	=ld86 -0
AS		=as --32
LD		=ld
LDFLAGS	=-m elf_i386 -Ttext 0 -e startup_32 -s -x -M

all: floppy.img

floppy.img: boot system
	dd bs=512 count=2880 if=/dev/zero of=floppy.img
	dd bs=32 if=boot of=floppy.img skip=1 conv=notrunc
	dd bs=512 if=system of=floppy.img skip=8 seek=1 conv=notrunc
	sync

head.o: head.s
	$(AS) -o head.o head.s

system: head.o
	$(LD) $(LDFLAGS) head.o -o system > system.map

boot: boot.s
	$(AS86) -o boot.o boot.s
	$(LD86) -s -o boot boot.o

run:
	qemu-system-i386 -drive format=raw,file=floppy.img,index=0,if=floppy

debug:
	qemu-system-i386 -s -S -drive format=raw,file=floppy.img,index=0,if=floppy

clean:
	rm -f floppy.img system.map boot *.o system
