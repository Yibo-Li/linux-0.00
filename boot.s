! boot.s 程序
! 首先利用 BIOS 中断把内核代码（head代码）加载到内存0x10000处，然后移动到内存0处
! 最后进入保护模式，并跳转到内存0（head代码）开始处继续运行
BOOTSEC = 0x07c0            ! 引导扇区（本程序）被BIOS加载到内存0x7c00处
SYSSEG  = 0x1000            ! 内核（head）先加载到0x10000处，然后移动到0x0处
SYSLEN  = 17                ! 内核占用的最大磁盘扇区数
entry start
start:
    jmpi go,#BOOTSEC        ! 段间跳转到0x07c0:go处。当本程序刚运行时所有段寄存
go: mov ax,cs               ! 器值均为0。该跳转语句会把CS寄存器加载到0x07c0（原
    mov ds,ax               ! 为0）。让DS和SS都指向0x07c0段。
    mov ss,ax
    mov sp,#0x400           ! 设置临时栈指针，其值需大于程序末端并有一定空间。

! 加载内核代码到内存0x10000开始处
load_system:
    mov dx,#0x0000          ! 利用BIOS中断int 0x13功能2从启动盘读取head代码。
    mov cx,#0x0002          ! DH - 磁头号；DL - 磁盘驱动号；CH - 10位磁道号低8位
    mov ax,#SYSSEG          ! CL - 位7、6是磁道号高2位，位5-0起始扇区号（从1计）
    mov es,ax               ! ES:BX - 读入缓冲区设置（0x1000:0000）。
    xor bx,bx               ! AH - 读扇区功能号，AL - 需读的扇区数（17）
    mov ax,#0x200+SYSLEN
    int 0x13
    jnc ok_load             ! 若没有发生错误则跳转继续运行，否则死循环
die:
    jmp die

! 把内核代码移动到内存0开始处，共移动8KB字节（内核长度不超过8KB）
ok_load:
    cli                     ! 关中断
    mov ax,#SYSSEG          ! 移动开始位置DS:SI = Ox1000:0；目的位置 ES:DI = 0:0
    mov ds,ax
    xor ax,ax
    mov es,ax
    mov cx,#0x1000          ! 设置共移动4k次，每次移动一个字（word）
    sub si,si
    sub di,di
    rep
    movsw               ! 执行重复移动指令
! 加载IDT和GDT基地址寄存器IDTR和GDTR
    mov ax,#BOOTSEC
    mov ds,ax               ! 让DS重新指向0x07c0段
    lidt idt_48             ! 加载IDTR。6字节操作数：2字节长度，4字节线性基地址
    lgdt gdt_48             ! 加载GDTR。6字节操作数：2字节长度，4字节线性基地址

! 设置控制寄存器CR0（即机器状态字），进入保护模式。
! 段选择符值8对应GDT表中第2个段描述符
    mov ax,#0x0001          ! 在CR0中设置保护模式标志PE（位0）
    lmsw ax                 ! 然后跳转到段选择符指定的段中，偏移0处
    jmpi 0,8                ! 注意此时段值已是段选择符，该段线性基地址是0

! 下面是全局描述符表GDT的内容，其中包括3个段描述符，第1个不用，另2个是代码和数据
! 段描述符
gdt:
    .word 0,0,0,0           ! 段描述符0，不用，每个描述符占8字节

    .word 0x07ff            ! 段描述符1。8Mb - 段限长值
    .word 0x0000            ! 段基地址=0x0000
    .word 0x9A00            ! 是代码段，可读/执行
    .word 0x00C0            ! 段属性颗粒度=4KB

    .word 0x07ff            ! 段描述符2。8Mb - 段限长值
    .word 0x0000            ! 段基地址=0x0000
    .word 0x9200            ! 是数据段，可读/执行
    .word 0x00C0            ! 段属性颗粒度=4KB
! 下面分别是LIDT和LGDT指令的6字节操作数
idt_48:
    .word 0                 ! IDT表长度是0
    .word 0,0               ! IDT表的线性基地址也是0
gdt_48:
    .word 0x07ff            ! GDT表长度是2048字节，可容纳256个描述符项
    .word 0x7c00+gdt,0      ! GDT表的线性基地址在0x07c0段的偏移gdt处
.org 510
    .word 0xAA55            ! 引导扇区有效标志，必须处于引导扇区最后2字节
