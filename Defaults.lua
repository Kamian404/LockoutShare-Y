local LSY, L, P, G = unpack((select(2, ...)))

P.DBVer = 2
P.Enable = false
P.Debug = true
P.AutoExtend = true
P.DNDMessage = true
P.InviteOnWhisper = true
P.InviteOnWhisperMsg = '!share'
P.InviteOnBNWhisper = true
P.InviteOnBNWhisperMsg = '!share'
P.InviteOnInvited = false
P.BlacklistMaliciousUser = true
P.AutoQueue = true
P.LeaveQueueOnWhisper = true
P.LeaveQueueOnWhisperMsg = '!leave'
P.AutoLeave = true
P.InviteTimeLimit = 0
P.TimeLimit = 30
P.WhisperMessage = true
P.BNWhisperMessage = true
P.GroupMessage = true
P.DNDMsg = L["Current length of queue: QLEN."]
P.EnterQueueMsg = L["QUEUED"]
P.QueryQueueMsg = L["QUEUED"]
P.LeaveQueueMsg = ERR_LFG_LEFT_QUEUE
P.FetchErrorMsg = L["Failed to fetch your character information from Battle.net, please PM NAME."]
P.TLELeaveMsg = L["Time Limit Exceeded. You're promoted to team leader."]
P.AutoLeaveMsg = L["You're promoted to team leader. Good luck!"]
P.Blacklist = {}

G.DebugLog = {
    {},
    {},
    {},
}
