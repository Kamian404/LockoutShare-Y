local addon, Core = ...
local LSY = LibStub('AceAddon-3.0'):NewAddon(addon, 'AceEvent-3.0', 'AceTimer-3.0', 'AceBucket-3.0')

-- Cache global Lua functions for performance
local _G = _G
local date, string_format, pairs, table_insert, type = date, string.format, pairs, table.insert, type

-- WoW API / Globals (for static analysis)
-- GLOBALS: FISConfig, LibStub, UnitName, GetRealmName, UnitGUID, UnitFactionGroup, DEFAULT_CHAT_FRAME

-- Localization fallback: returns key if no translation is available
local L = setmetatable({}, {
    __index = function(tbl, key)
        tbl[key] = key or ""
        return key
    end,
})

-- Default database tables including debug logs initialized
LSY.DF = {
    profile = {},
    global = { DebugLog = { {}, {}, {} } }
}

LSY.Options = {
    name = L["LockoutShare-Y"],
    type = 'group',
    args = {}
}

-- Expose main tables in Core for external access
Core[1] = LSY
Core[2] = L
Core[3] = LSY.DF.profile
Core[4] = LSY.DF.global
_G[addon] = Core

-- Basic player and addon info cached once
LSY.addonPrefix = "\124cFF70B8FF" .. addon .. "\124r: "
LSY.playerFullName = UnitName('player') .. '-' .. GetRealmName()
LSY.playerGUID = UnitGUID('player')
LSY.sharinguser = ""
LSY.RaidForMsg = ""
LSY.playerfaction = UnitFactionGroup("player")
LSY.invitedTime = 0

function LSY:OnEnable()
    -- Initialize the database with AceDB-3.0, using default tables and default profile enabled
    self.data = LibStub('AceDB-3.0'):New('LockoutShareYDB', self.DF, true)

    -- Migrate legacy data from FISConfig if present
    if FISConfig and FISConfig.DBVer == 2 then
        self.data:SetProfile(self.playerFullName)
        for key in pairs(self.DF.profile) do
            if FISConfig[key] ~= nil then
                self.data.profile[key] = FISConfig[key]
            end
        end
        FISConfig = nil -- clear old global reference
    end

    -- Register profile event callbacks to reinitialize after profile changes
    self.data.RegisterCallback(self, 'OnProfileChanged', 'Initialize')
    self.data.RegisterCallback(self, 'OnProfileCopied', 'Initialize')
    self.data.RegisterCallback(self, 'OnProfileReset', 'Initialize')

    -- Shorthand for current profile and global data
    self.db = self.data.profile
    self.global = self.data.global

    -- Rotate debug logs: oldest discarded, shift logs and clear newest slot
    self.global.DebugLog[1] = self.global.DebugLog[2]
    self.global.DebugLog[2] = self.global.DebugLog[3]
    self.global.DebugLog[3] = {}

    self:Initialize()
end

-- Print a formatted message with prefix to the default chat frame
function LSY:PrintMessage(...)
    _G.DEFAULT_CHAT_FRAME:AddMessage(self.addonPrefix .. string_format(...))
end

-- Append a timestamped log entry with status to debug log buffer
function LSY:LogMessage(...)
    local currentStatus = self.status or "unknown"
    table_insert(self.global.DebugLog[3], date("%Y-%m-%d %H:%M:%S%z") .. " - Status: " .. currentStatus .. " - " .. string_format(...))
end

-- If debugging enabled, log and print messages
function LSY:DebugPrint(...)
    if self.db.Debug then
        self:LogMessage(...)
        self:PrintMessage(...)
    end
end
