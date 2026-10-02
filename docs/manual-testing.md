# Manual testing

Run this preview on a separate MTA test server before installing it on a live server. Back up any existing `studio.db` and `cinematic_export.map` before updating.

1. Confirm the resource loads without Lua errors and creates a new resource-local `studio.db`.
2. Confirm a non-Admin account cannot use `/obj`, `/cinpc`, `/skinset`, or `/studioexport`.
3. As Admin, create an object, find its model with `/objfind`, move, rotate, duplicate, list, and delete it. Check the results visually.
4. Create an NPC, move/rotate/freeze it, set and clear an animation, toggle invulnerability and passive state, then delete it.
5. Save a skin, reconnect and respawn, confirm restoration, then reset it. Confirm unrelated account data is unchanged.
6. Restart only this resource and confirm saved objects/NPCs reappear without duplicates.
7. Export a map, inspect its contents, and verify that running the export again intentionally overwrites the previous `cinematic_export.map`.
8. Check server logs and client FPS for errors or unexpected load. Test alongside Freeroam, Admin, CameraTool, and other resources in your own setup.

Document actual results and environment versions. A clean startup alone is not a gameplay test.
