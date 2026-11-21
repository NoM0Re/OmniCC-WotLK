-- hooks for watching cooldown events
local _, Addon = ...

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- how far in the future a cooldown can be before we show text for it
-- this is used to filter out buggy cooldowns (usually ones that started)
-- before a user rebooted
local MIN_START_OFFSET = -86400

-- the global cooldown spell id
local GCD_SPELL_ID = 61304

-- how long after a cooldown ends its finish effect can play (in milliseconds)
local FINISH_EFFECT_BUFFER = 300

-------------------------------------------------------------------------------
-- Utility Methods
-------------------------------------------------------------------------------

-- gcd tests
---@param start number
---@param duration number
---@return boolean
local function IsGCD(start, duration)
    if not (start > 0 and duration > 0) then
        return false
    end

    local gcdStart, gcdDuration, gcdEnabled = GetSpellCooldown(GCD_SPELL_ID)

    return gcdEnabled == 1
        and start == gcdStart
        and duration == gcdDuration
end

---Retrieves the name of the given region. If no name is found, checks ancestors
---@param frame Region
---@return string?
local function getFirstName(frame)
    while frame do
        local name = frame:GetName()

        if name then
            return name
        end

        frame = frame:GetParent()
    end
end

-------------------------------------------------------------------------------
-- Cooldown Tracking
-------------------------------------------------------------------------------

local Cooldown = {}

---@type { [OmniCCCooldown]: true }
local cooldowns = {}

---@param self OmniCCCooldown
---@return boolean
function Cooldown:CanShowText()
    if self.noCooldownCount or self._occ_gcd then
        return false
    end

    local duration = self._occ_duration or 0
    if duration <= 0 then
        return false
    end

    local start = self._occ_start or 0
    if start <= 0 then
        return false
    end

    local elapsed = GetTime() - start
    if elapsed >= duration or elapsed <= MIN_START_OFFSET then
        return false
    end

    -- config checks
    local settings = self._occ_settings

    -- text enabled
    if not (settings and settings.enableText) then
        return false
    end

    -- at least min duration
    if duration < (settings.minDuration or math.huge) then
        return false
    end

    -- at most max duration
    local maxDuration = settings.maxDuration or 0
    if maxDuration > 0 and duration > maxDuration then
        return false
    end

    return true
end

---@param self OmniCCCooldown
---@param ignoreRemainingTime boolean? Check eligibility before scheduling an effect.
---@param gcdEnd number? End of the global cooldown replacing this cooldown.
function Cooldown:CanShowFinishEffect(ignoreRemainingTime, gcdEnd)
    if self.noCooldownCount or self._occ_gcd or self._occ_finishPlayed then
        return false
    end

    local start, duration = self._occ_start or 0, self._occ_duration or 0
    if start <= 0 or duration <= 0 then
        return false
    end

    local settings = self._occ_settings
    if not settings or duration < (settings.minEffectDuration or math.huge) then
        return false
    end

    local effect = settings.effect or 'none'
    if effect == 'none' then
        return false
    end

    if not ignoreRemainingTime then
        local now = GetTime()
        local endTime = start + duration
        local millisecondsLate = math.floor((now - endTime) * 1000 + 0.5)
        local millisecondsEarly = math.floor((endTime - math.max(now, gcdEnd or now)) * 1000 + 0.5)
        if millisecondsLate > FINISH_EFFECT_BUFFER or millisecondsEarly > 0 then
            return false
        end
    end

    return true, effect
end

---@param self OmniCCCooldown
function Cooldown:CancelFinishTimer()
    local timer = self._occ_finishTimer
    if timer then
        self._occ_finishTimer = nil
        timer:Cancel()
    end
end

---@param self OmniCCCooldown
function Cooldown:UpdateFinishTimer()
    local start = self._occ_start or 0
    local endTime = start + (self._occ_duration or 0)
    local now = GetTime()
    if now - start <= MIN_START_OFFSET or not Cooldown.CanShowFinishEffect(self, true) then
        Cooldown.CancelFinishTimer(self)
        return
    end

    if self._occ_finishTimer or endTime <= now then
        return
    end

    self._occ_finishTimer = Addon.C_Timer.NewTimer(endTime - now, function(timer)
        if self._occ_finishTimer ~= timer then
            return
        end

        self._occ_finishTimer = nil
        if GetTime() < endTime then
            Cooldown.UpdateFinishTimer(self)
        else
            Cooldown.OnCooldownDone(self)
        end
    end)
end

---@param self OmniCCCooldown
---@return OmniCCCooldownKind
function Cooldown:GetKind()
    return 'default'
end

---@param self OmniCCCooldown
---@return OmniCCCooldownPriority
function Cooldown:GetPriority()
    if self._occ_kind == 'charge' then
        return 2
    end

    return 1
end

---@param self OmniCCCooldown
function Cooldown:Initialize()
    -- one time initialization
    if not cooldowns[self] then
        self._occ_settings = Cooldown.GetTheme(self)

        self:HookScript('OnShow', Cooldown.OnVisibilityUpdated)
        self:HookScript('OnHide', Cooldown.OnVisibilityUpdated)

        cooldowns[self] = true
    end
end

---@param self OmniCCCooldown
function Cooldown:ShowText()
    local oldDisplay = self._occ_display
    ---@type OmniCCDisplay?
    local newDisplay = Addon.Display:GetOrCreate(self:GetParent() or self)

    if oldDisplay ~= newDisplay then
        self._occ_display = newDisplay

        if oldDisplay then
            oldDisplay:RemoveCooldown(self)
        end
    end

    if newDisplay then
        newDisplay:AddCooldown(self)
    end
end

---@param self OmniCCCooldown
function Cooldown:HideText()
    local display = self._occ_display

    if display then
        self._occ_display = nil

        if display.RemoveCooldown then
            display:RemoveCooldown(self)
        end
    end
end

---@param self OmniCCCooldown
function Cooldown:UpdateText()
    if self:IsVisible() and Cooldown.CanShowText(self) then
        Cooldown.ShowText(self)
    else
        Cooldown.HideText(self)
    end
end

---@param self OmniCCCooldown
function Cooldown:UpdateStyle()
    local settings = self._occ_settings
    if not settings then
        return
    end

    local opacity = settings.cooldownOpacity or 1
    if opacity < 1 then
        if self:GetAlpha() ~= opacity then
            self:SetAlpha(opacity)
        end
    end
end

do
    local pending = {}

    local updater = Addon:CreateHiddenFrame('Frame')

    updater:SetScript('OnUpdate', function(self)
        for cooldown in pairs(pending) do
            Cooldown.UpdateText(cooldown)
            Cooldown.UpdateStyle(cooldown)
            pending[cooldown] = nil
        end

        self:Hide()
    end)

    function Cooldown:RequestUpdate()
        if not pending[self] then
            pending[self] = true
            updater:Show()
        end
    end
end

---@param self OmniCCCooldown
function Cooldown:Refresh()
    Cooldown.Initialize(self)
    Cooldown.UpdateFinishTimer(self)
    Cooldown.RequestUpdate(self)
end

---@param self OmniCCCooldown
---@param start number
---@param duration number
function Cooldown:SetTimer(start, duration)
    -- both the wow api and addons (especially auras) have a habit of resetting
    -- cooldowns every time there's an update to an aura
    -- we check and do nothing if there is an exact start/duration match
    if self._occ_start == start and self._occ_duration == duration then
        return
    end

    -- A GCD can replace a cooldown just before its scheduled effect.
    local isGCD = IsGCD(start, duration)
    local gcdEnd = isGCD and start <= GetTime() and start + duration or nil
    Cooldown.CancelFinishTimer(self)
    Cooldown.TryShowFinishEffect(self, gcdEnd)

    self._occ_start = start
    self._occ_duration = duration
    self._occ_finishPlayed = nil

    self._occ_gcd = isGCD
    self._occ_kind = Cooldown.GetKind(self)
    self._occ_priority = Cooldown.GetPriority(self)

    Cooldown.Refresh(self)
end

---@param self OmniCCCooldown
---@param disable boolean?
---@param owner Frame|boolean|nil
function Cooldown:SetNoCooldownCount(disable, owner)
    owner = owner or true

    if disable then
        if not self.noCooldownCount then
            self.noCooldownCount = owner
            Cooldown.Refresh(self)
        end
    elseif self.noCooldownCount == owner then
        self.noCooldownCount = nil
        Cooldown.Refresh(self)
    end
end

---@param self OmniCCCooldown
---@param gcdEnd number?
function Cooldown:TryShowFinishEffect(gcdEnd)
    local show, effect = Cooldown.CanShowFinishEffect(self, false, gcdEnd)
    if show and self:IsVisible() then
        self._occ_finishPlayed = true
        Addon.FX:Run(self, effect)
    end
end

---@param self OmniCCCooldown
function Cooldown:OnCooldownDone()
    if self.noCooldownCount then
        return
    end

    Cooldown.TryShowFinishEffect(self)
end

---@param self OmniCCCooldown
---@param start number
---@param duration number
function Cooldown:OnSetCooldown(start, duration)
    if self.noCooldownCount and not cooldowns[self] then
        return
    end

    Cooldown.SetTimer(self, start, duration)
end

---@param self OmniCCCooldown
function Cooldown:SetDisplayAsPercentage()
    if self.noCooldownCount then
        return
    end

    Cooldown.SetNoCooldownCount(self, true)
end

---@param self OmniCCCooldown
function Cooldown:OnVisibilityUpdated()
    if self.noCooldownCount then
        return
    end

    Cooldown.RequestUpdate(self)
end

---@param self OmniCCCooldown
function Cooldown:OnClear()
    if self._occ_start ~= nil then
        Cooldown.CancelFinishTimer(self)
        self._occ_start = nil
        self._occ_duration = nil
        self._occ_finishPlayed = nil

        Cooldown.HideText(self)
    end
end

---@param self OmniCCCooldown
function Cooldown:UpdateSettings(force)
    local newSettings = Cooldown.GetTheme(self)

    if force or self._occ_settings ~= newSettings then
        self._occ_settings = newSettings
        Cooldown.Refresh(self)
        return true
    end

    return false
end

---@param self OmniCCCooldown
---@return OmniCCCooldownSettings
function Cooldown:GetTheme()
    if self._occ_settings_force then
        return self._occ_settings_force
    end

    local name = getFirstName(self)

    if name then
        local rule = Addon:GetMatchingRule(name)
        if rule and Addon:HasTheme(rule.theme) then
            return Addon:GetTheme(rule.theme)
        end
    end

    return Addon:GetDefaultTheme()
end

-- misc
function Cooldown.SetupHooks()
    hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, 'SetCooldown', Cooldown.OnSetCooldown)
end

---@param method string
function Cooldown:ForAll(method, ...)
    local func = self[method]
    if type(func) ~= 'function' then
        error(('Cooldown method %q not found'):format(method), 2)
    end

    for cooldown in pairs(cooldowns) do
        func(cooldown, ...)
    end
end

-- exports
Addon.Cooldown = Cooldown
