local gameMT = getrawmetatable(game)
local psuedoEnv = {
    __index = gameMT.__index,
    __newindex = gameMT.__newindex;
}

local SpoofInstances = {
    {
        ParentInstance = game:GetService("Workspace"),
        ChildInstance = "Camera",
        Method = game.FindFirstChildOfClass,
        Property = "FieldOfView",
        InvisibleValue = 120,
        VisibleValue = 70;
    },
    {
        ParentInstance = game:GetService("Players").LocalPlayer.Character,
        ChildInstance = "Humanoid",
        Method = game.FindFirstChild,
        Property = "WalkSpeed",
        InvisibleValue = 35,
        VisibleValue = 16;
    },
    {
        ParentInstance = game:GetService("Players").LocalPlayer.Character,
        ChildInstance = "Humanoid",
        Method = game.FindFirstChild,
        Property = "JumpPower",
        InvisibleValue = 50,
        VisibleValue = 25;
    };
}

setreadonly(gameMT, false)
gameMT.__index = newcclosure(function(self, index, ...)
    for InstanceIndex, InstanceValue in pairs(SpoofInstances) do
        if InstanceValue.ParentInstance then
            if self == InstanceValue.Method(InstanceValue.ParentInstance, InstanceValue.ChildInstance) and index == InstanceValue.Property then
                return InstanceValue.VisibleValue
            end
        end
    end
    return psuedoEnv.__index(self, index, ...)
end)
gameMT.__newindex = newcclosure(function(self, index, value, ...)
    for InstanceIndex, InstanceValue in pairs(SpoofInstances) do
        if InstanceValue.ParentInstance then
            if self == InstanceValue.Method(InstanceValue.ParentInstance, InstanceValue.ChildInstance) and index == InstanceValue.Property then
                InstanceValue.VisibleValue = value
                value = InstanceValue.InvisibleValue
            end
        end
    end
    return psuedoEnv.__newindex(self, index, value, ...)
end)
setreadonly(gameMT, true)
