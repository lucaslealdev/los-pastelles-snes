# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Los Pastelles: O Império do Pastel" is a pastry-shop management game for the Super Nintendo. It is written in 65816 assembly (ca65), and all of its assets (art, font, text, music) are generated from code by Node.js and Python scripts. The code, comments, game text and docs are in Brazilian Portuguese, so keep new identifiers and comments in Portuguese to match. `LEIAME.md` is the player-facing doc. It covers controls, content, secrets and how to burn a cartridge.

## Build

```
node build.js
```

This writes intermediate files to `gen/` (gitignored), assembles and links with cc65, fixes the header checksum and overwrites `LosPastelles.sfc` at the repo root. The ROM is committed.

Requirements that are not in the repo (`tools/` is gitignored and currently absent):
- cc65 extracted to `tools/cc65`. The build calls `tools/cc65/bin/ca65` and `ld65` directly.
- Python with Pillow, used for `gerador/logo.py`, `gerador/icones.py` and `gerador/checa_largura.py`.
- The Python interpreter comes from the `PYTHON` env var. If it isn't set, the build uses `python` on Windows and `python3` everywhere else. If Python fails, logo and icons fall back to existing `gen/` files.
- `gerador/icones.py` downloads Twemoji PNGs from jsDelivr the first time. They are cached in `arte_fonte/emoji/`, which is committed.

Other generators, run on demand:
- `node gerador/preview.js` writes art previews to `gen/preview/`.
- `node gerador/exporta_arte.js` exports transparent character PNGs to `cartucho/arte/`.
- `python gerador/cartucho.py` regenerates the cartridge label and the manual PDF in `cartucho/`.
- `gerador/trailer*.py` builds the trailer.
- `cartucho.py`, `capa.py` and `trailer.py` load TrueType fonts (Impact, Arial…) from the folder in the `FONTES` env var, defaulting to `C:/Windows/Fonts/`. On Linux, point it at a folder that has those fonts.

## Tests

There is no unit test suite. Tests are Lua scripts that run inside **Mesen 2** in test-runner mode, from a separate install in `teste/mesen/` so they don't touch the player's saves:

```
teste/mesen/Mesen.exe --testrunner LosPastelles.sfc teste/bot.lua
```

- `teste/bot.lua` is a robot that plays the game by reading RAM. It resolves variable addresses by name from `gen/labels.txt` (ld65 `-Ln` output), so renaming a variable in `vars.inc` can break the bot. Its behavior is configured with `botcfg*.lua` (choose one by setting the `BOTCFG` global).
- The other scripts are focused probes: `lag.lua` (frame lag), `tut.lua` (tutorial), `mg.lua` (minigame), `fotos.lua`/`ui_fotos.lua` (screenshots), `trace.lua`, `ram.lua`, and `run.lua` (input script plus `cenario.lua`).
- Each Lua script finds `teste/` from its own path via `debug.getinfo`. If Mesen doesn't expose `debug`, it falls back to the relative path `teste/`, so launch Mesen from the repo root. Other paths are built from that directory (`dir .. "../gen/labels.txt"`).
- Outputs (`teste/*.png`, `teste/*.txt`) are gitignored.
- Running Mesen 2 (Linux x64 build 2.1.1) here:
  - It crashes with `std::bad_cast` (a libstdc++ conflict inside MesenCore). Work around it with `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 teste/mesen/Mesen --testrunner ...`.
  - A `settings.json` next to the binary puts it in portable mode, so configs and saves stay in `teste/mesen/`.
  - That file must have `Debug.ScriptWindow.AllowIoOsAccess: true`, or the scripts can't use `io` and can't save screenshots.
  - It must also have `Snes.Port1.Type: "SnesController"`, or `emu.setInput` is ignored.
  - Press a button for a few polls in a row so the game sees it.

## Architecture

### Asset pipeline (build.js → gen/ → src/)
`build.js` is the hub. It calls the `gerador/` modules and writes:
- Binary blobs (`*_tiles.bin`, `*_map.bin`, `*_pal.bin`, `spc.bin`, `font.bin`, `ui_*.bin`) that `src/main.s` pulls in with `.incbin`.
- `gen/assets.inc` holds generated constants: `SPR_*` sprite IDs, `FONT_*` glyph codes, `SONG_*`/`SFX_*` indices, `CARD_*` and `SPC_SIZE`.
- `gen/data.inc` holds compiled strings (`TXT_<key>`), the lookup tables `MissionTxt`/`ShopName`/`ShopDesc`/`TrophyTxt` (their **counts are hard-coded in build.js**: 15 missions, 19 shop items, 16 trophies), music tracks, the SFX/pitch/instrument tables and the UI tables.
- `gen/cards.inc` holds the story-card text, which lives in its own bank (BANK11).

The generator modules:
- `gerador/textos.js` defines every game string as `T` (key → text, uppercase, `\n` = new line) plus `CARDS`.
- `gerador/fonte.js` turns text into tile codes with `compile()`. A character without a glyph throws at build time, so any new accented or special character needs a glyph in `G` first.
- `gerador/arte.js` and `gerador/gfx.js` contain all pixel art as code: scenes, sprites, palettes and 4bpp encoding. `shopScene(bairro, reforma)` gives 5 neighborhoods × 3 renovation stages.
- `gerador/audio.js` contains the SPC700 driver blob and the chiptune songs and SFX.
- `gerador/ui_tabs.js` builds the HDMA gradient and animation tables.
- `gerador/logo.py` converts whichever root-level PNG has "pastelles" in its filename into the 15-color title logo.

### ROM layout
`src/snes.cfg` maps LoROM SlowROM with 32 banks of 32 KB (1 MB). The header in `main.s` says 1 MB and 2 KB of battery SRAM.
- `src/main.s` is the single translation unit. It `.include`s `macros.inc`, `gen/assets.inc`, `vars.inc`, then `audio.s`, `game.s`, `telas.s`, `extra.s`, `segredo.s` and `ui.s` (all in the `CODE` segment, bank 0), then the data. Graphics go in the `BANK1`–`BANK12` segments, roughly one scene group per bank. The banks are 32 KB, so watch for overflow when art grows.
- Register convention: **A is 8-bit, X/Y are 16-bit, DBR = $80, D = $0000**. Switch widths with the `A8`/`A16`/`I8`/`I16` macros so that the assembler's `.a8`/`.a16` tracking stays correct.
- `gerador/checa_largura.py` runs on every build and flags branches or jumps whose target label was assembled under a different accumulator width. Treat its "problemas: N>0" output as a real bug.

### Menu background (BG2)
Menu screens (`LoadMenuScene`) show a 2-layer background:
- BG1 holds the panel. Outside the panel it is transparent.
- BG2 holds the checker pattern (`menuChecker` in `arte.js`): 3 tiles at tile index 1021 (`MENU_CHK_VRAM`) and a map at `VRAM_BG2MAP` = $5800.

`UiNmi` scrolls BG2 1 px to the right every 2 frames and turns BG2 on in `TM` only while `ui_mode == UI_PANEL`. Every other scene uses BG1 only.

### Game loop and state machine
`MainLoop` in `main.s` dispatches through the `StateInit`/`StateUpdate` jump tables (`src/telas.s`), indexed by `state`. The `ST_*` constants are defined at the top of `src/game.s` (title, intro, card, preday, day, results, shop, map, options, choose, slots, splash, trophies, secret). To change screens, write to `next_state`. The main loop runs the new state's Init once, then calls Update every frame, followed by `UiUpdate`, `AudioUpdate`, `WaitFrame` and `ReadPad`. NMI uploads OAM, palettes and VRAM from RAM buffers.
- `game.s` is the in-day gameplay: frying, customers, minigame, deliveries. `telas.s` holds the screens and menus, `extra.s` additional features, `segredo.s` the secret cheat menu, `ui.s` the HDMA panels and icons, and `audio.s` the APU upload and the music and SFX sequencer.
- `src/vars.inc` declares the RAM variables. The block between `save_start` and `save_end` is copied to SRAM as one unit (3 save slots) and **must stay contiguous**. Adding, removing or reordering fields there changes the save format.

### Other folders
`cartucho/` holds the label, manual, photos and exported art for the physical cartridge. `trailer/` holds the final trailer MP4. `roteiro_*.md` is the game's design and story script.
