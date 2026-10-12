# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Los Pastelles: O Império do Pastel" is a pastry-shop management game for the Super Nintendo. It is written in 65816 assembly (ca65), and all of its assets (art, font, text, music) are generated from code by Node.js and Python scripts. The code, comments, game text and docs are in Brazilian Portuguese, so keep new identifiers and comments in Portuguese to match. `LEIAME.md` is the player-facing doc. It covers controls, content, secrets and how to burn a cartridge.

## Build

```
node build.js
```

This writes intermediate files to `gen/` (gitignored), assembles and links with cc65, fixes the header checksum and overwrites `LosPastelles.sfc` at the repo root. The ROM is committed (as a development build; official ROMs come from the GitHub releases). The build is deterministic: the same source and version produce the same bytes.

Requirements that are not in the repo (`tools/` is gitignored):
- cc65 (2.19). The build uses `tools/cc65/bin/ca65` and `ld65` if they exist; otherwise it runs `ca65`/`ld65` from `PATH` (for example after `apt install cc65`).
- Python with Pillow, used for `gerador/logo.py`, `gerador/icones.py` and `gerador/checa_largura.py`.
- The Python interpreter comes from the `PYTHON` env var. If it isn't set, the build uses `python` on Windows and `python3` everywhere else. If Python fails, logo and icons fall back to existing `gen/` files.
- `gerador/checa_largura.py` (the 65816 width checker) runs on every build. If it finds a problem, the build fails. If Python is missing, it only warns, except in CI (`CI` env var set), where it fails too.
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

`teste/ci.lua` is the pass/fail test that CI runs:
- The robot plays a new game, and the script checks these milestones in order: day 1 starts, the tutorial is completed, the day ends (results), the shop opens, and day 2 starts.
- It also checks for a valid save in SRAM and allows at most 4 lag frames during gameplay. Scene loads and open boxes don't count, since they pause the loop on purpose.
- It exits with code 0 if everything passed and 1 if anything failed. A summary goes to `teste/ci.txt`, and the robot's own log goes to `teste/bot.txt`.
- It takes about 55 s (about 9,700 frames). Run it locally (Linux) with:

```
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 teste/mesen/Mesen --testrunner LosPastelles.sfc teste/ci.lua
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
  - It works without a display. The minimal `settings.json` that CI writes is enough: `{"Snes":{"Port1":{"Type":"SnesController"}},"Debug":{"ScriptWindow":{"AllowIoOsAccess":true}}}`.

## Versioning and releases

The project uses semantic versioning (`MAJOR.MINOR.PATCH`), starting at `0.0.1`. The version is computed by `gerador/versao.js` from two sources:
- `VERSION`: the minimum version for the next release.
- git tags `vX.Y.Z`: the versions already released.

`node gerador/versao.js --proxima` prints the next version to release:
- If `VERSION` is higher than the latest tag, it uses `VERSION`.
- Otherwise, it uses the latest tag with PATCH + 1.

The version of each build (`node gerador/versao.js`) is:
- **In CI:** the `GAME_VERSION` env var, validated as semver.
- **Locally:** `git describe` gives the latest tag plus the commits since it (e.g. `0.0.3-dev.2+abc1234`). With no tags, it's `VERSION` plus `-dev`.

`build.js` only writes the version as text in the credits card (`CARDS.CREDITOS`, line "VERSÃO …"). Nothing in the game logic, the save format or the ROM layout depends on it.
- `versaoNaTela` keeps only characters that have a glyph and caps the text at 19 characters. If it's too long, the `+metadata` part is dropped first.
- `gen/versao.txt` records the version of the last build.

**CI** (`.github/workflows/ci.yml`, on `ubuntu-24.04`):
- **Build job:**
  - installs cc65, Pillow and SDL2 via apt, with Mesen 2.1.1 cached;
  - computes the version and compiles with `node build.js` (which includes the width checker);
  - runs `teste/ci.lua` headless;
  - uploads the ROM as an unzipped artifact (`archive: false`, `LosPastelles-<version>.sfc`, kept for 14 days).
- **Push to `main`:** the version is the next one (e.g. `0.0.2`). The `release` job (the only one with `contents: write`) creates the `v<version>` tag on the commit and publishes the release with the ROM.
  - Runs on `main` are queued, never in parallel, so two releases never compute the same version.
- **Pull requests:** the version is `<next>-pr.<number>+<sha>`. The PR's ROM is the artifact of the run, linked in the run summary. A new push cancels the PR's previous run.
- **Skipped changes:** changes only to `*.md`, `cartucho/`, `trailer/` or `.gitignore` don't run CI (and don't release).

**How to cut a new version:**
- **PATCH:** nothing to do. Every merge or push to `main` that passes the tests releases the next PATCH automatically (`0.0.1`, `0.0.2`, …).
- **MINOR or MAJOR:** change `VERSION` (e.g. to `0.1.0` or `1.0.0`) in the same commit/PR as the change. The next release uses that version, and later ones continue from it (`0.1.1`, …). Never lower `VERSION` below the latest tag (it would be ignored).
- To check what the next release will be: `git fetch --tags && node gerador/versao.js --proxima`.

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
- To show a controller button inside text, use the tokens `{A}` `{B}` `{X}` `{Y}` `{CIMA}` `{BAIXO}` `{ESQ}` `{DIR}` (never a bare letter):
  - `compile()` turns each token into a transparent glyph (codes `FONT_BTN0`…`FONT_BTN0+N_BTN-1`).
  - `PrintStr`/`TypeStep` record its position via `BtnReg` in `ui.s`.
  - Every frame, `BtnSprites` draws a colored 8×8 button sprite (`SPR_BTN8_*`, sprite palette 0) over each recorded position that still holds the glyph.
  - At most 12 buttons can be on screen at once.
- Dialog-box footers (action hints such as `{A}: CONTINUAR`) are printed with `Footer` in `ui.s` (X = text, A = row; the boxes use row 26, which straddles the panel's bottom edge):
  - It centers the text and records it, and `PillSprites` draws a cream gradient "pill" behind it every frame, made of 16×16 sprites `SPR_PILULA_*` (sprite palette 1).
  - The pill disappears when the text in that position changes.
- Reserved OAM slots (`vars.inc`): 100–111 for buttons (`OAM_BTN`), 112–127 for the pill (`OAM_PILL`). `AddSprite` stops at `OAM_BTN`. Lower slot numbers draw in front, which keeps the buttons over the pill.
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

### Tutorial balloon (day 1)
`TutBox` (in `game.s`) sets `dim_on = 2`, and the NMI then calls `TutNmi` (in `ui.s`):
- It turns on BG2, which holds the cream balloon (`tutBalloon` in `arte.js`). `LoadShopScene` loads its tiles (from tile 960), map and palette 3. Box size and position (`TUT_X0`…) come from `TUT_BOX` in `arte.js`.
- Window 1 hides BG1 inside the balloon. HDMA channel 6 limits the window to the balloon's rows.
- HDMA channel 7 changes `CGADSUB` per line, so BG3 (the HUD) is darkened outside the balloon.
- `TutSprites` lowers game sprites to priority 2 so they go behind the balloon (BG2 with high priority).

### Game loop and state machine
`MainLoop` in `main.s` dispatches through the `StateInit`/`StateUpdate` jump tables (`src/telas.s`), indexed by `state`. The `ST_*` constants are defined at the top of `src/game.s` (title, intro, card, preday, day, results, shop, map, options, choose, slots, splash, trophies, secret). To change screens, write to `next_state`. The main loop runs the new state's Init once, then calls Update every frame, followed by `UiUpdate`, `AudioUpdate`, `WaitFrame` and `ReadPad`. NMI uploads OAM, palettes and VRAM from RAM buffers.
- `game.s` is the in-day gameplay: frying, customers, minigame, deliveries. `telas.s` holds the screens and menus, `extra.s` additional features, `segredo.s` the secret cheat menu, `ui.s` the HDMA panels and icons, and `audio.s` the APU upload and the music and SFX sequencer.
- `src/vars.inc` declares the RAM variables. The block between `save_start` and `save_end` is copied to SRAM as one unit (3 save slots) and **must stay contiguous**. Adding, removing or reordering fields there changes the save format.

### Other folders
`cartucho/` holds the label, manual, photos and exported art for the physical cartridge. `trailer/` holds the final trailer MP4. `roteiro_*.md` is the game's design and story script.
