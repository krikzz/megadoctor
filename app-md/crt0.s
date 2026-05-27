.text
    .org	0x0000

    .long   0,   RST, BER, AER, IER, INT, INT, INT
    .long   INT, INT, INT, INT, INT, INT, INT, INT
    .long   INT, INT, INT, INT, INT, INT, INT, INT
    .long   INT, INT, INT, INT, HBL, INT, VBL, INT
    .long   INT, INT, INT, INT, INT, INT, INT, INT
    .long   INT, INT, INT, INT, INT, INT, INT, INT
    .long   INT, INT, INT, INT, INT, INT, INT, INT
    .long   INT, INT, INT, INT, INT, INT, INT, INT

    .ascii  "SEGA MEGA DRIVE "      | SEGA must be the first four chars for TMSS
    .ascii  "KRIKZZ 2026.MAY "
    .ascii  "MEGADOCTOR      "      | export name
    .ascii  "                "
    .ascii  "                "
    .ascii  "MEGADOCTOR      "      | domestic (Japanese) name
    .ascii  "                "
    .ascii  "                "
    .ascii  "GM MK-0000 -01"
    .word   0x0000                  | checksum - not needed
    .ascii  "J6              "
    .long   0x00000000, 0x0007ffff   | ROM start, end
    .long   0x00ff0000, 0x00ffffff   | RAM start, end
    .ascii  "            "           | no SRAM
    .ascii  "    "
    .ascii  "        "
    .ascii  "        "               | memo
    .ascii  "                "
    .ascii  "                "
    .ascii  "F               "       | enable any hardware configuration


RST:
    move.w  #0x2700, %sr            | disable interrupts
    tst.l   0xa10008                | check CTRL1 and CTRL2 setup
    bne.b   1f
    tst.w   0xa1000c                | check CTRL3 setup
1:
    bne.b   skip_tmss               | if any controller control port is setup, skip TMSS handling
    move.b  0xa10001, %d0
    andi.b  #0x0f, %d0              | check hardware version
    beq.b   skip_tmss               | 0 = original hardware, TMSS not present
    move.l  #0x53454741, 0xa14000   | Store Sega Security Code "SEGA" to TMSS
skip_tmss:
    lea     0, %sp
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| cpu ram test
test_ram:
|   data bus test
    lea     0x000000, %a0 | cart regs
    lea     0xff0000, %a1 | ram ptr
    move.w  #0x0000, (%a1)
    move.w  (%a1), (%a0)+
    move.w  #0xffff, (%a1)
    move.w  (%a1), (%a0)+
    move.w  #0x5555, (%a1)
    move.w  (%a1), (%a0)+
    move.w  #0xaaaa, (%a1)
    move.w  (%a1), (%a0)+
    move.b  #0x11, 0(%a1)
    move.b  #0x22, 1(%a1)
    move.w  (%a1), (%a0)+

|   address bus test
    move.b  #1, %d0
    move.w  #1, %d1
    move.b  #0, 0xff0000
1:
    lea     0xff0000, %a1
    add.w   %d1, %a1
    move.b  %d0, (%a1)
    add.b   #1, %d0
    add.w   %d1, %d1
    bne     1b

    move.w  #1, %d1
    move.b  0xff0000, (%a0)+
1:
    lea     0xff0000, %a1
    add.w   %d1, %a1
    move.b  (%a1), (%a0)+
    add.w   %d1, %d1
    bne     1b
 

|   fill memory array
    lea     0xff0000, %a1
    move.w  #0, %d0
1:
    move.w  %d0, (%a1)+
    add.w   #2, %d0
    bne     1b

|   compare array vals
    lea     0xff0000, %a1
    move.w  #0x00, %d0
    move.b  #0xA0, %d2
1:
    move.w  (%a1)+, %d1
    cmp.w   %d0, %d1
    beq     2f
    move.b  #0xA1, %d2 | error
2:
    add.w   #2, %d0
    bne     1b

    move.b  %d2, (%a0)+ | write result

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| vdp ram test
    lea     0xc00008, %a4 | the default global VDP hvcounter port
    lea     0xc00004, %a5 | the default global VDP ctrl port
    lea     0xc00000, %a6 | the default global VDP data port

    move.w  #0x8004, (%a5)  | normal operation
    move.w  #0x8104, (%a5)  | disable display to speed up vdp transfers
    move.w  #0x8700, (%a5)  | bg color
    move.w  #0x8b00, (%a5)  | external irq off
    move.w  #0x8c81, (%a5)  | display mode 320 pixel (40 cell)
    move.w  #0x8f02, (%a5)  | auto inc

|   data bus test    
    move.l  #0x40000000, (%a5) | vram wr mode
    move.w  #0x0000, (%a6)
    move.w  #0xffff, (%a6)
    move.w  #0x5555, (%a6)
    move.w  #0xaaaa, (%a6)
    move.l  #0x00000000, (%a5) | vram rd mode
    move.w  (%a6), (%a0)+
    move.w  (%a6), (%a0)+
    move.w  (%a6), (%a0)+
    move.w  (%a6), (%a0)+

|   fill memory array
    move.l  #0x40000000, (%a5) | vram wr mode
    move.w  #0, %d0
1:
    move.w  %d0, (%a6)
    add.w   #2, %d0
    bne     1b

|   compare array vals
    move.l  #0x00000000, (%a5) | vram rd mode
    move.w  #0x00, %d0
    move.b  #0xA0, %d2
1:
    move.w  (%a6), %d1
    cmp.w   %d0, %d1
    beq     2f
    move.b  #0xA1, %d2 | error
2:
    add.w   #2, %d0
    bne     1b

    move.b  %d2, (%a0)+ | write result
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| z80 tests
|   get z80 bus
    move.w  #0x000, 0xA11200 | z80 reset on
    move.w  #0x100, 0xA11100 | z80 bus req on
    move.w  #0x100, 0xA11200 | z80 reset off

    lea     0xA00000, %a1 | z80 ram
    move.b  #0x00, (%a1)
    move.b  (%a1), (%a0)+
    move.b  #0xff, (%a1)
    move.b  (%a1), (%a0)+
    move.b  #0x55, (%a1)
    move.b  (%a1), (%a0)+
    move.b  #0xaa, (%a1)
    move.b  (%a1), (%a0)+

|   address bus test
    move.b  #1, %d0
    move.w  #1, %d1
    move.b  #0, 0xA00000
1:
    lea     0xA00000, %a1
    add.w   %d1, %a1
    move.b  %d0, (%a1)
    add.b   #1, %d0
    add.w   %d1, %d1
    cmp.w   #8192, %d1
    bne     1b

    move.w  #1, %d1
    move.b  0xA00000, (%a0)+
1:
    lea     0xA00000, %a1
    add.w   %d1, %a1
    move.b  (%a1), (%a0)+
    add.w   %d1, %d1
    cmp.w   #8192, %d1
    bne     1b


|   fill memory array
    lea     0xA00000, %a1
    move.w  #0, %d0
1:
    move.b  %d0, (%a1)+
    add.w   #1, %d0
    cmp.w   #8192, %d0
    bne     1b

|   compare array vals
    lea     0xA00000, %a1
    move.w  #0x00, %d0
    move.b  #0xA0, %d2
1:
    move.b  (%a1)+, %d1
    cmp.b   %d0, %d1
    beq     2f
    move.b  #0xA1, %d2 | error
2:
    add.w   #1, %d0
    cmp.w   #8192, %d0
    bne     1b
    
    move.b  %d2, (%a0)+ | write result
    
    move.w  #0x1234, 0xA00000

|   run z80 app (write 0x11,0x22,0x33,0x44 at 0x100)
    lea     0xA00000, %a1
    lea     z80_asm, %a2
1:
    move.b  (%a2)+, (%a1)+
    cmp.l   #z80_asm_end, %a2
    bne 1b

|   release z80 and wait
    move.w  #0x000, 0xA11200 | z80 reset on
    move.w  #512, %d0
1:
    sub.w   #1, %d0
    bne 1b

    move.w  #0x100, 0xA11200 | z80 reset off
    move.w  #0x000, 0xA11100 | z80 bus req off
    move.w  #32768, %d0
1:
    sub.w   #1, %d0
    bne 1b

|   get z80 bus again
    move.w  #0x000, 0xA11200 | z80 reset on
    move.w  #0x100, 0xA11100 | z80 bus req on
    move.w  #0x100, 0xA11200 | z80 reset off

    move.b  #0xA0, %d2
    lea     0xA00100, %a1
    cmp.b   #0x11, (%a1)+
    bne     1f
    cmp.b   #0x22, (%a1)+
    bne     1f
    cmp.b   #0x33, (%a1)+
    bne     1f
    cmp.b   #0x44, (%a1)+
    bne     1f
    beq     2f
1:
    move.b  #0xA1, %d2  |error
2:
    move.b  %d2, (%a0)+ | write result
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| demo
demo:
    lea     0xc00008, %a4 | the default global VDP hvcounter port
    lea     0xc00004, %a5 | the default global VDP ctrl port
    lea     0xc00000, %a6 | the default global VDP data port
    
    move.l  #0xc0000000, (%a5)  | cram wr mode
    move.w  #0xf00, (%a6)       | bg color
    move.w  #0xfff, (%a6)       | sprite color

|   init vram
    move.l  #0x40000000, (%a5) | vram wr mode
    move.w  #0, %d0
    move.w  #32767, %d1
1:
    move.w  %d0, (%a6)
    dbra    %d1, 1b
    
|   init sprite at 0x100 (tile idx 8)
    move.l  #0x41000000, (%a5) | vram wr mode
    move.w  #0x1111, %d0
    move.w  #15, %d1
1:
    move.w  %d0, (%a6)
    dbra    %d1, 1b


    move.w  #0x8502, (%a5)      | map sprite table at 0x400
    move.w  #0x82ff, (%a5)      | plan-a tbl
    move.w  #0x83ff, (%a5)      | plan-w tbl
    move.w  #0x84ff, (%a5)      | plan-b tbl
    move.w  #0x8144, (%a5)      | display en

    move.w  #128, %d1
    move.w  #128, %d2
    move.w  #2, %d3     | x speed
    move.w  #2, %d4     | y speed
    move.w  #0xc00, %d5 | bg color
demo_loop:
|   vsync
0:
    btst    #3, 1(%a5)
    bne     0b
1:
    btst    #3, 1(%a5)
    beq     1b

|   set sprite
    move.l  #0x44000000, (%a5) | vram wr mode
    move.w  %d1, (%a6)      | y-pos
    move.w  #0x0000, (%a6)  | size, link
    move.w  #0x0008, (%a6)  | gfx
    move.w  %d2, (%a6)      | x-pos

|   inc position 
    add.w   %d3, %d1
    add.w   %d4, %d2

    cmp.w   #344, %d1  | max y
    bgt     1f
    cmp.w   #128, %d1  | min y
    blt     1f
    bra     2f
1:
    neg.w   %d3
    rol.w   #4, %d5
2:

    cmp.w   #440, %d2  | max x
    bgt     1f
    cmp.w   #128, %d2  | min x
    blt     1f
    bra     2f
1:
    neg.w   %d4
    rol.w   #4, %d5
2:
    move.l  #0xc0000000, (%a5)  | cram wr mode
    move.w  %d5, (%a6)    | bg color
    jmp     demo_loop


z80_asm:
.byte 0x21,0x00,0x01,0x36,0x11,0x23,0x36,0x22
.byte 0x23,0x36,0x33,0x23,0x36,0x44,0x76,0x00
z80_asm_end:
|    ld   hl, 0x0100
|    ld   (hl), 0x11
|    inc  hl
|    ld   (hl), 0x22
|    inc  hl
|    ld   (hl), 0x33
|    inc  hl
|    ld   (hl), 0x44
|    halt

VBL:
HBL:
INT:
BER:
AER:
IER:
    move.l  #0xc0000000, 0xc00004
    move.w  #0xf0f, 0xc00000
    rte


