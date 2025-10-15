local AddonName, Addon = ...
local OmniCC = _G.OmniCC

local function nop(_, _) end

local function Clamp(value, min, max)
  if value > max then
    return max
  elseif value < min then
    return min
  end
  return value
end

local function Lerp(startValue, endValue, amount)
  return (1 - amount) * startValue + amount * endValue
end

local function Saturate(value)
  return Clamp(value, 0, 1)
end

OmniCC.Templates = {
  ["UIPanelCloseButton"] = function(frame)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    close:SetFrameLevel(128)
    frame.CloseButton = close
    close:SetNormalTexture(format("Interface\\AddOns\\%s\\media\\redbutton2x", AddonName))
    close:GetNormalTexture():SetTexCoord(0.152344, 0.292969, 0.0078125, 0.304688)
    close:SetPushedTexture(format("Interface\\AddOns\\%s\\media\\redbutton2x", AddonName))
    close:GetPushedTexture():SetTexCoord(0.152344, 0.292969, 0.320312, 0.617188)
    close:SetDisabledTexture(format("Interface\\AddOns\\%s\\media\\redbutton2x", AddonName))
    close:GetDisabledTexture():SetTexCoord(0.152344, 0.292969, 0.632812, 0.929688)
    close:SetHighlightTexture(format("Interface\\AddOns\\%s\\media\\redbutton2x", AddonName), "ADD")
    close:GetHighlightTexture():SetTexCoord(0.449219, 0.589844, 0.0078125, 0.304688)
  end,

  ["TitleDragAreaTemplate"] = function(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
      local p = self:GetParent()
      p.moving = true
      p:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
      local p = self:GetParent()
      p.moving = nil
      p:StopMovingOrSizing()
    end)
  end,

  ["InputBoxTemplate"] = function(frame)
    frame:EnableMouse(true)
    -- Left Texture
    local left = frame:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(format("Interface\\AddOns\\%s\\media\\CommonSearch", AddonName))
    left:SetSize(8, 20)
    left:SetPoint("LEFT", frame, "LEFT", -5, 0)
    left:SetTexCoord(0.886719, 0.949219, 0.335938, 0.648438)
    frame.Left = left
    -- Right Texture
    local right = frame:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(format("Interface\\AddOns\\%s\\media\\CommonSearch", AddonName))
    right:SetSize(8, 20)
    right:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    right:SetTexCoord(0.00390625, 0.0664062, 0.664062, 0.976562)
    frame.Right = right
    -- Middle Texture (zwischen Left und Right)
    local middle = frame:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture(format("Interface\\AddOns\\%s\\media\\CommonSearch", AddonName))
    middle:SetSize(10, 20)
    middle:SetTexCoord(0.00390625, 0.878906, 0.335938, 0.648438)
    middle:SetPoint("LEFT", left, "RIGHT")
    middle:SetPoint("RIGHT", right, "LEFT")
    frame.Middle = middle
    -- FontString
    local fontString = frame:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    frame.FontString = fontString
    -- Scripts
    frame:SetScript("OnEscapePressed", function(self)
      EditBox_ClearFocus(self)
    end)
    frame:SetScript("OnEditFocusLost", function(self)
      EditBox_ClearHighlight(self)
    end)
    frame:SetScript("OnEditFocusGained", function(self)
      EditBox_HighlightText(self)
    end)
  end,

  ["NumericInputBoxTemplate"] = function(frame)
    OmniCC.Templates["InputBoxTemplate"](frame)
    frame:SetNumeric(true)
    -- Callbacks
    frame.valueChangedCallback = nop
    frame.valueFinalizedCallback = nop
    -- Mixin Functions
    function frame:SetOnValueChangedCallback(func)
      self.valueChangedCallback = func or nop
    end
    function frame:SetOnValueFinalizedCallback(func)
      self.valueFinalizedCallback = func or nop
    end
    -- Scripts
    frame:SetScript("OnTextChanged", function(self, userInput)
      self.valueChangedCallback(self:GetNumber(), userInput)
    end)
    frame:SetScript("OnEditFocusLost", function(self)
      EditBox_ClearHighlight(self)
      self.valueFinalizedCallback(self:GetNumber())
    end)
    frame:SetScript("OnEnterPressed", function(self)
      EditBox_ClearFocus(self)
    end)
  end,

  ["NumericInputSpinnerTemplate"] = function(frame)
    OmniCC.Templates["InputBoxTemplate"](frame)
    frame:SetMaxLetters(3)
    frame:SetNumeric(true)
    frame:ClearFocus()
    frame:SetSize(31, 20)

    -- Left texture
    local left = frame:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(format("Interface\\AddOns\\%s\\media\\Common-Input-Border", AddonName))
    left:SetSize(8, 20)
    left:SetPoint("LEFT", frame, "LEFT", -5, 0)
    left:SetTexCoord(0.0, 0.0625, 0.0, 0.625)
    frame.Left = left

    -- Right texture
    local right = frame:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(format("Interface\\AddOns\\%s\\media\\Common-Input-Border", AddonName))
    right:SetSize(8, 20)
    right:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    right:SetTexCoord(0.9375, 1.0, 0.0, 0.625)
    frame.Right = right

    -- Middle texture
    local middle = frame:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture(format("Interface\\AddOns\\%s\\media\\Common-Input-Border", AddonName))
    middle:SetSize(10, 20)
    middle:SetPoint("LEFT", left, "RIGHT")
    middle:SetPoint("RIGHT", right, "LEFT")
    middle:SetTexCoord(0.0625, 0.9375, 0.0, 0.625)
    frame.Middle = middle

    -- Increment button
    local inc = CreateFrame("Button", nil, frame)
    inc:SetSize(23, 22)
    inc:SetPoint("LEFT", frame, "RIGHT", 0, 0)
    inc:SetNormalTexture(format("Interface\\AddOns\\%s\\media\\UI-SpellbookIcon-NextPage-Up", AddonName))
    inc:SetPushedTexture(format("Interface\\AddOns\\%s\\media\\UI-SpellbookIcon-NextPage-Down", AddonName))
    inc:SetDisabledTexture(format("Interface\\AddOns\\%s\\media\\UI-SpellbookIcon-NextPage-Disabled", AddonName))
    local incHL = inc:CreateTexture(nil, "HIGHLIGHT")
    incHL:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-Common-MouseHilight", AddonName))
    incHL:SetBlendMode("ADD")
    incHL:SetAllPoints()
    frame.IncrementButton = inc

    inc:SetScript("OnMouseDown", function(self)
      if self:IsEnabled() then
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:GetParent():StartIncrement()
      end
    end)
    inc:SetScript("OnMouseUp", function(self)
      self:GetParent():EndIncrement()
    end)

    -- Decrement button
    local dec = CreateFrame("Button", nil, frame)
    dec:SetSize(23, 22)
    dec:SetPoint("RIGHT", frame, "LEFT", -6, 0)
    dec:SetNormalTexture(format("Interface\\AddOns\\%s\\media\\UI-SpellbookIcon-PrevPage-Up", AddonName))
    dec:SetPushedTexture(format("Interface\\AddOns\\%s\\media\\UI-SpellbookIcon-PrevPage-Down", AddonName))
    dec:SetDisabledTexture(format("Interface\\AddOns\\%s\\media\\UI-SpellbookIcon-PrevPage-Disabled", AddonName))
    local decHL = dec:CreateTexture(nil, "HIGHLIGHT")
    decHL:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-Common-MouseHilight", AddonName))
    decHL:SetBlendMode("ADD")
    decHL:SetAllPoints()
    frame.DecrementButton = dec

    dec:SetScript("OnMouseDown", function(self)
      if self:IsEnabled() then
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:GetParent():StartDecrement()
      end
    end)
    dec:SetScript("OnMouseUp", function(self)
      self:GetParent():EndDecrement()
    end)

    -- Mouse wheel catcher
    local wheel = CreateFrame("Frame", nil, frame)
    wheel:EnableMouse(true)
    wheel:SetAllPoints()
    frame.MouseWheelCatcher = wheel

    wheel:SetScript("OnMouseWheel", function(self, delta)
      if self:GetParent():IsEnabled() then
        local amount = IsShiftKeyDown() and 10 or 1
        if delta > 0 then
          self:GetParent():Increment(amount)
        else
          self:GetParent():Decrement(amount)
        end
        self:GetParent():ClearFocus()
      end
    end)

    -- Scripts
    frame:SetScript("OnEscapePressed", EditBox_ClearFocus)
    frame:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
    frame:SetScript("OnEditFocusGained", EditBox_HighlightText)
    frame:SetScript("OnTextChanged", function(self)
      self:OnTextChanged()
    end)

    -- Fontstring
    local fs = frame:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    frame:SetFontString(fs)

    -- Mixin
    local MAX_TIME_BETWEEN_CHANGES_SEC = .5
    local MIN_TIME_BETWEEN_CHANGES_SEC = .075
    local TIME_TO_REACH_MAX_SEC = 3
    local EditBox_SetEnabled = getmetatable(frame).__index.SetEnabled

    function frame:SetValue(value)
      local newValue = Clamp(value, self.min or -math.huge, self.max or math.huge)
      local clampIfExceededRange = self.clampIfInputExceedsRange and (value ~= newValue)
      local changed = newValue ~= self.currentValue
      if clampIfExceededRange or changed then
        self.currentValue = newValue
        self:SetNumber(newValue)
        if self.highlightIfInputExceedsRange and clampIfExceededRange then
          self:HighlightText()
        end
        if changed and self.onValueChangedCallback then
          self.onValueChangedCallback(self, self:GetNumber())
        end
      end
    end

    function frame:SetMinMaxValues(min, max)
      if self.min ~= min or self.max ~= max then
        self.min = min
        self.max = max
        self:SetValue(self:GetValue())
      end
    end

    function frame:GetValue()
      return self.currentValue or self.min or 0
    end

    function frame:SetOnValueChangedCallback(onValueChangedCallback)
      self.onValueChangedCallback = onValueChangedCallback
    end

    function frame:Increment(amount)
      self:SetValue(self:GetValue() + (amount or 1))
    end

    function frame:Decrement(amount)
      self:SetValue(self:GetValue() - (amount or 1))
    end

    function frame:SetEnabled(enable)
      self.IncrementButton:SetEnabled(enable)
      self.DecrementButton:SetEnabled(enable)
      EditBox_SetEnabled(self, enable)
    end

    function frame:Enable()
      self:SetEnabled(true)
    end

    function frame:Disable()
      self:SetEnabled(false)
    end

    function frame:OnTextChanged()
      self:SetValue(self:GetNumber())
    end

    function frame:StartIncrement()
      self.incrementing = true
      self.startTime = GetTime()
      self.nextUpdate = MAX_TIME_BETWEEN_CHANGES_SEC
      self:SetScript("OnUpdate", self.OnUpdate)
      self:Increment()
      self:ClearFocus()
    end

    function frame:EndIncrement()
      self:SetScript("OnUpdate", nil)
    end

    function frame:StartDecrement()
      self.incrementing = false
      self.startTime = GetTime()
      self.nextUpdate = MAX_TIME_BETWEEN_CHANGES_SEC
      self:SetScript("OnUpdate", self.OnUpdate)
      self:Decrement()
      self:ClearFocus()
    end

    function frame:EndDecrement()
      self:SetScript("OnUpdate", nil)
    end

    function frame:OnUpdate(elapsed)
      self.nextUpdate = self.nextUpdate - elapsed
      if self.nextUpdate <= 0 then
        if self.incrementing then
          self:Increment()
        else
          self:Decrement()
        end
        local totalElapsed = GetTime() - self.startTime
        local nextUpdateDelta = Lerp(MAX_TIME_BETWEEN_CHANGES_SEC, MIN_TIME_BETWEEN_CHANGES_SEC, Saturate(totalElapsed / TIME_TO_REACH_MAX_SEC))
        self.nextUpdate = self.nextUpdate + nextUpdateDelta
      end
    end
  end,

  ["UIPanelDialogTemplate"] = function(frame)
    -- OVERLAY layer
    local tl = frame:CreateTexture(nil, "OVERLAY")
    tl:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    tl:SetSize(64, 64)
    tl:SetPoint("TOPLEFT")
    tl:SetTexCoord(0.501953125, 0.625, 0, 1)
    frame.TopLeft = tl

    local tr = frame:CreateTexture(nil, "OVERLAY")
    tr:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    tr:SetSize(64, 64)
    tr:SetPoint("TOPRIGHT")
    tr:SetTexCoord(0.625, 0.75, 0, 1)
    frame.TopRight = tr

    local t = frame:CreateTexture(nil, "OVERLAY")
    t:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    t:SetHeight(64)
    t:SetPoint("TOPLEFT", tl, "TOPRIGHT")
    t:SetPoint("TOPRIGHT", tr, "TOPLEFT")
    t:SetTexCoord(0.25, 0.369140625, 0, 1)
    frame.Top = t

    local bl = frame:CreateTexture(nil, "OVERLAY")
    bl:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    bl:SetSize(64, 64)
    bl:SetPoint("BOTTOMLEFT")
    bl:SetTexCoord(0.751953125, 0.875, 0, 1)
    frame.BottomLeft = bl

    local br = frame:CreateTexture(nil, "OVERLAY")
    br:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    br:SetSize(64, 64)
    br:SetPoint("BOTTOMRIGHT")
    br:SetTexCoord(0.875, 1, 0, 1)
    frame.BottomRight = br

    local b = frame:CreateTexture(nil, "OVERLAY")
    b:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    b:SetHeight(64)
    b:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT")
    b:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
    b:SetTexCoord(0.376953125, 0.498046875, 0, 1)
    frame.Bottom = b

    local l = frame:CreateTexture(nil, "OVERLAY")
    l:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    l:SetWidth(64)
    l:SetPoint("TOPLEFT", tl, "BOTTOMLEFT")
    l:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")
    l:SetTexCoord(0.001953125, 0.125, 0, 1)
    frame.Left = l

    local r = frame:CreateTexture(nil, "OVERLAY")
    r:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Border", AddonName))
    r:SetWidth(64)
    r:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT")
    r:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
    r:SetTexCoord(0.1171875, 0.2421875, 0, 1)
    frame.Right = r

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -8)
    title:SetPoint("TOPRIGHT", -32, -8)
    frame.Title = title

    -- BACKGROUND layer
    local titleBG = frame:CreateTexture(nil, "BACKGROUND")
    titleBG:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-GearManager-Title-Background", AddonName))
    titleBG:SetPoint("TOPLEFT", 8, -7)
    titleBG:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -8, -24)
    frame.TitleBG = titleBG

    local dialogBG = frame:CreateTexture(nil, "BACKGROUND")
    dialogBG:SetTexture(format("Interface\\AddOns\\%s\\media\\UI-Character-CharacterTab-L1", AddonName))
    dialogBG:SetPoint("TOPLEFT", 8, -24)
    dialogBG:SetPoint("BOTTOMRIGHT", -6, 8)
    dialogBG:SetTexCoord(0.255, 1, 0.29, 1)
    frame.DialogBG = dialogBG

    OmniCC.Templates["UIPanelCloseButton"](frame)
  end,
}

--[[
Interface\AddOns\<AddonName>\Media\Textures\redbutton2x
Interface\AddOns\<AddonName>\Media\Textures\CommonSearch
Interface\Common\Common-Input-Border
Interface\Buttons\UI-SpellbookIcon-NextPage-Up
Interface\Buttons\UI-SpellbookIcon-NextPage-Down
Interface\Buttons\UI-SpellbookIcon-NextPage-Disabled
Interface\Buttons\UI-SpellbookIcon-PrevPage-Up
Interface\Buttons\UI-SpellbookIcon-PrevPage-Down
Interface\Buttons\UI-SpellbookIcon-PrevPage-Disabled
Interface\Buttons\UI-Common-MouseHilight
Interface\PaperDollInfoFrame\UI-GearManager-Border
Interface\PaperDollInfoFrame\UI-GearManager-Title-Background
Interface\PaperDollInfoFrame\UI-Character-CharacterTab-L1
]]
