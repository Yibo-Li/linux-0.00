# linux-0.00

This is the first ever known version Linux kernel which just prints "AAAA" and "BBBB" over and over again. The code is checked out from [oldlinux.org](http://oldlinux.org/) originally.

There are only two assembly files: an 8086 bootloader, and an 80386 kernel that sets up protected mode, and two hard-coded tasks, then runs the two tasks in level 3.

Build with:

```bash
$ make
as86 -0 -a -o boot.o boot.s
ld86 -0 -s -o boot boot.o
as --32 -o head.o head.s
ld -m elf_i386 -Ttext 0 -e startup_32 -s -x -M head.o -o system > system.map
dd bs=512 count=2880 if=/dev/zero of=floppy.img
记录了2880+0 的读入
记录了2880+0 的写出
1474560 bytes (1.5 MB, 1.4 MiB) copied, 0.341425 s, 4.3 MB/s
dd bs=32 if=boot of=floppy.img skip=1 conv=notrunc
记录了16+0 的读入
记录了16+0 的写出
512 bytes copied, 0.00207484 s, 247 kB/s
dd bs=512 if=system of=floppy.img skip=8 seek=1 conv=notrunc
记录了9+1 的读入
记录了9+1 的写出
5004 bytes (5.0 kB, 4.9 KiB) copied, 0.00161871 s, 3.1 MB/s
sync
```

Run with:

```bash
$ make run
qemu-system-i386 -drive format=raw,file=floppy.img,index=0,if=floppy
```
Debug with:
```bash
$ gdb
(gdb) target remote localhost:1234
(gdb) set arch i8086
(gdb) info reg cs eip
cs      0xf000  61440
eip     0x7c00  0x7c00
(gdb) break *0x7c00
(gdb) c
Continuing.
Breakpoint 1, 0x00007c00 in ?? ()
(gdb) x /10i $eip
=> 0x7c00:      ljmp   $0x7c0,$0x5
   0x7c05:      mov    %cs,%ax
   0x7c07:      mov    %ax,%ds
   0x7c09:      mov    %ax,%ss
   0x7c0b:      mov    $0x400,%sp
   0x7c0e:      mov    $0x0,%dx
   0x7c11:      mov    $0x2,%cx
   0x7c14:      mov    $0x1000,%ax
   0x7c17:      mov    %ax,%es
   0x7c19:      xor    %bx,%bx
```
