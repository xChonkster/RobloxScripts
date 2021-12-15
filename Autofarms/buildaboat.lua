local tween_service = game:GetService("TweenService")
local players_service = game:GetService("Players")
local run_service = game:GetService("RunService")

local frame_step = run_service.RenderStepped
local local_player = players_service.LocalPlayer

local start;

local function reset()
    local_player.Character.HumanoidRootPart.CFrame = CFrame.new(-50, 75, -175)
    
    start()
end

start = function()
    local connection = frame_step:Connect(function()
        local root = local_player.Character.HumanoidRootPart
        local v = root.Velocity
        
        root.Velocity = Vector3.new(v.X, 0.5, v.Z)
    end)
    
    local tween = tween_service:Create(
        local_player.Character.HumanoidRootPart,
        TweenInfo.new(
            30,
            Enum.EasingStyle.Linear
        ),
        {CFrame = CFrame.new(-50, 75, 9500)}
    )
        
    tween.Completed:Connect(function()
        connection:Disconnect() -- remove renderstepped loop, prevent lagg
        
        local wait_time;
        while (true) do
            frame_step:Wait()
            
            if not (local_player.Character:FindFirstChild("HumanoidRootPart")) then -- died
                wait_time = 10
                break;
            else
                if (local_player.Character.HumanoidRootPart.Velocity.Y < -100) then -- falling
                    wait_time = 20
                    break;
                end
            end
        end
        wait(wait_time)
        
        reset()
    end)
    
    tween:Play()
end

reset()
