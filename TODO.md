# TO-DO

Lista de trabalho pendente. Antes de cada item, reler as regras do `CLAUDE.md` (limite de sprites por linha, banco 0 cheio, larguras de texto, alinhamento 8×8 dos botões, testes em Mesen sem save).

## Correções

- [x] **"PRACA" → "PRAÇA"** no evento `EV_FESTIVAL` (`gerador/textos.js:236`). O glifo `Ç` já existe em `gerador/fonte.js`. Procurar outras ocorrências sem cedilha/acento (`grep -rni praca gerador/ src/`) e conferir se a quebra de linha continua cabendo no card.

- [x] **Soft-lock: dia começa sem estoque de pastel.** Feito: `DiaBloqueado` (`src/banco28.s`) no início de `PreDayInit`; carta `SEMESTOQUE` com {A} loja / {B} menu; sem dinheiro para o estoque, o mestre dá 10 porções (carta `FALIU`). Novos impedimentos entram em `DiaBloqueado`.
  - Hoje, se o dia começa com `s_stock` = 0, o jogador é obrigado a passar o dia inteiro falhando para só então chegar à loja e comprar estoque.
  - Correção: antes de iniciar o dia (no `ST_PREDAY` / `DayInit`), checar se há algo que impeça o dia de acontecer normalmente. Se houver, mostrar uma caixa explicando o problema (ex.: "SEM ESTOQUE DE PASTEL!") com duas opções:
    1. voltar ao menu principal (`ST_TITLE`);
    2. ir à loja (`ST_SHOP`) para resolver — e da loja seguir para o dia normalmente.
  - Fazer a checagem genérica (lista de impedimentos), para incluir outros casos além do estoque. Levantar quais existem (ex.: estoque menor que o mínimo para um pedido, todos os cestos quebrados?).
  - Cuidar do caso sem dinheiro para comprar estoque (a loja não resolveria): definir saída (ex.: estoque mínimo de emergência).
  - Textos novos em `gerador/textos.js`, respeitando a largura das caixas; opções com `{A}`/`{CIMA}`/`{BAIXO}` e rodapé com `Footer`. Banco 0 cheio: código em outro banco.

- [ ] **Acentos faltando em textos.** Ex.: "LUCRO DOS ULTIMOS DIAS" (ÚLTIMOS), carta `EV_CRITICO` ("CRITICO GASTRONOMICO" → CRÍTICO GASTRONÔMICO). Revisar todo `gerador/textos.js` procurando palavras sem acento.

## Melhorias

Ordenadas da mais simples para a mais complexa, respeitando dependências (fazer na ordem).

1. - [x] **Emoji do sabor ao lado do pastel na fritura.**
     - Cada cesto com pastel fritando mostra, ao lado, o emoji do sabor (🥩 🧀 🍗 🥓 etc.), para o jogador saber qual pastel vai pegar antes de pegar.
     - Reaproveitar os sprites de sabor de `emoji_sprites.py`; some quando o cesto esvazia. Atenção ao limite de sprites por linha com vários cestos lado a lado (pode valer usar ícone 8×8 em vez de 16×16).
     - Vem primeiro porque é o menor e cria a rotina "desenhar ícone de sabor" que o item 2 reaproveita.

2. - [ ] **Indicador visual do que está na mão do jogador.** *(depende do 1)*
     - Mostrar um emoji de mão (✋/🫴) combinado com o emoji do que foi pego — sabor do recheio (🥩 🧀 🍗 🥓 etc.) ou pastel pronto do sabor X.
     - Objetivo: o jogador não precisar lembrar o que pegou nem qual pastel é qual (ex.: "pastel de queijo na mão").
     - Atualizar sempre que a mão mudar (pegar, montar, entregar, descartar); mão vazia não mostra nada (ou mão aberta vazia).
     - Novo sprite: só a mão. Conferir em `game.s` quais estados de "mão" existem de fato. Preferir junto ao cursor (fixo na HUD seria refeito no item 7).
     - **Banco 0 está cheio** (~1 byte livre após o item 1): o código novo vai para o banco 28 (`src/banco28.s`, `JSL`/`RTL`, chamando o banco 0 com `FAR0`). Se precisar de bytes no banco 0, mover outra rotina grande para lá, como foi feito com `DrawChart`. Os sabores 8×8 já existem (`SPR_MINI` + sabor, tiles consecutivos).

3. - [ ] **Tela de fim do dia (resultados) modernizada.**
     - Usar emojis no lugar de rótulos e cortar texto sempre que um ícone + número bastar.
     - Tela isolada, fora do dia (sem disputa de sprites com clientes); usa os ícones emoji já existentes (`IconeSprite`/`ICO_*`).

4. - [ ] **Loja do caixa com abas por tipo de item.**
     - Agrupar os 19 itens da loja (`ShopName`/`ShopDesc`) por categoria, uma aba por grupo.
     - L e R trocam de aba.
     - Mostrar ícones dos botões L e R ao lado das abas (criar tokens/sprites `{L}`/`{R}` no padrão de `{A}`/`{B}`, se ainda não existirem).

5. - [ ] **Menu de pausa no estilo do tutorial.**
     - Redesenhar a pausa com o mesmo balão creme do tutorial (BG2 + janela + escurecimento via HDMA, como `TutBox`/`TutNmi`), um emoji por item e rodapé com pílula (`Footer`).
     - Mais trabalho que a loja: mexe com HDMA/janelas por cima do jogo e com o limite de sprites (esconder sprites sob o balão, como `TutSprites`).

6. - [ ] **Cenário da loja com emojis.**
     - Substituir desenhos simples de `gerador/arte.js` por arte partindo de emojis ajustados à interface — por exemplo (mas não só): chef 🧑‍🍳, vaso de planta 🪴, janela 🪟. Revisar o cenário inteiro procurando outros elementos candidatos.
     - São 5 bairros × 3 reformas (`shopScene`); atenção a paleta e tamanho de banco.
     - Antes da HUD (item 7) porque a HUD nova deve combinar com o cenário novo.

7. - [ ] **HUD do dia mais moderno.** *(depois do 2 e do 6)*
     - Trocar a HUD atual por balões (estilo do balão do tutorial / pílula), ícones de emoji (moeda, relógio, estrela etc.) e texto estilizado.
     - Cuidado com o limite de 32 sprites / 34 tiles por linha durante o jogo e com as paletas de sprite 3–7, que são dos clientes. Reservar espaço/sprites para os indicadores dos itens 1 e 2.

8. - [ ] **Animação grande da montagem do pastel (minigame).**
     - Pelo menos 5 quadros-chave da montagem (massa → recheio → dobra → fechamento → pastel pronto), exibidos grandes na tela.
     - Cada acerto de botão sorteado avança a animação; errar desvia para o desfecho de erro (item 9).
     - Arte baseada em emojis/glyphs da internet (Twemoji, como o resto do projeto), com quadros intermediários gerados por morph entre os quadros-chave para suavizar o movimento.
     - Gerar tudo por script em `gerador/` (como `emoji_sprites.py`); verificar espaço em banco/VRAM. Montar o gerador de morph de forma reutilizável para o item 9.

9. - [ ] **Animação de erro: pastel indo para a lixeira.** *(depende do 8)*
     - Quando a montagem falhar, mostrar o pastel caindo numa lixeira 🗑️. Mesmo método: emojis, 5 quadros-chave + morphs, reaproveitando o gerador e o player de animação do item 8.

10. - [ ] **Sistema de password (salvar sem SRAM).** *(depois do 4: o password aparece na loja)*
      - **Uma única ROM.** No boot, detectar se o cartucho tem SRAM: gravar e reler dois padrões diferentes (ex.: `$55`/`$AA`) num endereço de SRAM, sem confiar em open bus, e restaurar o byte original. Guardar o resultado numa variável (ex.: `tem_sram`).
        - **Com SRAM:** mantém carregar/salvar como hoje **e** as opções de password (carregar password e depois salvar na SRAM, ou jogo novo na SRAM e depois ver o password dele).
        - **Sem SRAM:** só password. Esconder as opções de slot/salvar e não tentar ler/gravar SRAM.
      - **Onde aparece:** "carregar password" no menu principal; "mostrar password" onde hoje o jogo salva (fim do dia/loja). Se o password for curto o bastante (ver abaixo), mostrá-lo sempre no rodapé do menu de compras.
      - **Conteúdo:** o bloco `save_start`..`save_end` (~32 bytes úteis sem `s_magic`). Antes de codificar, compactar ao máximo: cada campo só com os bits do seu intervalo real (ex.: `s_fryer` 1..3 = 2 bits), limitar/arredondar campos grandes (`s_money`, `s_tot_*`) ou recalcular o que der. Pode usar o algoritmo mais pesado que couber, mesmo que a CPU demore para gerar (só roda em menu).
      - **Verificação:** dígito(s)/glifo(s) verificador(es) (CRC ou similar) + embaralhar os bits com chave fixa (LFSR/XOR), para que trocar um caractere mude tudo e combinações aleatórias quase nunca funcionem. Incluir um número de versão do formato.
      - **Alfabeto — decidir nesta ordem de preferência:**
        1. **Até 8 glifos do jogo** (ex.: QUEIJO CALABRESA FRANGO QUEIJO CARNE QUEIJO QUEIJO FRANGO). Atenção: 8 símbolos de 6 sabores ≈ 20 bits, e de 16 ícones = 32 bits, muito menos que o save atual (~100+ bits mesmo compactado). Só dá se o save for reduzido a quase nada; fazer a conta antes e descartar se não couber.
        2. **Conjunto pequeno, ex.: 16 símbolos** (hexadecimal, ou 16 ícones do jogo = 4 bits cada): mais caracteres, mas poucos botões para digitar e anotar.
        3. **A–Z (+ dígitos)** com teclado QWERTY virtual: só se os anteriores ficarem longos demais.
      - **Tela de digitação** (acessível pelo menu principal): teclado virtual moderno em pixel art, com as cores do jogo; com 16 símbolos, uma grade 4×4 em vez de QWERTY. Pensar na usabilidade no controle: cursor que dá a volta nas bordas, {B} apaga, {A} digita, START confirma, agrupar o código em blocos de 4 para facilitar a anotação, mensagem clara quando o password for inválido.
      - Opções de jogo (`OPT_SRAM`) e troféus: decidir se entram no password ou ficam só na SRAM.
      - Código em outro banco (banco 0 cheio). Teste Lua: gerar password, carregar e comparar o bloco do save; testar também o boot sem SRAM.

11. - [ ] **Vozes com taxa maior (mais qualidade).** *(por último: as melhorias acima adicionam CPU por quadro e mudam o orçamento do barramento)*
      - Objetivo: subir a taxa das vozes gravadas. A música tema (`VOZ_TEMA`, 10 kHz) já está boa; **não mexer nela**.
      - **Falas em stream** (10 kHz, voz 7 / anel B): o limite é o barramento. Hoje o dia tem ~170–180 bytes/quadro de folga, e música + fala usam ~94 + 94. Para subir a fala, liberar tempo de CPU por quadro otimizando o que compete com o `Bomba` (lógica do dia, montagem de OAM, uploads na NMI, `BtnSprites`/`PillSprites`, etc.). Perfilar antes (skill `snes-otimizacao`, Mesen) para achar os maiores consumidores.
      - Outras ideias: aumentar `LOTE_MAX`, acelerar o laço do `Bomba`, dar prioridade maior à fala enquanto toca, ajustar colchões (0,5 s música / 0,15 s fala).
      - **Vozes fixas** (9 kHz): o limite aqui é espaço na ARAM (~50 KB divididos entre elas), não barramento. Para subir, liberar ARAM (ex.: anéis menores, eco menor, mover vozes pouco frequentes para stream).
      - Medir o nível dos anéis nos quadros mais pesados antes e depois (anel vazio = estalo/corte). Validar no console real se possível. A troca de taxa regera o BRR (`arte_fonte/brr/`, precisa de ffmpeg).
