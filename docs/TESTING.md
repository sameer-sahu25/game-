# Testing checklist

Legend: **I** implemented in this repo · **S** needs Studio · **A** needs uploaded assets · **C** needs live DataStore / creator config

## Phase gates

| Phase | Focus | Status |
| --- | --- | --- |
| 1 Foundation | Rojo tree, remotes, bootstrap | I, not S |
| 2 World | Procedural lobby + 5 arenas + lighting | I, not S |
| 3 Characters | 8 configs, 2 starters equippable | I, not S |
| 4 Combat | Light/heavy/block/dodge, server hits | I, not S |
| 5 Abilities | All 8 specials + ultimates | I, not S; A for anim/sfx |
| 6 UI | Menu, HUD, mobile cluster | I, not S |
| 7 Modes | FFA MVP; Duel/2v2/Survival wired | I, not S |
| 8 Progression | XP, coins, DataStore schema v1 | I; C for persistence |
| 9 Content | 5 maps, 8 fighters, dummies, NPC waves | I, not S |
| 10 Optimization | Budgets documented, not profiled | Planned S |
| 11 Polish | Tutorial banner, theme | Partial I |
| 12 Publish | Checklist only | Docs only |

## Functional (run in Studio)

- [ ] Place starts without red errors
- [ ] Lobby geometry underfoot, spawn not falling
- [ ] Eternal Arena teleport on FFA queue
- [ ] Light attack cooldown cannot be spammed past `LightCooldown`
- [ ] Dummy Humanoid health drops; floating damage numbers
- [ ] Heavy attack delayed by startup
- [ ] Block reduces damage; dodge grants brief i-frames
- [ ] Special spends energy; ultimate requires meter
- [ ] Match timer / results / return to lobby
- [ ] Shop purchase rejected if coins insufficient
- [ ] Failed DataStore load does not save defaults (disable network to simulate)

## Security

- [ ] Client cannot FireServer damage amounts (payload is intent only)
- [ ] Invalid fighter id rejected
- [ ] Shop item id unknown rejected
- [ ] Combat remote rate limited

## Devices

- [ ] PC mouse combat
- [ ] Touch buttons visible when TouchEnabled
- [ ] Menu readable at 1280×720 and phone-like emulator
