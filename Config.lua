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

local CONTINUE = "Continue"
local SLASH_STOPWATCH_PARAM_PAUSE1 = "Pause"

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
            name = "Debug Mode",
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
                    name = "Auto Extend Saved Instances",
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; RequestRaidInfo() end,
                },
                DNDMessage = {
                    order = 13,
                    name = "Use DND Message",
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
                    name = "Auto Invite on Whisper",
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:Update() end,
                },
                InviteOnBNWhisper = {
                    order = 22,
                    name = "Auto Invite on Battle.net Whisper",
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:Update() end,
                },
                InviteOnInvited = {
                    order = 23,
                    name = "Auto Invite on Invited",
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:Update() end,
                },
                BlacklistMaliciousUser = {
                    order = 24,
                    name = "Blacklist Malicious User",
                    type = 'toggle',
                    disabled = function() return not LSY.db.Enable or not LSY.db.InviteOnWhisper end,
                },
            },
        },
        Queue = {
            order = 30,
            name = "Auto Queuing",
            type = 'group',
            guiInline = true,
            disabled = function() return not LSY.db.Enable or not LSY.db.AutoQueue end,
            args = {
                AutoQueue = {
                    order = 31,
                    name = "Auto Queuing",
                    type = 'toggle',
                    set = function(info, value) LSY.db[info[#info]] = value; LSY:ReleaseAndUpdate() end,
                    disabled = function() return not LSY.db.Enable end,
                },
                LeaveQueueOnWhisper = {
                    order = 32,
                    name = "Leave queue on whisper",
                    type = 'toggle',
                },
                AutoLeave = {
                    order = 33,
                    name = "Auto leave party",
                    type = 'toggle',
                },
                blankTimes = {
                    order = 33.1,
                    type = "description",
                    width = "full",
                    name = " ",
                },
                InviteTimeLimit = {
                    order = 34,
                    name = "Invite time limit (s)",
                    desc = "Time limit for user to accept invitation. If set to zero, no time limit is imposed.",
                    type = 'range',
                    min = 0, max = 60, step = 1,
                },
                TimeLimit = {
                    order = 35,
                    name = "Enter time limit (s)",
                    desc = "Time limit for user to enter instance. If set to zero, no time limit is imposed.",
                    type = 'range',
                    min = 0, max = 120, step = 1,
                },
                TimeExtraForLead = {
                    order = 36,
                    name = "Extra Time after promote (s)",
                    desc = "This will extend the Time for x seconds, so the User can do stuff after lead given.",
                    type = 'range',
                    min = 0, max = 60, step = 1,
                },
                Pause = {
                    order = 37,
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
            name = L["COMMANDS_MESSAGES"],
            type = 'group',
            guiInline = true,
            disabled = function() return not LSY.db.Enable or not LSY.db.AutoQueue end,
            args = {
                WhisperMessage = {
                    order = 41,
                    name = "Whisper Message",
                    type = 'toggle',
                },
                BNWhisperMessage = {
                    order = 42,
                    name = "Battle.net Whisper Message",
                    type = 'toggle',
                },
                GroupMessage = {
                    order = 43,
                    name = "Group Message",
                    type = 'toggle',
                },
            },
        },
        Blacklist = {
            order = 50,
            name = "Blacklist",
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
    name = L["COMMANDS_MESSAGES"],
    confirm = true,
    get = function(info) return LSY.db[info[#info]] end,
    set = function(info, value) LSY.db[info[#info]] = value end,
    args = {
        header_general = {
            order = 01,
            type = "header",
            width = "full",
            name = "Allowed commands",
        },
        InviteOnWhisperMsg = {
            order = 02,
            name = "Command for Sharing",
            type = 'input',
        },
        InviteOnBNWhisperMsg = {
            order = 03,
            name = "Command for BNet Sharing",
            type = 'input',
        },
        LeaveQueueOnWhisperMsg = {
            order = 04,
            name = "Command to Leave queue",
            type = 'input',
        },
        CommandsForVIP = {
            order = 04,
            name = "Commands for VIPs",
            type = 'input',
        },
        CommandsForNormal = {
            order = 05,
            name = "Normal Difficulty",
            type = 'input',
        },
        CommandsForHeroic = {
            order = 06,
            name = "Heroic Difficulty",
            type = 'input',
        },
        blankcommand = {
            order = 06.1,
            type = "description",
            width = "full",
            name = " ",
        },
        CommandsForLost = {
            order = 07,
            name = "Command for Lost",
            type = 'input',
        },
        CommandsForJourney = {
            order = 08,
            name = "Command for Journey",
            type = 'input',
        },
        CommandsBlacklist = {
            order = 08.1,
            name = "Blacklisted Commands",
            type = 'input',
        },
        description_general = {
            order = 09,
            name = "You can enter multiple commands by dividing with comma ','",
            type = 'description',
        },
        blank1 = {
            order = 09.1,
            type = "description",
            width = "full",
            name = " ",
        },
        header_welcome_message = {
            order = 10,
            type = "header",
            width = "full",
            name = "Welcome Messages",
        },
        WelcomeMsg1 = {
            order = 11,
            name = L["WELCOME_HEADER_1"],
            type = 'input',
            width = "full",
        },
        WelcomeMsg2 = {
            order = 12,
            name = L["WELCOME_HEADER_2"],
            type = 'input',
            width = "full",
        },
        WelcomeMsg3 = {
            order = 13,
            name = L["WELCOME_HEADER_3"],
            type = 'input',
            width = "full",
        },
        WelcomeMsg4 = {
            order = 14,
            name = L["WELCOME_HEADER_4"],
            type = 'input',
            width = "full",
        },
        description_welcome_message = {
            order = 19.1,
            name = "Leave it blank to not send all 4 messages",
            type = 'description',
        },
        blank2 = {
            order = 19.2,
            type = "description",
            width = "full",
            name = " ",
        },
        header_other = {
            order = 20,
            type = "header",
            width = "full",
            name = "Other Messages",
        },
        DNDMsg = {
            order = 21,
            name = L["DND"],
            type = 'input',
            width = "full",
        },
        InviteMessageToPlayer = {
            order = 22,
            name = L["CONFIG_INVITE_MESSAGE"],
            type = 'input',
            width = "full",
        },
        VIPMessage = {
            order = 22.1,
            name = "Message for VIPs",
            type = 'input',
            width = "full",
        },
        EnterQueueMsg = {
            order = 23,
            name = L["ENTER_QUEUE"],
            type = 'input',
            width = "full",
        },
        FetchErrorMsg = {
            order = 24,
            name = L["Message when failing to fetch"],
            type = 'input',
            width = "full",
        },
        QueryQueueMsg = {
            order = 25,
            name = L["Message when quering queue position"],
            type = 'input',
            width = "full",
        },
        LeaveQueueMsg = {
            order = 26,
            name = L["Message when leaving queue"],
            type = 'input',
            width = "full",
        },
        TLELeaveMsg = {
            order = 32,
            name = L["Message before leaving due to Time Limit Exceeded"],
            type = 'input',
            width = "full",
        },
        AutoLeaveMsg = {
            order = 33,
            name = L["Message before leaving due to player entered instance"],
            type = 'input',
            width = "full",
        },
        TipMsg = {
            order = 34,
            name = "Message for tips",
            type = 'input',
            width = "full",
        },
        TextReplace = {
            order = 91,
            name = "You can insert following words into the text field, and it will be replace by corresponding variables." .. "\n" ..
            "QCURR - The position of the player in queue." .. "\n" ..
            "QLEN - The length of the queue." .. "\n" ..
            "QWAIT - The estimated waiting time for the queue." .. "\n" ..
            "MTIME - Time Limit to wait players to enter instance." .. "\n" ..
            "SUPINSTANCE - The instance the player stands infront of (hopefully)" .. "\n" ..
            "SHARINGUSER - The name of the player." .. "\n" ..
            "NAME - The name and realm of your own character.",
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


LSY.Options.args.Informations = {
    name = "About",
    type = "group",
    args = {
        author = {
            order = 1,
            type = "description",
            width = "full",
            fontSize = "medium",
            name = "|cffeda55f" .. "Autor".. ": |r" .. "Kamian (Yrni-Antonidas)",
        },
        support = {
            order = 2.2,
            type = "description",
            width = "full",
            fontSize = "medium",
            name = "|cffeda55f" .. "Support" .. ": |r" .. "Fudrick (Yermaw-Bronzebeard)",
        },
        version = {
            order = 2.5,
            type = "description",
            width = "full",
            fontSize = "medium",
            name = "|cffeda55f" .. "Version" .. ": |r" .. "1.1.9",
        },
        header_commands_you = {
            order = 3,
            type = "header",
            width = "full",
            name = "Commands for YOU",
        },
        blank1 = {
            order = 3.1,
            type = "description",
            width = "full",
            name = " ",
        },
        commands_you = {
            order = 3.2,
            type = "description",
            width = "full",
            fontSize = "medium",
            name = "|cffeda55f/lsy |r- " .. "Show the Settings" .. "\n" ..
                "|cffeda55f/lsy on/off |r- " .. "Activate/Deactivates the Addon" .. "\n" ..
                "|cffeda55f/lsy show |r- " .. "Show the Counter-Window" .. "\n" ..
                "|cffeda55f/lsy dnd |r- " .. "Activates DND & stops sharing" .. "\n"
        },
        blank11 = {
            order = 3.3,
            type = "description",
            width = "full",
            name = " ",
        },
        header_commands_player = {
            order = 4,
            type = "header",
            width = "full",
            name = "Commands for Player",
        },
        blank0 = {
            order = 4.1,
            type = "description",
            width = "full",
            name = " ",
        },
        commands_player = {
            order = 4.2,
            type = "description",
            width = "full",
            fontSize = "medium",
            name = "|cffeda55f!sharing |r- " .. "Standard command for sharing request" .. "\n" ..
                "|cffeda55f!heroic / !hc |r- " .. "Sets the difficulty to Heroic" .. "\n" ..
                "|cffeda55f!normal / !nhc / !nm |r- " .. "Sets the difficulty to Normal (default)" .. "\n" ..
                "|cffeda55f!lead |r- " .. "The Player get lead after entering the Dungeon/Raid. So they can invite friends or list in LFG - They can invite Friends before entering the Instance too." .. "\n" ..
                "|cffeda55f+ |r- " .. "This command will free you." .. "\n" ..
                "|cffeda55f!tip |r- " .. "This will print out your Name+Realm, if someone wants to tip you." .. "\n" ..
                "|cffeda55f!info |r- " .. "This will just whispers the Info about the Autor." .. "\n"
        }
    }
}

function C:OnEnable()
    LSY.Options.args.Profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(LSY.data)

    AceConfig:RegisterOptionsTable('LockoutShare-Y', LSY.Options, 'fis')
    local _, configFrameName = AceConfigDialog:AddToBlizOptions('LockoutShare-Y', L["LockoutShare-Y"], nil, 'General')
    AceConfigDialog:AddToBlizOptions('LockoutShare-Y', L["COMMANDS_MESSAGES"], L["LockoutShare-Y"], 'Message')
    AceConfigDialog:AddToBlizOptions('LockoutShare-Y', L["Instances"], L["LockoutShare-Y"], 'Instances')
    AceConfigDialog:AddToBlizOptions('LockoutShare-Y', "Informations", L["LockoutShare-Y"], 'Informations')

    self.configFrameName = configFrameName
end

function C:ShowConfig()
    if _G.SettingsPanel:IsShown() then
        HideUIPanel(_G.SettingsPanel)
    else
        Settings_OpenToCategory(self.configFrameName)
    end
end

function LSY:ShowConfig()
    Settings_OpenToCategory("LockoutShare-Y")
end
