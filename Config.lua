local LSY, L, P, G = unpack((select(2, ...)))
local C = LSY:NewModule('Config')
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

-- Lua functions
local _G = _G
local ipairs, pairs, tinsert = ipairs, pairs, tinsert

-- WoW API / Variables
local RequestRaidInfo = RequestRaidInfo
local Settings_OpenToCategory = Settings.OpenToCategory

local HideUIPanel = HideUIPanel
local tDeleteItem = tDeleteItem

local CONTINUE = CONTINUE
local SLASH_STOPWATCH_PARAM_PAUSE1 = SLASH_STOPWATCH_PARAM_PAUSE1

-- GLOBALS: LibStub

local currentSelectBlacklist


-- Hilfsfunktion: Erzeuge Toggle-Einträge aus InstanceData
function GenerateTogglesFromInstanceData()
    local toggles = {}
    for key, data in pairs(InstanceData) do
        toggles[key] = {
            order = data.order,
            type = "toggle",
            name = data.displayName,
            desc = data.description or "",
            width = 100,
            get = function(info) return LSY.db[key] end,
            set = function(info, value) LSY.db[key] = value end,
        }
    end
    return toggles
end

LSY.Options.args.config = {
    name = L["Open config"],
    guiHidden = true,
    type = 'execute',
    func = function() C:ShowConfig() end,
}

LSY.Options.args.General = {
    order = 1,
    type = 'group',
    name = L["General settings"],
    get = function(info) return LSY.db[info[#info]] end,
    set = function(info, value) LSY.db[info[#info]] = value end,
    args = {
        Enable = {
            order = 1,
            name = ENABLE,
            type = 'toggle',
            set = function(info, value) LSY.db[info[#info]] = value; LSY:Initialize() end,
        },
        Debug = {
            order = 2,
            name = L["Debug Mode"],
            type = 'toggle',
        },
        Utility = {
            order = 10,
            name = L["Utility"],
            type = 'group',
            guiInline = true,
            set = function(info, value) LSY.db[info[#info]] = value; LSY:Update() end,
            disabled = function() return not LSY.db.Enable end,
            args = {
                AutoExtend = {
                    order = 12,
                    name = L["Auto Extend Saved Instances"],
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; RequestRaidInfo() end,
                },
                DNDMessage = {
                    order = 13,
                    name = L["Use DND Message"],
                    type = 'toggle',
                },
            },
        },
        Invite = {
            order = 20,
            name = L["Invite"],
            type = 'group',
            guiInline = true,
            disabled = function() return not LSY.db.Enable end,
            args = {
                InviteOnWhisper = {
                    order = 21,
                    name = L["Auto Invite on Whisper"],
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:Update() end,
                },
                InviteOnBNWhisper = {
                    order = 22,
                    name = L["Auto Invite on Battle.net Whisper"],
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:Update() end,
                },
                InviteOnInvited = {
                    order = 23,
                    name = L["Auto Invite on Invited"],
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:Update() end,
                },
                BlacklistMaliciousUser = {
                    order = 24,
                    name = L["Blacklist Malicious User"],
                    type = 'toggle',
                    disabled = function() return not LSY.db.Enable or not LSY.db.InviteOnWhisper end,
                },
            },
        },
        Queue = {
            order = 30,
            name = L["Auto Queuing"],
            type = 'group',
            guiInline = true,
            disabled = function() return not LSY.db.Enable or not LSY.db.AutoQueue end,
            args = {
                AutoQueue = {
                    order = 31,
                    name = L["Auto Queuing"],
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:ReleaseAndUpdate() end,
                    disabled = function() return not LSY.db.Enable end,
                },
                LeaveQueueOnWhisper = {
                    order = 32,
                    name = L["Leave Queue on Whisper"],
                    type = 'toggle',
                },
                AutoLeave = {
                    order = 33,
                    name = L["Auto Leave Party"],
                    type = 'toggle',
                },
                InviteTimeLimit = {
                    order = 34,
                    name = L["Invite Time Limit (s)"],
                    desc = L["Time limit for user to accept invitation. If set to zero, no time limit is imposed."],
                    type = 'range',
                    min = 0, max = 60, step = 1,
                },
                TimeLimit = {
                    order = 35,
                    name = L["Enter Time Limit (s)"],
                    desc = L["Time limit for user to enter instance. If set to zero, no time limit is imposed."],
                    type = 'range',
                    min = 0, max = 120, step = 1,
                },
                Pause = {
                    order = 36,
                    name = function()
                        return not LSY.pausedQueue and SLASH_STOPWATCH_PARAM_PAUSE1 or CONTINUE
                    end,
                    type = 'execute',
                    func = function()
                        LSY:TogglePause(not LSY.pausedQueue)
                    end,
                },
            },
        },
        Message = {
            order = 40,
            name = L["Notify Message"],
            type = 'group',
            guiInline = true,
            disabled = function() return not LSY.db.Enable or not LSY.db.AutoQueue end,
            args = {
                WhisperMessage = {
                    order = 41,
                    name = L["Whisper Message"],
                    type = 'toggle',
                },
                BNWhisperMessage = {
                    order = 42,
                    name = L["Battle.net Whisper Message"],
                    type = 'toggle',
                },
                GroupMessage = {
                    order = 43,
                    name = L["Group Message"],
                    type = 'toggle',
                },
            },
        },
        Blacklist = {
            order = 50,
            name = L["Blacklist"],
            type = 'group',
            guiInline = true,
            disabled = function() return not LSY.db.Enable end,
            args = {
                Add = {
                    order = 51,
                    name = ADD,
                    type = 'input',
                    get = function() end,
                    set = function(_, value) LSY:QueuePop(value); tinsert(LSY.db.Blacklist, value) end,
                },
                List = {
                    order = 52,
                    name = IGNORE_LIST,
                    type = 'select',
                    get = function() return currentSelectBlacklist end,
                    set = function(_, value) currentSelectBlacklist = value end,
                    values = function()
                        local result = {}
                        for _, name in ipairs(LSY.db.Blacklist) do
                            result[name] = name
                        end
                        return result
                    end,
                },
                Delete = {
                    order = 53,
                    name = DELETE,
                    type = 'execute',
                    func = function() tDeleteItem(LSY.db.Blacklist, currentSelectBlacklist); currentSelectBlacklist = nil end,
                    disabled = function() return not LSY.db.Enable or not currentSelectBlacklist end,
                },
            },
        },
    },
}

LSY.Options.args.Message = {
    order = 2,
    type = 'group',
    name = L["Notify Message"],
    confirm = true,
    get = function(info) return LSY.db[info[#info]] end,
    set = function(info, value) LSY.db[info[#info]] = value end,
    args = {
        InviteOnWhisperMsg = {
            order = 1,
            name = L["Whisper Message of Auto Inviting"],
            type = 'input',
        },
        InviteOnBNWhisperMsg = {
            order = 2,
            name = L["Battle.net Whisper Message of Auto Inviting"],
            type = 'input',
        },
        LeaveQueueOnWhisperMsg = {
            order = 3,
            name = L["Whisper Message of Leaving Queue"],
            type = 'input',
        },
        DNDMsg = {
            order = 11,
            name = L["DND Message"],
            type = 'input',
            width = "full",
            multiline = true,
        },
        EnterQueueMsg = {
            order = 21,
            name = L["Message When Entering Queue"],
            type = 'input',
            width = "full",
            multiline = true,
        },
        FetchErrorMsg = {
            order = 22,
            name = L["Message When Failing to Fetch"],
            type = 'input',
            width = "full",
            multiline = true,
        },
        QueryQueueMsg = {
            order = 23,
            name = L["Message When Quering Queue Position"],
            type = 'input',
            width = "full",
            multiline = true,
        },
        LeaveQueueMsg = {
            order = 24,
            name = L["Message When Leaving Queue"],
            type = 'input',
            width = "full",
            multiline = true,
        },
        TLELeaveMsg = {
            order = 32,
            name = L["Message Before Leaving due to Time Limit Exceeded"],
            type = 'input',
            width = "full",
            multiline = true,
        },
        AutoLeaveMsg = {
            order = 33,
            name = L["Message Before Leaving due to player entered instance"],
            type = 'input',
            width = "full",
            multiline = true,
        },
        TextReplace = {
            order = 91,
            name = L["You can insert following words into the text field, and it will be replace by corresponding variables."] .. "\n" ..
            L["QCURR - The position of the player in queue."] .. "\n" ..
            L["QLEN - The length of the queue."] .. "\n" ..
            L["MTIME - Time Limit to wait players to enter instance."] .. "\n" ..
            L["NAME - The name and realm of current character."],
            type = 'description',
        },
    },
}

-- Instanzgruppen definieren (nach Bedarf erweiterbar)
local instanceGroups = {
    raids = {
        order = 3,
        name = "Raids",
        filter = function(data) return data.category == "raid" and not data.factionSpecific end,
    },
    megadungeons = {
        order = 4,
        name = "Mega Dungeons",
        filter = function(data) return data.category == "dungeon" end,
    },
    factionSpecifics = {
        order = 5,
        name = "Faction Specifics",
        filter = function(data) return data.factionSpecific == true end,
    },
    transmogsAndPets = {
        order = 6,
        name = "Transmogs & Pets",
        filter = function(data)
            return data.category == "transmogsAndPets" or data.difficultyId == nil
        end,
    },
}

-- Generiere dynamisch alle Toggles basierend auf InstanceData
local function GenerateTogglesFromInstanceData()
    local toggles = {}
    for key, data in pairs(InstanceData) do
        toggles[key] = {
            order = data.order or 99,
            type = "toggle",
            name = data.displayName or key,
            desc = data.description or "",
            width = 100,
            get = function() return LSY.db[key] end,
            set = function(_, value) LSY.db[key] = value end,
        }
    end
    return toggles
end

-- Erstelle Gruppen und füge gefilterte Instanzen ein
local function BuildInstanceOptions()
    local toggles = GenerateTogglesFromInstanceData()
    local args = {}

    for groupKey, groupData in pairs(instanceGroups) do
        args[groupKey] = {
            order = groupData.order,
            type = "group",
            name = groupData.name,
            inline = true,
            args = {},
        }

        for key, data in pairs(InstanceData) do
            if groupData.filter(data) and toggles[key] then
                args[groupKey].args[key] = toggles[key]
            end
        end
    end

    return {
        order = 3,
        type = 'group',
        name = L["Instances"],
        childGroups = 'tree',
        args = args,
    }
end

-- Weise die dynamisch generierte Config zu
LSY.Options.args.Instances = BuildInstanceOptions()

function C:OnEnable()
    LSY.Options.args.Profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(LSY.data)

    AceConfig:RegisterOptionsTable('LockoutShare-Y', LSY.Options, 'fis')
    local _, configFrameName = AceConfigDialog:AddToBlizOptions('LockoutShare-Y', L["LockoutShare-Y"], nil, 'General')
    AceConfigDialog:AddToBlizOptions('LockoutShare-Y', L["Notify Message"], L["LockoutShare-Y"], 'Message')
    AceConfigDialog:AddToBlizOptions('LockoutShare-Y', L["Instances"], L["LockoutShare-Y"], 'Instances')

    self.configFrameName = configFrameName
end

function C:ShowConfig()
    if _G.SettingsPanel:IsShown() then
        HideUIPanel(_G.SettingsPanel)
    else
        Settings_OpenToCategory(self.configFrameName)
    end
end