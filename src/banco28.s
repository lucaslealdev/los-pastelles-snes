; Rotinas no banco 28 (o banco 0 esta cheio). Chamadas com JSL e voltam com RTL;
; rotinas do banco 0 sao chamadas com FAR0 (macros.inc).
.segment "BANK28"

; ---------------------------------------------------------------- impedimentos do dia
; Chamado no inicio de PreDayInit. C=1 se o dia nao pode comecar: ja preparou a
; carta de aviso (e o proximo estado). Hoje o unico impedimento e ficar sem estoque.
DiaBloqueado:
    .a8
    .i16
    lda s_tflags
    and #VENTO_BIT          ; pastel de vento nao gasta estoque
    bne @livre
    A16
    lda s_stock
    A8
    bne @livre
    FAR0 CardReset
    ; sem dinheiro nem para o estoque: o mestre da 10 porcoes e o dia segue
    A16
    lda s_money+2
    bne @compra
    lda s_money
    cmp #30
    bcs @compra
    lda #10
    sta s_stock
    A8
    lda #CARD_FALIU
    FAR0 CardAdd
    lda #ST_PREDAY
    bra @vai
@compra:
    ; da para comprar: aviso com {A} loja / {B} menu
    A8
    lda #CARD_SEMESTOQUE
    FAR0 CardAdd
    lda #ST_SHOP
@vai:
    FAR0 CardGo
    sec
    rtl
@livre:
    clc
    rtl

; A = carta mostrada agora
CartaAtual:
    .a8
    .i16
    A16
    lda card_i
    and #$00FF
    tax
    A8
    lda card_q,x
    rts

; {B} na carta de falta de estoque: volta ao menu principal
CardBotaoB:
    .a8
    .i16
    lda pad_new+1
    and #KH_B
    beq @r
    jsr CartaAtual
    cmp #CARD_SEMESTOQUE
    bne @r
    lda #SFX_CURSOR
    FAR0 PlaySfx
    lda #ST_TITLE
    sta next_state
    ldx #0                  ; {A} no mesmo quadro nao desfaz a escolha
    stx pad_new
@r: rtl

; rodape da carta: a de falta de estoque mostra as duas saidas
CardRodape:
    .a8
    .i16
    jsr CartaAtual
    ldx #TXT_C_A
    cmp #CARD_SEMESTOQUE
    bne :+
    ldx #TXT_C_LOJA
:   lda #26
    FAR0 Footer
    rtl

; ---------------------------------------------------------------- grafico de lucro (resultado)
DrawChart:
    .a8
    .i16
    FAR0 ClearBg3
    PRINT0 TXT_G_TIT, 3, 3, 5
    lda hist_n
    bne :+
    PRINT0 TXT_G_VAZIO, 3, 10, 4
    jmp @foot
:   ; maior valor absoluto -> passo = max/8 (minimo 1)
    ldx #0
    stx tmp2
    stx tmp4
@mx:
    A16
    lda hist,x
    bpl :+
    eor #$FFFF
    inc a
:   cmp tmp2
    bcc :+
    sta tmp2
:   A8
    inx
    inx
    cpx #14
    bne @mx
    A16
    lda tmp2
    lsr a
    lsr a
    lsr a
    bne :+
    lda #1
:   sta tmp2            ; passo
    lda #0
    sta tmp4            ; melhor dia
    A8
    ; barras: entradas 7-n..6
    lda #7
    sec
    sbc hist_n
    sta loop_i
@bar:
    lda loop_i
    cmp #7
    bcc :+
    jmp @foot
:   A16
    and #$00FF
    asl a
    tax
    lda hist,x
    sta tmp3
    bmi :+
    cmp tmp4
    bcc :+
    sta tmp4
:   ; altura = |v| / passo
    lda tmp3
    bpl :+
    eor #$FFFF
    inc a
:   ldy #0
@dv:
    cmp tmp2
    bcc @dvd
    sec
    sbc tmp2
    iny
    cpy #8
    bne @dv
@dvd:
    A8
    ; coluna = 4 + 3*(i - (7-n))
    lda #7
    sec
    sbc hist_n
    sta num_pad
    lda loop_i
    sec
    sbc num_pad
    stz num_pad
    sta num            ; k
    asl a
    clc
    adc num
    clc
    adc #4
    sta num            ; coluna
    lda tmp3+1
    bmi @neg
    ; positiva: linhas 16, 15, ... para cima
    lda #16
    sta num+1
@pl:
    cpy #0
    beq @lbl
    jsr ChartCell6
    dec num+1
    dey
    bra @pl
@neg:
    cpy #5
    bcc :+
    ldy #4
:   lda #17
    sta num+1
@nl:
    cpy #0
    beq @lbl
    jsr ChartCell5
    inc num+1
    dey
    bra @nl
@lbl:
    ; numero do dia embaixo (linha 22)
    lda num
    sta num_w+1
    A16
    lda s_day
    sec
    sbc #7
    sta num+2
    lda loop_i
    and #$00FF
    clc
    adc num+2
    sta num+2
    A8
    lda num_w+1
    A16
    and #$00FF
    clc
    adc #(22*32)
    sta txt_pos
    lda num+2
    sta num
    stz num+2
    A8
    lda #((4<<2)|$20)
    sta txt_attr
    lda #3
    sta num_w
    FAR0 PrintNum
    inc loop_i
    jmp @bar
@foot:
    PRINT0 TXT_G_MELHOR, 3, 24, 6
    PRINT0 TXT_G_RS, 10, 24, 6
    PRINTNUM16_0 tmp4, 13, 24, 6, 5
    ldx #TXT_R_CONT
    lda #26
    FAR0 Footer
    rtl

; bloco cheio na coluna num (2 tiles) e linha num+1: paleta 6 (verde) / 5 (vermelho)
ChartCell6:
    .a8
    .i16
    lda #((6<<2)|$20)
    bra ChartCell
ChartCell5:
    .a8
    .i16
    lda #((5<<2)|$20)
ChartCell:
    sta txt_attr
    phy
    A16
    lda num+1
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta txt_pos
    lda num
    and #$00FF
    clc
    adc txt_pos
    asl a
    tax
    A8
    lda #FONT_BOX
    sta bg3_buf,x
    sta bg3_buf+2,x
    lda txt_attr
    sta bg3_buf+1,x
    sta bg3_buf+3,x
    lda #1
    sta bg3_dirty
    ply
    rts


; ---------------------------------------------------------------- mao do jogador
; Ao lado do cursor: mao (emoji) com o que o jogador segura em cima dos dedos
; (sabor 8x8 do pastel pronto e/ou a latinha do combo). Mao vazia nao mostra nada.
; Chamado por DayDraw logo depois do cursor: spr_x/spr_y ainda sao os do cursor
; (com a balancada), entao a mao acompanha o movimento. Termina com spr_size = 1.
MAO_DX = 11                 ; canto da mao em relacao ao cursor
MAO_DY = 3
MaoSprites:
    .a8
    .i16
    lda hold_flav
    cmp #$FF
    bne @tem
    lda hold_soda
    bne @tem
    rtl
@tem:
    A16
    lda spr_x
    clc
    adc #MAO_DX
    sta spr_x
    A8
    lda spr_y
    clc
    adc #MAO_DY
    sta spr_y
    lda #$30
    sta spr_attr
    stz spr_size
    ; itens antes da mao (slot menor fica na frente)
    lda hold_flav
    cmp #$FF
    beq @soda
    clc
    adc #<SPR_MINI
    sta spr_tile
    lda #>SPR_MINI
    adc #0
    sta spr_tile+1
    lda #7                  ; sabor sobre as pontas dos dedos
    ldy #$FFFB
    jsr MaoItem
@soda:
    lda hold_soda
    beq @mao
    A16
    lda #SPR_REFRI_P
    sta spr_tile
    A8
    lda #1                  ; latinha sobre o polegar
    ldy #$FFFC
    jsr MaoItem
@mao:
    A16
    lda #SPR_MAO
    sta spr_tile
    A8
    lda #1
    sta spr_size
    FAR0 AddSprite
    rtl

; sprite 8x8 em (mao + A, mao + Y), sem mexer na posicao da mao
MaoItem:
    .a8
    .i16
    sta tmp
    A16
    lda spr_x
    pha
    lda tmp
    and #$00FF
    clc
    adc spr_x
    sta spr_x
    A8
    lda spr_y
    pha
    tya
    clc
    adc spr_y
    sta spr_y
    FAR0 AddSprite
    pla
    sta spr_y
    A16
    pla
    sta spr_x
    A8
    rts
