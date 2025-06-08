    * = $C000       ; Tell the assembler this code goes at $C000

    LDA $D011      ; VIC mode
    ORA #$20       ; Set bit 5 (OR with 32)
    STA $D011      ; Write it back

    LDA $DD00
    AND #$FC
    ORA #$01
    STA $DD00

    LDA #$00
    STA $FB         ; Low byte of target address
    LDA #$40
    STA $FC         ; High byte

    JSR ClearPage
    RTS

ClearPage:
    LDY #$00        ; Y will index from 0 to 255
    LDA #$00        ; Value to store (zero)

ClearPageLoop:
    STA ($FB),Y     ; Store 0 at address ($FB) + Y
    INY
    BNE ClearPageLoop   ; Loop until Y wraps back to 0 (after 256 iterations)

    RTS             ; Done
