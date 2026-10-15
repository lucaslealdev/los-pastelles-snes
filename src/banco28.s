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

; ---------------------------------------------------------------- fim do dia (resultado)
; Pagina 1 do resultado: um icone emoji no lugar de cada rotulo (folha
; gen/icon_res_*, carregada nos tiles OBJ 0-95 como os icones da loja).
; Coluna da esquerda: entradas (verde); da direita: saidas (vermelho).
; Icones centrados na linha do texto (y = linha*8 - 4), como na loja.
ICR_DIA    = 0              ; ordem de ICONES_RES em gerador/icones.py
ICR_CLI    = 1
ICR_PERF   = 2
ICR_LIXO   = 3
ICR_ENTR   = 4
ICR_VEND   = 5
ICR_GORJ   = 6
ICR_UNID   = 7
ICR_ALUG   = 8
ICR_SAL    = 9
ICR_LUCRO  = 10
ICR_PREJ   = 11
ICR_CAIXA  = 12
ICR_REP    = 13
ICR_NIVEL  = 14
ICR_XP     = 15
ICR_SUBIU  = 16
ICR_DESAF  = 17
ICR_FALHOU = 18
ICR_MISSAO = 19
ICR_GRAF   = 20
ICR_MELHOR = 21
RES_XE = 20                 ; x do icone da coluna esquerda (texto na coluna 5)
RES_XD = 124                ; x do icone da coluna direita (texto na coluna 18)

; posicao e paleta do proximo texto (TxtEsq/NumEsq avancam a posicao)
.macro RPOS col, row, pal
    ldx #((row)*32+(col))
    stx txt_pos
    lda #(((pal)<<2)|$20)
    sta txt_attr
.endmacro
.macro RTXT str
    ldx #str
    jsr TxtEsq
.endmacro
.macro RNUM8 var
    A16
    lda var
    and #$00FF
    sta num
    stz num+2
    A8
    jsr NumEsq
.endmacro
.macro RNUM16 var
    A16
    lda var
    sta num
    stz num+2
    A8
    jsr NumEsq
.endmacro
.macro RICO ico, xx, row
    lda #ico
    ldx #xx
    ldy #((row)*8-4)
    jsr IcoRes
.endmacro

DrawResults:
    .a8
    .i16
    ; folha de icones do resultado (a tela esta desligada)
    ldx #VRAM_OBJ
    stx VMADDL
    ldx #.loword(IconResGfx)
    stx dma_src
    lda #^IconResGfx
    sta dma_src+2
    ldx #(IconResGfx_end - IconResGfx)
    stx dma_len
    FAR0 DmaVram
    ldx #.loword(IconResPal)
    stx dma_src
    lda #^IconResPal
    sta dma_src+2
    ldx #(176*2)            ; paletas OBJ 3..6
    ldy #128
    FAR0 CopyPal
    FAR0 OamClear
    ; titulo
    RICO ICR_DIA, RES_XE, 3
    RPOS 5, 3, 5
    RTXT TXT_R_FIM
    RNUM16 s_day
    ; o dia: clientes, perfeitos, desperdicio e entregas
    RICO ICR_CLI, RES_XE, 6
    RPOS 5, 6, 4
    RNUM8 d_served
    RTXT TXT_HUD_BAR
    RNUM8 d_total
    RICO ICR_PERF, RES_XD, 6
    RPOS 18, 6, 4
    RNUM8 d_perfect
    RICO ICR_LIXO, RES_XE, 8
    RPOS 5, 8, 4
    RNUM8 d_waste
    lda s_level
    cmp #TEL_LV
    bcc @noent
    RICO ICR_ENTR, RES_XD, 8
    RPOS 18, 8, 7
    RNUM8 d_deliv
    RTXT TXT_R_ENTR
    RNUM16 d_dvsales
@noent:
    ; entradas
    RICO ICR_VEND, RES_XE, 11
    RPOS 5, 11, 6
    RTXT TXT_R_MAIS
    RNUM16 d_sales
    RICO ICR_GORJ, RES_XE, 13
    RPOS 5, 13, 6
    RTXT TXT_R_MAIS
    RNUM16 d_tips
    A16
    lda r_other             ; sem outras lojas/franquias: nem mostra
    A8
    beq @nooutr
    RICO ICR_UNID, RES_XE, 15
    RPOS 5, 15, 6
    RTXT TXT_R_MAIS
    RNUM16 r_other
@nooutr:
    ; saidas
    RICO ICR_ALUG, RES_XD, 11
    RPOS 18, 11, 5
    RTXT TXT_R_MENOS
    RNUM16 r_rent
    A16
    lda r_salary            ; sem atendente nem motoboy: nem mostra
    A8
    beq @nosal
    RICO ICR_SAL, RES_XD, 13
    RPOS 18, 13, 5
    RTXT TXT_R_MENOS
    RNUM16 r_salary
@nosal:
    ; lucro ou prejuizo do dia e caixa
    A16
    lda r_profit
    bmi @neg
    A8
    RICO ICR_LUCRO, RES_XE, 18
    RPOS 5, 18, 6
    RTXT TXT_R_MAIS
    bra @lucro
@neg:
    .a16
    eor #$FFFF
    inc a
    sta r_profit
    A8
    RICO ICR_PREJ, RES_XE, 18
    RPOS 5, 18, 5
    RTXT TXT_R_MENOS
@lucro:
    RNUM16 r_profit
    RICO ICR_CAIXA, RES_XD, 18
    RPOS 18, 18, 7
    RTXT TXT_R_RS
    A16
    lda s_money
    sta num
    lda s_money+2
    sta num+2
    A8
    jsr NumEsq
    ; reputacao, nivel (confete se subiu) e experiencia
    RICO ICR_REP, RES_XE, 20
    RPOS 5, 20, 4
    RNUM8 s_rep
    RTXT TXT_R_100
    RICO ICR_NIVEL, RES_XD, 20
    lda r_levels
    beq @nv
    RPOS 18, 20, 6
    RNUM8 s_level
    RICO ICR_SUBIU, 164, 20  ; ao lado do numero (ate 2 digitos)
    bra @xp
@nv:
    RPOS 18, 20, 4
    RNUM8 s_level
@xp:
    RICO ICR_XP, RES_XE, 22
    RPOS 5, 22, 4
    RNUM16 s_xp
    RTXT TXT_HUD_BAR
    FAR0 XpNeed
    RNUM16 tmp
    ; desafio do dia (chefe ou duelo)
    lda r_bossres
    bne :+
    lda r_duel
    beq @nob
:   cmp #1
    bne @falhou
    RICO ICR_DESAF, RES_XD, 22
    RPOS 18, 22, 6
    RTXT TXT_R_META_OK
    bra @nob
@falhou:
    RICO ICR_FALHOU, RES_XD, 22
    RPOS 18, 22, 5
    RTXT TXT_R_META_NO
@nob:
    ; missao atual (ate 24 letras: build.js confere)
    RICO ICR_MISSAO, RES_XE, 24
    RPOS 5, 24, 6
    A16
    lda s_mission
    and #$00FF
    asl a
    tax
    lda MissionTxt,x
    tax
    A8
    jsr TxtEsq
    ldx #TXT_R_CONT
    lda #26
    FAR0 Footer
    rtl

; X = texto (banco 0): imprime em txt_pos/txt_attr e avanca txt_pos
TxtEsq:
    .a8
    .i16
    FAR0 PrintStr
    A16
    txa                     ; PrintStr termina com X = 2 * proxima posicao
    lsr a
    sta txt_pos
    A8
    rts

; num (32 bits) alinhado a esquerda (sem espacos) em txt_pos; avanca txt_pos
NumEsq:
    .a8
    .i16
    FAR0 NumConv
    ldx #0
@z: lda numdig,x            ; pula os zeros a esquerda (fica ao menos um digito)
    bne @c
    cpx #7
    beq @c
    inx
    bra @z
@c: ldy #0
@cp:
    lda numdig,x
    clc
    adc #FONT_0
    sta numstr,y
    iny
    inx
    cpx #8
    bne @cp
    lda #$FF
    sta numstr,y
    ldx #numstr
    bra TxtEsq

; icone A da folha do resultado em (X, Y)
IcoRes:
    .a8
    .i16
    stx spr_x
    pha
    tya
    sta spr_y
    pla
    A16
    and #$00FF
    tax
    A8
    lda f:IconResPalTab,x
    asl a
    ora #$30
    sta spr_attr
    txa                     ; tile = (i % 8) * 2 + (i / 8) * 32
    and #$07
    asl a
    sta spr_tile
    txa
    and #$F8
    asl a
    asl a
    clc
    adc spr_tile
    sta spr_tile
    stz spr_tile+1
    lda #1
    sta spr_size
    FAR0 AddSprite
    stz spr_size
    rts

; ---------------------------------------------------------------- grafico de lucro (resultado)
DrawChart:
    .a8
    .i16
    FAR0 ClearBg3
    FAR0 OamClear
    RICO ICR_GRAF, RES_XE, 3
    PRINT0 TXT_G_TIT, 5, 3, 5
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
    ; melhor dia
    RICO ICR_MELHOR, RES_XE, 24
    RPOS 5, 24, 6
    RTXT TXT_R_RS
    RNUM16 tmp4
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

; folha de icones da tela de fim do dia (gerador/icones.py, ICONES_RES)
IconResGfx: .incbin "gen/icon_res_tiles.bin"
IconResGfx_end:
IconResPal: .incbin "gen/icon_res_pal.bin"
.include "gen/icon_res_pal.inc"
