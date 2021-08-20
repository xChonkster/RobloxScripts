local Hooks = {} -- < stored hooks > --

local Hooking = {}
function Hooking:AddHook(TBL)
    Hooks[#Hooks + 1] = TBL
end
function Hooking:RemoveHook(TBL)
    for HookIndex, HookValue in pairs(Hooks) do
        if TBL == HookValue then
            table.remove(Hooks, HookIndex)
        end
    end
end

local AvailableHooks = { -- < table for adding and storing hooks > --
    {
        Name = "LockProperty",
        Function = function(Instance, ...)
            local Args, Property = {...}, ({...})[1]
            local Value = Instance[Property] -- < check if property exists, will automatically error if not > --

            local TBL = {
                ["HookType"] = "LockProperty",
                ["Instance"] = Instance,
                ["Property"] = Property,
                ["Args"] = Args
            }

            Hooking:AddHook(TBL)
            return function()
                Hooking:RemoveHook(TBL)
            end
        end
    },
    {
        Name = "AddPropertyGetHook",
        Function = function(Instance, ...)
            local Args, Property, Function = {...}, ({...})[1], ({...})[2]
            local Value = Instance[Property] -- < check if property exists, will automatically error if not > --

            if not Function or type(Function) ~= "function" then error("Function to be called is missing") end

            local TBL = {
                ["HookType"] = "AddPropertyGetHook",
                ["Instance"] = Instance,
                ["Property"] = Property,
                ["Function"] = Function,
                ["Args"] = Args
            }

            Hooking:AddHook(TBL)
            return function()
                Hooking:RemoveHook(TBL)
            end
        end
    },
    {
        Name = "AddPropertySetHook",
        Function = function(Instance, ...)
            local Args, Property, Function = {...}, ({...})[1], ({...})[2]
            local Value = Instance[Property] -- < check if property exists, will automatically error if not > --

            if not Function or type(Function) ~= "function" then error("Function to be called is missing") end

            local TBL = {
                ["HookType"] = "AddPropertySetHook",
                ["Instance"] = Instance,
                ["Property"] = Property,
                ["Function"] = Function,
                ["Args"] = Args
            }

            Hooking:AddHook(TBL)
            return function()
                Hooking:RemoveHook(TBL)
            end
        end
    },
    {
        Name = "AddPropertySpoofer",
        Function = function(Instance, ...)
            local Args, Property, SpoofedValue = {...}, ({...})[1], ({...})[2]
            local Value = Instance[Property] -- < check if property exists, will automatically error if not > --

            if not SpoofedValue then SpoofedValue = Value warn("Property for spoofing missing, Set property to current value") end

            local TBL = {
                ["HookType"] = "AddPropertySpoofer",
                ["Instance"] = Instance,
                ["Property"] = Property,
                ["VisibleValue"] = Value,
                ["InvisibleValue"] = SpoofedValue,
                ["Args"] = Args
            }

            Hooking:AddHook(TBL)
            return function()
                Hooking:RemoveHook(TBL)
            end
        end
    }
}

local writeable = make_writeable or setreadonly
local readonly = make_readonly or setreadonly

local gameMT = getrawmetatable(game)
writeable(gameMT, false)

local old_namecall;
old_namecall = hookmetamethod(game, "__namecall", function(Instance, ...) -- < used for monitoring hooks being added > --
    if checkcaller() then
        local Method, Args = getnamecallmethod(), {...}
        for HookIndex, HookValue in pairs(AvailableHooks) do
            if Method == HookValue.Name then
                local Removable = HookValue.Function(Instance, ...)
                return {remove = Removable, Remove = Removable};
            end
        end
    end
    return old_namecall(Instance, ...)
end)

local old_index;
old_index = hookmetamethod(game, "__index", function(Instance, Property, ...) -- < used for monitoring hooks being added > --
    for HookIndex, HookValue in pairs(Hooks) do
        if Property == HookValue.Property and Instance == HookValue.Instance then
            if HookValue.HookType == "AddPropertyGetHook" then
                pcall(HookValue.Function, Instance)
            end
            if HookValue.HookType == "AddPropertySpoofer" then
                return HookValue.VisibleValue
            end
        end
    end
    return old_index(Instance, Property, ...)
end)

local old_newindex;
old_newindex = hookmetamethod(game, "__newindex", function(Instance, Property, Value, ...) -- < used for monitoring hooks being added > --
    for HookIndex, HookValue in pairs(Hooks) do
        if Property == HookValue.Property and Instance == HookValue.Instance then
            if HookValue.HookType == "LockProperty" then
                Value = HookValue.Instance[HookValue.Property]
            end
            if HookValue.HookType == "AddPropertySetHook" then
                pcall(HookValue.Function, Instance)
            end
            if HookValue.HookType == "AddPropertySpoofer" then
                HookValue.VisibleValue = Value
                Value = HookValue.InvisibleValue
            end
        end
    end
    return old_newindex(Instance, Property, Value, ...)
end)

readonly(gameMT, true)
