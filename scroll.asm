
    * = $C000       ; Tell the assembler this code goes at $C000

VIC_CTRL_1      = $d011
VIC_RASTER      = $d012
VIC_CTRL_2      = $d016


    LDA VIC_CTRL_1      ; VIC mode
    ORA #$20            ; Set graphics mode
    STA VIC_CTRL_1      ; Write it back
    
    LDA $DD00      ; VIC memory bank
    AND #$FC
    ORA #$01       ; 01 for $8000, 03 for $0000
    STA $DD00

    LDA $D018      ; VIC memory base address
    AND #$F0
    ORA #$08       ; 08 for $2000
    STA $D018

    LDA #$00
    STA $FB         ; Low byte of target address
    LDA #$A0
    STA $FC         ; High byte
    JSR ClearPage

    LDA #$00
    STA $FB
    LDA #$84
    STA $FC
    JSR ClearPage

    LDX #0
MainLoop:
    STX VIC_CTRL_2      ; store h scroll
    JSR WaitForFrame
    INX
    TXA
    AND #7
    TAX
    JMP MainLoop

    RTS

ClearPage:
    LDY #$00        ; Y will index from 0 to 255
    LDA #$01        ; Value to store (zero)

ClearPageLoop:
    STA ($FB),Y     ; Store 0 at address ($FB) + Y
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



