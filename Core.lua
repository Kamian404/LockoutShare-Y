local LSY, L, P, G = unpack((select(2, ...)))
-- Lua functions
_G["LSY"] = LSY
local _G = _G
local bit_band, bit_bor, format, gsub, ipairs, pairs, select = bit.band, bit.bor, format, gsub, ipairs, pairs, select
local strfind, strlower, strmatch, tinsert, tonumber, tremove = strfind, strlower, strmatch, tinsert, tonumber, tremove

-- WoW API / Variables
local BNSendWhisper = BNSendWhisper
local C_BattleNet_GetAccountInfoByID = C_BattleNet.GetAccountInfoByID
local C_PartyInfo_ConfirmConvertToRaid = C_PartyInfo.ConfirmConvertToRaid
local C_PartyInfo_ConfirmInviteUnit = C_PartyInfo.ConfirmInviteUnit
local C_PartyInfo_ConfirmLeaveParty = C_PartyInfo.ConfirmLeaveParty
local C_PartyInfo_ConvertToParty = C_PartyInfo.ConvertToParty
local C_PartyInfo_GetInviteReferralInfo = C_PartyInfo.GetInviteReferralInfo
local GetInviteConfirmationInfo = GetInviteConfirmationInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceChatLink = GetSavedInstanceChatLink
local GetSavedInstanceInfo = GetSavedInstanceInfo
local GetTime = GetTime
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local PromoteToLeader = PromoteToLeader
local RequestRaidInfo = RequestRaidInfo
local ResetInstances = ResetInstances
local RespondToInviteConfirmation = RespondToInviteConfirmation
local SendChatMessage = SendChatMessage
local SetDungeonDifficultyID = SetDungeonDifficultyID
local SetLegacyRaidDifficultyID = SetLegacyRaidDifficultyID
local SetRaidDifficultyID = SetRaidDifficultyID
local SetSavedInstanceExtend = SetSavedInstanceExtend
local UnitIsDND = UnitIsDND
local UnitPosition = UnitPosition

local tContains = tContains
local StaticPopup_Visible = StaticPopup_Visible
local StaticPopup_Hide = StaticPopup_Hide
local StaticPopupSpecial_Hide = StaticPopupSpecial_Hide

local Enum_PartyRequestJoinRelation_Friend = Enum.PartyRequestJoinRelation.Friend
local Enum_PartyRequestJoinRelation_Guild = Enum.PartyRequestJoinRelation.Guild
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local GREEN_FONT_COLOR_CODE = GREEN_FONT_COLOR_CODE
local LE_INVITE_CONFIRMATION_REQUEST = LE_INVITE_CONFIRMATION_REQUEST
local LE_INVITE_CONFIRMATION_SUGGEST = LE_INVITE_CONFIRMATION_SUGGEST
local LFG_LIST_LOADING = LFG_LIST_LOADING
local LIGHTYELLOW_FONT_COLOR_CODE = LIGHTYELLOW_FONT_COLOR_CODE
local MARKED_AFK = MARKED_AFK
local RED_FONT_COLOR_CODE = RED_FONT_COLOR_CODE
local SLASH_STOPWATCH_PARAM_PAUSE1 = "Pause"
local SLASH_STOPWATCH_PARAM_STOP1 = "Stop"
local SOCIAL_SHARE_TEXT = "Share"
local START = START
local UNLIMITED = UNLIMITED

local invitedToGroupTemplate = gsub(ERR_INVITED_TO_GROUP_SS, '|Hplayer:%%s|h%[%%s%]|h', '|Hplayer:(.+)|h(.+)|h')
local invitedAlreadyInGroupTemplate = gsub(ERR_INVITED_ALREADY_IN_GROUP_SS, '|Hplayer:%%s|h%[%%s%]|h', '|Hplayer:(.+)|h(.+)|h')

local STATUS_INIT     = 0
local STATUS_IDLE     = 1
local STATUS_INVITING = 2
local STATUS_INVITED  = 3
local STATUS_LEAVING  = 4

SLASH_LSY1 = "/lsy"

LSY.supportedInstances = {}

function LSY:BuildSupportedInstances()
    self.supportedInstances = {}

    for key, data in pairs(InstanceData) do
        if self.db[key] and data.instanceId then -- only active instances
            local diff = data.difficultyId
            if type(diff) ~= "table" then
                diff = { diff }
            end

            -- Wenn 14 dabei, dann auch 15 hinzufügen
            if tContains(diff, 14) and not tContains(diff, 15) then
                table.insert(diff, 15)
            end

            self.supportedInstances[data.instanceId] = {
                difficulty = diff
            }
        end
    end
end

-- print current status and config to chatframe
function LSY:PrintStatus()
    if not self.db.Enable then
        self:PrintMessage(RED_FONT_COLOR_CODE .. " ".. SLASH_STOPWATCH_PARAM_STOP1 .. FONT_COLOR_CODE_CLOSE .. SOCIAL_SHARE_TEXT)
    elseif self.status == STATUS_INIT then
        self:PrintMessage(LIGHTYELLOW_FONT_COLOR_CODE .. " ".. LFG_LIST_LOADING .. FONT_COLOR_CODE_CLOSE)
    elseif self.db.AutoQueue and self.pausedQueue then
        self:PrintMessage(LIGHTYELLOW_FONT_COLOR_CODE .. " ".. SLASH_STOPWATCH_PARAM_PAUSE1 .. FONT_COLOR_CODE_CLOSE)
    else
        self:PrintMessage(GREEN_FONT_COLOR_CODE .. START .. " " .. FONT_COLOR_CODE_CLOSE .. SOCIAL_SHARE_TEXT)
    end
end

-- send formatted message
function LSY:SendMessage(text, chatType, channel, currIndex)
    if not text or text == '' then return end

    if chatType == 'WHISPER' and not self.db.WhisperMessage then
        return
    elseif chatType == 'BNWHISPER' and not self.db.BNWhisperMessage then
        return
    elseif (chatType == 'CHECK' or chatType == 'RAID' or chatType == 'PARTY') and not self.db.GroupMessage then
        return
    end

    if not self.sharinguser then -- To prevent weird names
        self.sharinguser = ""
    end

    text = gsub(text, 'QCURR', currIndex or 0)
    text = gsub(text, 'QLEN', #self.queue)
    text = gsub(text, 'MTIME', self.db.TimeLimit == 0 and UNLIMITED or self.db.TimeLimit)
    text = gsub(text, 'TIMELEFT', math.floor(GetTime() - self.invitedTime))
    text = gsub(text, 'NAME', self.playerFullName)
    text = gsub(text, 'SHARINGUSER', self.sharinguser)
    text = gsub(text, 'SUPINSTANCE', self.RaidForMsg)
    text = gsub(text, 'FACTIONSPECIFIC', self.playerfaction)

    if chatType == 'BNWHISPER' then
        return BNSendWhisper(channel, text)
    elseif chatType == 'CHECK' then
        if IsInRaid() then
            chatType = 'RAID'
        elseif IsInGroup() then
            chatType = 'PARTY'
        else
            return
        end
    end

    return SendChatMessage(text, chatType, nil, channel)
end

function LSY:UpdateDNDMessage()
    if self.db.DNDMessage then
        self:SendMessage(self.db.DNDMsg, 'DND')
    end
end

function LSY:RemoveDNDStatus()
    if UnitIsDND('player') then
        SendChatMessage('', 'DND')
    end
end

function LSY:TogglePause(pausedQueue)
    self.pausedQueue = pausedQueue
    self:PrintStatus()
end

function LSY:Initialize()
    self:Release()
    self.status = STATUS_INIT
    self.queue = {}

    SlashCmdList["LSY"] = function(msg)
        LSY:HandleSlashCommand(msg)
    end

    if self.db.Enable then
        LSY:CreateSharesFrame()
        LSY.sharesFrame:Show()
        self:RegisterEvent('UPDATE_INSTANCE_INFO')
        self:RegisterBucketEvent('PLAYER_ENTERING_WORLD', 1, RequestRaidInfo)
        RequestRaidInfo()
    else
        self:UnregisterAllEvents()
        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end
    end

    self:RemoveDNDStatus()

    self:PrintStatus()
end

function LSY:Update()
    self:UnregisterAllEvents()
    if not self.db.Enable then return end

    self:RegisterEvent('UPDATE_INSTANCE_INFO')
    self:RegisterEvent('PARTY_INVITE_REQUEST')
    self:RegisterEvent('CHAT_MSG_SYSTEM')

    if self.db.DNDMessage then
        self:UpdateDNDMessage()
    else
        self:RemoveDNDStatus()
    end
    if self.db.InviteOnWhisper then
        self:RegisterEvent('CHAT_MSG_WHISPER')
    end
    if self.db.InviteOnBNWhisper then
        self:RegisterEvent('CHAT_MSG_BN_WHISPER')
    end
    if self.db.InviteOnInvited then
        self:RegisterEvent('UI_ERROR_MESSAGE')
    end
    if self.db.AutoQueue and not self.timer then
        self.timer = self:ScheduleRepeatingTimer('FetchUpdate', .5)
    end
end

function LSY:ReleaseAndUpdate()
    if self.status ~= STATUS_IDLE then
        self:Release()
    end
    self:Update()
end

function LSY:UPDATE_INSTANCE_INFO()
    self:BuildSupportedInstances()
    if not self.db.Enable then return end

    if self.db.AutoExtend then
        for i = 1, GetNumSavedInstances() do
            local _, _, _, difficulty, _, extended = GetSavedInstanceInfo(i)
            local link = GetSavedInstanceChatLink(i)
            ---@cast link string

            -- Extract InstanceID from chat link
            local instanceID = tonumber(strmatch(link, ':(%d+):%d+:%d+%|h'))

            -- check if supported and not yet extended
            if instanceID and not extended and self.supportedInstances[instanceID] then
                local allowedDifficulties = self.supportedInstances[instanceID].difficulty

                if allowedDifficulties and tContains(allowedDifficulties, difficulty) then
                    SetSavedInstanceExtend(i, true)
                    LSY:PrintMessage(L["EXTEND_INSTANCE"], link)
                end
            end
        end
    end

    if self.status == STATUS_INIT then
        self.status = STATUS_IDLE
        self:PrintStatus()
        self:Update()
    end
end

function LSY:PARTY_INVITE_REQUEST(_, name)
    self:DebugPrint("Rejected invitation from %s", name)
    self:SendMessage(L["AUTODECLINE_INVITES"], "WHISPER", name)

    StaticPopup_Hide('PARTY_INVITE')
    StaticPopupSpecial_Hide(_G.LFGInvitePopup)
end

function LSY:CHAT_MSG_SYSTEM(_, text)
    if self.db.DNDMessage and strfind(text, MARKED_AFK) then
        self:UpdateDNDMessage()
    elseif self.db.InviteOnInvited then
        local playerName = strmatch(text, invitedToGroupTemplate)
            or strmatch(text, invitedAlreadyInGroupTemplate)

        if playerName then
            if self:DetectMaliciousUser(playerName) then return end

            if not self.db.AutoQueue then
                self:Invite(playerName)
            else
                self:QueuePush(playerName)
            end
        end
    end
end

function LSY:UI_ERROR_MESSAGE(_, errorType)
    if errorType == 720 then
        self:DebugPrint("Inviting during invited")

        if self.pendingInvite then
            self:DebugPrint("Readding %s to queue", self.pendingInvite)

            tinsert(self.queue, 1, self.pendingInvite)
        end
    end
end

-- Check the user's current zone and determine the appropriate instance settings
function LSY:CheckUserLocation()
    local userZoneId = C_Map.GetBestMapForUnit("party1")
    local userFaction = UnitFactionGroup("party1")
    self.sharinguser = UnitName("party1")

    for key, instance in pairs(InstanceData) do
        -- Only continue if this instance is enabled in the addon settings
        if self.db[key] then
            for _, zoneId in ipairs(instance.zoneId) do
                if zoneId == userZoneId then

                    -- Handle faction-specific instances
                    if instance.factionSpecific then
                        if userFaction == self.playerfaction then
                            C_PartyInfo_ConfirmConvertToRaid()
                            self.RaidDifficulty = instance.difficultyId
                            self.RaidForMsg = instance.displayName
                            SetRaidDifficultyID(self.RaidDifficulty)
                            LSY:UpdateCounterAndList(instance.displayName)
                            return true, userZoneId
                        else
                            self:SendMessage(L["FACTIONSPECIFIC"], 'CHECK')
                            C_Timer.After(1, function() C_PartyInfo.LeaveParty() end)
                            return false, userZoneId
                        end

                    -- Handle non-faction-specific instances
                    else

                        if userZoneId == 2025 and LSY:AreAllInstancesWithZoneIdEnabled(2025) then -- Special for Dragonflight, where Raid and Dungeon are in the same zone
                            C_PartyInfo_ConfirmConvertToRaid()
                            self.RaidForMsg = "Dawn of the Infinite and Vault of the Incarnates"
                            SetDungeonDifficultyID(23)
                            SetRaidDifficultyID(14)
                            return true, userZoneId
                        end
                        
                        LSY:UpdateCounterAndList(instance.displayName)
                        
                        if instance.category == "raid" then
                            C_PartyInfo_ConfirmConvertToRaid()
                            self.RaidDifficulty = instance.difficultyId
                            SetRaidDifficultyID(self.RaidDifficulty)
                        elseif instance.category == "dungeon" then
                            self.DungeonDifficulty = instance.difficultyId
                            SetDungeonDifficultyID(self.DungeonDifficulty)
                        end
                        self.RaidForMsg = instance.displayName
                        return true, userZoneId
                    end
                end
            end
        end
    end

    -- If no valid instance was found for the current zone
    self:SendMessage(L["ZONE_UNSOPPORTED"], 'CHECK')
    self:DebugPrint("Unsupported Zone: " .. userZoneId)
    C_Timer.After(1, function() C_PartyInfo.LeaveParty() end)
    return false, nil
end

function LSY:UpdateCounterAndList(name)

    LSY:AddOrUpdateInstanceCount(name)
    self.db.totalCount = (self.db.totalCount or 0) + 1
    LSY.totalCount = self.db.totalCount
    LSY.todayCount = (LSY.todayCount or 0) + 1
    LSY.lastShared = name
    LSY:UpdateSharesFrame()
end

function LSY:AddOrUpdateInstanceCount(name)
    if not self.lockouts then self.lockouts = {} end

    for i, value in ipairs(self.lockouts) do
        -- Extrahiere Zählung, falls vorhanden (z. B. "3x Black Temple")
        local count, baseStr = value:match("^(%d+)x (.+)$")
        if baseStr == name or value == name then
            count = tonumber(count) or 1
            count = count + 1
            self.lockouts[i] = count .. "x " .. name
            return
        end
    end

    -- Noch nicht vorhanden? Dann neu einfügen
    table.insert(self.lockouts, "1x " .. name)
end


-- invite player, STATUS_IDLE -> STATUS_INVITING when queue
function LSY:Invite(name)
    -- If DND active, dont share and response DND message
    if self.db.DNDMessage then
        self:UpdateDNDMessage()
        return
    end

    self:DebugPrint("Inviting %s to party", name)
    self:SendMessage(self.db.InviteMessageToPlayer, "WHISPER", name)

    C_PartyInfo_ConfirmLeaveParty()
    ResetInstances()

    if self.db.AutoQueue then
        self.status = STATUS_INVITING
        self.inviteTime = GetTime()
        self:RegisterEvent('GROUP_ROSTER_UPDATE')
    end

    C_PartyInfo_ConfirmInviteUnit(name)

    self.pendingInvite = name
end

-- player in party, STATUS_INVITING -> STATUS_INVITED
function LSY:ConfirmInvite()
    self:RegisterEvent('CHAT_MSG_PARTY')
    self:RegisterEvent('CHAT_MSG_RAID')
    self:RegisterEvent('GROUP_INVITE_CONFIRMATION')
    self:RegisterEvent('LFG_LIST_ACTIVE_ENTRY_UPDATE')

    self.status = STATUS_INVITED
    self.invitedTime = GetTime()
    self.pendingInvite = nil
    self.playerWantsLead = false

    -- Things for Pebble..
    if LSY:FindStringInHaystack(self.whisperedCommand, self.db.CommandsForPebble) then
        LSY:HandlePebble()
    end

    -- check where the player is and if we support his location
    C_Timer.After(2, function()
        local supportedZone, userZoneID = LSY:CheckUserLocation()
        if supportedZone then
            if (self.db.WelcomeMsg1) then self:SendMessage(self.db.WelcomeMsg1, 'CHECK') end
            if (self.db.WelcomeMsg2) then self:SendMessage(self.db.WelcomeMsg2, 'CHECK') end
            if (self.db.WelcomeMsg3) then self:SendMessage(self.db.WelcomeMsg3, 'CHECK') end
            if (self.db.WelcomeMsg4) then self:SendMessage(self.db.WelcomeMsg4, 'CHECK') end

            if userZoneID == 118 then
                self:SendMessage("You need to have the first boss already killed on 25 Heroic.", 'CHECK')
                self:SendMessage("Kill Blood Queen boss only, then leave ICC.", 'CHECK')
                self:SendMessage("Then re-enter and go straight to Lich King.", 'CHECK')
            else
                C_Timer.After(1, function()
                    self:SendMessage(L["DifficultyInfo"], 'CHECK')
                end)
            end
        else
            return
        end
    end)
end

-- pending to leave, STATUS_INVITED -> STATUS_LEAVING
function LSY:Leave(leaveMsg)
    self:UnregisterEvent('CHAT_MSG_PARTY')
    self:UnregisterEvent('CHAT_MSG_RAID')
    self:UnregisterEvent('LFG_LIST_ACTIVE_ENTRY_UPDATE')
    self:RegisterEvent('CHAT_MSG_PARTY_LEADER', 'Release')
    self:RegisterEvent('CHAT_MSG_RAID_LEADER', 'Release')

    self.status = STATUS_LEAVING
    self.leavingTime = GetTime()

    if not IsInGroup() then
        -- player left
        self:DebugPrint("Player left before leaving message sent")
        self:Release()
        return
    end

    if not self.db.GroupMessage or not leaveMsg or leaveMsg == '' then
        self:Release()
    end

    self:SendMessage(leaveMsg, 'CHECK')
end

-- release current user, STATUS_LEAVING -> STATUS_IDLE
function LSY:Release()
    self:UnregisterEvent('GROUP_ROSTER_UPDATE')
    self:UnregisterEvent('CHAT_MSG_PARTY')
    self:UnregisterEvent('CHAT_MSG_RAID')
    self:UnregisterEvent('GROUP_INVITE_CONFIRMATION')
    self:UnregisterEvent('CHAT_MSG_PARTY_LEADER')
    self:UnregisterEvent('CHAT_MSG_RAID_LEADER')

    if IsInGroup() then
        if GetNumGroupMembers() > 1 then
            PromoteToLeader('party1')
        end
        C_PartyInfo_ConfirmLeaveParty()
    end

    self.status = STATUS_IDLE
end

function LSY:FetchUpdate()
    if self.status == STATUS_IDLE then
        if self.pausedQueue then return end

        -- check queue
        if #self.queue > 0 then
            local name = tremove(self.queue, 1)

            self:Invite(name)
        end
    elseif self.status == STATUS_INVITING then
        local elapsed = GetTime() - self.inviteTime
        if self.db.InviteTimeLimit ~= 0 and elapsed >= self.db.InviteTimeLimit then
            self:DebugPrint("Leaving party: Invite Time Limit Exceeded")
            self:Release()
            return
        end
    elseif self.status == STATUS_INVITED then
        -- check max waiting time
        local elapsed = GetTime() - self.invitedTime
        if self.db.TimeLimit ~= 0 and elapsed >= self.db.TimeLimit then
            self:DebugPrint("Leaving party: Enter Time Limit Exceeded")
            self:Leave(self.db.TLELeaveMsg)
            return
        end

        -- check player place and if he wants lead, we give him lead and 10 more seconds
        if self.playerWantsLead then
            if UnitIsGroupLeader('player') then
                local instanceID = select(4, UnitPosition('party1'))
                if instanceID and self.supportedInstances[instanceID] then
                    self.invitedTime = self.invitedTime + 10
                    self:SendMessage(L["HINT_LEAD"], 'CHECK')
                    self:DebugPrint("Promote Player to lead, he entered instance %d", instanceID)
                    if GetNumGroupMembers() > 1 then
                        PromoteToLeader('party1')
                    end
                end
            end
        else
            if self.db.AutoLeave then
                local instanceID = select(4, UnitPosition('party1'))
                if instanceID and self.supportedInstances[instanceID] then
                    self:DebugPrint("Leaving party: Player entered instance %d", instanceID)
                    self:Leave(self.db['AutoLeaveMsg' .. instanceID] or self.db.AutoLeaveMsg)
                    return
                end
            end
        end
    elseif self.status == STATUS_LEAVING then
        if self.leavingTime < GetTime() - 5 then
            -- 5 seconds after trying to send leaving message
            -- but no message sent
            self:DebugPrint("Failed to send leaving message")
            self:Release()
        end
    end
end

function LSY:GROUP_ROSTER_UPDATE()
    if self.status == STATUS_INVITING then
        if IsInGroup() then
            if GetNumGroupMembers() > 1 then
                -- accepted
                self:DebugPrint("Player accepted")
                self:ConfirmInvite()
            end
            -- still waiting
        else
            -- rejected
            self:DebugPrint("Player rejected")
            self:Release()
        end
    elseif self.status == STATUS_INVITED then
        if not IsInGroup() then
            if GetTime() - self.invitedTime < .5 then
                -- protection: delay check here
                -- IsInGroup() return false just after invite in some case
                self:ScheduleTimer('GROUP_ROSTER_UPDATE', .5)
                return
            end
            -- player left
            self:DebugPrint("Player left while in group")
            self:Release()
        end
    elseif self.status == STATUS_LEAVING then
        if not IsInGroup() then
            -- player left
            self:DebugPrint("Player left while sending leaving message")
            self:Release()
        end
    end
end

-- add a player to queue
function LSY:QueuePush(name)
    self:DebugPrint("Adding %s to queue", name)

    local playerIndex = self:QueueQuery(name)
    if not playerIndex then
        tinsert(self.queue, name)
        if UnitInParty("player") then
            self:SendMessage(self.db.EnterQueueMsg, 'WHISPER', name, #self.queue)
        end
    else
        self:SendMessage(self.db.QueryQueueMsg, 'WHISPER', name, playerIndex)
    end
end

-- remove a player from queue
function LSY:QueuePop(name, leaveQueueMsg)
    self:DebugPrint("Removing %s from queue", name)

    local playerIndex = self:QueueQuery(name)
    if playerIndex then
        tremove(self.queue, playerIndex)
    end
    self:SendMessage(leaveQueueMsg, 'WHISPER', name)
end

-- query a player in queue
function LSY:QueueQuery(name)
    local playerIndex
    for index, playerName in ipairs(self.queue) do
        if playerName == name then
            playerIndex = index
            break
        end
    end
    return playerIndex
end

function LSY:RecvChatMessage(text)
    text = strlower(text)
    if text == '++' then
        self:SendMessage(L["OLD_COMMAND_FOR_LEAD"], 'CHECK')
        return
    end

    if text == '+' then
        return self:Leave(self.db.AutoLeaveMsg)
    elseif strfind(text, 'raid') then
        return C_PartyInfo_ConfirmConvertToRaid()
    elseif strfind(text, 'party') then
        return C_PartyInfo_ConvertToParty()
    end

    if string.upper(text) == "!INFO" then
        self:SendMessage(L["ADDON_INFO"], 'CHECK')
    end

    if string.upper(text) == "!TIP" then
        self:SendMessage(L["COMMAND_TIP"], 'CHECK')
    end

    if string.upper(text) == "!LEAD" then
        self.playerWantsLead = true
        self:SendMessage(L["COMMAND_LEAD"], 'CHECK')
    end

    -- Check if heroic
    if LSY:FindStringInHaystack(text, self.db.CommandsForHeroic) then
        SetRaidDifficultyID(15)
        self:SendMessage(L["COMMAND_HEROIC"], 'CHECK')
        self:SendMessage(L["HINT_HEROIC"], 'CHECK')
    end

    -- Check if normal
    if LSY:FindStringInHaystack(text, self.db.CommandsForNormal) then
        SetRaidDifficultyID(14)
        self:SendMessage(L["COMMAND_NORMAL"], 'CHECK')
        self:SendMessage(L["HINT_NORMAL"], 'CHECK')
    end

    if string.upper(text) == "!MYTHIC" then
        self:SendMessage(L["COMMAND_MYTHIC"], 'CHECK')
    end
end

function LSY:CHAT_MSG_PARTY(_, text, playerName)
    self:DebugPrint("Received party message '%s' from %s", text, playerName)

    self:RecvChatMessage(text)
end

function LSY:CHAT_MSG_RAID(_, text, playerName)
    self:DebugPrint("Received raid message '%s' from %s", text, playerName)

    self:RecvChatMessage(text)
end

function LSY:LFG_LIST_ACTIVE_ENTRY_UPDATE(_)
    self:SendMessage(L["HINT_LFG"], 'CHECK')
    return self:Leave(self.db.AutoLeaveMsg)
end

do
    local lastMessageTime = {}
    local lastMessageCount = {}

    function LSY:DetectMaliciousUser(sender)
        if self.db.BlacklistMaliciousUser then
            if tContains(self.db.Blacklist, sender) then
                self:DebugPrint("Ignored whisper from malicious user %s", sender)
                return true
            end

            -- rule: 5 messages within 2 seconds

            local now = GetTime()
            if lastMessageTime[sender] and lastMessageTime[sender] >= now - 2 then
                if lastMessageCount[sender] >= 4 then -- before increases
                    -- malicious user detected!
                    self:DebugPrint("Malicious user %s detected", sender)
                    self:SendMessage(L["IGNORE_PLAYER"], "WHISPER", sender)

                    self:QueuePop(sender)
                    tinsert(self.db.Blacklist, sender)
                    return true
                end
            else
                -- reset count after 2 seconds
                lastMessageCount[sender] = nil
            end

            lastMessageTime[sender] = now
            lastMessageCount[sender] = (lastMessageCount[sender] or 0) + 1
        end
    end

    function LSY:CHAT_MSG_WHISPER(_, text, sender)
        self:DebugPrint("Received whisper '%s' from %s", text, sender)

        if self:DetectMaliciousUser(sender) then return end

        if self.db.InviteOnWhisper and LSY:FindStringInHaystack(text, self.db.InviteOnWhisperMsg) or self.db.InviteOnWhisper and LSY:FindStringInHaystack(text, self.db.CommandsForPebble) then
            self.whisperedCommand = text
            if not self.db.AutoQueue then
                self:Invite(sender)
            else
                self:QueuePush(sender)
            end
        elseif self.db.LeaveQueueOnWhisper and text == self.db.LeaveQueueOnWhisperMsg then
            self:QueuePop(sender, self.db.LeaveQueueMsg)
        end
        
        self:RecvChatMessage(text)
    end
end

function LSY:CHAT_MSG_BN_WHISPER(_, text, playerName, _, _, _, _, _, _, _, _, _, _, presenceID)
    self:DebugPrint("Received Battle.net whisper '%s' from %s(%s)", text, playerName, presenceID)

    if text ~= self.db.InviteOnBNWhisperMsg then return end

    local accountInfo = C_BattleNet_GetAccountInfoByID(presenceID)
    local gameAccountInfo = accountInfo and accountInfo.gameAccountInfo
    local characterName = gameAccountInfo and gameAccountInfo.characterName
    local realmName = gameAccountInfo and gameAccountInfo.realmName
    self:DebugPrint("Received character %s-%s", characterName or "UNKNOWN", realmName or "UNKNOWN")

    if characterName and characterName ~= '' and realmName and realmName ~= '' then
        local sender = characterName .. '-' .. realmName
        if not self.db.AutoQueue then
            self:Invite(sender)
        else
            self:QueuePush(sender)
        end
    else
        self:SendMessage(self.db.FetchErrorMsg, 'BNWHISPER', presenceID)
    end
end

function LSY:GROUP_INVITE_CONFIRMATION()
    local dialogName, dialog = StaticPopup_Visible('GROUP_INVITE_CONFIRMATION')
    if not dialogName then return end

    local invite = dialog.data
    local confirmationType, name = GetInviteConfirmationInfo(invite)
    local suggesterGuid, suggesterName, relationship = C_PartyInfo_GetInviteReferralInfo(invite)

    self:DebugPrint("Received invite %s to %s from %s with relation %d",
        confirmationType == LE_INVITE_CONFIRMATION_REQUEST and "REQUEST" or
        (confirmationType == LE_INVITE_CONFIRMATION_SUGGEST and "SUGGEST" or "UNKNOWN")
        , name, suggesterName, relationship)

    if confirmationType == LE_INVITE_CONFIRMATION_REQUEST then
        if not suggesterGuid or suggesterGuid == LSY.playerGUID or (
            relationship ~= Enum_PartyRequestJoinRelation_Friend and
            relationship ~= Enum_PartyRequestJoinRelation_Guild
        ) then
            -- we only allow invite request from friend and guild
            -- reject
            StaticPopup_Hide('GROUP_INVITE_CONFIRMATION')
            return
        end
    elseif confirmationType ~= LE_INVITE_CONFIRMATION_SUGGEST then
        -- not request and not suggest
        -- reject
        StaticPopup_Hide('GROUP_INVITE_CONFIRMATION')
        return
    end

    RespondToInviteConfirmation(invite, true)
    StaticPopup_Hide('GROUP_INVITE_CONFIRMATION')

    self:QueuePop(name)
end


function LSY:manipulateTotalCount(number)
    self.db.totalCount = number
    LSY:UpdateSharesFrame()
end

function string.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function LSY:GetInstanceKeysByZoneId(targetZoneId)
    local keys = {}

    for key, data in pairs(InstanceData) do
        local zones = data.zoneId
        if type(zones) == "table" then
            for _, zone in ipairs(zones) do
                if zone == targetZoneId then
                    table.insert(keys, key)
                    break
                end
            end
        elseif zones == targetZoneId then
            table.insert(keys, key)
        end
    end

    return keys
end
function LSY:AreAllInstancesWithZoneIdEnabled(targetZoneId)
    local keys = self:GetInstanceKeysByZoneId(targetZoneId)
    for _, key in ipairs(keys) do
        if not self.db[key] then
            return false
        end
    end
    return true
end

function LSY:FindStringInHaystack(needle, haystack)
    local messages = { strsplit(",", haystack) }

    for _, msg in ipairs(messages) do
        msg = msg:trim():lower() -- Leerzeichen entfernen, lowercase
        if needle:lower() == msg then
            return true
        end
    end
    return false
end

function LSY:HandleSlashCommand(msg)
    msg = msg:lower():trim()

    if msg == "show" then
        LSY.sharesFrame:Show()
    else
        print("What?")
    end
end

function LSY:HandlePebble()
    local userZoneId = C_Map.GetBestMapForUnit("party1")
    for key, instance in pairs(InstanceData) do
        -- Only continue if this instance is enabled in the addon settings
        if self.db[key] then
            for _, zoneId in ipairs(instance.zoneId) do
                if zoneId == userZoneId then
                    self:SendMessage(L["MOVE_OUT_DEEPHOLM"], 'CHECK')
                    C_Timer.After(1, function() C_PartyInfo.LeaveParty() end)
                else 
                    LSY:UpdateCounterAndList(instance.displayName)
                    self:SendMessage("Hello pet collector!", 'CHECK')
                    self:SendMessage("You now have MTIME seconds to accept the Quest.", 'CHECK')
                    self:SendMessage("As soon as you did write '+'in chat.", 'CHECK')
                    local quest_ids = {instance.description}

                    for _, questID in pairs(quest_ids) do
                        local questID = tonumber(questID)
                        local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
                        if questLogIndex then
                            QuestLogPushQuest(questLogIndex)
                            return
                        end
                    end
                end
            end
        end
    end
end