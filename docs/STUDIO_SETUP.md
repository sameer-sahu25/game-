# Studio configuration

## Game Settings (published / team create)

| Setting | Value |
| --- | --- |
| Title | BATTLE LEGENDS |
| Genre | Fighting / Action |
| Playability | Private until QA passes |
| Enable Studio Access to API Services | On, for DataStore testing |
| Security | Allow HTTP **off** unless you add a future webhook (this project does not need HTTP) |

DataStores will **fail closed** in Studio if API access is off. The game still runs with **session-only** profiles and will **not** overwrite a failed load with empty data.

## Collision / character

- R15 is expected (default avatar). Appearance overlays (colors + neon core) are applied in `CharacterService`.
- Do not set client-authoritative `Humanoid.Health` from LocalScripts.

## Streaming

StreamingEnabled is left at Studio default. If you enable it later, keep lobby and the active arena in stream radius; spawn pads must exist before teleport.

## Multiplayer local test

Test → Players → 2 players. Queue FFA on both clients. Confirm damage is identical on both screens and that only the server health bar drops.

## Animations and audio

`AnimationIds` and `AudioIds` are empty on purpose. Upload assets on **your** account, then paste `rbxassetid://` values. Using IDs you do not own will fail at runtime.
