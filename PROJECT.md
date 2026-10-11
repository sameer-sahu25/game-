# BATTLE LEGENDS — project handoff

Stylized third-person Roblox fighter. Tagline: **Fight. Win. Become a Legend.**

**Open this first:** [STATUS.md](STATUS.md) · [docs/INSTALL.md](docs/INSTALL.md) · [docs/CONTROLS.md](docs/CONTROLS.md)

## Layout

```
default.project.json          Rojo map
src/shared                    ReplicatedStorage.BattleLegends
src/server                    ServerScriptService.BattleLegends
  ServerBootstrap.luau        Script
  World/                      Procedural maps
  Services/                   Combat, match, data, economy, NPC, security
src/client                    LocalScript UI + input + camera
docs/                         Install, test, publish, assets
```

The original product documents remain at the repo root (readme master prompt, SRS, PRD, combat rules, phases).

## Security model

Clients send **intent** (`Light`, `Heavy`, `Dodge`, …). The server owns damage, coins, unlocks, and match scores. Empty animation/audio IDs are intentional.
