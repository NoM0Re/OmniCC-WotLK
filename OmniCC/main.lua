-- code to drive the addon
local AddonName, Addon = ...
local CONFIG_ADDON = AddonName .. '_Config'
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == AddonName then
        Addon:InitializeDB()
        Addon.Cooldown:SetupHooks()

        -- setup slash commands
        SLASH_OMNICC1 = '/omnicc'
        SLASH_OMNICC2 = '/occ'
        SlashCmdList["OMNICC"] = function(cmd)
            cmd = cmd and cmd:lower() or ""
            if cmd == 'version' then
                print(L.Version:format(Addon.db.global.addonVersion))
            elseif cmd == 'config' then
                Addon:ShowOptionsFrame()
            else
                Addon:ShowOptionsFrame()
            end
        end

        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_ENTERING_WORLD" then
        Addon:PLAYER_ENTERING_WORLD()
    end
end)

function Addon:PLAYER_ENTERING_WORLD()
    self.Timer:ForActive('Update')
end

-- utility methods
function Addon:ShowOptionsFrame()
    if LoadAddOn(CONFIG_ADDON) then
        local dialog = LibStub('AceConfigDialog-3.0')

        dialog:Open(AddonName)
        dialog:SelectGroup(AddonName, "themes", DEFAULT)

        return true
    end

    return false
end

function Addon:CreateHiddenFrame(...)
    local f = CreateFrame(...)

    f:Hide()

    return f
end

function Addon:GetButtonIcon(frame)
    if frame then
        local icon = frame.icon
        if type(icon) == 'table' and icon.GetTexture then
            return icon
        end

        local name = frame:GetName()
        if name then
            icon = _G[name .. 'Icon'] or _G[name .. 'IconTexture']

            if type(icon) == 'table' and icon.GetTexture then
                return icon
            end
        end
    end
end

-- exports
_G[AddonName] = Addon
