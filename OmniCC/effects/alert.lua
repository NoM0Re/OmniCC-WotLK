-- a finish effect that displays the cooldown at the center of the screen
local AddonName, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AlertFrame = CreateFrame("Frame", nil, UIParent)
AlertFrame:SetPoint("CENTER")
AlertFrame:SetSize(50, 50)
AlertFrame:SetAlpha(0)
AlertFrame:Hide()

local icon = AlertFrame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(AlertFrame)
AlertFrame.icon = icon

local animationGroup = AlertFrame:CreateAnimationGroup()
animationGroup:SetLooping("NONE")
animationGroup:SetScript("OnFinished", function() AlertFrame:Hide() end)
AlertFrame.animationGroup = animationGroup

local function newAnim(type, order, dur, change)
    local anim = AlertFrame.animationGroup:CreateAnimation(type)
    anim:SetOrder(order)
    anim:SetDuration(dur or 0)

    if type == "Scale" then
        anim:SetOrigin("CENTER", 0, 0)
        anim:SetScale(change, change)
    elseif type == "Alpha" then
        anim:SetChange(change)
    end
    return anim
end

newAnim("Scale", 1, 0.3 , 2.5)
newAnim("Alpha", 1, 0,     -1) -- transparent
newAnim("Alpha", 1, 0.3,  0.7) -- 70% opaque

newAnim("Scale", 2, 0.3,    0)
newAnim("Alpha", 2, 0.3, -0.7) -- transparent

local AlertEffect = Addon.FX:Create("alert", L.Alert, L.AlertTip)

function AlertEffect:Run(cooldown)
	local buttonIcon = Addon:GetButtonIcon(cooldown:GetParent())
	if not buttonIcon then
		return
	end

	AlertFrame:Show()

	local alertIcon = AlertFrame.icon
	alertIcon:SetVertexColor(buttonIcon:GetVertexColor())
	alertIcon:SetTexture(buttonIcon:GetTexture())

	local alertAnimation = AlertFrame.animationGroup
	if alertAnimation:IsPlaying() then
		alertAnimation:Finish()
	end

	alertAnimation:Play()
end
