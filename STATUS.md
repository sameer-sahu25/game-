# STATUS — BATTLE LEGENDS

Honest QA labels per the development-phase document: implementation is **not** the same as Studio acceptance.

## Implemented in this repository (code complete, Studio untested)

- Rojo DataModel map (`default.project.json`)
- Shared config: fighters, abilities, shop, achievements, schema v1
- Procedural lobby + five arenas + lighting effects
- Server-authoritative combat (range, cooldown, LOS, team FF off for 2v2)
- FFA match lifecycle with solo Studio flag
- Duel, 2v2, Survival (NPC waves), training dummy commands
- DataStore load/save with retries, failed-load save guard, BindToClose
- Battle Coins, XP/level, daily claim, coin shop unlocks (no P2W stats)
- HUD + menu + mobile buttons + third-person camera
- Rate-limited combat remotes; basic speed correction

## Needs your Roblox account

- Animation IDs, audio IDs
- API Services for persistence
- Place publish

## Not finished / limited

- Custom R15 keyframe playback (IDs empty; default Animate script still runs)
- Ranked MMR, parties, private servers, Roblox PromptGamePass
- Pathfinding-quality AI (NPCs use `Humanoid:MoveTo`)
- Performance profiling on device
- Promotional renders
- Lobby pad proximity auto-open (menu is the interaction layer)

## MVP gate (docs)

Lobby, Eternal Arena, two starters, light/heavy/block/dodge, one special each, FFA loop, HUD, PC/mobile intent — **present in code**. **Studio Play + 2-client combat is the remaining acceptance test.**
