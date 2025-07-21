local LSY, L, P, G = unpack((select(2, ...)))
function LSY:CreateSharesFrame()
    if self.sharesFrame then
        self:UpdateSharesFrame()
        self.sharesFrame:Show()
        return
    end

    local frame = CreateFrame("Frame", "LSYSharesFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(320, 420)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Title: "Shares"
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", 0, -10)
    frame.title:SetText("Shares")

    -- Total and Today
    frame.totalText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.totalText:SetPoint("TOPLEFT", 15, -35)

    frame.todayText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.todayText:SetPoint("TOPRIGHT", -15, -35)

    -- ScrollFrame für Lockouts
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 40)

    local content = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(content)
    content:SetSize(1, 1) -- Placeholder size

    frame.content = content
    frame.entries = {}

    -- Last shared
    frame.lastSharedText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.lastSharedText:SetPoint("BOTTOMLEFT", 15, 15)

    self.sharesFrame = frame

    -- Inhalte anzeigen
    self:UpdateSharesFrame()
end

function LSY:UpdateSharesFrame()
    local frame = self.sharesFrame
    if not frame then return end

    frame.totalText:SetText("Total: " .. (self.db.totalCount or 0))
    frame.todayText:SetText("Today: " .. (self.todayCount or 0))
    frame.lastSharedText:SetText("Last shared: " .. (self.lastShared or "-"))

    -- Alte Labels entfernen
    for _, label in ipairs(frame.entries) do
        label:Hide()
        label:SetParent(nil)
    end
    frame.entries = {}

    -- Neue Lockouts anzeigen
    local yOffset = -5
    for i, text in ipairs(self.lockouts or {}) do
        local label = frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", 0, yOffset)
        label:SetText(text)
        table.insert(frame.entries, label)
        yOffset = yOffset - 18
    end

    -- Höhe des Content-Frames für Scrollbar setzen
    frame.content:SetHeight(math.max(#frame.entries * 18, 1))
end
