# Battle Legends — Studio installation

This folder is a **Rojo** project. There is no `.rbxl` binary in git; the server **builds the lobby and arenas at runtime**.

## Option A — Rojo (recommended)

1. Install [Rojo 7](https://rojo.space/docs/installation/) (Aftman pin is in `aftman.toml`, or `aftman install` if you use Aftman).
2. Install the Rojo plugin in Roblox Studio.
3. In a terminal at this folder:
   ```
   rojo serve
   ```
4. In Studio: File → New, then connect the Rojo plugin to `localhost:34872`.
5. Press **Play**. You should spawn in the circular lobby with the BATTLE LEGENDS title.

## Option B — Manual copy (no Rojo)

1. Create a new Baseplate in Studio.
2. Recreate this tree and paste ModuleScripts / Scripts to match `src/`:
   - `ReplicatedStorage/BattleLegends/` ← every file in `src/shared`
   - `ServerScriptService/BattleLegends/` ← `src/server` (Script named `ServerBootstrap`, modules under `Services` and `World`)
   - `StarterPlayer/StarterPlayerScripts/BattleLegendsClient/` ← `src/client` (`ClientBootstrap` must be a **LocalScript**)
3. Enable **API Services** only when you need live DataStores (see `docs/STUDIO_SETUP.md`).

## First play (MVP)

1. Play Solo.
2. Press **QUEUE FFA** (or walk to the red Matchmaking pad conceptually — queue is driven from the Play menu).
3. With `AllowSoloMatch = true` in `GameConfig`, a one-player FFA starts on **The Eternal Arena**.
4. Use LMB / mobile Punch against empty space or return and hit **training dummies** (cyan Training pad, south of the monument).
5. Press **M** to toggle the menu.

## Studio tests that are not available here

This environment cannot open Roblox Studio or start a live place. Treat in-Studio Play and 2-player local server as **required QA** before any public publish.
