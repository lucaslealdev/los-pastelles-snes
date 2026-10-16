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
    adc #(22*32-1)          ; campo de 3 a partir da coluna antes da barra: o numero fica embaixo dela
    sta txt_pos
    lda num+2
    sta num
    stz num+2
    A8
    lda #((4<<2)|$20)
    sta txt_attr
    lda #3
    sta num_w
    A16
    lda tmp2                ; o passo: PrintStr usa tmp2
    pha
    A8
    FAR0 PrintNum
    A16
    pla
    sta tmp2
    A8
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

; ---------------------------------------------------------------- mapa da expansao
; Com a tela desligada (VMAIN = $80): escreve no mapa do BG1 o retangulo de cada
; unidade ja comprada (lojas 1..s_stores e franquias 1..s_fran) por cima do
; terreno em obra / da placa de venda. Dados: gen/map_obras.inc (gerador/mapa.js)
MapObras:
    .a8
    .i16
    ldy #0
@u: tya
    cmp #4
    bcs @fr
    cmp s_stores
    bcs @nx
    bra @ap
@fr:
    sec
    sbc #4
    cmp s_fran
    bcs @nx
@ap:
    phy
    A16
    tya
    asl a
    tax
    lda f:MapObraPtr,x
    tax
    lda f:MapObraDados,x    ; endereco do canto na VRAM
    sta tmp
    lda f:MapObraDados+2,x  ; largura, altura
    sta tmp2
    inx
    inx
    inx
    inx
    A8
@lin:
    ldy tmp
    sty VMADDL
    lda tmp2
    sta tmp3
@col:
    lda f:MapObraDados,x
    sta $2118
    lda f:MapObraDados+1,x
    sta $2119
    inx
    inx
    dec tmp3
    bne @col
    A16
    lda tmp
    clc
    adc #32
    sta tmp
    A8
    dec tmp2+1
    bne @lin
    ply
@nx:
    iny
    cpy #MAP_OBRAS_N
    bne @u
    rtl

; agua do mapa correndo: a cada 16 quadros troca as cores dos dois brilhos
; (cores 9 e 11 da paleta BG 2)
MapAgua:
    .a8
    .i16
    lda frame
    and #$0F
    bne @r
    A16
    lda cgram_buf+(41*2)
    pha
    lda cgram_buf+(43*2)
    sta cgram_buf+(41*2)
    pla
    sta cgram_buf+(43*2)
    A8
    lda #1
    sta pal_dirty
@r: rtl

.include "gen/map_obras.inc"

; ---------------------------------------------------------------- ajuda da pausa
; Opcao AJUDA da pausa: balao grande (BG2, mapas fixos na VRAM carregados com o
; cenario) com abas (L/R) e paginas (cima/baixo ou A). A aba CONTROLES mostra o
; controle do Super Famicom desenhado no BG2 (paleta 4); a NMI troca o BG2SC (aj_sc).
; Textos e tabelas em gen/ajuda.inc (banco 11, gerador/ajuda.js).
AJ_LINABA = 5               ; barra de abas
AJ_LINTIT = 7               ; nome da aba e numero da pagina
AJ_LIN0   = 9               ; primeira linha do texto (13 linhas)
AJ_LINROD = 23              ; rodape (pilula na borda de baixo)
AJ_ICO_Y  = AJ_LINABA*8 - 4

; com o cenario do expediente (tela desligada): tiles, os dois mapas e a paleta 4
AjudaCarrega:
    .a8
    .i16
    ldx #AJ_VRAM
    stx VMADDL
    ldx #.loword(AjTiles)
    stx dma_src
    lda #^AjTiles
    sta dma_src+2
    ldx #(AjTiles_end - AjTiles)
    stx dma_len
    FAR0 DmaVram
    ldx #AJ_MAPA_VRAM
    stx VMADDL
    ldx #.loword(AjMapA)
    stx dma_src
    lda #^AjMapA
    sta dma_src+2
    ldx #2048
    stx dma_len
    FAR0 DmaVram
    ldx #AJ_MAPB_VRAM
    stx VMADDL
    ldx #.loword(AjMapB)
    stx dma_src
    lda #^AjMapB
    sta dma_src+2
    ldx #2048
    stx dma_len
    FAR0 DmaVram
    ldx #.loword(AjPal)
    stx dma_src
    lda #^AjPal
    sta dma_src+2
    ldx #(64*2)
    ldy #32
    FAR0 CopyPal
    rtl

; NMI com dim_on = 3 (chamada pelo TutNmi): janela e escurecimento do balao grande
AjudaNmi:
    .a8
    .i16
    ldx #.loword(AjWinTab)
    stx $4362
    lda #^AjWinTab
    sta $4364
    ldx #.loword(AjMathTab)
    stx $4372
    lda #^AjMathTab
    sta $4374
    lda aj_sc
    sta BG2SC
    rtl
; HDMA: contagem ate 127 por bloco (bit 7 seria o modo repetido)
AjWinTab:
    .byte AJ_Y0, 255, 0
    .byte 127, AJ_X0, AJ_X1
    .byte AJ_H-127, AJ_X0, AJ_X1
    .byte 1, 255, 0
    .byte 0
AjMathTab:
    .byte AJ_Y0, $B5
    .byte 127, $B1
    .byte AJ_H-127, $B1
    .byte 1, $B5
    .byte 0

; AJUDA escolhida na pausa
AjudaAbre:
    .a8
    .i16
    lda #1
    sta aj_on
    lda #3
    sta dim_on
    stz aj_aba
    stz aj_pag
    lda #SFX_OK
    FAR0 PlaySfx
    jsr AjudaDraw
    rtl

; volta para a pausa
AjudaFecha:
    .a8
    .i16
    stz aj_on
    lda #2
    sta dim_on
    jsr AjLimpa
    lda #SFX_CURSOR
    FAR0 PlaySfx
    FAR0 PauseDraw
    rts

; apaga as linhas da ajuda (4..23)
AjLimpa:
    .a8
    .i16
    lda #4
@l: pha
    FAR0 ClearRow
    pla
    inc a
    cmp #(AJ_LINROD+1)
    bne @l
    rts

; A = indice da pagina atual (AjPagIni[aba] + pagina)
AjPagina:
    .a8
    .i16
    A16
    lda aj_aba
    and #$00FF
    tax
    A8
    lda f:AjPagIni,x
    clc
    adc aj_pag
    rts

; A = numero de paginas da aba atual
AjNPag:
    .a8
    .i16
    A16
    lda aj_aba
    and #$00FF
    tax
    A8
    lda f:AjPagIni+1,x
    sec
    sbc f:AjPagIni,x
    rts

AjudaDraw:
    .a8
    .i16
    jsr AjLimpa
    PRINT0 TXT_SH_L, 2, AJ_LINABA, 4
    PRINT0 TXT_SH_R, 29, AJ_LINABA, 4
    ; nome da aba
    A16
    lda aj_aba
    and #$00FF
    asl a
    tax
    lda f:AjNome,x
    tax
    A8
    ldy #(AJ_LINTIT*32+3)
    sty txt_pos
    lda #((5<<2)|$20)
    sta txt_attr
    lda #^AjNome
    FAR0 PrintStrB
    ; "1/3" e o texto da pagina
    jsr AjPagina
    A16
    and #$00FF
    pha
    asl a
    tax
    lda f:AjPagNum,x
    tax
    A8
    ldy #(AJ_LINTIT*32+26)
    sty txt_pos
    lda #((4<<2)|$20)
    sta txt_attr
    lda #^AjPagNum
    FAR0 PrintStrB
    A16
    lda 1,s
    asl a
    tax
    lda f:AjPagTxt,x
    tax
    A8
    ldy #(AJ_LIN0*32+3)
    sty txt_pos
    lda #^AjPagTxt
    FAR0 PrintStrB
    ; BG2: mapa com o desenho do controle ou so o balao
    A16
    pla
    tax
    A8
    lda f:AjPagDes,x
    beq :+
    lda #AJ_SC_A
    bra :++
:   lda #AJ_SC_B
:   sta aj_sc
    ; rodape: com mais de uma pagina, diz como trocar
    jsr AjNPag
    cmp #2
    ldx #TXT_AJ_ROD0
    bcc :+
    ldx #TXT_AJ_ROD1
:   lda #AJ_LINROD
    FAR0 Footer
    rts

; um quadro com a ajuda aberta (chamada pelo PauseMenu)
AjudaUpdate:
    .a8
    .i16
    lda pad_new+1
    and #(KH_B|KH_START)
    beq @nb
    jsr AjudaFecha
    rtl
@nb:
    ; L ou esquerda: aba anterior; R ou direita: proxima (dao a volta)
    lda pad_new
    and #KL_L
    bne @al
    lda pad_new+1
    and #KH_LEFT
    beq @nl
@al:
    lda aj_aba
    dec a
    bpl @aba
    lda #(AJ_ABAS-1)
    bra @aba
@nl:
    lda pad_new
    and #KL_R
    bne @ar
    lda pad_new+1
    and #KH_RIGHT
    beq @nr
@ar:
    lda aj_aba
    inc a
    cmp #AJ_ABAS
    bcc @aba
    lda #0
@aba:
    sta aj_aba
    stz aj_pag
    bra @muda
@nr:
    ; cima: pagina anterior; baixo ou A: proxima (dao a volta)
    jsr AjNPag
    sta tmp
    cmp #2
    bcc @r
    lda pad_new+1
    and #KH_UP
    beq @nu
    lda aj_pag
    dec a
    bpl @pag
    lda tmp
    dec a
    bra @pag
@nu:
    lda pad_new+1
    and #KH_DOWN
    bne @prox
    lda pad_new
    and #KL_A
    beq @r
@prox:
    lda aj_pag
    inc a
    cmp tmp
    bcc @pag
    lda #0
@pag:
    sta aj_pag
@muda:
    lda #SFX_CURSOR
    FAR0 PlaySfx
    jsr AjudaDraw
@r: rtl

; icones das abas, com a pilula atras da escolhida (chamada pelo PauseSprites)
AjudaSprites:
    .a8
    .i16
    lda #0
@l: pha
    A16
    and #$00FF
    asl a
    tax
    lda f:AjIcoX,x
    sta spr_x
    lda f:AjIcoTile,x
    sta spr_tile
    A8
    lda #AJ_ICO_Y
    sta spr_y
    lda 1,s
    cmp aj_aba
    bne :+
    A16
    lda frame
    lsr a
    and #$001F
    tax
    A8
    lda f:UiBob,x
    clc
    adc spr_y
    sta spr_y
:   lda #$30
    sta spr_attr
    lda #1
    sta spr_size
    FAR0 AddSprite
    pla
    inc a
    cmp #AJ_ABAS
    bne @l
    ; pilula (2 pecas de 16) centrada no icone escolhido; depois dos icones = atras
    A16
    lda aj_aba
    and #$00FF
    asl a
    tax
    lda f:AjIcoX,x
    sec
    sbc #8
    sta spr_x
    lda #SPR_PILULA_E
    sta spr_tile
    A8
    lda #AJ_ICO_Y
    sta spr_y
    lda #$32
    sta spr_attr
    FAR0 AddSprite
    A16
    lda spr_x
    clc
    adc #16
    sta spr_x
    lda #SPR_PILULA_D
    sta spr_tile
    A8
    FAR0 AddSprite
    stz spr_size
    rtl
AjIcoX:    .word 54, 98, 142, 186
AjIcoTile: .word SPR_AJ_CONTROLE, SPR_AJ_LIVRO, SPR_ESTRELA, SPR_AJ_GRAFICO

; ---------------------------------------------------------------- HUD do expediente
; Pilulas creme no topo (dia, dinheiro, nivel, hora) e painel creme no rodape
; (linha de avisos/missao e linha de numeros), desenhados no cenario por
; gerador/hud.js + arte.js. Aqui ficam o texto (BG3, paletas 4-7) e os emojis.

; parte fixa (DrawHudStatic): ':' da hora
HudFixo:
    .a8
    .i16
    PRINT0 TXT_HUD_DP, HUD_HORA_COL+2, HUD_LIN_TOPO, 4
    rtl

; numeros (todo quadro, DrawHud)
.macro HUDNUM8 var, col, lin, pal, larg
    A16
    lda var
    and #$00FF
    sta num
    stz num+2
    A8
    ldx #((lin)*32+(col))
    stx txt_pos
    lda #(((pal)<<2)|$20)
    sta txt_attr
    lda #larg
    jsr HudNum
.endmacro
.macro HUDNUM16 var, col, lin, pal, larg
    A16
    lda var
    sta num
    stz num+2
    A8
    ldx #((lin)*32+(col))
    stx txt_pos
    lda #(((pal)<<2)|$20)
    sta txt_attr
    lda #larg
    jsr HudNum
.endmacro

HudValores:
    .a8
    .i16
    HUDNUM16 s_day, HUD_DIA_COL, HUD_LIN_TOPO, 4, HUD_DIA_W
    A16
    lda s_money
    sta num
    lda s_money+2
    sta num+2
    A8
    ldx #(HUD_LIN_TOPO*32+HUD_RS_COL)
    stx txt_pos
    lda #((6<<2)|$20)
    sta txt_attr
    lda #HUD_RS_W
    jsr HudNum
    HUDNUM8 s_level, HUD_NV_COL, HUD_LIN_TOPO, 5, HUD_NV_W
    ; hora: hh (com espaco) e mm (com zero)
    A16
    lda d_hour
    and #$00FF
    sta num
    stz num+2
    A8
    ldx #(HUD_LIN_TOPO*32+HUD_HORA_COL)
    stx txt_pos
    lda #((4<<2)|$20)
    sta txt_attr
    lda #2
    sta num_w
    FAR0 PrintNum
    A16
    lda d_min
    and #$00FF
    sta num
    A8
    ldx #(HUD_LIN_TOPO*32+HUD_HORA_COL+3)
    stx txt_pos
    lda #2
    sta num_w
    lda #FONT_0
    sta num_pad
    FAR0 PrintNum
    HUDNUM16 s_stock, HUD_EST_COL, HUD_LIN_NUM, 4, HUD_EST_W
    HUDNUM8 s_rep, HUD_REP_COL, HUD_LIN_NUM, 4, HUD_REP_W
    ; meta: perfeitos (desafio do sabor) ou satisfeitos, alinhado a direita do '/'
    FAR0 HasGoal
    bcc @r
    lda d_boss
    cmp #1
    bne :+
    lda d_perfect
    bra :++
:   lda d_happy
:   A16
    and #$00FF
    sta num
    stz num+2
    A8
    ldx #(HUD_LIN_NUM*32+HUD_META_COL)
    stx txt_pos
    lda #((6<<2)|$20)
    sta txt_attr
    lda #2
    sta num_w
    FAR0 PrintNum
    PRINT0 TXT_HUD_BAR, HUD_META_COL+2, HUD_LIN_NUM, 6
    HUDNUM8 d_goal, HUD_META_COL+3, HUD_LIN_NUM, 6, 2
@r: rtl

; num (32 bits) alinhado a esquerda em txt_pos/txt_attr, completado com espacos
; ate A casas (apaga os digitos que sobram quando o numero encolhe)
HudNum:
    .a8
    .i16
    sta hud_w
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
@sp:
    tya
    cmp hud_w
    bcs @fim
    lda #FONT_SPACE
    sta numstr,y
    iny
    bra @sp
@fim:
    lda #$FF
    sta numstr,y
    ldx #numstr
    FAR0 PrintStr
    rts

; emojis do HUD: 16x16 na ponta de cada pilula do topo; 8x8 no rodape (estoque,
; reputacao, meta e a estrela da missao)
HudSprites:
    .a8
    .i16
    lda #$30                ; prioridade 3, paleta 0
    sta spr_attr
    lda #1
    sta spr_size
    lda #HUD_ICO_Y
    sta spr_y
    ldx #0
@t: phx
    A16
    lda f:HudIcoX,x
    sta spr_x
    lda f:HudIcoTile,x
    sta spr_tile
    A8
    FAR0 AddSprite
    plx
    inx
    inx
    cpx #8
    bne @t
    stz spr_size
    lda #(HUD_LIN_NUM*8)
    sta spr_y
    A16
    lda #((HUD_EST_COL-1)*8)
    sta spr_x
    lda #SPR_MINI_CAIXA
    sta spr_tile
    A8
    FAR0 AddSprite
    A16
    lda #((HUD_REP_COL-1)*8)
    sta spr_x
    lda #SPR_MINI_CORACAO
    sta spr_tile
    A8
    FAR0 AddSprite
    FAR0 HasGoal
    bcc :+
    A16
    lda #((HUD_META_COL-1)*8)
    sta spr_x
    lda #SPR_MINI_ALVO
    sta spr_tile
    A8
    FAR0 AddSprite
:   lda hud_mis
    beq @r
    lda #(HUD_LIN_MSG*8)
    sta spr_y
    A16
    lda #8
    sta spr_x
    lda #SPR_MINI_ESTRELA
    sta spr_tile
    A8
    FAR0 AddSprite
@r: rtl
HudIcoX:    .word HUD_DIA_ICOX, HUD_RS_ICOX, HUD_NV_ICOX, HUD_HORA_ICOX
HudIcoTile: .word SPR_CALENDARIO, SPR_MOEDA, SPR_ESTRELA, SPR_RELOGIO

; ---------------------------------------------------------------- animacoes grandes (BG2)
; Player generico das animacoes grandes do expediente (gerador/anim.js): um cartao
; creme no BG2 (mapa ANIM_MAPA_VRAM, paleta 5, prioridade alta) cujo miolo (8x6
; tiles) recebe o quadro atual pela NMI (AnimDma) so quando ele muda. Uso:
;   lda #quadro : jsl AnimMostra   mostra o cartao ja nesse quadro (indice global)
;   lda #quadro : jsl AnimVai      anda ate esse quadro (para frente ou para tras)
;   lda #n      : jsl AnimSome     some n quadros de video depois de chegar ao alvo
;   jsl AnimEsconde                some ja
; Os quadros de uma animacao vao de ANIM_<NOME> a ANIM_<NOME>+ANIM_<NOME>_N-1;
; Anim<Nome>Chaves tem os quadros-chave (relativos). AnimSprites (fim do DayDraw)
; anda a animacao e poe atras do cartao os sprites que encostam nele.
ANIM_VEL = 3                ; quadros de video por quadro de animacao

; com o cenario do expediente (tela desligada): borda do cartao, mapa e paleta 5
AnimCarrega:
    .a8
    .i16
    stz anim_vis
    stz anim_sujo
    ldx #ANIM_VRAM
    stx VMADDL
    ldx #.loword(AnimBorda)
    stx dma_src
    lda #^AnimBorda
    sta dma_src+2
    ldx #ANIM_BORDA_BYTES
    stx dma_len
    FAR0 DmaVram
    ldx #ANIM_MAPA_VRAM
    stx VMADDL
    ldx #.loword(AnimMapa)
    stx dma_src
    lda #^AnimMapa
    sta dma_src+2
    ldx #2048
    stx dma_len
    FAR0 DmaVram
    ldx #.loword(AnimPal)
    stx dma_src
    lda #^AnimPal
    sta dma_src+2
    ldx #(80*2)
    ldy #32
    FAR0 CopyPal
    rtl

AnimMostra:
    .a8
    .i16
    sta anim_cur
    sta anim_tgt
    lda #1
    sta anim_vis
    sta anim_sujo
    stz anim_ok
    stz anim_fim
    lda #ANIM_VEL
    sta anim_t
    rtl

AnimVai:
    .a8
    .i16
    sta anim_tgt
    rtl

AnimSome:
    .a8
    .i16
    sta anim_fim
    rtl

AnimEsconde:
    .a8
    .i16
    lda anim_vis
    beq :+
    lda #2
    sta anim_vis
:   rtl

; um quadro do expediente (chamada no fim do DayDraw): anda a animacao, poe atras
; do cartao (prioridade 2; o BG2 de prioridade alta fica na frente) os sprites que
; encostam nele e desenha os extras da animacao (o recheio da montagem)
AnimSprites:
    .a8
    .i16
    lda anim_vis
    cmp #1
    beq :+
    rtl
:   lda dim_on              ; pausa/tutorial aberto: a animacao espera
    bne @spr
    lda anim_sujo           ; espera a NMI mandar o quadro anterior
    bne @spr
    lda anim_cur
    cmp anim_tgt
    beq @parado
    dec anim_t
    bne @spr
    lda #ANIM_VEL
    sta anim_t
    lda anim_cur
    cmp anim_tgt
    bcc :+
    dec a
    dec a
:   inc a
    sta anim_cur
    lda #1
    sta anim_sujo
    bra @spr
@parado:
    lda anim_fim
    beq @spr
    dec anim_fim
    bne @spr
    lda #2
    sta anim_vis
    rtl
@spr:
    lda anim_ok
    bne :+
    rtl
:   ldx #0
@l: cpx oam_idx
    bcs @extra
    ; encosta no cartao? (supondo 16x16: linhas y..y+15, colunas x..x+15)
    lda oam_buf+1,x
    cmp #(ANIM_Y0-15)
    bcc @nx
    cmp #(ANIM_Y1+1)
    bcs @nx
    lda oam_buf,x
    cmp #(ANIM_X0-15)
    bcc @nx
    cmp #(ANIM_X1+1)
    bcs @nx
    lda oam_buf+3,x
    and #$CF
    ora #$20
    sta oam_buf+3,x
@nx:
    inx
    inx
    inx
    inx
    bra @l
@extra:
    jmp MgaSprites

; NMI, no envio (nmi_ready): tiles do quadro atual para o miolo do cartao
AnimDma:
    .a8
    .i16
    lda #$80
    sta VMAIN
    ldx #ANIM_SLOT_VRAM
    stx VMADDL
    lda #$01
    sta $4300
    lda #$18
    sta $4301
    A16
    lda anim_cur            ; x = quadro * 3 (na NMI nada de tmp: usa a pilha)
    and #$00FF
    pha
    asl a
    clc
    adc 1,s
    tax
    pla
    lda f:AnimQuadro,x
    sta $4302
    A8
    lda f:AnimQuadro+2,x
    sta $4304
    ldx #ANIM_BYTES
    stx $4305
    lda #$01
    sta MDMAEN
    stz anim_sujo
    lda #1
    sta anim_ok
    rtl

; NMI sem pausa/tutorial (depois da UiNmi): liga o BG2 com o cartao. Fora do
; expediente, ou sumindo, volta o BG2SC do xadrez dos menus
AnimNmi:
    .a8
    .i16
    lda state
    cmp #ST_DAY
    bne @off
    lda anim_vis
    cmp #1
    bne @off
    lda anim_ok
    beq @r
    lda #$17                ; BG1 + BG2 + BG3 + sprites
    sta TM
    lda #(ANIM_MAPA_VRAM >> 8)
    sta BG2SC
    stz BG2HOFS
    stz BG2HOFS
    lda #$FF
    sta BG2VOFS
    lda #$03
    sta BG2VOFS
@r: rtl
@off:
    stz anim_vis
    lda #(VRAM_BG2MAP >> 8)
    sta BG2SC
    rtl

; ---------------------------------------------------------------- montagem do pastel (minijogo)
; Quadros-chave: 0 massa, 1 recheio, 2 dobra, 3 fechando com o garfo, 4 pronto.
; Cada acerto anda ate a chave proporcional ao progresso (mg_pos / mg_len).
MGA_CHAVES = 5

; minijogo de fechar o pastel comecou (o conserto do cesto nao tem animacao)
MgaInicio:
    .a8
    .i16
    lda mg_mode
    bne :+
    lda #ANIM_MONTAGEM
    jsl AnimMostra
:   rtl

; acertou um botao: chave = arredonda(mg_pos * 4 / mg_len); na ultima, some depois
MgaAcerto:
    .a8
    .i16
    lda mg_mode
    bne @r
    lda mg_pos              ; (mg_pos * 8 + mg_len) / (mg_len * 2)
    asl a
    asl a
    asl a
    clc
    adc mg_len
    sta tmp
    lda mg_len
    asl a
    sta tmp+1
    ldx #0
:   lda tmp
    cmp tmp+1
    bcc :+
    sbc tmp+1
    sta tmp
    inx
    bra :-
:   cpx #MGA_CHAVES
    bcc :+
    ldx #(MGA_CHAVES-1)
:   lda f:AnimMontagemChaves,x
    clc
    adc #ANIM_MONTAGEM
    jsl AnimVai
    cpx #(MGA_CHAVES-1)
    bne @r
    lda #24                 ; pastel pronto aparece um pouco e o cartao some
    jsl AnimSome
@r: rtl

; errou ou acabou o tempo: desfecho de erro. Por enquanto so some; a melhoria 11
; (pastel indo para a lixeira) toca aqui a sua animacao a partir de anim_cur
MgaErro:
    .a8
    .i16
    lda mg_mode
    bne :+
    jsl AnimEsconde
:   rtl

; recheio: o emoji do sabor (mg_flav) em cima do monte, nos quadros marcados em
; AnimMontagemExtra (chamada pelo AnimSprites, depois de por os outros atras)
MgaSprites:
    .a8
    .i16
    lda anim_cur
    sec
    sbc #ANIM_MONTAGEM
    cmp #ANIM_MONTAGEM_N
    bcs @r
    A16
    and #$00FF
    tax
    A8
    lda f:AnimMontagemExtra,x
    beq @r
    A16
    lda mg_flav
    and #$00FF
    asl a
    tax
    lda IconTiles,x
    sta spr_tile
    lda #(ANIM_MONTAGEM_PX-8)
    sta spr_x
    A8
    lda #(ANIM_MONTAGEM_PY-8)
    sta spr_y
    lda #$30
    sta spr_attr
    lda #1
    sta spr_size
    FAR0 AddSprite
    stz spr_size
@r: rtl

.segment "BANK28"
AnimBorda: .incbin "gen/anim_borda.bin"
AnimMapa:  .incbin "gen/anim_map.bin"
AnimPal:   .incbin "gen/anim_pal.bin"
.include "gen/anim.inc"
