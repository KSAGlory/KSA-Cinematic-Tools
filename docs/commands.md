# Commands

All commands require a logged-in account in the MTA `Admin` ACL group. IDs in the examples are examples, not fixed model or saved-object IDs.

## Objects

| Command | Action |
| --- | --- |
| `/obj <model ID>` | Create and save an object a short distance in front of you. |
| `/objfind <name fragment>` | Search up to eight catalog matches, for example `/objfind lamp`. |
| `/objmove <saved ID>` | Move a saved object to your position. |
| `/objrot <saved ID> <x> <y> <z>` | Set its rotation; omitted values use the command defaults. |
| `/objdup <saved ID>` | Duplicate a saved object. |
| `/objdel <saved ID>` | Delete a saved object. |
| `/objlist` | List saved object IDs and models. |

## NPC scene actors

| Command | Action |
| --- | --- |
| `/cinpc <skin ID>` | Create and save an NPC near you. |
| `/npcmove <saved ID>` | Move a saved NPC to your position. |
| `/npcrot <saved ID> <degrees>` | Rotate a saved NPC. |
| `/npcfreeze <saved ID> on/off` | Freeze or unfreeze an NPC. |
| `/npcinvuln <saved ID> on/off` | Toggle damage cancellation for that NPC. |
| `/npcpassive <saved ID> on/off` | Toggle the passive flag; enabling it removes that NPC's weapons. |
| `/npcanim <saved ID> <block> <animation>` | Set and save an animation. |
| `/npcclearanim <saved ID>` | Clear a saved animation. |
| `/npcdel <saved ID>` | Delete a saved NPC. |
| `/npclist` | List saved NPC IDs and skin models. |

## Skin and export

| Command | Action |
| --- | --- |
| `/skinset <skin ID>` | Apply and save a skin for your MTA account. |
| `/skinsave` | Save your current skin. |
| `/skinrestore` | Reapply your saved skin. |
| `/skinreset` | Remove your saved cinematic skin and set skin 0. |
| `/studioexport` | Overwrite `cinematic_export.map` with current saved objects and NPCs. |
| `/studiohelp` | Show the built-in command summary. |
