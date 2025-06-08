
    * = $C000       ; Tell the assembler this code goes at $C000

VIC_CTRL_1      = $d011
VIC_CTRL_2      = $d016
VIC_RASTER      = $d012
VIC_MEM_CTRL    = $d018

CIA2_PORT_A     = $dd00

PT_LOW          = $FB
PT_HIGH         = $FC

FRAME_BUFFER        = $a000
FRAME_COL           = $8400


X_LO       = $FB
X_HI       = $FC
Y          = $FD



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

    LDA #>FRAME_BUFFER
    STA PT_HIGH             ; High byte
    LDA #$C0
    STA ClearPagesEnd
    LDA #$0                 ; no pixels set
    STA ClearPagesValue

    JSR ClearPages

; clear all from 8400 - 84ff: Default is 1024

    LDA #>FRAME_COL
    STA PT_HIGH             ; High byte
    LDA #$88
    STA ClearPagesEnd
    LDA #$10                ; white foreground, black background
    STA ClearPagesValue

    JSR ClearPages

; write test pixel

    LDA     #1
    STA     Y
    LDA     #<318
    STA     X_LO
    LDA     #>318
    STA     X_HI

    JSR     SetPixel

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

ClearPagesValue
    .BYTE 0

ClearPagesEnd
    .BYTE 0

; Clear pages from PT_HIGH to ClearPagesEnd with ClearPagesValue
ClearPages:
    LDA #$00
    STA PT_LOW              ; Low byte of target address

    LDA ClearPagesValue
    JSR ClearPage
    LDA PT_HIGH
    CLC
    ADC #1
    STA PT_HIGH
    CMP ClearPagesEnd
    BNE ClearPages
    RTS

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



BIT_INDEX  = $FE

ADDR_LO     = $04
ADDR_HI     = $05

BIT_MASK   = $08



BitMaskTable:
    .BYTE $80, $40, $20, $10, $08, $04, $02, $01


SetPixel:
    ; --- Step 1: Compute 7 - (X AND 7) ---
    LDA X_LO
    AND #$07      ; X MOD 8
    EOR #$07      ; Bit = 7 - (X MOD 8)
    STA BIT_INDEX

    ; --- Step 2: Compute X / 8 ---
    LSR X_HI
    ROR X_LO
    LSR X_HI
    ROR X_LO
    LSR X_HI
    ROR X_LO

    ; --- Step 3: Multiply Y * 40 ---
    ; Input: A = Y, Multiplier = 40
    LDA Y
    LDX #40
    JSR Multiply      ; result in ADDR_LO/ADDR_HI

    ; --- Step 4: Add (X / 8) to result ---
    CLC
    LDA ADDR_LO
    ADC X_LO
    STA ADDR_LO

    LDA ADDR_HI
    ADC X_HI
    STA ADDR_HI

    ; --- Step 5: Add $8000 base address ---
    CLC
    LDA ADDR_HI
    ADC #>FRAME_BUFFER
    STA ADDR_HI

    ; --- Step 6: Load mask and set bit ---
    LDY BIT_INDEX
    LDA BitMaskTable,Y
    STA BIT_MASK

    LDY #0
    LDA (ADDR_LO),Y
    ORA BIT_MASK
    STA (ADDR_LO),Y

    RTS


Multiply:
    ; A = multiplier 1 (Y), X = multiplier 2 (40)
    STA $00
    STX $01
    LDA #0
    STA ADDR_LO
    STA ADDR_HI
    LDX #8
MulLoop:
    LSR $00         ; Shift right multiplicand
    BCC NoAdd
    CLC
    LDA ADDR_LO
    ADC $01
    STA ADDR_LO
    LDA ADDR_HI
    ADC #0
    STA ADDR_HI
NoAdd:
    ASL $01         ; Shift multiplier left
    DEX
    BNE MulLoop
    RTS
