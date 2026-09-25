-- @fnnywys

local ALLOWED_UIDS = {
    [966434] = true,
}

local function verifyUIDAccess()
    local localPlayer = GetLocal()
    local attempts = 0
    
    while (not localPlayer or not localPlayer.userid or localPlayer.userid == 0) and attempts < 10 do
        Sleep(200)
        localPlayer = GetLocal()
        attempts = attempts + 1
    end

    if not localPlayer or not localPlayer.userid or localPlayer.userid == 0 then
        LogToConsole("`4[SYSTEM LOCK] `wGagal membaca User ID akun Anda!")
        return false
    end

    local currentUID = tonumber(localPlayer.userid)

    if not ALLOWED_UIDS[currentUID] then
        LogToConsole("`4[SYSTEM LOCK] `wAkses Ditolak! UID (`w" .. tostring(currentUID) .. "`4) tidak terdaftar.")
        return false
    end

    LogToConsole("`2[SYSTEM LOCK] `wAkses Diterima! Selamat datang, UID: `w" .. tostring(currentUID))
    return true
end

if not verifyUIDAccess() then
    return
end
-- =======================================================

local CMD_HOST          = "46.8.226.128:3000"
local CMD_POLL_INTERVAL = 2500
local autoRespawn       = false

local WHITELIST_IDS = { 536347, 494414, 188089, 748280, 240523, 996019 }

local LOCK = { x = 50, y = 51 }

local FLAGS = {
    basic    = { x = 29, y = 46 },
    inti     = { x = 71, y = 46 },
    recom    = { x = 29, y = 30 },
    infinity = { x = 71, y = 30 },
}

local VIP_DOORS = {
    basic = {
        { x=40, y=37 }, { x=40, y=39 }, { x=40, y=41 },
        { x=40, y=43 }, { x=40, y=45 }, { x=40, y=47 }, { x=40, y=49 },
    },
    inti = {
        { x=60, y=37 }, { x=60, y=39 }, { x=60, y=41 },
        { x=60, y=43 }, { x=60, y=45 }, { x=60, y=47 }, { x=60, y=49 },
    },
    recom = {
        { x=40, y=21 }, { x=40, y=23 }, { x=40, y=25 },
        { x=40, y=27 }, { x=40, y=29 }, { x=40, y=31 }, { x=40, y=33 },
    },
    infinity = {
        { x=60, y=21 }, { x=60, y=23 }, { x=60, y=25 },
        { x=60, y=27 }, { x=60, y=29 }, { x=60, y=31 }, { x=60, y=33 },
    },
}

local DBOX_WEBHOOK = "https://ptb.discord.com/api/webhooks/1505406932377145455/bmdWmNNJhEkkpuTn064Y_dQg5Lkw9Hit_XoGArpv0xkfO07wnvCGYoIBDpcHIPD5JAHz"

local VIP_BREAK_WEBHOOK    = "https://discord.com/api/webhooks/1192458938176778300/CQ-qyPvwRhdxiI5j59pEO1fVsawnY4Jjhs3oDa0hMPOz8KSGHpmCasaN0s0t_Pfc1exQ"
local VIP_BREAK_DISCORD_ID = "1176411157242839132"
local VIP_BREAK_ENABLE_TAG = true
local VIP_DOOR_ID          = 3798

local MODAL_REQ = { basic = 30, infinity = 200, inti = 80, recom = 150, all = 0 }
local ID_BGL  = 7188
local ID_BBGL = 11550

local FLAG_ORDER = { "basic", "inti", "recom", "infinity" }

local VIP_AUTO = {
    basic    = { 1, 2, 3, 4 },
    inti     = { 1, 2, 3, 4 },
    recom    = { 4, 5, 6, 7 },
    infinity = { 4, 5, 6, 7 },
}

local VALID_CMDS = {
    acc = true, unacc = true, unaccall = true, addflag = true, unflag = true,
    addvip = true, unvip = true, ping = true, afklog = true, afk = true, takeafk = true,
    accall = true,
}

local C = {
    ok   = "`2",
    err  = "`4",
    warn = "`9",
    info = "`e",
    txt  = "`w",
    dim  = "`s",
    hl   = "`#",
    blk  = "`b",
}

local ROOM_COLOR = {
    basic    = "`2",
    inti     = "`4",
    recom    = "`8",
    infinity = "`5",
}

-- Kurung [ ] selalu hitam (`b)
local TAG = C.blk .. "[" .. C.hl .. "@anotherv66" .. C.blk .. "]"

local function chatTag(name)
    return C.blk .. "[" .. C.hl .. name .. C.blk .. "] "
end

local function roomTag(ftype)
    return (ROOM_COLOR[ftype] or C.txt) .. tostring(ftype):upper() .. C.txt
end

local function formatNumbers(text, fallbackColor)
    local result = {}
    local currentColor = fallbackColor
    local i = 1
    local len = #text

    while i <= len do
        if text:sub(i, i) == "`" and i < len then
            local codeChar = text:sub(i + 1, i + 1)
            currentColor = "`" .. codeChar
            table.insert(result, currentColor)
            i = i + 2
        else
            local nextBacktick = text:find("`", i, true)
            local segment
            if nextBacktick then
                segment = text:sub(i, nextBacktick - 1)
                i = nextBacktick
            else
                segment = text:sub(i)
                i = len + 1
            end
            segment = segment:gsub("(%d+)", C.blk .. "%1" .. currentColor)
            table.insert(result, segment)
        end
    end

    return table.concat(result)
end

local function L(color, ...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    local rawText = table.concat(parts)
    local formattedText = formatNumbers(rawText, color)
    LogToConsole(TAG .. " " .. C.blk .. "[" .. color .. formattedText .. C.blk .. "]")
end

local DoorPositions = {}
local LastToucher   = {}

local isRunning           = false
local isFetchingUIDs      = false
local pendingUIDs         = {}
local pendingQueue        = {}
local pendingBalanceCheck = nil
local pollBlocked         = false

local WHITELIST = {}
for _, id in ipairs(WHITELIST_IDS) do WHITELIST[id] = true end

local ACCESS_FIELD = "access_on_userid_"

local function jsonEscape(s)
    s = tostring(s)
    s = s:gsub('\\', '\\\\'):gsub('"', '\\"')
    s = s:gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    s = s:gsub('[%z\1-\31]', '')
    return s
end

local function cName(raw)
    return (tostring(raw)
        :gsub("`.", "")
        :gsub("%s*%(%d+%)%s*", "")
        :gsub("%s*%[.-%]%s*", "")
        :gsub("@", "")
        :gsub("%s+$", ""))
end

local function normName(raw)
    return (tostring(raw)
        :gsub("`.", "")
        :gsub("%s*%(%d+%)%s*", "")
        :gsub("%s*%[.-%]%s*", "")
        :gsub("%s+", " ")
        :gsub("^%s+", ""):gsub("%s+$", "")
        :lower())
end

local function cleanTargetStr(target)
    return (tostring(target):gsub("[^%d%a%s_]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parseCmdLine(line)
    local parts = {}
    for word in line:gmatch("%S+") do table.insert(parts, word) end
    return parts
end

local function parseUidList(s)
    local t = {}
    for uid in s:gmatch("[^,]+") do
        local n = tonumber(uid)
        if n then t[#t + 1] = n end
    end
    return t
end

local function parseVipInput(raw)
    if not raw or raw == "" then return nil end
    raw = raw:gsub("%s+", "")
    if raw == "0" or raw:lower() == "all" then return "vip" end
    local clean = raw:gsub("[^1-7]", "")
    if clean == "" then return nil end
    return "vip" .. clean
end

local function fnywys(target)
    local list        = GetPlayerList()
    local cleanTarget = cleanTargetStr(target)

    if cleanTarget:match("^%d+$") then
        local numId = tonumber(cleanTarget)
        for _, p in pairs(list) do
            if p.userid == numId then return p, p.netid, tostring(p.userid) end
        end
        return nil, nil, tostring(numId)
    end

    local lower = cleanTarget:lower()
    for _, p in pairs(list) do
        if normName(p.name):find(lower, 1, true) then
            return p, p.netid, tostring(p.userid)
        end
    end
    return nil, nil, nil
end

local function isPlayerInWorld(target)
    local cleanTarget = cleanTargetStr(target)
    local list        = GetPlayerList()

    if cleanTarget:match("^%d+$") then
        local numId = tonumber(cleanTarget)
        for _, p in pairs(list) do
            if p.userid == numId then return true end
        end
        return false
    end

    local lower = cleanTarget:lower()
    for _, p in pairs(list) do
        if normName(p.name):find(lower, 1, true) then return true end
    end
    return false
end

local function respawnIfNeeded()
    if autoRespawn then SendPacket(2, "action|respawn\n") end
end

local function chat(text)
    SendPacket(2, "action|input\ntext|" .. text)
end

local function readAndClearCmd()
    local headers = {
        ["User-Agent"]      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        ["Accept"]          = "text/plain, application/json, */*",
        ["Accept-Language"] = "en-US,en;q=0.9",
        ["Cache-Control"]   = "no-cache",
        ["Connection"]      = "keep-alive",
    }
    local ok, res = pcall(MakeRequest, CMD_HOST .. "/cmd", "GET", headers)
    if not ok or not res then return nil end

    local content = tostring(res.content or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if content:find("<!DOCTYPE", 1, true) or content:find("<html", 1, true) then
        if not pollBlocked then
            pollBlocked = true
            L(C.err, "Poll diblokir Cloudflare")
        end
        return nil
    end
    if pollBlocked then
        pollBlocked = false
        L(C.ok, "Poll pulih")
    end
    if content == "" then return nil end

    local firstWord = content:match("^(%S+)")
    if not firstWord or not VALID_CMDS[firstWord:lower()] then return nil end

    L(C.info, "<- ", content)
    return content
end

local function clickTile(x, y)
    SendPacketRaw(false, { type=3, state=32, value=32, px=x, py=y, x=x*32, y=y*32 })
    Sleep(350)
end

local function sendLockEdit(x, y, netID, userID, value)
    clickTile(x, y)
    local pkt = "action|dialog_return\ndialog_name|lock_edit\n"
        .. "x|" .. x .. "|\ny|" .. y .. "|\n"
    if netID and value == 1 then pkt = pkt .. "targetNetID|" .. netID .. "\n" end
    pkt = pkt .. ACCESS_FIELD .. userID .. "|" .. value .. "\nis_public|0\nignore_empty|0\n"
    SendPacket(2, pkt)
    Sleep(300)
end

local function accLock(netID, userID)
    sendLockEdit(LOCK.x, LOCK.y, netID, userID, 1)
end

local function accFlag(netID, userID, flagType)
    local pos = FLAGS[flagType]
    if not pos then return end
    sendLockEdit(pos.x, pos.y, netID, userID, 1)
end

local function accVipDoor(netID, userID, flagType, vipIndex)
    local doors = VIP_DOORS[flagType]
    if not doors or not doors[vipIndex] then return end
    local door = doors[vipIndex]
    clickTile(door.x, door.y)
    local pkt = "action|dialog_return\ndialog_name|vip_edit\n"
        .. "x|" .. door.x .. "|\ny|" .. door.y .. "|\n"
    if netID then pkt = pkt .. "targetNetID|" .. netID .. "\n" end
    SendPacket(2, pkt .. userID .. "|1\n")
    Sleep(300)
end

local function unaccLock(userID)
    sendLockEdit(LOCK.x, LOCK.y, nil, userID, 0)
end

local function unaccFlag(userID, flagType)
    local pos = FLAGS[flagType]
    if not pos then return end
    sendLockEdit(pos.x, pos.y, nil, userID, 0)
end

local function unaccVipDoor(userID, flagType, vipIndex)
    local doors = VIP_DOORS[flagType]
    if not doors or not doors[vipIndex] then return end
    local door = doors[vipIndex]
    clickTile(door.x, door.y)
    SendPacket(2,
        "action|dialog_return\ndialog_name|vip_edit\n"
        .. "x|" .. door.x .. "|\ny|" .. door.y .. "|\n"
        .. userID .. "|0\n"
    )
    Sleep(300)
end

local function flagLabels(flagList)
    local out = {}
    for _, ftype in ipairs(flagList) do out[#out + 1] = roomTag(ftype) end
    return table.concat(out, " ") .. " "
end

local MAX_RESOLVE_RETRY = 5

local function requeueOrFail(action, target, flagType, vipArg, vipOnly, retryCount)
    retryCount = retryCount or 0
    if retryCount < MAX_RESOLVE_RETRY then
        L(C.dim, action, " ", target, " belum kebaca, retry ", retryCount + 1, "/", MAX_RESOLVE_RETRY)
        table.insert(pendingQueue, {
            action = action, target = target,
            flagType = flagType, vipArg = vipArg, vipOnly = vipOnly,
            retryCount = retryCount + 1,
        })
        return true
    end
    L(C.err, "Tidak ditemukan: ", target)
    return false
end

local function doAcc(target, flagType, vipArg, vipOnly, retryCount)
    retryCount = retryCount or 0
    local plr, netID, resolvedUID = fnywys(target)
    if not resolvedUID then
        requeueOrFail("acc", target, flagType, vipArg, vipOnly, retryCount)
        return
    end

    local pname    = plr and cName(plr.name) or ("UID:" .. resolvedUID)
    local userID   = resolvedUID
    local flagList = flagType == "all" and FLAG_ORDER or { flagType }
    isRunning      = true

    if not vipOnly then
        accLock(netID, userID)
        for _, ftype in ipairs(flagList) do accFlag(netID, userID, ftype) end
    end

    local resolvedVipArg = vipArg
    if not resolvedVipArg then
        local autoNums = ""
        for _, ftype in ipairs(flagList) do
            for _, n in ipairs(VIP_AUTO[ftype] or {}) do
                if not autoNums:find(tostring(n), 1, true) then
                    autoNums = autoNums .. tostring(n)
                end
            end
        end
        if autoNums ~= "" then resolvedVipArg = "vip" .. autoNums end
    end

    if resolvedVipArg then
        local vipNums = resolvedVipArg:match("^vip([1-7]+)$")
        for _, ftype in ipairs(flagList) do
            if vipNums then
                for v in vipNums:gmatch(".") do accVipDoor(netID, userID, ftype, tonumber(v)) end
            end
        end
    end

    Sleep(120)
    isRunning = false

    local flagInfo = flagLabels(flagList)
    L(C.ok, "Acc ", C.txt, pname, C.dim, " | ", flagInfo)

    chat(TAG .. " " .. C.txt .. "Added Room " .. flagInfo .. C.txt .. ": " .. pname)
    Sleep(120)
    respawnIfNeeded()
end

local function resolveUserID(target)
    local userID = tostring(target)
    if userID:match("^%d+$") then return userID end
    local plr, _, uid = fnywys(target)
    if not plr then
        L(C.err, "Tidak ditemukan: ", userID)
        return nil
    end
    return uid
end

local function doUnacc(target, flagType, vipArg, vipOnly)
    local userID = resolveUserID(target)
    if not userID then return end

    isRunning      = true
    local flagList = (not flagType or flagType == "all") and FLAG_ORDER or { flagType }

    if not vipOnly then
        unaccLock(userID)
        for _, ftype in ipairs(flagList) do unaccFlag(userID, ftype) end
    end

    for _, ftype in ipairs(flagList) do
        for i = 1, 7 do
            unaccVipDoor(userID, ftype, i)
        end
    end

    Sleep(120)
    isRunning = false
    L(C.warn, "Unacc ", C.txt, userID)
    chat(TAG .. " " .. C.err .. "Access Removed: " .. C.txt .. userID)
    Sleep(120)
    respawnIfNeeded()
end

local function doAddFlag(target, flagType, retryCount)
    retryCount = retryCount or 0
    local plr, netID, resolvedUID = fnywys(target)
    if not resolvedUID then
        requeueOrFail("addflag", target, flagType, nil, nil, retryCount)
        return
    end

    local pname    = plr and cName(plr.name) or ("UID:" .. resolvedUID)
    local flagList = flagType == "all" and FLAG_ORDER or { flagType }
    isRunning      = true

    for _, ftype in ipairs(flagList) do accFlag(netID, resolvedUID, ftype) end

    Sleep(120)
    isRunning = false

    local flagInfo = flagLabels(flagList)
    L(C.ok, "Flag ", C.txt, pname, C.dim, " | ", flagInfo)
    chat(TAG .. " " .. C.txt .. "Added Flag " .. flagInfo .. C.txt .. ": @" .. pname)
    Sleep(120)
    respawnIfNeeded()
end

local function doUnflag(target, flagType)
    local userID = resolveUserID(target)
    if not userID then return end

    local flagList = (not flagType or flagType == "all") and FLAG_ORDER or { flagType }
    isRunning = true
    for _, ftype in ipairs(flagList) do unaccFlag(userID, ftype) end
    Sleep(120)
    isRunning = false
    L(C.warn, "Unflag ", C.txt, userID)
    chat(TAG .. " " .. C.err .. "Flag Removed: " .. C.txt .. userID)
    Sleep(120)
    respawnIfNeeded()
end

local function bulkLock(uids, x, y)
    local pkt = "action|dialog_return\ndialog_name|lock_edit\nx|" .. x .. "|\ny|" .. y .. "|\n"
    for _, uid in ipairs(uids) do pkt = pkt .. ACCESS_FIELD .. uid .. "|0\n" end
    SendPacket(2, pkt .. "is_public|0\nignore_empty|0\n")
    Sleep(160)
end

local function bulkVip(uids, x, y)
    local pkt = "action|dialog_return\ndialog_name|vip_edit\nx|" .. x .. "|\ny|" .. y .. "|\n"
    for _, uid in ipairs(uids) do pkt = pkt .. uid .. "|0\n" end
    SendPacket(2, pkt)
    Sleep(160)
end

local function runBulkUnacc(uids)
    bulkLock(uids, LOCK.x, LOCK.y)
    for _, ftype in ipairs(FLAG_ORDER) do
        local pos = FLAGS[ftype]
        if pos then
            bulkLock(uids, pos.x, pos.y)
            local doors = VIP_DOORS[ftype]
            if doors then
                for i = 1, 7 do
                    if doors[i] then bulkVip(uids, doors[i].x, doors[i].y) end
                end
            end
        end
    end
end

local function doUnaccAllDirect(targetUids)
    if not targetUids or #targetUids == 0 then
        L(C.dim, "Unaccall: tidak ada UID")
        return
    end
    isRunning = true
    runBulkUnacc(targetUids)
    Sleep(120)
    isRunning = false
    L(C.warn, "Unaccall ", C.txt, #targetUids, " user")
    chat(TAG .. " " .. C.txt .. "Removed Users")
    Sleep(120)
    respawnIfNeeded()
end

local function fetchLockUIDs(x, y)
    isFetchingUIDs = true
    SendPacketRaw(false, { type=3, state=32, value=32, px=x, py=y, x=x*32, y=y*32 })
    Sleep(80)

    local timeout = 25
    while isFetchingUIDs and timeout > 0 do
        Sleep(30)
        timeout = timeout - 1
    end
    if timeout == 0 then
        L(C.err, "Timeout baca UID (", x, ",", y, ")")
    end

    isFetchingUIDs = false
    Sleep(30)
end

local function doUnaccAll(skipUids)
    local me    = GetLocal()
    isRunning   = true
    pendingUIDs = {}

    fetchLockUIDs(LOCK.x, LOCK.y)
    for _, ftype in ipairs(FLAG_ORDER) do
        local pos = FLAGS[ftype]
        if pos then fetchLockUIDs(pos.x, pos.y) end
    end

    local skipLookup = {}
    for uid in pairs(WHITELIST) do skipLookup[uid] = true end
    for _, uid in ipairs(skipUids or {}) do
        if uid and uid ~= 0 then skipLookup[uid] = true end
    end

    local targetUIDs, skipped = {}, 0
    for uidVal in pairs(pendingUIDs) do
        local uid = tonumber(uidVal)
        if uid and uid ~= 0 then
            if uid == me.userid or skipLookup[uid] then
                skipped = skipped + 1
            else
                table.insert(targetUIDs, uid)
            end
        end
    end

    if #targetUIDs == 0 then
        isRunning = false
        L(C.dim, "Unaccall: tidak ada yang perlu dicabut")
        respawnIfNeeded()
        return
    end

    runBulkUnacc(targetUIDs)

    Sleep(120)
    isRunning = false
    L(C.warn, "Unaccall ", C.txt, #targetUIDs, " user", skipped > 0 and (C.dim .. " (skip " .. skipped .. ")") or "")
    chat(TAG .. " " .. C.txt .. "Removed Users")
    Sleep(120)
    respawnIfNeeded()
end

AddHook("OnVariant", "blockLockDialog", function(var)
    if not isRunning then return false end
    if var[0] ~= "OnDialogRequest" then return false end

    local dlg = var[1] or ""

    if isFetchingUIDs then
        local found = 0
        for uid in dlg:gmatch(ACCESS_FIELD .. "(%d+)") do
            pendingUIDs[tonumber(uid)] = true
            found = found + 1
        end
        if found > 0 or dlg:find("lock_edit") or dlg:find("Access list:") then
            isFetchingUIDs = false
        end
    end

    if dlg:find("Access list:")
    or dlg:find("vip_edit")
    or dlg:find("Edit VIP")
    or dlg:find("lock_edit")
    or dlg:find(ACCESS_FIELD) then
        return true
    end

    return false
end)

local AFK_ENABLE     = true
local AFK_TICK       = 10     -- detik per scan posisi
local AFK_REPORT_SEC = 60     -- interval laporan ke bot
local AFK_HOME_WORLD = ""     -- nama world tetap utk auto-rejoin (mis. "H1TO")
local AFK_LABEL      = ""     -- label instance/akun staff (opsional)
local AFK_WATCH      = {}     -- [uid]=true
local AFK_STATE      = {}     -- [uid]={ sig, lastMove, movedSinceReport }
local AFK_NETID_MAP  = {}     -- [netid]=uid
local AFK_LAST_SEND  = 0
local AFK_FIRST_SEND = true
local AFK_LEFT_SINCE = nil
local AFK_CUR_WORLD  = nil
local AFK_CFG_TICK   = 0
local AFK_LAST_COUNT = -1

local function afkEpoch()
    local ok, t = pcall(os.time)
    return ok and t or 0
end

local function afkClean(v)
    return (tostring(v or ""):gsub("[^%d]", ""))
end

local function afkCleanName(raw)
    return (tostring(raw or "?"):gsub("`.", ""))
end

local function afkCount(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function afkTile(p)
    local x = math.floor(((p.pos and p.pos.x) or 0) / 32)
    local y = math.floor(((p.pos and p.pos.y) or 0) / 32)
    return x, y
end

local function afkSig(p)
    local x, y = afkTile(p)
    return x .. "," .. y .. "|" .. tostring(p.isleft)
end

local function afkPos(p)
    local x, y = afkTile(p)
    return x .. "," .. y
end

local function afkLoadWatch()
    local ok, res = pcall(MakeRequest, CMD_HOST .. "/config", "GET", {
        ["User-Agent"]    = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        ["Accept"]        = "application/json",
        ["Cache-Control"] = "no-cache",
    })
    if not ok or not res then
        L(C.err, "AFK config gagal: ", ok and "no response" or tostring(res))
        return false
    end

    local content = tostring(res.content or "")
    if content == "" or content:find("<!DOCTYPE", 1, true) then
        L(C.err, "AFK config kosong / HTML")
        return false
    end

    local arr = content:match('"afkUids"%s*:%s*%[(.-)%]')
    AFK_WATCH = {}
    if arr then
        for raw in arr:gmatch('"(.-)"') do
            local uid = afkClean(raw)
            if uid ~= "" then AFK_WATCH[uid] = true end
        end
    end

    local n = afkCount(AFK_WATCH)
    if n ~= AFK_LAST_COUNT then
        AFK_LAST_COUNT = n
        L(C.info, "AFK pantau ", n, " UID")
    end
    return true
end

local function afkLog(uid)
    L(C.dim, "AFK ", uid, " keluar")
end

local function afkLogJoin(uid, name)
    L(C.ok, "AFK ", uid, C.dim, " masuk ", C.txt, afkCleanName(name))
end

local function afkScan()
    local now        = afkEpoch()
    local records    = {}
    local leftUids   = {}
    local joinedUids = {}
    local present    = {}

    for _, p in pairs(GetPlayerList() or {}) do
        local uid = afkClean(p.userid)
        if uid ~= "" and AFK_WATCH[uid] then
            present[uid] = true
            local sig = afkSig(p)
            local st  = AFK_STATE[uid]

            if not st then
                st = { sig = sig, lastMove = now, movedSinceReport = false }
                AFK_STATE[uid] = st
                joinedUids[#joinedUids + 1] = uid
                if not AFK_FIRST_SEND then afkLogJoin(uid, p.name) end
            elseif st.sig ~= sig then
                st.sig              = sig
                st.lastMove         = now
                st.movedSinceReport = true
            end

            records[#records + 1] = {
                uid   = uid,
                name  = afkCleanName(p.name),
                moved = st.movedSinceReport,
                idle  = now - (st.lastMove or now),
                pos   = afkPos(p),
            }
            if p.netid then AFK_NETID_MAP[p.netid] = uid end
        end
    end

    for uid in pairs(AFK_STATE) do
        if not present[uid] then
            leftUids[#leftUids + 1] = uid
            AFK_STATE[uid] = nil
            afkLog(uid)
        end
    end

    return records, leftUids, joinedUids
end

local function afkSendReport(records, leftUids, event)
    if not AFK_ENABLE then return end

    local loc   = GetLocal()
    local world = (GetWorld() and GetWorld().name) or ""
    local acc   = loc and afkCleanName(loc.name) or "?"
    local accId = loc and afkClean(loc.userid) or "0"

    local pj = {}
    for _, r in ipairs(records or {}) do
        pj[#pj + 1] = '{"uid":"' .. r.uid ..
            '","name":"' .. jsonEscape(r.name) ..
            '","moved":' .. (r.moved and "true" or "false") ..
            ',"idle":' .. tostring(math.floor(r.idle or 0)) ..
            ',"pos":"' .. jsonEscape(r.pos or "") .. '"}'
    end

    local lj = {}
    for _, uid in ipairs(leftUids or {}) do
        lj[#lj + 1] = '"' .. afkClean(uid) .. '"'
    end

    local payload = '{"observer":{"account":"' .. jsonEscape(acc) ..
        '","uid":"' .. accId ..
        '","world":"' .. jsonEscape(world) ..
        '","label":"' .. jsonEscape(AFK_LABEL) ..
        '","event":"' .. jsonEscape(event or "scan") ..
        '","epoch":' .. tostring(afkEpoch()) ..
        '},"players":[' .. table.concat(pj, ",") .. '],"left":[' .. table.concat(lj, ",") .. ']}'

    local ok, err = pcall(function()
        MakeRequest(CMD_HOST .. "/afk", "POST", { ["Content-Type"] = "application/json" }, payload, 5000)
    end)
    if not ok then L(C.err, "AFK report gagal: ", err) end

    for _, r in ipairs(records or {}) do
        local st = AFK_STATE[r.uid]
        if st then st.movedSinceReport = false end
    end
end

local function afkFlushLeft(event)
    if afkCount(AFK_STATE) == 0 then return false end
    local leftUids = {}
    for uid in pairs(AFK_STATE) do
        leftUids[#leftUids + 1] = uid
        afkLog(uid)
    end
    AFK_STATE = {}
    afkSendReport({}, leftUids, event or "left_world")
    return true
end

RunThread(function()
    if not AFK_ENABLE then return end

    Sleep(6000)
    afkLoadWatch()

    while true do
        AFK_CFG_TICK = AFK_CFG_TICK + 1
        if AFK_CFG_TICK >= 12 then
            AFK_CFG_TICK = 0
            afkLoadWatch()
        end

        local world = (GetWorld() and GetWorld().name) or ""

        if afkCount(AFK_WATCH) == 0 then
        elseif world == "" or world == "EXIT" then
            afkFlushLeft("left_world")

            if AFK_HOME_WORLD ~= "" then
                if not AFK_LEFT_SINCE then AFK_LEFT_SINCE = afkEpoch() end
                if afkEpoch() - AFK_LEFT_SINCE >= 15 then
                    AFK_LEFT_SINCE = afkEpoch()
                    local ok = pcall(RequestJoinWorld, AFK_HOME_WORLD)
                    L(ok and C.info or C.err, "AFK rejoin ", AFK_HOME_WORLD, ok and "" or " gagal")
                end
            end
        else
            AFK_LEFT_SINCE = nil

            if AFK_CUR_WORLD ~= world then
                if AFK_CUR_WORLD then afkFlushLeft("world_change") end
                AFK_CUR_WORLD = world
            end

            local records, leftUids, joinedUids = afkScan()
            local now   = afkEpoch()
            local event = AFK_FIRST_SEND and "startup" or "scan"

            if AFK_FIRST_SEND or (now - AFK_LAST_SEND >= AFK_REPORT_SEC) or #leftUids > 0 or #joinedUids > 0 then
                AFK_FIRST_SEND = false
                AFK_LAST_SEND  = now
                afkSendReport(records, leftUids, event)
            end
        end

        Sleep(AFK_TICK * 1000)
    end
end)

AddHook("OnVariant", "afkActivityHook", function(var)
    if var[0] ~= "OnTalkBubble" then return false end

    local plr = GetPlayer(tonumber(var[1]) or -1)
    if not plr then return false end

    local st = AFK_STATE[afkClean(plr.userid)]
    if st then
        st.lastMove         = afkEpoch()
        st.movedSinceReport = true
    end
    return false
end)

AddHook("OnVariant", "afkLeftHook", function(var)
    if var[0] ~= "OnRemove" then return false end

    local netid = tonumber(tostring(var[1] or ""):match("netID|(%d+)") or "")
    if not netid then return false end

    local uid = AFK_NETID_MAP[netid]
    if not uid or not AFK_WATCH[uid] then return false end

    AFK_STATE[uid]       = nil
    AFK_NETID_MAP[netid] = nil

    afkLog(uid)
    RunThread(function()
        afkSendReport({}, { uid }, "left_instant")
    end)
    return false
end)

AddHook("OnVariant", "afkJoinHook", function(var)
    if var[0] ~= "OnSpawn" then return false end

    local uidStr = tostring(var[1] or ""):match("userID|(%d+)")
    if not uidStr then return false end
    local uid = afkClean(uidStr)

    if uid ~= "" and AFK_WATCH[uid] then
        RunThread(function()
            Sleep(500)
            local records, leftUids = afkScan()
            afkSendReport(records, leftUids, "join_instant")
        end)
    end
    return false
end)

local function sendDboxWebhook(name, uid, count, item)
    if DBOX_WEBHOOK == "" then return end
    local ok, timeStr = pcall(os.date, "%H:%M:%S")
    if not ok then timeStr = "N/A" end
    local worldName = jsonEscape(GetWorld() and GetWorld().name or "UNKNOWN")

    local payload = [[{"embeds":[{"title":"Donation Box Log<:box:1439454469518528542>","color":]]
        .. math.random(0, 16777215)
        .. [[,"fields":[]]
        .. [[{"name":"<a:info:1405869396991410246> Player","value":"]] .. jsonEscape(name) .. [[ (]] .. jsonEscape(uid) .. [[)","inline":true},]]
        .. [[{"name":"<:bag:1374826126404485234> Item","value":"]]    .. jsonEscape(item) .. [[","inline":true},]]
        .. [[{"name":"<:blnc:1468798189011472478> Amount","value":"]] .. jsonEscape(tostring(count)) .. [[","inline":true},]]
        .. [[{"name":"<:clock:1470710596516184104> Time","value":"]]  .. jsonEscape(timeStr) .. [[","inline":true},]]
        .. [[{"name":"<:world:1470710366098161932> World","value":"]] .. worldName .. [[","inline":false}]]
        .. [[],"footer":{"text":"Donation log by @vbbyy"}}]}]]

    local ok2, err = pcall(function()
        MakeRequest(DBOX_WEBHOOK, "POST", { ["Content-Type"] = "application/json" }, payload, 8000)
    end)
    if not ok2 then L(C.err, "Webhook donasi gagal: ", err) end

    local waPayload = [[{"player":"]] .. jsonEscape(name) .. [[","uid":"]] .. jsonEscape(uid) .. [[","item":"]] .. jsonEscape(item) .. [[","amount":"]] .. jsonEscape(tostring(count)) .. [[","time":"]] .. jsonEscape(timeStr) .. [[","world":"]] .. worldName .. [["}]]

    local ok3, err2 = pcall(function()
        MakeRequest(CMD_HOST .. "/donation", "POST", { ["Content-Type"] = "application/json" }, waPayload, 5000)
    end)
    if not ok3 then L(C.err, "Donasi ke bot gagal: ", err2) end
end

local function parseDboxMessage(rawMsg)
    local s = tostring(rawMsg)
        :gsub("`.", "")
        :gsub("[\n\r\t]+", " ")
        :gsub("%s+", " ")
    local inner = (s:match("^%s*%[(.-)%]") or s):gsub("^%s+", ""):gsub("%s+$", "")

    local function tryParse(kw1, kw2)
        local pi = inner:find(kw1, 1, true)
        if not pi then return nil end
        local name = inner:sub(1, pi - 1):gsub("^%s+", ""):gsub("%s+$", "")
        local rest = inner:sub(pi + #kw1)
        local sp   = rest:find(" ", 1, true)
        if not sp then return nil end
        local cnt  = tonumber(rest:sub(1, sp - 1))
        if not cnt then return nil end
        local tail = rest:sub(sp + 1)
        local ii   = kw2 and tail:find(kw2, 1, true)
        local item = (ii and tail:sub(1, ii - 1) or tail):gsub("^%s+", ""):gsub("%s+$", "")
        if name ~= "" and item ~= "" then return name, cnt, item end
    end

    local n, c, it = tryParse(" places ", " into the Donation Box")
    if n then return n, c, it end
    return tryParse(" donated ", " to the Donation Box")
end

AddHook("OnVariant", "dboxDetectHook", function(var)
    if var[0] ~= "OnTalkBubble" then return false end

    local netid  = tonumber(var[1]) or -1
    local rawMsg = tostring(var[2] or "")
    local lmsg   = rawMsg:lower()

    if lmsg:find("donation box", 1, true) or lmsg:find("how nice", 1, true) then
        local name, count, item = parseDboxMessage(rawMsg)
        if name then
            local uid = nil
            if netid > 0 then
                local plr = GetPlayer(netid)
                if plr and plr.userid and plr.userid ~= 0 then uid = plr.userid end
            end
            if not uid then
                local rawUid = name:match("%((%d+)%)")
                if rawUid then uid = tonumber(rawUid) end
            end
            local uidDisplay = uid and tostring(uid) or "N/A"
            L(C.info, "Donasi ", C.txt, name, C.dim, " | ", C.txt, count, "x ", item)
            RunThread(function() sendDboxWebhook(name, uidDisplay, count, item) end)
        end
    end
    return false
end)

local function whisperTo(netid, text)
    local ok, err = pcall(SendVariantList,
        { [0] = "OnTalkBubble", [1] = netid, [2] = tostring(text) }, netid)
    if not ok then L(C.err, "Whisper gagal: ", err) end
end

AddHook("OnVariant", "takeaccHook", function(var)
    if var[0] ~= "OnTalkBubble" then return false end

    local netid  = tonumber(var[1]) or -1
    local rawMsg = tostring(var[2] or "")
    local lmsg   = rawMsg:gsub("`.", ""):gsub("%s+", " "):lower()

    local isTakeacc   = lmsg:find("%.takeacc")   or lmsg:find("!takeacc")
    local isCancelacc = lmsg:find("%.cancelacc") or lmsg:find("!cancelacc")
    if not isTakeacc and not isCancelacc then return false end

    local uid = nil
    if netid > 0 then
        local plr = GetPlayer(netid)
        if plr and plr.userid and plr.userid ~= 0 then uid = plr.userid end
    end
    if not uid then return false end

    local action = isCancelacc and "cancelacc" or "takeacc"

    whisperTo(netid, TAG .. " " .. C.info .. "Memproses " .. action .. "... tunggu sebentar!")
    L(C.info, action, " ", uid)

    RunThread(function()
        local payload = [[{"uid":"]] .. jsonEscape(uid) .. [["}]]
        local ok, res = pcall(MakeRequest, CMD_HOST .. "/" .. action, "POST",
            { ["Content-Type"] = "application/json" }, payload, 3000)

        local plr    = GetPlayer(netid)
        local growid = plr and cName(plr.name) or "Unknown"
        local secureTag = ""

        local function say(text)
            chat(chatTag(action) .. C.txt .. growid .. " " .. C.dim .. "(" .. uid .. ") " .. text .. secureTag)
        end

        if not ok or not res then
            L(C.err, action, " ", uid, " gagal konek ke server")
            whisperTo(netid, TAG .. " " .. C.err .. "Gagal konek ke server! Coba lagi.")
            say(C.err .. "GAGAL" .. C.txt .. " - Server error")
            return
        end

        local content = tostring(res.content or "")
        local reg     = content:match('"registered"%s*:%s*(%a+)')
        local secured = content:match('"secured"%s*:%s*(%a+)')
        if secured and secured:lower() == "true" then
            secureTag = " " .. C.warn .. "[SECURED]"
        end

        if not reg or reg:lower() ~= "true" then
            L(C.err, action, " ditolak ", uid, C.dim, " (tidak terdaftar)")
            whisperTo(netid, TAG .. " " .. C.err .. "Userid " .. uid .. " tidak terdaftar di grup reme.")
            say(C.err .. "GAGAL" .. C.txt .. " - Tidak terdaftar")
            return
        end

        if isCancelacc then
            local success = content:match('"success"%s*:%s*(%a+)')
            if success and success:lower() == "true" then
                L(C.ok, "cancelacc ", uid, C.dim, " (akses dibatalkan)")
                whisperTo(netid, TAG .. " " .. C.ok .. "Akses dibatalkan untuk userid " .. uid .. ".")
                say(C.ok .. "BERHASIL")
            else
                local reason = content:match('"reason"%s*:%s*"([^"]+)"') or "unknown"
                if reason == "retax_pending" then
                    L(C.err, "cancelacc ditolak ", uid, C.dim, " (retax pending)")
                    whisperTo(netid, TAG .. " " .. C.err .. "Sedang proses retax, .cancelacc belum tersedia.")
                    say(C.err .. "GAGAL" .. C.txt .. " - Retax pending")
                else
                    L(C.err, "cancelacc ditolak ", uid, C.dim, " (", reason, ")")
                    whisperTo(netid, TAG .. " " .. C.err .. "Kamu tidak sedang mengambil Shift, tidak ada yang dibatalkan.")
                    say(C.err .. "GAGAL" .. C.txt .. " - Tidak di shift")
                end
            end
        else
            local room = content:match('"room"%s*:%s*"([^"]+)"') or ""
            local rc   = ROOM_COLOR[room:lower()] or C.txt
            L(C.ok, "takeacc ", uid, room ~= "" and (C.dim .. " (" .. room .. ")") or "")
            whisperTo(netid, TAG .. " " .. C.ok .. "Acc diproses untuk userid " .. uid
                .. (room ~= "" and (" (" .. rc .. room .. C.ok .. ")") or "") .. ".")
            say(C.ok .. "BERHASIL" .. (room ~= "" and (" " .. rc .. "[" .. room:upper() .. "]") or ""))
        end
    end)

    return false
end)

local function sendVipBreakWebhook(playerName, worldName, x, y)
    if VIP_BREAK_WEBHOOK == "" then return end

    local roomName = "Tidak Dikenal"
    for room, doors in pairs(VIP_DOORS) do
        for _, door in ipairs(doors) do
            if door.x == x and door.y == y then
                roomName = room:upper()
                break
            end
        end
        if roomName ~= "Tidak Dikenal" then break end
    end

    local waMsg = "🚨 *VIP DOOR BREAK DETECTED* 🚨\n\n"
        .. "Player: *" .. playerName .. "*\n"
        .. "World: " .. worldName .. "\n"
        .. "Room: *" .. roomName .. "*\n"
        .. "Posisi: " .. x .. ", " .. y

    local waPayload = [[{"message":"]] .. jsonEscape(waMsg) .. [["}]]

    local tag = (VIP_BREAK_ENABLE_TAG and VIP_BREAK_DISCORD_ID ~= "") and ("<@" .. VIP_BREAK_DISCORD_ID .. "> ") or ""
    local data = string.format([[
    {
        "content": "%s",
        "embeds": [{
            "title": "<a:warn:1471371025043423316> VIP DOOR BREAK DETECTED",
            "description": "VIP Door (id %d) terdeteksi hancur di Room %s!",
            "color": 16711680,
            "fields": [
                {"name": "<:player:1471371280786788405> Nickname", "value": "`%s`", "inline": true},
                {"name": "<a:world:1474160169817477173> World", "value": "`%s`", "inline": true},
                {"name": "Room", "value": "`%s`", "inline": true},
                {"name": "Posisi", "value": "`%d, %d`", "inline": true}
            ],
            "footer": {"text": "Anti VIP Door Break System"}
        }]
    }
    ]], tag, VIP_DOOR_ID, roomName, jsonEscape(playerName), jsonEscape(worldName), roomName, x, y)

    RunThread(function()
        pcall(function()
            MakeRequest(VIP_BREAK_WEBHOOK, "POST", { ["Content-Type"] = "application/json" }, data)
        end)
        pcall(function()
            MakeRequest(CMD_HOST .. "/notify", "POST", { ["Content-Type"] = "application/json" }, waPayload, 5000)
        end)
    end)
end

AddHook("OnProcessTankUpdatePacket", "VipDoorHook", function(varss)
    if varss.px and varss.py then
        local key = varss.px .. "," .. varss.py
        if DoorPositions[key] and varss.netid then
            LastToucher[key] = varss.netid
        end
    end
    return false
end)

local function postNotify(endpoint, uid, msg)
    local payload = [[{"uid":"]] .. jsonEscape(uid) .. [[","message":"]] .. jsonEscape(msg) .. [["}]]
    RunThread(function()
        local ok, err = pcall(function()
            MakeRequest(CMD_HOST .. endpoint, "POST", { ["Content-Type"] = "application/json" }, payload, 5000)
        end)
        if not ok then L(C.err, "Notif bot gagal: ", err) end
    end)
end

AddHook("OnVariant", "balanceCheckHook", function(var)
    if var[0] ~= "OnDialogRequest" or not pendingBalanceCheck then return false end

    local dialog      = var[1]
    local cleanDialog = dialog:gsub("`.", "")

    if cleanDialog:find("Inventory") or cleanDialog:find("Bank") or dialog:find("item_id|") then
        local bgl_count, bbgl_count = 0, 0

        for line in dialog:gmatch("[^\n]+") do
            local nums = {}
            for n in line:gmatch("%d+") do table.insert(nums, tonumber(n)) end
            for i, n in ipairs(nums) do
                if n == ID_BGL  and nums[i + 1] then bgl_count  = nums[i + 1] end
                if n == ID_BBGL and nums[i + 1] then bbgl_count = nums[i + 1] end
            end
        end

        local totalBgl  = bgl_count + (bbgl_count * 100)
        local t_uid     = tostring(pendingBalanceCheck.uid)
        local t_room    = pendingBalanceCheck.room
        local t_vipArg  = pendingBalanceCheck.vipArg
        local t_vipOnly = pendingBalanceCheck.vipOnly
        local req       = MODAL_REQ[t_room] or 0
        local rtag      = roomTag(t_room)

        if totalBgl >= req then
            L(C.ok, "Modal ", C.txt, t_uid, C.dim, " | ", C.ok, totalBgl, "/", req, " BGL")
            chat(C.ok .. "Modal cukup! " .. C.txt .. "(" .. totalBgl .. " / " .. req .. " BGL)")
            RunThread(function() doAcc(t_uid, t_room, t_vipArg, t_vipOnly) end)

            postNotify("/notify", t_uid,
                "✅ *AKSES DIBERIKAN*\n"
                .. "UID: " .. t_uid .. " berhasil mengambil shift untuk Room *" .. t_room:upper() .. "*.\n"
                .. "- Modal user: " .. totalBgl .. " BGL\n"
                .. "- Minimal modal: " .. req .. " BGL")
        else
            L(C.err, "Modal ", C.txt, t_uid, C.dim, " | ", C.err, totalBgl, "/", req, " BGL")
            chat(C.err .. "Modal tidak cukup! " .. C.txt .. "Butuh " .. C.info .. req .. " BGL " .. C.txt .. "untuk room " .. rtag)
            chat(C.txt .. "Kamu hanya punya " .. C.info .. totalBgl .. " BGL")

            postNotify("/rejectacc", t_uid,
                "❌ *AKSES DITOLAK*\n"
                .. "UID: " .. t_uid .. " gagal mengambil shift untuk Room *" .. t_room:upper() .. "*.\n"
                .. "Alasan: Modal kurang!\n"
                .. "- Modal user: " .. totalBgl .. " BGL\n"
                .. "- Minimal modal: " .. req .. " BGL")
        end

        pendingBalanceCheck = nil
        return true
    end

    return false
end)

local function queueCommand(parts)
    local act = parts[1]:lower()

    if act == "acc" and parts[2] then
        table.insert(pendingQueue, {
            action = "acc", target = parts[2],
            flagType = parts[3] and parts[3]:lower() or "all",
            vipArg = nil, vipOnly = false,
        })
        return true

    elseif act == "unacc" and parts[2] then
        table.insert(pendingQueue, {
            action   = "unacc",
            target   = parts[2],
            flagType = parts[3] and parts[3]:lower() or nil,
            vipArg   = parseVipInput(parts[4] or ""),
            vipOnly  = false,
        })
        return true

    elseif act == "unaccall" then
        local uidsStr = parts[2] and parts[2]:match("^uids:(.+)$")
        local skipStr = parts[2] and parts[2]:match("^skip:(.+)$")
        if uidsStr then
            table.insert(pendingQueue, { action = "unaccall_direct", targetUids = parseUidList(uidsStr) })
        else
            table.insert(pendingQueue, { action = "unaccall", skipUids = skipStr and parseUidList(skipStr) or nil })
        end
        return true
    end

    return false
end

local function processPendingQueue()
    if #pendingQueue == 0 or isRunning then return end

    local i = 1
    while i <= #pendingQueue do
        local item = pendingQueue[i]

        if item.action == "unaccall_direct" then
            table.remove(pendingQueue, i)
            RunThread(function() doUnaccAllDirect(item.targetUids) end)
            return

        elseif item.action == "unaccall" then
            table.remove(pendingQueue, i)
            RunThread(function() doUnaccAll(item.skipUids) end)
            return

        elseif item.action == "unacc" then
            table.remove(pendingQueue, i)
            RunThread(function() doUnacc(item.target, item.flagType, item.vipArg, item.vipOnly or false) end)
            return

        elseif item.action == "acc" then
            table.remove(pendingQueue, i)
            local plr, netid, resolvedUID = fnywys(item.target)
            local reqModal = MODAL_REQ[item.flagType]
            if netid and reqModal and reqModal > 0 then
                pendingBalanceCheck = { uid = resolvedUID or item.target, room = item.flagType, vipArg = item.vipArg, vipOnly = item.vipOnly, time = os.time() }
                SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|viewinv")
            else
                RunThread(function() doAcc(item.target, item.flagType, item.vipArg, item.vipOnly, item.retryCount) end)
            end
            return

        elseif item.action == "addflag" then
            table.remove(pendingQueue, i)
            RunThread(function() doAddFlag(item.target, item.flagType, item.retryCount) end)
            return

        elseif item.action == "accall" then
            table.remove(pendingQueue, i)
            local capturedTarget = item.target
            local function doAccAllQueued(t)
                local plr, netID, resolvedUID = fnywys(t)
                if not resolvedUID then return end
                local pname  = plr and cName(plr.name) or ("UID:" .. resolvedUID)
                local userID = resolvedUID
                isRunning    = true

                accLock(netID, userID)
                Sleep(120)
                for _, ftype in ipairs(FLAG_ORDER) do
                    accFlag(netID, userID, ftype)
                    Sleep(120)
                end
                for _, ftype in ipairs(FLAG_ORDER) do
                    local doors = VIP_DOORS[ftype]
                    if doors then
                        for i = 1, 7 do
                            if doors[i] then
                                local door = doors[i]
                                local pkt = "action|dialog_return\ndialog_name|vip_edit\n"
                                    .. "x|" .. door.x .. "|\ny|" .. door.y .. "|\n"
                                if netID then pkt = pkt .. "targetNetID|" .. netID .. "\n" end
                                SendPacket(2, pkt .. userID .. "|1\n")
                                Sleep(160)
                            end
                        end
                    end
                    Sleep(40)
                end

                Sleep(120)
                isRunning = false
                L(C.ok, "AccAll ", C.txt, pname, C.dim, " | ALL ROOM")
                chat(TAG .. " " .. C.txt .. "Added Room " .. "`^ALL ROOM`w" .. C.txt .. ": " .. pname)
                Sleep(120)
                respawnIfNeeded()
            end
            RunThread(function() doAccAllQueued(capturedTarget) end)
            return

        else
            i = i + 1
        end
    end
end

local function handleBotCommand(parts)
    if queueCommand(parts) then return end
    local action = parts[1]:lower()

    if action == "addflag" then
        local target = parts[2]
        local room   = parts[3] and parts[3]:lower() or "all"
        if not target then return end
        if isPlayerInWorld(target) then
            RunThread(function() doAddFlag(target, room) end)
        else
            table.insert(pendingQueue, { action = "addflag", target = target, flagType = room })
        end

    elseif action == "unflag" then
        local target = parts[2]
        if not target then return end
        RunThread(function() doUnflag(target, parts[3] and parts[3]:lower() or nil) end)

    elseif action == "addvip" then
        local target = parts[2]
        local room   = parts[3] and parts[3]:lower() or "all"
        local vipArg = parseVipInput(parts[4] or "0")
        if not target then return end
        if isPlayerInWorld(target) then
            RunThread(function() doAcc(target, room, vipArg, true) end)
        else
            table.insert(pendingQueue, { action = "acc", target = target, flagType = room, vipArg = vipArg, vipOnly = true })
        end

    elseif action == "unvip" then
        local target = parts[2]
        local vipArg = parseVipInput(parts[4] or "0")
        if not target then return end
        RunThread(function() doUnacc(target, parts[3] and parts[3]:lower() or nil, vipArg, true) end)

    elseif action == "afk" or action == "takeafk" then
        afkLoadWatch()
        for i = 2, #parts do
            local uid = afkClean(parts[i])
            if uid ~= "" then AFK_WATCH[uid] = true end
        end
        local records, leftUids = afkScan()
        afkSendReport(records, leftUids, "on_demand")

    elseif action == "afklog" then
        local records, leftUids = afkScan()
        afkSendReport(records, leftUids, "on_demand")
        L(C.info, "AFK ", afkCount(AFK_WATCH), " dipantau, ", #records, " di world")

    elseif action == "ping" then
        L(C.ok, "Pong")
        chat(TAG .. " " .. C.ok .. "Pong!")

    elseif action == "accall" and parts[2] then
        local target = parts[2]
        local function doAccAll(t)
            local plr, netID, resolvedUID = fnywys(t)
            if not resolvedUID then
                L(C.err, "accall: tidak ditemukan: ", t)
                return
            end

            local pname  = plr and cName(plr.name) or ("UID:" .. resolvedUID)
            local userID = resolvedUID
            isRunning    = true

            accLock(netID, userID)
            Sleep(120)

            for _, ftype in ipairs(FLAG_ORDER) do
                accFlag(netID, userID, ftype)
                Sleep(120)
            end

            for _, ftype in ipairs(FLAG_ORDER) do
                local doors = VIP_DOORS[ftype]
                if doors then
                    for i = 1, 7 do
                        if doors[i] then
                            local door = doors[i]
                            local pkt = "action|dialog_return\ndialog_name|vip_edit\n"
                                .. "x|" .. door.x .. "|\ny|" .. door.y .. "|\n"
                            if netID then pkt = pkt .. "targetNetID|" .. netID .. "\n" end
                            SendPacket(2, pkt .. userID .. "|1\n")
                            Sleep(160)
                        end
                    end
                end
                Sleep(40)
            end

            Sleep(120)
            isRunning = false

            L(C.ok, "AccAll ", C.txt, pname, C.dim, " | ALL ROOM")
            chat(TAG .. " " .. C.txt .. "Added Room " .. "`^ALL ROOM`w" .. C.txt .. ": " .. pname)
            Sleep(120)
            respawnIfNeeded()
        end

        if isPlayerInWorld(target) then
            RunThread(function() doAccAll(target) end)
        else
            L(C.dim, target, " belum di world, antri (accall)")
            table.insert(pendingQueue, {
                action = "accall", target = target,
            })
        end
    end
end

local function tryFetchConfig(url)
    local ok, res = pcall(MakeRequest, url .. "/config", "GET", {
        ["User-Agent"]      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        ["Accept"]          = "application/json, text/plain, */*",
        ["Accept-Language"] = "en-US,en;q=0.9",
        ["Cache-Control"]   = "no-cache",
        ["Connection"]      = "keep-alive",
    })
    if not ok or not res then return nil end

    local content = tostring(res.content or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if content:find("<!DOCTYPE", 1, true) or content:find("<html", 1, true) then
        return nil
    end
    if not content:find('"groupName"', 1, true) and not content:find('"cmdHost"', 1, true) then
        return nil
    end
    return content
end

local function bootstrapCmdHost()
    local content = tryFetchConfig(CMD_HOST)

    if content then
        local host = content:match('"cmdHost"%s*:%s*"([^"]+)"')
        if host and host ~= "" then
            CMD_HOST = host
            L(C.ok, "Terkoneksi ", C.dim, CMD_HOST)
        else
            L(C.ok, "Terkoneksi ", C.dim, "(URL bawaan)")
        end
    else
        L(C.err, "Gagal konek / diblokir Cloudflare")
    end
end

RunThread(function()
    Sleep(2000)
    bootstrapCmdHost()
    Sleep(1000)

    local drained = 0
    while true do
        local startupCmd = readAndClearCmd()
        if not startupCmd then break end
        drained = drained + 1
        local parts = parseCmdLine(startupCmd)
        if #parts > 0 then queueCommand(parts) end
    end
    if drained > 0 then L(C.info, drained, " command lama masuk antrian") end

    while true do
        local cmd = readAndClearCmd()
        if cmd then
            local parts = parseCmdLine(cmd)
            if #parts > 0 then
                if not isRunning then
                    handleBotCommand(parts)
                else
                    queueCommand(parts)
                end
            end
        end

        if not isRunning and #pendingQueue > 0 then
            processPendingQueue()
        end

        Sleep(CMD_POLL_INTERVAL)
    end
end)

RunThread(function()
    local currentWorld = (GetWorld() and GetWorld().name) or ""

    for _, tile in pairs(GetTiles() or {}) do
        if tile.fg == VIP_DOOR_ID then
            DoorPositions[tile.x .. "," .. tile.y] = true
        end
    end

    while true do
        local world = GetWorld()
        if world and world.name and world.name ~= "" and world.name ~= "EXIT" then
            if world.name ~= currentWorld then
                DoorPositions = {}
                LastToucher   = {}
                currentWorld  = world.name

                for _, tile in pairs(GetTiles() or {}) do
                    if tile.fg == VIP_DOOR_ID then
                        DoorPositions[tile.x .. "," .. tile.y] = true
                    end
                end
            else
                for key in pairs(DoorPositions) do
                    local x, y = key:match("(-?%d+),(-?%d+)")
                    x, y = tonumber(x), tonumber(y)
                    local tile = GetTile(x, y)

                    if not tile or tile.fg ~= VIP_DOOR_ID then
                        local netid      = LastToucher[key]
                        local playerName = "Unknown Player"

                        if netid then
                            local plr = GetPlayer(netid)
                            if plr then playerName = (plr.name:gsub("`.", "")) end
                        end

                        L(C.err, "VIP door hancur ", C.txt, "(", x, ",", y, ")", C.dim, " oleh ", C.txt, playerName)
                        sendVipBreakWebhook(playerName, world.name, x, y)

                        DoorPositions[key] = nil
                        LastToucher[key]   = nil
                    end
                end

                for _, tile in pairs(GetTiles() or {}) do
                    if tile.fg == VIP_DOOR_ID then
                        local key = tile.x .. "," .. tile.y
                        if not DoorPositions[key] then DoorPositions[key] = true end
                    end
                end
            end
        else
            if currentWorld ~= "" then
                DoorPositions = {}
                LastToucher   = {}
                currentWorld  = ""
            end
        end

        Sleep(500)
    end
end)

L(C.ok, "Loaded")

local SPAMMER_LIST = {
    { label = "infinity", color = ROOM_COLOR.infinity, x = 71, y = 30, spam_text = "`5MAX 5 BLACK" },
    { label = "recom",    color = ROOM_COLOR.recom,    x = 29, y = 30, spam_text = "`8MAX 1 BLACK" },
    { label = "inti",     color = ROOM_COLOR.inti,     x = 71, y = 38, spam_text = "`4MAX 25 BGL" },
    { label = "basic",    color = ROOM_COLOR.basic,    x = 29, y = 38, spam_text = "`2MAX 7 BGL" },
    { label = "owner",    color = C.hl,                x = 50, y = 31, spam_text = "`#BUY `2ACC`w/`4PROBLEM `8CONTACT ADMIN ON BOARD ^^^" },

    { label = "slot-6",   color = C.dim, x = 51, y = 17, spam_text = nil },
    { label = "slot-7",   color = C.dim, x = 52, y = 17, spam_text = nil },
    { label = "slot-8",   color = C.dim, x = 53, y = 17, spam_text = nil },
    { label = "slot-9",   color = C.dim, x = 54, y = 17, spam_text = nil },
    { label = "slot-10",  color = C.dim, x = 55, y = 17, spam_text = nil },
}

local SPAMMER_ITEM_ID = 16550

_G.SpammerSlaveDialogOpened = false
_G.CurrentSpamText = nil

local function slotLog(slot, color, msg)
    local rawText = slot.label:upper() .. " " .. color .. msg
    local formattedText = formatNumbers(rawText, color)
    LogToConsole(TAG .. " " .. C.blk .. "[" .. slot.color .. formattedText .. C.blk .. "]")
end

local function GetNeighbors(tile)
    return {
        { x = tile.x + 1, y = tile.y },
        { x = tile.x - 1, y = tile.y },
        { x = tile.x, y = tile.y + 1 },
        { x = tile.x, y = tile.y - 1 },
    }
end

local function BFSPathfind(startX, startY, targetX, targetY)
    local queue   = {}
    local visited = { [startX .. "," .. startY] = true }

    table.insert(queue, {
        current = { x = startX, y = startY },
        path    = { { x = startX, y = startY } },
    })

    while #queue > 0 do
        local node = table.remove(queue, 1)
        local curr = node.current
        local path = node.path

        if curr.x == targetX and curr.y == targetY then
            return path
        end

        for _, neighbor in ipairs(GetNeighbors(curr)) do
            local key = neighbor.x .. "," .. neighbor.y
            if neighbor.x >= 0 and neighbor.x < 100 and neighbor.y >= 0 and neighbor.y < 60 then
                if not visited[key] and CheckPath(neighbor.x, neighbor.y) then
                    visited[key] = true
                    local newPath = {}
                    for _, p in ipairs(path) do table.insert(newPath, p) end
                    table.insert(newPath, { x = neighbor.x, y = neighbor.y })
                    table.insert(queue, { current = neighbor, path = newPath })
                end
            end
        end
    end
    return nil
end

local function moveTo(destX, destY, slot)
    local player = GetLocal()
    if not player then return false end

    local startX = math.floor(player.pos.x / 32)
    local startY = math.floor(player.pos.y / 32)

    if startX == destX and startY == destY then return true end

    local path = BFSPathfind(startX, startY, destX, destY)
    if path then
        for i = 2, #path do
            FindPath(path[i].x, path[i].y)
            Sleep(80)
        end
        return true
    end

    local msg = "rute terhalang (" .. destX .. "," .. destY .. ")"
    if slot then
        slotLog(slot, C.err, msg)
    else
        L(C.err, "Gagal: ", msg)
    end
    return false
end

local function getSpammerItemID()
    local info = GetItemInfo("Spammer Slave")
    if info and info.id and info.id > 0 then return info.id end

    local inv = GetInventory()
    if inv then
        for _, item in pairs(inv) do
            local dbInfo = GetItemByIDSafe(item.id)
            if dbInfo and dbInfo.name then
                local nameLower = dbInfo.name:lower()
                if nameLower:find("spammer") or nameLower:find("slave") then return item.id end
            end
        end
    end

    local matches = GetItemsByPartialName("Spammer")
    if matches and #matches > 0 then return matches[1].id end

    return 16550
end

AddHook("OnVariant", "SpammerSlaveHandler", function(var)
    if var[0] == "OnDialogRequest" then
        local dlg = tostring(var[1] or "")
        if dlg:find("anpc_edit") then
            local netid = dlg:match("netID|(%d+)") or dlg:match("netid|(%d+)")
            if netid and _G.CurrentSpamText then
                _G.SpammerSlaveDialogOpened = true

                RunThread(function()
                    local p1 = "action|dialog_return\ndialog_name|anpc_edit\nnetID|" .. netid .. "\nspam_text|" .. _G.CurrentSpamText .. "\nbuttonClicked|Update\n"
                    local p2 = "action|dialog_return\ndialog_name|anpc_edit\nnetID|" .. netid .. "|\nspam_text|" .. _G.CurrentSpamText .. "\nbuttonClicked|Update\n"

                    SendPacket(2, p1)
                    Sleep(200)
                    SendPacket(2, p2)
                end)
            end
            return true
        end
    end
    return false
end)

local function getSpammerNetIDFromPlayerList(targetX, targetY)
    local players = GetPlayerList()
    if players then
        for _, p in pairs(players) do
            if p and p.pos then
                local px = math.floor(p.pos.x / 32)
                local py = math.floor(p.pos.y / 32)

                local isSpammer = false
                if p.name and (p.name:lower():find("spammer") or p.name:lower():find("slave")) then
                    isSpammer = true
                end

                if (px == targetX and py == targetY) or isSpammer then
                    if px == targetX and (py == targetY or py == targetY - 1 or py == targetY + 1) then
                        return p.netid
                    end
                end
            end
        end
    end
    return nil
end

local ALLOWED_OWNERS = {
    ["REMEXSTAFF"] = true,
}

local function GetSpammerOwnerName(p)
    if not p.name then return nil end

    local clean = p.name:gsub("`.", "")
    local idx   = clean:lower():find("spammer")
    if not idx then return nil end

    local prefix = clean:sub(1, idx - 1)
    prefix = prefix:gsub("['’]s%s*$", "")
    prefix = prefix:gsub("[%s:%-|]+$", "")
    prefix = prefix:gsub("^%s+", "")

    if prefix == "" then return nil end
    return prefix
end

local function IsAllowedOwner(ownerName)
    if not ownerName then return false end
    return ALLOWED_OWNERS[ownerName:upper()] == true
end

local function KillSpammer(netid)
    SendPacket(2, "action|wrench\n|netid|" .. netid .. "\n")
    Sleep(300)
    SendPacket(2, "action|dialog_return\ndialog_name|anpc_edit\nnetID|" .. netid .. "|\nbuttonClicked|kill\n")
end

local function DestroySpammer(netid)
    for _ = 1, 3 do
        KillSpammer(netid)
        Sleep(400)

        local stillThere = false
        for _, p in pairs(GetPlayerList() or {}) do
            if p and p.netid == netid then
                stillThere = true
                break
            end
        end

        if not stillThere then return true end
    end
    return false
end

local function AutoKickForeignSpammers()
    local players = GetPlayerList()
    if not players then return 0 end

    local kicked = 0
    for _, p in pairs(players) do
        if p and p.name and p.netid then
            local nameLower = p.name:lower()
            if nameLower:find("spammer") or nameLower:find("slave") then
                local ownerName = GetSpammerOwnerName(p)
                if not IsAllowedOwner(ownerName) then
                    if DestroySpammer(p.netid) then
                        kicked = kicked + 1
                        L(C.warn, "Spammer asing dihancurkan ", C.dim, "(", ownerName or "?", ")")
                    else
                        L(C.err, "Gagal hancurkan spammer netid ", p.netid)
                    end
                end
            end
        end
    end
    return kicked
end

local function processSpammerSlave(pos)
    if not moveTo(pos.x, pos.y + 1, pos) then
        return false
    end
    Sleep(200)

    local spammerNetID = getSpammerNetIDFromPlayerList(pos.x, pos.y)

    if not spammerNetID then
        local p = GetLocal()
        local px_pos = (p and p.pos and p.pos.x) or (pos.x * 32)
        local py_pos = (p and p.pos and p.pos.y) or ((pos.y + 1) * 32)

        SetItemSelected(SPAMMER_ITEM_ID)
        Sleep(250)

        SendPacketRaw(false, {
            type  = 3,
            value = SPAMMER_ITEM_ID,
            px    = pos.x, py = pos.y,
            x     = px_pos, y = py_pos,
        })

        for _ = 1, 10 do
            Sleep(500)
            spammerNetID = getSpammerNetIDFromPlayerList(pos.x, pos.y)
            if spammerNetID then break end
        end
    end

    if not spammerNetID then
        slotLog(pos, C.err, "gagal: tidak terpasang")
        return false
    end

    if pos.spam_text == nil or pos.spam_text == "" then
        slotLog(pos, C.ok, "terpasang")
        return true
    end

    _G.CurrentSpamText = pos.spam_text
    _G.SpammerSlaveDialogOpened = false

    for _ = 1, 5 do
        if _G.SpammerSlaveDialogOpened then break end
        SendPacket(2, "action|wrench\n|netid|" .. spammerNetID)
        for _ = 1, 6 do
            if _G.SpammerSlaveDialogOpened then break end
            Sleep(250)
        end
    end

    if not _G.SpammerSlaveDialogOpened then
        slotLog(pos, C.err, "gagal: dialog tidak muncul")
        return false
    end

    slotLog(pos, C.ok, "terpasang + teks")
    Sleep(500)
    return true
end

RunThread(function()
    local startPlayer = GetLocal()
    local originX, originY
    if startPlayer then
        originX = math.floor(startPlayer.pos.x / 32)
        originY = math.floor(startPlayer.pos.y / 32)
    end

    SPAMMER_ITEM_ID = getSpammerItemID()

    while true do
        local world = GetWorld()
        if world and world.name and world.name ~= "" and world.name ~= "EXIT" then
            if AutoKickForeignSpammers() > 0 then Sleep(500) end

            local anyMissing = false
            for _, slot in ipairs(SPAMMER_LIST) do
                if not getSpammerNetIDFromPlayerList(slot.x, slot.y) then
                    anyMissing = true
                    break
                end
            end

            local needModFly = false
            if anyMissing then
                local currentModFly = GetValue("[C] Modfly")
                if currentModFly == false or currentModFly == nil then
                    ChangeValue("[C] Modfly", true)
                    needModFly = true
                    Sleep(300)
                end
            end

            for _, slot in ipairs(SPAMMER_LIST) do
                if not getSpammerNetIDFromPlayerList(slot.x, slot.y) then
                    processSpammerSlave(slot)
                end
            end

            if anyMissing and originX and originY then
                moveTo(originX, originY)
                Sleep(200)
                if needModFly then ChangeValue("[C] Modfly", false) end
            end
        end
        Sleep(5000)
    end
end)
