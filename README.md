# KSA Cinematic Tools

Admin-only, chat-command tools for placing and saving objects and NPC scene actors in an MTA:SA server. You can search GTA:SA object model names, arrange props and NPCs, save a personal skin, and export placements as an MTA map file. There is no custom GUI, client script, or downloaded game asset.

This is a **public preview for testing**, not a claim that every command works on every MTA server. The private-server version was used during development, but the standalone public package has not yet completed an independent in-game test.

## Download

Get the ready-to-install package from [GitHub Releases](https://github.com/KSAGlory/KSA-Cinematic-Tools/releases). The ZIP contains source and documentation only. It contains no account data, saved scenes, server configuration, or GTA:SA assets.

## Requirements

- An MTA:SA server with the standard `Admin` ACL group and a logged-in administrator account.
- MTA's SQLite database functions enabled. The resource creates its own `studio.db` in the resource directory.
- GTA: San Andreas / MTA:SA for the referenced object model IDs and names.

## Install

1. Back up your server before adding a new resource.
2. Copy `cinematic_tools` into `mods/deathmatch/resources/`.
3. Refresh the server's resource list and start `cinematic_tools`, or add it to your normal startup configuration.
4. Log in with an account in the `Admin` ACL group and use `/studiohelp`.

This package uses a **resource-local** `studio.db`. It does not read or migrate the private-server version's global `:/studio.db`; do not replace a working installation expecting its saved content without planning a migration. Runtime databases and exported maps are deliberately excluded from this repository.

## Features and commands

| Area | Commands |
| --- | --- |
| Objects | `/obj`, `/objfind`, `/objmove`, `/objrot`, `/objdup`, `/objdel`, `/objlist` |
| NPC scene actors | `/cinpc`, `/npcmove`, `/npcrot`, `/npcfreeze`, `/npcinvuln`, `/npcpassive`, `/npcanim`, `/npcclearanim`, `/npcdel`, `/npclist` |
| Player skin | `/skinset`, `/skinsave`, `/skinrestore`, `/skinreset` |
| Export and help | `/studioexport`, `/studiohelp` |

See [all command arguments and examples](docs/commands.md). Objects and NPCs are saved to SQLite and recreated when the resource starts. The NPCs are **scene actors**, not autonomous AI; movement and animation are controlled by commands. `/studioexport` writes `cinematic_export.map` and overwrites the previous export, so save a copy before exporting again.

## Compatibility and limitations

- The public package removes private-server hooks for Misterix skin data and a mission-specific element-data flag. It does not require Misterix.
- The resource controls only elements it creates. It is not a replacement for the stock Map Editor, Freeroam, Freecam, or CameraTool.
- The object name search uses a catalog from the official MTA Map Editor; model availability still depends on GTA:SA/MTA. Search results are limited to eight matches per command.
- Saved NPCs do not pathfind, drive, attack, or simulate civilian behavior.
- The Admin ACL check and persistence commands should be tested on your own server before use in a live environment.

Follow the [manual test checklist](docs/manual-testing.md) before treating this preview as ready for production.

## Third-party attribution

`cinematic_tools/object_catalog.lua` is an unmodified copy of the official MTA Map Editor's [`getObjectNameFromModel.lua`](https://github.com/multitheftauto/mtasa-resources/blob/master/%5Beditor%5D/editor_main/server/getObjectNameFromModel.lua). It is included under the [MTA resources MIT license](third_party/MTASA-RESOURCES-LICENSE), with details in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The object catalog was **not** authored by KSAGlory.

## Contributing

Focused bug reports and improvements are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Author and community

- KSA Cinematic Tools code and maintenance: **KSAGlory**
- Community: [discord.gg/ksahub](https://discord.gg/ksahub)

## License

The KSA Cinematic Tools code is under the [MIT License](LICENSE). The bundled MTA catalog carries its own MIT copyright notice as described above. GTA:SA, MTA:SA, and any third-party server resources are separate projects and are not bundled.
Copyright © 2026 KSAGlory. All rights reserved.
