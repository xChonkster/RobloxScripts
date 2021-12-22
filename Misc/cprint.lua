local core_gui = game:GetService("CoreGui")

local function run()
    local dev_console = core_gui.DevConsoleMaster.DevConsoleWindow.DevConsoleUI

    local success, result = pcall(function() return dev_console.MainView.ClientLog; end)

    local container = (success and result) or nil; -- fuck you infinite yield
    
    local scheduled = {}
    local cached = {}

    dev_console.DescendantAdded:Connect(function(added)
        if added.Name == "ClientLog" then
            container = added

            for _, val in pairs(scheduled) do
                cprint(unpack(val))
            end
        end

        if container and added:IsDescendantOf(container) and tonumber(added.Name) ~= nil and cached[added.Name] then
            added.msg.TextColor3 = cached[added.Name]
        end
    end)

    dev_console.DescendantRemoving:Connect(function(removing)
        if container and removing:IsDescendantOf(container) and tonumber(removing.Name) ~= nil then
            cached[removing.Name] = removing.msg.TextColor3
        end
    end)

    getgenv().cprint = function(...)
        if not container then
            scheduled[#scheduled + 1] = {...}

            return;
        end

        local to_be_added = 1

        for _, val in pairs(container:GetChildren()) do
            local n = tonumber(val.Name)

            if n and n > to_be_added and n < 501 then
                to_be_added = n
            end
        end

        local args = {...}
        local color = args[#args]
        
        table.remove(args, #args)
        print(unpack(args))

        container:WaitForChild(tostring(to_be_added + 1)).msg.TextColor3 = color
    end
end

if not core_gui:FindFirstChild("DevConsoleMaster") then
    local connection = nil;
    connection = core_gui.DescendantAdded:Connect(function(added)
        if added.Name == "DevConsoleUI" then
            task.spawn(run)

            connection:Disconnect()
        end
    end)
else
    run()
end
