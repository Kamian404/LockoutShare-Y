local LSY, L, P, G = unpack((select(2, ...)))

P.DBVer = 2
P.Enable = true
P.Debug = false
P.AutoExtend = true
P.DNDMessage = false
P.InviteOnWhisper = true
P.InviteOnWhisperMsg = '!sharing'
P.InviteOnBNWhisper = false
P.InviteOnBNWhisperMsg = '!sharing'
P.InviteOnInvited = false
P.BlacklistMaliciousUser = true
P.AutoQueue = true
P.LeaveQueueOnWhisper = true
P.LeaveQueueOnWhisperMsg = '!leave'
P.AutoLeave = true
P.InviteTimeLimit = 10
P.TimeLimit = 30
P.WhisperMessage = true
P.BNWhisperMessage = false
P.GroupMessage = true
P.DNDMsg = L["DND_MESSAGE"]
P.EnterQueueMsg = L["QUEUED"]
P.QueryQueueMsg = L["QUEUED_SPAM"]
P.LeaveQueueMsg = L["QUEUE_LEAVE"]
P.FetchErrorMsg = L["FETCH_ERROR_MSG"]
P.TLELeaveMsg = L["TIMELIMIT_EXCEED_AUTO_PROMOTE"]
P.AutoLeaveMsg = L["GOOD_LUCK"]
P.InviteMessageToPlayer = L["INVITE_MESSAGE_TO_PLAYER"]
P.WelcomeMsg1 = L["WELCOME_MSG_1"]
P.WelcomeMsg2 = L["WELCOME_MSG_2"]
P.WelcomeMsg3 = L["WELCOME_MSG_3"]
P.WelcomeMsg4 = L["WELCOME_MSG_4"]
P.CommandsForNormal = "!normal, !nhc, !nm"
P.CommandsForHeroic = "!heroic, !hc"
P.CommandsForLost = "!lost"
P.CommandsForJourney = "!journey"
P.Blacklist = {}

G.DebugLog = {
    {},
    {},
    {},
}
