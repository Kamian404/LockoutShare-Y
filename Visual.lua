local LSY, L, P, G = unpack((select(2, ...)))

function LSY:CreateSharesFrame()
    if self.sharesFrame then
        self:UpdateSharesFrame()
        self.sharesFrame:Show()
        return
    end

    local frame = CreateFrame("Frame", "LSYSharesFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(320, 420)
    local pos = self.db.sharesFramePos
    if pos then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        frame:SetPoint("CENTER") -- Fallback
    end
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        LSY.db.sharesFramePos = { point, relativePoint, xOfs, yOfs }
    end)

    -- Title: "LockoutShare-Y"
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("LockoutShare-Y")

    -- Total and Today (immer sichtbar)
    frame.totalText = self:CreateFont(frame, "GameFontNormal")
    frame.totalText:SetPoint("TOPLEFT", 15, -35)

    frame.todayText = self:CreateFont(frame, "GameFontNormal")
    frame.todayText:SetPoint("TOPRIGHT", -15, -35)

    -- Container für einklappbaren Content (ScrollFrame + Instanzliste)
    local contentContainer = CreateFrame("Frame", nil, frame)
    contentContainer:SetPoint("TOPLEFT", 15, -60)
    contentContainer:SetPoint("BOTTOMRIGHT", -35, 60)
    frame.contentContainer = contentContainer

    -- ScrollFrame im Container
    local scrollFrame = CreateFrame("ScrollFrame", nil, contentContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()
    frame.scrollFrame = scrollFrame

    -- Content Frame als ScrollChild
    local content = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(content)
    content:SetSize(1, 1) -- Platzhalter, wird dynamisch erweitert
    frame.content = content

    frame.entries = {}

    -- Last shared (immer sichtbar)
    frame.lastSharedText = self:CreateFont(frame, "GameFontNormal")
    frame.lastSharedText:SetPoint("BOTTOMLEFT", 15, 30)
    frame.lastSharedText:SetWidth(290)              -- Platz für Text
    frame.lastSharedText:SetWordWrap(true)          -- Automatischer Umbruch
    frame.lastSharedText:SetJustifyH("LEFT")        -- Linksbündig

    -- Last shared (immer sichtbar)
    frame.lastSharedToText = self:CreateFont(frame, "GameFontNormal")
    frame.lastSharedToText:SetPoint("BOTTOMLEFT", 15, 15)
    frame.lastSharedToText:SetWidth(290)              -- Platz für Text
    frame.lastSharedToText:SetWordWrap(true)          -- Automatischer Umbruch
    frame.lastSharedToText:SetJustifyH("LEFT")        -- Linksbündig

    -- Toggle Button für einklappen
    local toggleButton = CreateFrame("Button", nil, frame)
    toggleButton:SetSize(24, 24)
    toggleButton:SetPoint("TOPLEFT", 0, 1)
    frame.toggleButton = toggleButton

   -- Texturen für + und - Symbol
    local plusTex = toggleButton:CreateTexture(nil, "OVERLAY")
    plusTex:SetSize(18, 18)
    plusTex:SetPoint("CENTER")
    plusTex:SetTexture("Interface\\Buttons\\UI-PlusButton-UP") -- Plus-Icon

    local minusTex = toggleButton:CreateTexture(nil, "OVERLAY")
    minusTex:SetSize(18, 18)
    minusTex:SetPoint("CENTER")
    minusTex:SetTexture("Interface\\Buttons\\UI-MinusButton-UP") -- Minus-Icon

    -- Initial: Content sichtbar -> Minus sichtbar, Plus versteckt
    plusTex:Hide()
    minusTex:Show()

    toggleButton:SetScript("OnClick", function()
        if contentContainer:IsShown() then
            -- Minimieren
            contentContainer:Hide()
            plusTex:Show()
            minusTex:Hide()
            frame:SetHeight(110)  -- Höhe für Titel + Total/Today + Last shared
            LSY.db.sharesFrameCollapsed = true  -- <--- Zustand merken
        else
            -- Aufklappen
            contentContainer:Show()
            plusTex:Hide()
            minusTex:Show()
            frame:SetHeight(420) -- volle Höhe mit Inhalt
            LSY.db.sharesFrameCollapsed = false -- <--- Zustand merken
        end
    end)

    self.sharesFrame = frame

        -- Zustand beim Laden wiederherstellen
    if self.db.sharesFrameCollapsed then
        contentContainer:Hide()
        plusTex:Show()
        minusTex:Hide()
        frame:SetHeight(110)
    else    
        contentContainer:Show()
        plusTex:Hide()
        minusTex:Show()
        frame:SetHeight(420)
    end

    if ElvUI then
        local E = unpack(ElvUI)
        if E and E:GetModule("Skins") then
            local S = E:GetModule("Skins")
            S:HandleFrame(frame, true)  -- "true" = Transparent template
        end
    end

    self:UpdateSharesFrame()
end



function LSY:UpdateSharesFrame()
    local frame = self.sharesFrame
    if not frame then return end

    local function ApplyFontSize(fontString)
        if fontString and fontString.SetFont then
            local font, _, flags = fontString:GetFont()
            fontString:SetFont(font, LSY.db.fontSize, flags)
        end
    end

    ApplyFontSize(frame.totalText)
    ApplyFontSize(frame.todayText)
    ApplyFontSize(frame.lastSharedText)
    ApplyFontSize(frame.lastSharedToText)
    for _, label in ipairs(frame.entries) do
        ApplyFontSize(label)
    end

    frame.totalText:SetText("Total: " .. (self.db.totalCount or 0))
    frame.todayText:SetText("Today: " .. (self.todayCount or 0))
    frame.lastSharedText:SetText("Last shared: " .. (self.lastShared or "-"))
    frame.lastSharedToText:SetText("To: " .. (self.lastSharedTo or "-"))

    -- Alte Labels entfernen
    for _, label in ipairs(frame.entries) do
        label:Hide()
        label:SetParent(nil)
    end
    frame.entries = {}

    -- Neue Lockouts anzeigen
    local yOffset = -5
    for i, text in ipairs(self.lockouts or {}) do
        local label = self:CreateFont(frame, "GameFontNormal")
        label:SetPoint("TOPLEFT", 0, yOffset)
        label:SetWidth(250)
        label:SetWordWrap(true)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        table.insert(frame.entries, label)
        yOffset = yOffset - label:GetStringHeight() - 6  -- Dynamisch Höhe abziehen
    end


    -- Höhe des Content-Frames für Scrollbar setzen
    frame.content:SetHeight(math.max(#frame.entries * 18, 1))
end

function LSY:CreateFont(parent, template)
    local fontString = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    local font, _, flags = fontString:GetFont()
    fontString:SetFont(font, self.db.fontSize, flags)
    return fontString
end