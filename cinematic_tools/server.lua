-- Admin-only persistent object and NPC placement for cinematic work.
-- Commands intentionally use the chat console so it does not compete with
-- Inventory, Phone, CameraTool, Freecam, or the existing map resources.

local db
local objects, peds = {}, {}

local function isAdmin(player)
    local account = getPlayerAccount(player)
    return account and not isGuestAccount(account)
        and isObjectInACLGroup("user." .. getAccountName(account), aclGetGroup("Admin"))
end

local function tell(player, text, r, g, b)
    outputChatBox("[Cinematic] " .. text, player, r or 100, g or 200, b or 255)
end

local function requireAdmin(player)
    if isAdmin(player) then return true end
    tell(player, "This tool is available to administrators only.", 255, 80, 80)
    return false
end

local function dbRows(query, ...)
    local result = dbPoll(dbQuery(db, query, ...), -1)
    return result or {}
end

local function lastInsertId()
    local result = dbRows("SELECT last_insert_rowid() AS id")
    return result[1] and tonumber(result[1].id) or nil
end

local function getAccountNameFor(player)
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then return nil, nil end
    return getAccountName(account), account
end

local function getSavedSkin(player)
    local accountName = getAccountNameFor(player)
    if not accountName then return nil end
    local rows = dbRows("SELECT model FROM owner_skins WHERE account_name=?", accountName)
    return rows[1] and tonumber(rows[1].model) or nil
end

local function restoreSavedSkin(player)
    local model = getSavedSkin(player)
    if model and isElement(player) and not isPedDead(player) then setElementModel(player, model) end
    return model
end

local function saveSkin(player, model)
    local accountName = getAccountNameFor(player)
    if not accountName then return false end
    return dbExec(db, "INSERT OR REPLACE INTO owner_skins (account_name, model) VALUES (?, ?)", accountName, model)
end

local function playerPlacement(player, distance)
    local x, y, z = getElementPosition(player)
    local rotation = getPedRotation(player)
    local angle = math.rad(rotation)
    return x + math.sin(angle) * distance, y + math.cos(angle) * distance, z, rotation
end

local function saveObject(id, element)
    if not isElement(element) then return false end
    local x, y, z = getElementPosition(element)
    local rx, ry, rz = getElementRotation(element)
    return dbExec(db, "UPDATE placed_objects SET x=?, y=?, z=?, rx=?, ry=?, rz=?, interior=?, dimension=? WHERE id=?",
        x, y, z, rx, ry, rz, getElementInterior(element), getElementDimension(element), id)
end

local function savePed(id, element)
    if not isElement(element) then return false end
    local x, y, z = getElementPosition(element)
    local _, _, rz = getElementRotation(element)
    return dbExec(db, "UPDATE placed_peds SET x=?, y=?, z=?, rz=?, interior=?, dimension=?, frozen=?, invulnerable=?, passive=? WHERE id=?",
        x, y, z, rz, getElementInterior(element), getElementDimension(element), isElementFrozen(element) and 1 or 0,
        getElementData(element, "cinematic:invulnerable") and 1 or 0, getElementData(element, "cinematic:passive") and 1 or 0, id)
end

local function spawnObject(row)
    local object = createObject(tonumber(row.model), tonumber(row.x), tonumber(row.y), tonumber(row.z), tonumber(row.rx), tonumber(row.ry), tonumber(row.rz))
    if not object then return false end
    setElementInterior(object, tonumber(row.interior) or 0)
    setElementDimension(object, tonumber(row.dimension) or 0)
    setElementData(object, "cinematic:id", tonumber(row.id), false)
    objects[tonumber(row.id)] = object
    return object
end

local function applyPedState(ped, row)
    setElementFrozen(ped, tonumber(row.frozen) == 1)
    setElementData(ped, "cinematic:invulnerable", tonumber(row.invulnerable) == 1, false)
    setElementData(ped, "cinematic:passive", tonumber(row.passive) == 1, false)
    if tonumber(row.passive) == 1 then takeAllWeapons(ped) end
    if row.anim_block and row.anim_name and row.anim_block ~= "" and row.anim_name ~= "" then
        setPedAnimation(ped, row.anim_block, row.anim_name, -1, true, false, false, false)
    end
end

local function spawnPed(row)
    local ped = createPed(tonumber(row.model), tonumber(row.x), tonumber(row.y), tonumber(row.z), tonumber(row.rz))
    if not ped then return false end
    setElementInterior(ped, tonumber(row.interior) or 0)
    setElementDimension(ped, tonumber(row.dimension) or 0)
    setElementData(ped, "cinematic:id", tonumber(row.id), false)
    applyPedState(ped, row)
    peds[tonumber(row.id)] = ped
    return ped
end

local function getObject(id) return objects[tonumber(id)] end
local function getPed(id) return peds[tonumber(id)] end

local function createObjectCommand(player, _, model)
    if not requireAdmin(player) then return end
    model = tonumber(model)
    if not model then return tell(player, "Usage: /obj <model ID>", 255, 180, 80) end
    local x, y, z, rz = playerPlacement(player, 2.5)
    local object = createObject(model, x, y, z, 0, 0, rz)
    if not object then return tell(player, "That object model could not be created.", 255, 80, 80) end
    setElementInterior(object, getElementInterior(player))
    setElementDimension(object, getElementDimension(player))
    if not dbExec(db, "INSERT INTO placed_objects (model,x,y,z,rx,ry,rz,interior,dimension) VALUES (?,?,?,?,?,?,?,?,?)",
        model, x, y, z, 0, 0, rz, getElementInterior(player), getElementDimension(player)) then
        destroyElement(object)
        return tell(player, "The object could not be saved.", 255, 80, 80)
    end
    local id = lastInsertId()
    setElementData(object, "cinematic:id", id, false)
    objects[id] = object
    tell(player, "Object #" .. id .. " created and saved.")
end

local function setSkinCommand(player, _, model)
    if not requireAdmin(player) then return end
    model = tonumber(model)
    if not model then return tell(player, "Usage: /skinset <skin ID>", 255, 180, 80) end
    if not setElementModel(player, model) then return tell(player, "That skin ID could not be applied.", 255, 80, 80) end
    if saveSkin(player, model) then tell(player, "Skin " .. model .. " is now saved permanently for your account.")
    else tell(player, "The skin was applied but could not be saved.", 255, 80, 80) end
end

local function saveCurrentSkinCommand(player)
    if not requireAdmin(player) then return end
    local model = getElementModel(player)
    if saveSkin(player, model) then tell(player, "Current skin " .. model .. " saved permanently.")
    else tell(player, "Your current skin could not be saved.", 255, 80, 80) end
end

local function restoreSkinCommand(player)
    if not requireAdmin(player) then return end
    local model = restoreSavedSkin(player)
    if model then tell(player, "Restored your saved skin " .. model .. ".")
    else tell(player, "No cinematic skin is saved for your account.", 255, 180, 80) end
end

local function resetSkinCommand(player)
    if not requireAdmin(player) then return end
    local accountName = getAccountNameFor(player)
    if not accountName then return tell(player, "Log in before resetting your skin.", 255, 80, 80) end
    dbExec(db, "DELETE FROM owner_skins WHERE account_name=?", accountName)
    setElementModel(player, 0)
    tell(player, "Your cinematic skin was reset to the normal default skin.")
end

local function findObjectCommand(player, _, ...)
    if not requireAdmin(player) then return end
    local needle = table.concat({...}, " "):lower()
    if needle == "" then return tell(player, "Usage: /objfind <part of an object name>", 255, 180, 80) end

    local matches = {}
    -- The bundled MTA editor catalogue is only searched on this explicit
    -- admin command; it never runs in a frame/timer path.
    for model = 321, 20000 do
        local name = getObjectNameFromModel(model)
        if name and name:lower():find(needle, 1, true) then
            table.insert(matches, model .. " " .. name)
            if #matches == 8 then break end
        end
    end
    if #matches == 0 then return tell(player, "No GTA:SA object models match '" .. needle .. "'.", 255, 180, 80) end
    tell(player, "Object matches for '" .. needle .. "' (use /obj <model ID>):")
    -- outputChatBox has a short practical message limit.  One match per line
    -- avoids silently losing a long list such as /objfind lamp or gate.
    for _, match in ipairs(matches) do tell(player, "  /obj " .. match) end
end

local function moveObjectCommand(player, _, id)
    if not requireAdmin(player) then return end
    local object = getObject(id)
    if not isElement(object) then return tell(player, "Object not found. Use /objlist.", 255, 80, 80) end
    local x, y, z = getElementPosition(player)
    setElementPosition(object, x, y, z)
    setElementInterior(object, getElementInterior(player))
    setElementDimension(object, getElementDimension(player))
    saveObject(tonumber(id), object)
    tell(player, "Object #" .. id .. " moved to your position.")
end

local function rotateObjectCommand(player, _, id, rx, ry, rz)
    if not requireAdmin(player) then return end
    local object = getObject(id)
    if not isElement(object) then return tell(player, "Object not found.", 255, 80, 80) end
    rx, ry, rz = tonumber(rx) or 0, tonumber(ry) or 0, tonumber(rz) or getPedRotation(player)
    setElementRotation(object, rx, ry, rz)
    saveObject(tonumber(id), object)
    tell(player, "Object #" .. id .. " rotated and saved.")
end

local function duplicateObjectCommand(player, _, id)
    if not requireAdmin(player) then return end
    local source = getObject(id)
    if not isElement(source) then return tell(player, "Object not found.", 255, 80, 80) end
    local x, y, z = getElementPosition(source)
    local rx, ry, rz = getElementRotation(source)
    local clone = createObject(getElementModel(source), x + 1.5, y + 1.5, z, rx, ry, rz)
    if not clone then return tell(player, "Object duplication failed.", 255, 80, 80) end
    setElementInterior(clone, getElementInterior(source))
    setElementDimension(clone, getElementDimension(source))
    dbExec(db, "INSERT INTO placed_objects (model,x,y,z,rx,ry,rz,interior,dimension) VALUES (?,?,?,?,?,?,?,?,?)",
        getElementModel(clone), x + 1.5, y + 1.5, z, rx, ry, rz, getElementInterior(clone), getElementDimension(clone))
    local newId = lastInsertId()
    setElementData(clone, "cinematic:id", newId, false)
    objects[newId] = clone
    tell(player, "Object duplicated as #" .. newId .. ".")
end

local function deleteObjectCommand(player, _, id)
    if not requireAdmin(player) then return end
    local object = getObject(id)
    if not isElement(object) then return tell(player, "Object not found.", 255, 80, 80) end
    destroyElement(object)
    objects[tonumber(id)] = nil
    dbExec(db, "DELETE FROM placed_objects WHERE id=?", tonumber(id))
    tell(player, "Object #" .. id .. " deleted.")
end

local function listObjectsCommand(player)
    if not requireAdmin(player) then return end
    local rows = dbRows("SELECT id, model FROM placed_objects ORDER BY id")
    if #rows == 0 then return tell(player, "No saved cinematic objects.") end
    local lines = {}
    for _, row in ipairs(rows) do table.insert(lines, "#" .. row.id .. " (model " .. row.model .. ")") end
    tell(player, "Objects: " .. table.concat(lines, ", "))
end

local function createPedCommand(player, _, model)
    if not requireAdmin(player) then return end
    model = tonumber(model)
    if not model then return tell(player, "Usage: /cinpc <skin ID>", 255, 180, 80) end
    local x, y, z, rz = playerPlacement(player, 2.0)
    local ped = createPed(model, x, y, z, rz)
    if not ped then return tell(player, "That ped skin could not be created.", 255, 80, 80) end
    setElementInterior(ped, getElementInterior(player))
    setElementDimension(ped, getElementDimension(player))
    dbExec(db, "INSERT INTO placed_peds (model,x,y,z,rz,interior,dimension,frozen,invulnerable,passive,anim_block,anim_name) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
        model, x, y, z, rz, getElementInterior(player), getElementDimension(player), 0, 0, 1, "", "")
    local id = lastInsertId()
    setElementData(ped, "cinematic:id", id, false)
    setElementData(ped, "cinematic:passive", true, false)
    peds[id] = ped
    tell(player, "NPC #" .. id .. " created beside you and saved.")
end

local function movePedCommand(player, _, id)
    if not requireAdmin(player) then return end
    local ped = getPed(id)
    if not isElement(ped) then return tell(player, "NPC not found. Use /npclist.", 255, 80, 80) end
    local x, y, z = getElementPosition(player)
    setElementPosition(ped, x, y, z)
    setElementInterior(ped, getElementInterior(player))
    setElementDimension(ped, getElementDimension(player))
    savePed(tonumber(id), ped)
    tell(player, "NPC #" .. id .. " moved to your position.")
end

local function rotatePedCommand(player, _, id, rz)
    if not requireAdmin(player) then return end
    local ped = getPed(id)
    if not isElement(ped) then return tell(player, "NPC not found.", 255, 80, 80) end
    setElementRotation(ped, 0, 0, tonumber(rz) or getPedRotation(player))
    savePed(tonumber(id), ped)
    tell(player, "NPC #" .. id .. " rotated and saved.")
end

local function pedFlagCommand(flag)
    return function(player, _, id, value)
        if not requireAdmin(player) then return end
        local ped = getPed(id)
        if not isElement(ped) then return tell(player, "NPC not found.", 255, 80, 80) end
        local enabled = value == nil or value == "on" or value == "true" or value == "1"
        if flag == "frozen" then setElementFrozen(ped, enabled)
        elseif flag == "invulnerable" then setElementData(ped, "cinematic:invulnerable", enabled, false)
        elseif flag == "passive" then
            setElementData(ped, "cinematic:passive", enabled, false)
            if enabled then takeAllWeapons(ped) end
        end
        savePed(tonumber(id), ped)
        tell(player, "NPC #" .. id .. " " .. flag .. " set to " .. (enabled and "on" or "off") .. ".")
    end
end

local function animatePedCommand(player, _, id, block, animation)
    if not requireAdmin(player) then return end
    local ped = getPed(id)
    if not isElement(ped) or not block or not animation then return tell(player, "Usage: /npcanim <id> <block> <animation>", 255, 180, 80) end
    setPedAnimation(ped, block, animation, -1, true, false, false, false)
    dbExec(db, "UPDATE placed_peds SET anim_block=?, anim_name=? WHERE id=?", block, animation, tonumber(id))
    tell(player, "NPC #" .. id .. " animation saved.")
end

local function clearAnimationCommand(player, _, id)
    if not requireAdmin(player) then return end
    local ped = getPed(id)
    if not isElement(ped) then return tell(player, "NPC not found.", 255, 80, 80) end
    setPedAnimation(ped)
    dbExec(db, "UPDATE placed_peds SET anim_block='', anim_name='' WHERE id=?", tonumber(id))
    tell(player, "NPC #" .. id .. " animation cleared.")
end

local function deletePedCommand(player, _, id)
    if not requireAdmin(player) then return end
    local ped = getPed(id)
    if not isElement(ped) then return tell(player, "NPC not found.", 255, 80, 80) end
    destroyElement(ped)
    peds[tonumber(id)] = nil
    dbExec(db, "DELETE FROM placed_peds WHERE id=?", tonumber(id))
    tell(player, "NPC #" .. id .. " deleted.")
end

local function listPedsCommand(player)
    if not requireAdmin(player) then return end
    local rows = dbRows("SELECT id, model FROM placed_peds ORDER BY id")
    if #rows == 0 then return tell(player, "No saved cinematic NPCs.") end
    local lines = {}
    for _, row in ipairs(rows) do table.insert(lines, "#" .. row.id .. " (skin " .. row.model .. ")") end
    tell(player, "NPCs: " .. table.concat(lines, ", "))
end

local function exportCommand(player)
    if not requireAdmin(player) then return end
    if fileExists("cinematic_export.map") then fileDelete("cinematic_export.map") end
    local xml = xmlCreateFile("cinematic_export.map", "map")
    if not xml then return tell(player, "Could not create cinematic_export.map.", 255, 80, 80) end
    for _, row in ipairs(dbRows("SELECT * FROM placed_objects ORDER BY id")) do
        local node = xmlCreateChild(xml, "object")
        for _, key in ipairs({"id", "model", "x", "y", "z", "rx", "ry", "rz", "interior", "dimension"}) do
            xmlNodeSetAttribute(node, key == "id" and "id" or ({x="posX",y="posY",z="posZ",rx="rotX",ry="rotY",rz="rotZ"})[key] or key, tostring(row[key]))
        end
    end
    for _, row in ipairs(dbRows("SELECT * FROM placed_peds ORDER BY id")) do
        local node = xmlCreateChild(xml, "ped")
        xmlNodeSetAttribute(node, "id", "cinematic_ped_" .. row.id)
        xmlNodeSetAttribute(node, "model", tostring(row.model))
        xmlNodeSetAttribute(node, "posX", tostring(row.x))
        xmlNodeSetAttribute(node, "posY", tostring(row.y))
        xmlNodeSetAttribute(node, "posZ", tostring(row.z))
        xmlNodeSetAttribute(node, "rotZ", tostring(row.rz))
        xmlNodeSetAttribute(node, "interior", tostring(row.interior))
        xmlNodeSetAttribute(node, "dimension", tostring(row.dimension))
    end
    xmlSaveFile(xml)
    xmlUnloadFile(xml)
    tell(player, "Exported cinematic_export.map in the cinematic_tools resource.")
end

addEventHandler("onPedDamage", root, function()
    if getElementData(source, "cinematic:invulnerable") then cancelEvent() end
end)

addEventHandler("onResourceStart", resourceRoot, function()
    db = dbConnect("sqlite", "studio.db")
    if not db then return outputDebugString("cinematic_tools: SQLite connection failed", 1) end
    dbExec(db, "CREATE TABLE IF NOT EXISTS placed_objects (id INTEGER PRIMARY KEY AUTOINCREMENT, model INTEGER, x REAL, y REAL, z REAL, rx REAL, ry REAL, rz REAL, interior INTEGER, dimension INTEGER)")
    dbExec(db, "CREATE TABLE IF NOT EXISTS placed_peds (id INTEGER PRIMARY KEY AUTOINCREMENT, model INTEGER, x REAL, y REAL, z REAL, rz REAL, interior INTEGER, dimension INTEGER, frozen INTEGER, invulnerable INTEGER, passive INTEGER, anim_block TEXT, anim_name TEXT)")
    dbExec(db, "CREATE TABLE IF NOT EXISTS owner_skins (account_name TEXT PRIMARY KEY, model INTEGER NOT NULL)")
    for _, row in ipairs(dbRows("SELECT * FROM placed_objects")) do spawnObject(row) end
    for _, row in ipairs(dbRows("SELECT * FROM placed_peds")) do spawnPed(row) end
    for _, player in ipairs(getElementsByType("player")) do setTimer(restoreSavedSkin, 500, 1, player) end
end)

addEventHandler("onPlayerLogin", root, function()
    setTimer(restoreSavedSkin, 750, 1, source)
end)

addEventHandler("onPlayerSpawn", root, function()
    setTimer(restoreSavedSkin, 750, 1, source)
end)

addCommandHandler("obj", createObjectCommand)
addCommandHandler("skinset", setSkinCommand)
addCommandHandler("skinsave", saveCurrentSkinCommand)
addCommandHandler("skinrestore", restoreSkinCommand)
addCommandHandler("skinreset", resetSkinCommand)
addCommandHandler("objfind", findObjectCommand)
addCommandHandler("objmove", moveObjectCommand)
addCommandHandler("objrot", rotateObjectCommand)
addCommandHandler("objdup", duplicateObjectCommand)
addCommandHandler("objdel", deleteObjectCommand)
addCommandHandler("objlist", listObjectsCommand)
addCommandHandler("cinpc", createPedCommand)
addCommandHandler("npcmove", movePedCommand)
addCommandHandler("npcrot", rotatePedCommand)
addCommandHandler("npcfreeze", pedFlagCommand("frozen"))
addCommandHandler("npcinvuln", pedFlagCommand("invulnerable"))
addCommandHandler("npcpassive", pedFlagCommand("passive"))
addCommandHandler("npcanim", animatePedCommand)
addCommandHandler("npcclearanim", clearAnimationCommand)
addCommandHandler("npcdel", deletePedCommand)
addCommandHandler("npclist", listPedsCommand)
addCommandHandler("studioexport", exportCommand)
addCommandHandler("studiohelp", function(player)
    if not requireAdmin(player) then return end
    tell(player, "Objects: /obj /objfind /objmove /objrot /objdup /objdel /objlist. NPCs: /cinpc /npcmove /npcrot /npcfreeze /npcinvuln /npcpassive /npcanim /npcclearanim /npcdel /npclist. Skin: /skinset /skinsave /skinrestore /skinreset. Export: /studioexport")
end)
