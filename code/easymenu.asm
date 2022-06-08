; easymenu.asm
;
; Directory and program launcher utility for Commodore 64
; Copyright (c) 1987, 2022 by David R. Van Wagner
; MIT LICENSE
; davevw.com

cursorcol=$D3 ; cursor column on current line

clrchn=$FFCC ; restore default devices
chrout=$FFD2 ; output a character
clall=$FFE7 ; close all files
setmsg=$FF90 ; set kernal message control flag
setlfs=$FFBA ; set logical file parameters
setnam=$FFBD ; set filename parameters
open=$FFC0 ; open a logical file
chkin=$FFC6 ; define an input channel
chrin=$FFCF ; input a character
close=$FFC3 ; close a logical file
readst=$FFB7 ; read I/O status word
getin=$FFE4 ; get a character
savefile=$FFD8 ; save to a devicenum
loadfile=$FFD5 ; load from a devicenum

start=$C000
*=start

jmp entry
!byte $da,$9e,$20,$c2,$28
!byte $34,$33,$29,$aa,$32,$35,$36,$ac
!byte $c2,$28,$34,$34,$29,$aa,$32,$38
!byte $00,$00,$00,$00

*=$c01c

; copy 7 full pages from BASIC RAM to destination (program + extraneous)
    lda $2b
    sta $5b
    lda $2c
    sta $5c
    lda #<start
    sta $57
    lda #>start
    sta $58
    ldx #$07
    ldy #0
-   lda ($5b),y
    sta ($57),y
    iny
    bne -
    inc $5c
    inc $58
    dex
    bne -

; fix first two bytes of jmp entry at start
    lda #$4c ; jmp absolute opcode
    sta start
    lda #<entry
    sta start+1
    jmp start

entry:
    lda #$93 ; clear screen
    jsr chrout
    jsr applycolors

    lda #<buffer
    sta $57
    lda #>buffer
    sta $58

    lda #$ff
    sta num_files

    jsr clrchn
    jsr clall
    lda #0
    jsr setmsg
    lda #$01
    ldx devicenum
    ldy #0
    jsr setlfs
    lda #$01 ; len=1
    ldx #<directory
    ldy #>directory
    jsr setnam
    jsr open
    jsr ret_to_parent_if_err
    ldx #$01
    jsr chkin
    jsr ret_to_parent_if_err
    jsr chrin
    jsr ret_to_parent_if_err
    jsr chrin
    jsr ret_to_parent_if_err

--  lda num_files
    cmp #0
    bne +
    jsr draw_screen
    lda #<buffer
    sta $57
    lda #>buffer
    sta $58

+   ldy #0
    jsr chrin
    jsr ret_to_parent_if_err
    jsr chrin
    jsr ret_to_parent_if_err
    jsr chrin
    jsr ret_to_parent_if_err
    jsr chrin
    jsr ret_to_parent_if_err
    jsr chrin
    jsr ret_to_parent_if_err

    cmp #$42 ; 'B' ???
    bne +
    jmp +++

+
-   cmp #$22 ; double quote
    beq +
    jsr chrin
    jsr ret_to_parent_if_err
    jmp -

+
-   jsr chrin
    jsr ret_to_parent_if_err
    cmp #$22 ; double quote
    beq +
    cpy #16
    bcs -
    sta ($57),y
    iny
    bne -

+   cpy #$10 ; max length?
    bcs +
    lda #$a0
    sta ($57),y
    iny

+
-   jsr chrin
    jsr ret_to_parent_if_err
    cpy #16 ; max length?
    bcs +
    sta ($57),y
    iny
+   cmp #0
    bne -

    lda $57
    adc #15
    sta $57
    lda $58
    adc #0
    sta $58
    inc num_files
    lda num_files
    cmp #max_files
    beq +
    jmp --
+   jmp +++

--  jsr clrchn
    lda #$01
    jsr close
    jsr clall
    lda #15
    ldx devicenum
    tay
    jsr setlfs
    lda #0
    jsr setnam
    jsr open
    ldx #$0f
    jsr chkin

-   jsr chrin
    cmp #','
    bne -

    lda #$13 ; home
    jsr chrout
    lda #$11 ; down
    jsr chrout
    lda #$02
    sta cursorcol
    lda #$12 ; rvs

-   jsr chrout
    jsr chrin
    cmp #','
    bne -

-   jsr chrin
    cmp #13 ; cr
    bne -

    jsr clrchn
    lda #15
    jsr close
    lda #' '
-   jsr chrout
    ldx cursorcol
    cpx #39
    bne -
    jmp errkey

ret_to_parent_if_err
    pha
    jsr readst
    and #$83
    bmi +
    beq ++
    pla
    pla
    pla
    jmp --

+   lda #$08
    sta devicenum
    ldx #<drive_not_present
    ldy #>drive_not_present
    jsr strout
    pla
    pla
    pla
    jmp errkey
++  pla
    rts

+++ jsr clrchn
    lda #$01
    jsr close
    lda num_files
    bne ++
    ldx #<no_files
    ldy #>no_files
    jsr strout

errkey
-   jsr getin
    cmp #$03 ; ctrl+c
    bne +
    jmp ctlrc_handler

+   cmp #' '
    bne +
    jmp start

+   cmp #'1'
    bcc -
    cmp #'5'
    bcs -
    jmp go_drive

++  lda #0
    sta page_index
    jsr display_dir_page
    ldx #0
    stx cursor_index

drawthenkey
    jsr draw_names

checkkey
    jsr getin
    cmp #0
    bne ++
--  lda $dc00 ; joystick2 (cia#1 data port register a)
    and #$1f
    cmp #$1f
    beq checkkey

; delay - busy loop
    ldy #$46
    ldx #0
-   dex
    bne -
    dey
    bne -

    lda $dc00 ; joystick2
    and #$1f
    cmp joy2_last
    sta joy2_last
    bne --
    and #$01 ; up
    bne +
    lda #$91
    bne ++

+   lda $dc00 ; joystick2
    and #$02 ; down
    bne +
    lda #$11
    bne ++

+   lda $dc00 ; joystick2
    and #$04 ; left
    bne +
    lda #$9d
    bne ++

+   lda $dc00 ; joystick2
    and #$08 ; right
    bne +
    lda #$1d
    bne ++

+   lda $dc00 ; joystick2
    and #$10 ; fire
    bne checkkey
    lda #$0d ; enter

++  ldx cursor_index
    cmp #$11 ; down
    bne ++
    cpx #41 ; off page?
    beq +
    sec
    lda files_rem
    sbc #$01
    cmp cursor_index
    beq checkkey
    jsr draw_names
    inc cursor_index
    jmp drawthenkey
+   clc
    lda cursor_index
    adc #$01
    cmp files_rem
    bcc +
    jmp checkkey
+   lda #0
    sta cursor_index
    clc
    lda page_index
    adc #$2a
    sta page_index
    jsr display_dir_page
    jmp drawthenkey

++  cmp #$13 ; home
    bne +
    ldx #0
    stx page_index
    stx cursor_index
    jsr display_dir_page
    jmp drawthenkey

+   cmp #$91 ; up
    bne ++
    cpx #0
    beq +
    jsr draw_names
    dec cursor_index
    jmp drawthenkey
+   lda page_index
    bne +
    jmp checkkey
+   sec
    sbc #$2a
    sta page_index
    lda #$29
    sta cursor_index
    jsr display_dir_page
    jmp drawthenkey

++  cmp #$9d ; left
    bne ++
    cpx #$15
    bcs +
    jmp checkkey
+   jsr draw_names
    sec
    lda cursor_index
    sbc #$15
    sta cursor_index
    jmp drawthenkey

++  cmp #$1d ; right
    bne ++
    cpx #$15
    bcc +
    jmp checkkey
+   jsr draw_names
    clc
    lda cursor_index
    adc #$15
    cmp files_rem
    bcs +
    sta cursor_index
+   jmp drawthenkey

++  cmp #' '
    bne +
    jmp start

+   cmp #$03 ; ctrl+c
    bne +
    lda #$93
ctlrc_handler
-   lda $c5
    cmp #$40
    bne -
    lda #$93 ; clear screen
    jsr chrout
    rts

+   cmp #$06 ; ctrl+f
    bne +
; save copy of self to disk
    ldx #<writing
    ldy #>writing
    jsr strout
    ldx #<program_name
    ldy #>program_name
    jsr strout
    lda #$0f
    ldx devicenum
    ldy #$0f
    jsr setlfs
    lda #$0a
    ldx #<scratch
    ldy #>scratch
    jsr setnam
    jsr open
    jsr ret_to_parent_if_err
    lda #$0f
    jsr close
    lda #$01
    ldx devicenum
    ldy #0
    jsr setlfs
    lda #$08
    ldx #<program_name
    ldy #>program_name
    jsr setnam
    lda #<start
    sta $5b
    lda #>start
    sta $5c
    lda #$5b
    ldx #<num_files ; end of program to save
    ldy #>num_files ; end of program to save
    jsr savefile
    jsr ret_to_parent_if_err
    jmp start

+   cmp #$0d ; enter
    beq load_selection

    cmp #$85 ; f1
    bne +
    lda fg_choice
    adc #0
    and #$0f
    sta fg_choice
    jsr applycolors
    jmp checkkey

+   cmp #$86 ; f3
    bne +
    lda bg_choice
    adc #0
    and #$0f
    sta bg_choice
    jsr applycolors
    jmp checkkey

+   cmp #$87 ; f5
    bne +
    lda border_choice
    adc #0
    and #$0f
    sta border_choice
    jsr applycolors

go_drive
+   sec
    sbc #'1'
    bcc +
    cmp #$04
    bcs +
    adc #$08 ; convert to devicenum number 8-11
    sta devicenum
    jmp start

+   jmp checkkey

load_selection
    lda #0
    sta $59
    lda #$01
    sta $5a
    jsr $fd02 ; check for autostart cartridge
    bne +
    lda #$80
    sta $59

+   clc
    lda page_index
    adc cursor_index
    tax
    lda #<buffer
    sta $57
    lda #>buffer
    sta $58

    cpx #0
    beq +
-   clc
    lda $57
    adc #$10
    sta $57
    lda $58
    adc #0
    sta $58
    dex
    bne -

+   ldy #0
-   lda ($57),y
    cmp #$a0
    beq +
    iny
    cpy #$10
    bcc -

+   tya
    ldx $57
    ldy $58
    jsr setnam
    lda #$01
    ldx devicenum
    ldy #$02
    jsr setlfs
    jsr open
    jsr ret_to_parent_if_err
    ldx #$01
    jsr chkin
    jsr ret_to_parent_if_err
    jsr chrin
    jsr ret_to_parent_if_err
    sta $5b
    jsr chrin
    jsr ret_to_parent_if_err
    sta $5c
    jsr clrchn
    lda #$01
    jsr close

    lda $5c
    cmp $2c
    bne +
    lda $5b
    cmp $2b
    beq ++

+   lda $5b
    cmp #$01
    bne +

++  dec $5a
+   ldx #<loading
    ldy #>loading
    jsr strout

    ldy #0
-   lda ($57),y
    jsr display_char
    iny
    cpy #$10
    bne -

    ldx #<space_rvs_dir
    ldy #>space_rvs_dir
    jsr strout
    lda $5c
    jsr hexbyteout
    lda $5b
    jsr hexbyteout
    ldx #<unrvs_cr_cr
    ldy #>unrvs_cr_cr
    jsr strout

; copy loader to $700
    ldx #(loader_end-loader)
-   lda loader-1,x
    sta $06ff,x
    lda $d021
    sta $daff,x
    dex
    bne -

; execute loader
    jmp $0700

hexbyteout:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr hexdigitout
    pla
    and #$0f
    jsr hexdigitout
    rts

hexdigitout:
    ora #$30
    cmp #$3a
    bcc +
    adc #$06
+   jsr chrout
    rts

loader
    lda #0
    ldx devicenum
    ldy $5a
    jsr setlfs
    lda #0
    ldx $2b
    ldy $2c
    jsr loadfile
    bcs ++
    lda $5a
    bne +
    stx $2d
    sty $2e
    jsr $a533 ; linkprg - relink lines of tokenized program text
    jsr $a65e ; clear - perform clr
    jsr $a68e ; runc - reset current text to program text start
    jmp $a7ae ; newstt - set up next statement for execution
+   jsr $fd02 ; check for autostart cartridge
    beq +
-   jmp ($005b)
+   lda $59
    eor #$80
    beq -
    jmp ($fffc) ; soft reset via vector
++  ldx #$1d
    jmp $a437 ; error - general error handler
loader_end

draw_names
    lda #$7a
    sta $57
    lda #$04
    sta $58
    ldx cursor_index
    cpx #$15
    bcc +
    clc
    lda $57
    adc #20
    sta $57
    lda $58
    adc #0
    sta $58
    txa
    sec
    sbc #21
    tax
+   cpx #0
    beq +
-   clc
    lda $57
    adc #40
    sta $57
    lda $58
    adc #0
    sta $58
    dex
    bne -
+   ldy #0
-   lda ($57),y
    eor #$80
    sta ($57),y
    iny
    cpy #$10
    bcc -
    rts

draw_screen
    ldx #38
    lda #$40 ; petscii horiz. line
-   sta $0400,x
    sta $0450,x
    sta $07c0,x
    dex
    bne -
    lda #40 ; petscii horiz. line
    sta $57
    lda #$04
    sta $58
    ldx #$17
-   lda #$5d ; petscii vert. line
    ldy #0
    sta ($57),y
    ldy #$13
    sta ($57),y
    ldy #$27
    sta ($57),y
    clc
    lda $57
    adc #40
    sta $57
    lda $58
    adc #0
    sta $58
    dex
    bne -
    lda #$70 ; upper left corner lines petscii
+   sta $0400
    lda #$6e ; upper right corner lines petscii
    sta $0427
    lda #$6b ; vert. line w/ line to right
    sta $0450
    lda #$72 ; horiz. line w/ line down
    sta $0463
    lda #$73 ; vert. line w/ line to left
    sta $0477
    lda #$6d ; lower left corner lines petscii
    sta $07c0
    lda #$71 ; horiz. line w/ line up
    sta $07d3
    lda #$7d ; lower right corner lines petscii
    sta $07e7
    ldx #<down_right_rvs
    ldy #>down_right_rvs
    jsr strout
    ldx #0
-   lda buffer,x
    jsr display_char
    inx
    cpx #16
    bcc -
    lda #$92 ; rvsoff
    jsr chrout
    lda #' '
    jsr chrout
    ldx #<title
    ldy #>title
    jsr strout
    rts

display_dir_page
    sec
    lda num_files
    sbc page_index
    sta files_rem

; multiply page_index by 16, store result in $57/$58
    clc
    lda #0
    sta $57
    sta $58
    ldx #16
-   lda $57
    adc page_index
    sta $57
    lda $58
    adc #0
    sta $58
    dex
    bne -

; add offset to buffer
    lda $57
    adc #<buffer
    sta $57
    lda $58
    adc #>buffer
    sta $58

    lda #$13 ; home
    jsr chrout
    lda #$11 ; down
    jsr chrout
    jsr chrout
    jsr chrout
    ldx #0
--  lda #$02
    sta cursorcol
    cpx #21
    bcc +
    lda #22 ; start of second column of filenames
    sta cursorcol

+   ldy #0
-   lda ($57),y
    cpx files_rem
    bcc +
    lda #' '
+   jsr display_char
    iny
    cpy #16
    bcc -

    lda #13 ; cr
    jsr chrout
    clc
    lda $57
    adc #$10
    sta $57
    lda $58
    adc #0
    sta $58
    inx
    cpx #$15
    bcc --
    bne +
    lda #$13 ; home
    jsr chrout
    lda #$11 ; down
    jsr chrout
    jsr chrout
    jsr chrout
    jmp --

+   cpx #$2a
    bcc --
    rts

display_char
    bit ctlr_char
    bne +
    pha
    lda #$12 ; rvs
    jsr chrout
    pla
    adc #$40
    jsr chrout
    lda #$92 ; rvsoff
+   jsr chrout
    cmp #$22 ; double quote
    bne +
    dec cursorcol
    jsr chrout
+   rts

applycolors:
    lda bg_choice
    sta $d021 ; background color register
    lda border_choice
    sta $d020 ; border color register
    lda fg_choice
    sta $0286 ; foreground color kernal variable

; fill color memory with .a
    ldy #0
-   sta $d800,y
    sta $d900,y
    sta $da00,y
    sta $db00,y
    iny
    bne -
    rts

strout
    stx $5d
    sty $5e
    ldy #0
-   lda ($5d),y
    beq +
    jsr chrout
    iny
    bne -
+   rts

directory
    !byte "$"

down_right_rvs
    !byte $11,$1D,$12,0

title
    !text "DAVEVW.COM'S EASYMENU"
    !byte 0

loading
    !byte $93,$11,$1D
    !text "LOADING "
    !byte 0

no_files
    !byte $13,$11,$11,$11,$1D,$1D
    !text "NO FILES"
    !byte 0

drive_not_present
    !byte $13,$11,$1D,$12
    !text "DRIVE NOT PRESENT"
    !byte $92,0

writing
    !byte $93,$11,$1D
    !text "WRITING "
    !byte 0

space_rvs_dir
    !byte $20,$12
    !byte "$",0

unrvs_cr_cr
    !byte $92,$0D,$0D,0

scratch
    !text "S:" ; continues with program_name
program_name
    !text "EASYMENU"
    !byte 0

ctlr_char ; non-zero displays as inverse petascii (intended use, unused in original)
    !byte $60
    
bg_choice
    !byte 1

border_choice
    !byte 3

fg_choice
    !byte 6

devicenum
    !byte 8

num_files=* ; 0..254 number of files loaded from directory (255=not loaded)
page_index=num_files+1 ; directory index (starts at zero) of first filename shown on screen
files_rem=page_index+1 ; number of filenames on current screen and any further screens
cursor_index=files_rem+1 ; index of current selection (top left starts at zero, top right starts at 21)
joy2_last=cursor_index+1 ; last joystick read, for detecting changes

buffer = joy2_last+1
max_files = ($d000-buffer)/16