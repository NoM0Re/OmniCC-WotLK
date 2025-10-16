-- Simple NextFrame scheduler (list-based)
local _, Addon = ...

local Updater = Addon:CreateHiddenFrame("Frame")
local tasks = {}

Updater:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()

    for i = #tasks, 1, -1 do
        local t = tasks[i]
        if now >= t.next then
            t.func()
            table.remove(tasks, i)
        end
    end

    if #tasks == 0 then
        self:Hide()
    end
end)

function Updater:RunNextFrame(func)
    if type(func) ~= "function" then return end
    table.insert(tasks, { func = func, next = GetTime() + 0.01 })
    self:Show()
end

function Updater:ScheduleTimer(func, delay)
    if type(func) ~= "function" then return end
    table.insert(tasks, { func = func, next = GetTime() + (delay or 0.01) })
    self:Show()
end

-- exports
Addon.Updater = Updater