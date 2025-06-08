
    * = $C000       ; Tell the assembler this code goes at $C000

VIC_CTRL_1      = $d011
VIC_CTRL_2      = $d016
VIC_RASTER      = $d012
VIC_MEM_CTRL    = $d018

CIA2_PORT_A     = $dd00

PT_LOW          = $FB
PT_HIGH         = $FC

PT2_LOW         = $FD
PT2_HIGH        = $FE

;FRAME_BUFFER        = $a000
;FRAME_COL           = $8400

;FRAME_BUFFER        = $2000
;FRAME_COL           = $0400

FRAME_BUFFER        = $8000
FRAME_COL           = $a000
        
X_LO       = $FB
X_HI       = $FC
Y          = $FD


    LDA VIC_CTRL_1          ; VIC mode
    ORA #$20                ; Set graphics mode
    STA VIC_CTRL_1          ; Write it back

    JSR VICConfig2

; --- clear mem ----------------------------------------------------------------

; clear all from a000 - bfff

    LDA #>FRAME_BUFFER
    STA PT_HIGH             ; High byte
    CLC
    ADC #$20
    STA ClearPagesEnd
    LDA #$66                 ; no pixels set
    STA ClearPagesValue

    JSR ClearPages

; clear all from 8400 - 84ff: Default is 1024

    LDA #>FRAME_COL
    STA PT_HIGH             ; High byte
    CLC
    ADC #$08
    STA ClearPagesEnd
    LDA #$10                ; white foreground, black background
    STA ClearPagesValue

    JSR ClearPages

; write test pixel

    LDA     #1
    STA     Y
    LDA     #<319
    STA     X_LO
    LDA     #>319
    STA     X_HI

    JSR     SetPixel

;    JSR     RandomStuff         

; start main byte scroll loop

ScrollLoop:
    LDA #>FRAME_BUFFER
    STA PT_HIGH
    LDA #$08
    STA PT_LOW

    LDA #>FRAME_BUFFER
    STA PT2_HIGH
    LDA #$00
    STA PT2_LOW

    LDA #>FRAME_BUFFER
    CLC
    ADC #$1F
    STA MovePagesEnd

    JSR MovePages

    JSR DeleteColumn

    LDX Time
    INX
    STX Time

    LDA SineTable,X

    JMP ScrollLoop

; start main loop

    LDX #0
MainLoop:
;    STX VIC_CTRL_2              ; store h scroll
    JSR WaitForFrame
    INX
    TXA
    AND #7
    TAX
    JMP MainLoop

    RTS

; ---------------------------------------------------------------

; Globals

Time
    .BYTE 0

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
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    BNE ClearPageLoop   ; Loop until Y wraps back to 0 (after 256 iterations)

    RTS             ; Done

MovePagesEnd
    .BYTE 0

MovePages:
    JSR MovePage

    LDA PT2_HIGH
    CLC
    ADC #1
    STA PT2_HIGH

    LDA PT_HIGH
    CLC
    ADC #1
    STA PT_HIGH

    CMP MovePagesEnd
    BNE MovePages
    RTS

MovePage:
    LDY #$00

MovePageLoop:
    LDA (PT_LOW),Y
    STA (PT2_LOW),Y
    INY
    BNE MovePageLoop

    RTS

DeleteColumn:
    LDA #>FRAME_BUFFER
    CLC
    ADC #01
    STA PT_HIGH
    LDA #$38
    STA PT_LOW
    LDY #$00

    LDX #$29

Deletecolloop:
    JSR DeleteBlock
    LDA PT_LOW
    CLC
    ADC #$40
    STA PT_LOW
    LDA PT_HIGH
    ADC #$01
    STA PT_HIGH

    DEX
    BNE DeleteColLoop

    RTS

DeleteBlock:
    LDA #$00
    LDY #$00
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y
    INY
    STA (PT_LOW),Y     ; Store A at address ($FB) + Y

    RTS

VICConfig1:
    ; memory bank at $0000
    ; framebuffer at $2000
    ; colorbuffer at $0400
        
    LDA CIA2_PORT_A         ; VIC memory bank
    AND #%11111100
    ORA #3
    STA CIA2_PORT_A

    LDA #%00011000
    STA VIC_MEM_CTRL

    RTS

VICConfig2:
    ; memory bank at $8000
    ; framebuffer at $8000
    ; colorbuffer at $9000

    LDA CIA2_PORT_A         ; VIC memory bank
    AND #%11111100
    ORA #1
    STA CIA2_PORT_A

    LDA #%10000000
    STA VIC_MEM_CTRL

    RTS

SineTable:
    .BYTE 47, 45, 42, 40, 38, 36, 33, 31, 29, 27, 25, 24, 22, 20, 19, 17, 15, 14, 13, 11, 10, 9, 8, 7, 6, 5, 4, 4, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 19, 20, 22, 24, 25, 27, 29, 31, 33, 36, 38, 40, 42, 45, 47, 49, 52, 54, 57, 60, 62, 65, 68, 70, 73, 76, 79, 82, 85, 88, 91, 94, 97, 100, 103, 106, 109, 112, 115, 118, 121, 124

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
Y_OFF    = $09



BitMaskTable:
    .BYTE $80, $40, $20, $10, $08, $04, $02, $01


SetPixel:

    ; --- Step 1: Compute 7 - (X AND 7) ---
    LDA X_LO
    AND #$07      ; X MOD 8
    STA BIT_INDEX

    LDA X_LO
    AND #$F8      ; & ~7
    STA X_LO

    LDA Y
    AND #$7
    STA Y_OFF


    ; --- Step 3: Multiply Y * 40 ---
    ; Input: A = Y, Multiplier = 40
    LDA Y
    AND #$f8
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

    CLC
    LDA ADDR_LO
    ADC Y_OFF
    STA ADDR_LO
    LDA ADDR_HI
    ADC #0

    ; --- Step 5: Add $8000 base address ---
    CLC
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

; ---------------------------------------------------------------

; debugging

; Draw some random stuff

RandomStuff:
    LDA #$20
    STA PT_HIGH
    LDA #$00
    STA PT_LOW
    LDY #$20
    LDA #$06
    STA (PT_LOW),Y
    
    LDY #$40
    LDA #$36
    STA (PT_LOW),Y

    LDY #$46
    LDA #$38
    STA (PT_LOW),Y

    LDY #$86
    LDA #$41
    STA (PT_LOW),Y

    LDA #$23
    STA PT_HIGH
    LDY #$83
    LDA #$46
    STA (PT_LOW),Y

    RTS
