# Assets that cannot be invented

Do not put fake `rbxassetid` numbers in the game.

## Must upload on your account

| Kind | Where to plug in | Notes |
| --- | --- | --- |
| Movement / combat animations | `src/shared/AnimationIds.luau` | R15, Action priority for attacks |
| Licensed or original music/SFX | `src/shared/AudioIds.luau` | Roblox audio privacy rules |
| Custom meshes / textures | Import to `ServerStorage` then clone | Optional; parts already generate the world |
| Game icon / thumbnails | Creator Dashboard | Original art only |

## Generated in-engine (no upload)

- Lobby platform, monument, crystals, pads, portal
- Eternal Arena, Dragonfall Temple, Inferno Fortress, Skyblade Dojo, Cybernetic City
- Training dummies
- Fighter color overlays and neon cores
- UI (ScreenGui built in `ClientBootstrap`)
- Hit pulses and damage numbers

## Animation production spec (if you animate in Blender / Studio)

Export R15 KeyframeSequences, upload, paste IDs. Priorities:

- Idle/Walk/Run: Movement / Idle
- Light/Heavy/Special/Ult: Action
- Hit react: Action, shorter than attacks

Loop idle and walk. One-shots for attacks.

## Blender (optional hero meshes)

Keep under a few thousand triangles per accessory. Import as FBX, set as MeshPart, weld to UpperTorso. Do not replace HumanoidRootPart.
