
    * = $C000       ; Tell the assembler this code goes at $C000

VIC_CTRL_1      = $d011
VIC_CTRL_2      = $d016
VIC_RASTER      = $d012
VIC_MEM_CTRL    = $d018

CIA2_PORT_A     = $dd00

PT_LOW          = $FB
PT_HIGH         = $FC


    LDA VIC_CTRL_1          ; VIC mode
    ORA #$20                ; Set graphics mode
    STA VIC_CTRL_1          ; Write it back
    
    LDA CIA2_PORT_A         ; VIC memory bank
    AND #%11111100
    ORA #1                  ; 01 for $8000, 03 for $0000
    STA CIA2_PORT_A

    LDA VIC_MEM_CTRL        ; VIC memory base address
    AND #$F0
    ORA #$08                ; 08 for $2000, added to $8000 above
    STA VIC_MEM_CTRL

; --- clear mem ----------------------------------------------------------------

; clear all from a000 - bfff

    LDA #$00
    STA PT_LOW              ; Low byte of target address
    LDA #$A0
    STA PT_HIGH             ; High byte

@loop1:
    LDA #$01                ; no pixels set
    JSR ClearPage
    LDA PT_HIGH
    CLC
    ADC #1
    STA PT_HIGH
    CMP #$C0
    BNE @loop1
    
; clear all from 8400 - 84ff: Default is 1024

    LDA #$00
    STA PT_LOW              ; Low byte of target address
    LDA #$84
    STA PT_HIGH             ; High byte

@loop2:
    LDA #$10                ; white foreground, black background
    JSR ClearPage
    LDA PT_HIGH
    CLC
    ADC #1
    STA PT_HIGH
    CMP #$88
    BNE @loop2

; start main loop

    LDX #0
MainLoop:
    STX VIC_CTRL_2              ; store h scroll
    JSR WaitForFrame
    INX
    TXA
    AND #7
    TAX
    JMP MainLoop

    RTS

; ---------------------------------------------------------------










ClearPage:
    LDY #$00        ; Y will index from 0 to 255

ClearPageLoop:
    STA (PT_LOW),Y     ; Store 0 at address ($FB) + Y
    INY
    BNE ClearPageLoop   ; Loop until Y wraps back to 0 (after 256 iterations)

    RTS             ; Done


WaitForFrame:
    lda VIC_CTRL_1
    and #$80
    bne WaitForFrame

@WaitLow:
    lda VIC_RASTER
    cmp #$00
    bne WaitLow

    rts


; Input: X in PT_LOW, Y in PT_HIGH
; Output: Pixel set in bitmap at ($2000 + offset)

    ; example values
    LDA #100     ; X = 100
    STA PT_LOW
    LDA #50      ; Y = 50
    STA PT_HIGH

SetPixel:
    ; Load X and Y
    LDA PT_HIGH         ; Y
    LDX #40
    JSR Multiply    ; result in $FD/$FE = Y * 40

    LDA PT_LOW
    LSR A
    LSR A
    LSR A           ; X / 8
    CLC
    ADC $FE         ; low byte of Y*40 + (X / 8)
    STA $00         ; low byte of offset

    LDA $FD
    ADC #$00        ; carry from previous ADC
    STA $01         ; high byte of offset

    ; Set bit in the byte
    LDA PT_LOW
    AND #7
    EOR #7          ; Bit position = 7 - (X AND 7)
    TAX
    LDA BitMaskTable,X  ; Get mask to set bit

    LDY #$20        ; Bitmap at $2000
    LDX #$00
    CLC
    LDA $00
    ADC #$00
    STA $02         ; address = $2000 + offset
    LDA $01
    ADC #$20
    STA $03

    LDY #$00
    LDA ($02),Y
    ORA BitMask     ; set the bit
    STA ($02),Y

    RTS

; Lookup table for setting bits: %10000000, %01000000, ..., %00000001
BitMaskTable:
    .BYTE $80, $40, $20, $10, $08, $04, $02, $01

; Multiply Y * 40 (8-bit x 8-bit)
; Input: A = Y, X = 40
; Output: $FD/$FE = 16-bit result
Multiply:
    STX $02
    STA $03
    LDA #0
    STA $FD
    STA $FE
    LDX #8
MulLoop:
    ASL $03
    ROL $FE
    ROL $FD
    BCC SkipAdd
    CLC
    LDA $FE
    ADC $02
    STA $FE
    LDA $FD
    ADC #0
    STA $FD
SkipAdd:
    DEX
    BNE MulLoop
    RTS





