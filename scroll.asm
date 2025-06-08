    * = $C000       ; Tell the assembler this code goes at $C000

    LDA $D011      ; VIC mode
    ORA #$20       ; Set graphics mode
    STA $D011

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

    RTS

ClearPage:
    LDY #$00        ; Y will index from 0 to 255
    LDA #$01        ; Value to store (zero)

ClearPageLoop:
    STA ($FB),Y     ; Store 0 at address ($FB) + Y
    INY
    BNE ClearPageLoop   ; Loop until Y wraps back to 0 (after 256 iterations)

    RTS             ; Done

