local mt = getrawmetatable(game)
local OldIndex = mt.__namecall
local LocalPlayer = game:GetService("Players").LocalPlayer

local ReturnFunc = function()end

setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, Index, ...)
    if self == LocalPlayer then
        local NameCallMethod = getnamecallmethod()
        if string.find(NameCallMethod, "Kick") or string.find(NameCallMethod, "kick") then
            print("Prevented Kick At " .. tostring(os.time()))
            wait(9e999)
            return
        end
    end
    return OldIndex(self, Index, ...)
end)

local hook
hook = hookfunction(game:GetService("Players").LocalPlayer.Kick, function(reason)
    print("Prevented Kick At " .. tostring(os.time()))
    wait(9e999)
    return
end)
setreadonly(mt, true)
