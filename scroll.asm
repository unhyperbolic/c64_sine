    * = $C000       ; Tell the assembler this code goes at $C000

    LDA #$00
    STA $FB         ; Low byte of target address
    LDA #$20
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
