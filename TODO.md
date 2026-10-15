# TO-DO

Lista de trabalho pendente. Antes de cada item, reler as regras do `CLAUDE.md` (limite de sprites por linha, banco 0 cheio, larguras de texto, alinhamento 8×8 dos botões, testes em Mesen sem save).

## Correções

- [x] **"PRACA" → "PRAÇA"** no evento `EV_FESTIVAL` (`gerador/textos.js:236`). O glifo `Ç` já existe em `gerador/fonte.js`. Procurar outras ocorrências sem cedilha/acento (`grep -rni praca gerador/ src/`) e conferir se a quebra de linha continua cabendo no card.

## Melhorias

- [ ] **HUD do dia mais moderno.** Trocar a HUD atual por balões (estilo do balão do tutorial / pílula), ícones de emoji (moeda, relógio, estrela etc.) e texto estilizado. Cuidado com o limite de 32 sprites / 34 tiles por linha durante o jogo e com as paletas de sprite 3–7, que são dos clientes.

- [ ] **Menu de pausa no estilo do tutorial.** Redesenhar a pausa com o mesmo balão creme do tutorial (BG2 + janela + escurecimento via HDMA, como `TutBox`/`TutNmi`), um emoji por item e rodapé com pílula (`Footer`).

- [ ] **Animação grande da montagem do pastel (minigame).**
  - Pelo menos 5 quadros-chave da montagem (massa → recheio → dobra → fechamento → pastel pronto), exibidos grandes na tela.
  - Cada acerto de botão sorteado avança a animação; errar desvia para o desfecho de erro.
  - Arte baseada em emojis/glyphs da internet (Twemoji, como o resto do projeto), com quadros intermediários gerados por morph entre os quadros-chave para suavizar o movimento.
  - Gerar tudo por script em `gerador/` (como `emoji_sprites.py`); verificar espaço em banco/VRAM.

- [ ] **Animação de erro: pastel indo para a lixeira.** Quando a montagem falhar, mostrar o pastel caindo numa lixeira 🗑️. Mesmo método: emojis, 5 quadros-chave + morphs.

- [ ] **Cenário da loja com emojis.** Substituir desenhos simples de `gerador/arte.js` por arte partindo de emojis ajustados à interface — por exemplo (mas não só): chef 🧑‍🍳, vaso de planta 🪴, janela 🪟. Revisar o cenário inteiro procurando outros elementos candidatos. Lembrar que são 5 bairros × 3 reformas (`shopScene`) e dos limites de paleta/banco.

- [ ] **Tela de fim do dia (resultados) modernizada.** Usar emojis no lugar de rótulos e cortar texto sempre que um ícone + número bastar.

- [ ] **Indicador visual do que está na mão do jogador.**
  - Mostrar um emoji de mão (✋/🫴) combinado com o emoji do que foi pego — sabor do recheio (🥩 🧀 🍗 🥓 etc.) ou pastel pronto do sabor X.
  - Objetivo: o jogador não precisar lembrar o que pegou nem qual pastel é qual (ex.: "pastel de queijo na mão").
  - Atualizar sempre que a mão mudar (pegar, montar, entregar, descartar); mão vazia não mostra nada (ou mão aberta vazia).
  - Reaproveitar os sprites de sabor já em `emoji_sprites.py`; decidir onde fica (junto ao cursor ou fixo na HUD) e contar no limite de sprites por linha.

- [ ] **Emoji do sabor ao lado do pastel na fritura.**
  - Cada cesto com pastel fritando mostra, ao lado, o emoji do sabor (🥩 🧀 🍗 🥓 etc.), para o jogador saber qual pastel vai pegar antes de pegar.
  - Complementa o indicador da mão (item acima): um mostra o que está na fritura, o outro o que já foi pego.
  - Reaproveitar os sprites de sabor de `emoji_sprites.py`; some quando o cesto esvazia. Atenção ao limite de sprites por linha com vários cestos lado a lado (pode valer usar ícone 8×8 em vez de 16×16).

- [ ] **Vozes com taxa maior (mais qualidade).**
  - Objetivo: subir a taxa das vozes gravadas. A música tema (`VOZ_TEMA`, 10 kHz) já está boa; **não mexer nela**.
  - **Falas em stream** (10 kHz, voz 7 / anel B): o limite é o barramento. Hoje o dia tem ~170–180 bytes/quadro de folga, e música + fala usam ~94 + 94. Para subir a fala, liberar tempo de CPU por quadro otimizando o que compete com o `Bomba` (lógica do dia, montagem de OAM, uploads na NMI, `BtnSprites`/`PillSprites`, etc.). Perfilar antes (skill `snes-otimizacao`, Mesen) para achar os maiores consumidores.
  - Outras ideias: aumentar `LOTE_MAX`, acelerar o laço do `Bomba`, dar prioridade maior à fala enquanto toca, ajustar colchões (0,5 s música / 0,15 s fala).
  - **Vozes fixas** (9 kHz): o limite aqui é espaço na ARAM (~50 KB divididos entre elas), não barramento. Para subir, liberar ARAM (ex.: anéis menores, eco menor, mover vozes pouco frequentes para stream).
  - Medir o nível dos anéis nos quadros mais pesados antes e depois (anel vazio = estalo/corte). Validar no console real se possível. A troca de taxa regera o BRR (`arte_fonte/brr/`, precisa de ffmpeg).

- [ ] **Loja do caixa com abas por tipo de item.**
  - Agrupar os 19 itens da loja (`ShopName`/`ShopDesc`) por categoria, uma aba por grupo.
  - L e R trocam de aba.
  - Mostrar ícones dos botões L e R ao lado das abas (criar tokens/sprites `{L}`/`{R}` no padrão de `{A}`/`{B}`, se ainda não existirem).
