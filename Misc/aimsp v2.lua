local drawing_new = Drawing.new
local vector2_new = Vector2.new
local vector3_new = Vector3.new
local cframe_new = CFrame.new
local cframe_angles = CFrame.Angles
local color3_new = Color3.new
local color3_hsv = Color3.fromHSV
local math_floor = math.floor
local math_ceil = math.ceil
local math_atan2 = math.atan2
local math_rad = math.rad
local math_random = math.random
local math_randomseed = math.randomseed
local table_sort = table.sort
local instance_new = Instance.new
local raycast_params_new = RaycastParams.new
local enum_rft_blk = Enum.RaycastFilterType.Blacklist
local glass = Enum.Material.Glass

--[[
    todo

    add randomness to mouse movement (more human-like movements)
]]

--<- settings ->--

local _aimsp_settings; _aimsp_settings = {

    -- aimbot settings
    rage_mode = {
        use = false,
        --[[
            will completely disregard fov or smoothness setting
            will lock onto enemies behind player
            will always aim for heads headshots
            
            works best with closest_to_you and use_backwards_iteration.table_index set to false
        ]]

        flip_cframe = false, -- detectable, works alot better
        flip_mouse = true, -- not detectable, wanky
    },

    wall_check_method = {
        raycast = false, -- uses RaycastResult:IsDescendantOf()
        camera = true, -- uses GetPartsObscuringTarget (better)
    }, -- either of these must be true

    headshot_odds = {
        use_odds = false, -- if this is false, it will not try to calculate odds thus always hitting headshots

        func = function() -- if use_odds is false, this function won't be called
            local chance = 75 -- chance to aim on the head out of 100
            -- 0 = no head (lol), however if the torso is not visible it will still aim for the head

            math_randomseed(tick())
            return math_random(1, 100) <= chance
        end
    },

    use_backwards_iteration = {
        use = true,
        --[[
            this feature fixes the scenario where the closest player is behind a wall, and the player you want to shoot is not causing the aimbot to not lock on

            do note that this feature is only useful in very few scenarios, so you should be fine just leaving this off

            *can* be replaced by setting use_wallcheck to false, although not ideal
        ]]

        table_index = true; -- less lagg, less reliable
    },

    ignore_parts = true,
    --[[
        this will try to ignore things such as invisble walls or glass

        usually doesnt lagg
    ]]

    use_aimbot = true,
    use_wallcheck = true, -- checks for walls
    team_check = true, -- turn off for ffa games
    loop_all_humanoids = false, -- laggy, if toggled in-game you have to rejoin
    max_dist = 9e9, -- 9e9 = very big
    toggle = {
        r_mouse_button = true, -- makes you have to hold right mouse button, keybind will no longer work
        key = Enum.KeyCode.Z; -- acts as toggle
    },
    prefer = {
        looking_at_you = false, -- will prefer whoever is looking at you "the most", threat judging
        closest_to_center_screen = true, -- ideal
        closest_to_you = false, -- will sometimes not work, backwards iteration will make this alot more consistent
    },
    toggle_hud_key = Enum.KeyCode.P, -- toggle drawing
    smoothness = 4, -- anything over 5 = aim assist,  1 = lock on (using 1 might get u banned)
    fov_size = 250; -- <450 = safezone

    -- esp settings
    use_esp = true,
    esp_toggle_key = Enum.KeyCode.L,
    esp_thickness = 2, -- thickness in pixels
    rainbow_speed = 5,
    use_rainbow = false, -- rgb mode
    crosshair = {
        use = false,

        distance = 4,
        thickness = 1,
        length = 8;
    },
    tracers = true,
    looking_at_tracers = {
        use = true,

        --https://www.google.com/search?q=color+picker
        color = color3_new(200, 0, 255), -- color in rgb
        thickness = 2,
        length = 5; -- how far the tracer will go
    }, -- will show where a player is looking
    box = true,
    name = true,
    dist = true, -- distance
    health = true; -- might not work on some games
}

--<- settings ->--

local white = color3_new(255, 255, 255)
local green = color3_new(0, 255, 0)

local pi = math.pi

local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local rep_storage = game:GetService("ReplicatedStorage")

local frame_wait = run_service.RenderStepped

local local_player = players.LocalPlayer
local mouse = local_player:GetMouse()
local dummy_part = instance_new("Part", nil)

local reverse_camera = instance_new("Camera")

local camera = workspace:FindFirstChildOfClass("Camera")
local screen_size = camera.ViewportSize
local center_screen = vector2_new((screen_size.X / 2), (screen_size.Y / 2))

if getgenv().aimsp_settings then 
    getgenv().aimsp_settings = _aimsp_settings; 
    return 
end
getgenv().aimsp_settings = _aimsp_settings

local objects; objects = {
    fov = nil,
    text = nil,
    tracers = {},
    looking_at_tracers = {},
    quads = {},
    labels = {},
    crosshair = {
        top = nil,
        bottom = nil,
        right = nil,
        left = nil,
    },
    look_at = {
        tracer = nil,
        point = nil;
    };
}

local debounces; debounces = {
    start_aim = false,
    custom_players = true,
    spoofs_hum_health = false;
}

local ignored_instances = {}

local utility; utility = {
    get_rainbow = function()
        return color3_hsv((tick() % aimsp_settings.rainbow_speed / aimsp_settings.rainbow_speed), 1, 1)
    end,

    get_part_corners = function(part)
        local size = part.Size * vector3_new(1, 1.5, 0)

        return {
            top_right = (part.CFrame * cframe_new(-size.X, -size.Y, 0)).Position,
            bottom_right = (part.CFrame * cframe_new(-size.X, size.Y, 0)).Position,
            top_left = (part.CFrame * cframe_new(size.X, -size.Y, 0)).Position,
            bottom_left = (part.CFrame * cframe_new(size.X, size.Y, 0)).Position,
        }
    end,

    run_player_check = function()
        local plrs = players:GetChildren()

        for idx, val in pairs(objects.tracers) do
            if not plrs[idx] then
                utility.remove_esp(idx)
            end
        end
    end,

    remove_esp = function(name)
        utility.update_drawing(objects.tracers, name, {
            Visible = false,
            instance = "Line";
        })

        utility.update_drawing(objects.looking_at_tracers, name, {
            Visible = false,
            instance = "Line";
        })

        utility.update_drawing(objects.quads, name, {
            Visible = false,
            instance = "Quad";
        })

        utility.update_drawing(objects.labels, name, {
            Visible = false,
            instance = "Text";
        })
    end,

    update = function(str)
        if objects.fov.Visible then
            objects.text.Text = str
            objects.text.Visible = true

            wait(1)

            objects.text.Visible = false
        end
    end,

    is_inside_fov = function(point)
        if aimsp_settings.rage_mode.use then
            return true
        end

        return (point.x - objects.fov.Position.X) ^ 2 + (point.y - objects.fov.Position.Y) ^ 2 <= objects.fov.Radius ^ 2
    end,
    
    to_screen = function(point)
        local screen_pos, in_screen = camera:WorldToViewportPoint(point)

        if aimsp_settings.rage_mode.use then
            return vector2_new(screen_pos.X, screen_pos.Y), screen_pos, in_screen, true
        end

        return vector2_new(screen_pos.X, screen_pos.Y), screen_pos, in_screen
    end,

    is_part_visible = function(origin_part, part)
        if not aimsp_settings.use_wallcheck then
            return true
        end

        if aimsp_settings.wall_check_method.raycast then
            local ignore_list = {camera, local_player.Character, origin_part.Parent}
            if aimsp_settings.ignore_parts then
                for idx, val in pairs(ignored_instances) do
                    ignore_list[#ignore_list + 1] = val
                end
            end

            local raycast_params = raycast_params_new()
            raycast_params.FilterType = enum_rft_blk
            raycast_params.FilterDescendantsInstances = ignore_list
            raycast_params.IgnoreWater = true
            
            local raycast_result = workspace:Raycast(origin_part.Position, (part.Position - origin_part.Position).Unit * aimsp_settings.max_dist, raycast_params)
    
            local result_part = ((raycast_result and raycast_result.Instance) or dummy_part)

            if result_part ~= dummy_part then
                if result_part.Transparency >= 0.3 then -- ignore low transparency
                    ignored_instances[#ignored_instances + 1] = result_part
                end

                if result_part.Material == glass then -- ignore glass
                    ignored_instances[#ignored_instances + 1] = result_part
                end
            end

            return result_part:IsDescendantOf(part.Parent)
        end

        if aimsp_settings.wall_check_method.camera then
            local ignore_list = {camera, local_player.Character, origin_part.Parent}
            if aimsp_settings.ignore_parts then
                for idx, val in pairs(ignored_instances) do
                    ignore_list[#ignore_list + 1] = val
                end
            end

            local parts = camera:GetPartsObscuringTarget(
                {
                    origin_part.Position, 
                    part.Position
                },
                ignore_list
            )

            for idx, val in pairs(parts) do
                if val.Transparency >= 0.3 then -- ignore low transparency
                    ignored_instances[#ignored_instances + 1] = val
                end

                if val.Material == glass then -- ignore glass
                    ignored_instances[#ignored_instances + 1] = val
                end
            end

            return #parts == 0
        end

        return false
    end,
    
    is_dead = function(char)
        if debounces.spoofs_hum_health then
            local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            if torso and #(torso:GetChildren()) < 10 then
                return true
            end
        else
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health == 0 then
                return true
            end
        end

        return false
    end,

    update_drawing = function(tbl, child, val)
        if not tbl[child] then
            tbl[child] = utility.new_drawing(val.instance)(val)
        end
        
        for idx, val in pairs(val) do
            if idx ~= "instance" then
                tbl[child][idx] = val
            end
        end
        
        return tbl[child]
    end,
    
    new_drawing = function(classname)
        return function(tbl)
            local draw = drawing_new(classname)
            
            for idx, val in pairs(tbl) do
                if idx ~= "instance" then
                    draw[idx] = val
                end
            end
            
            return draw
        end
    end
}

objects.text = utility.new_drawing("Text"){
    Transparency = aimsp_settings.esp_thickness,
    Visible = false,
    Center = true,
    Size = 24,
    Color = white,
    Position = vector2_new(screen_size.X - 100, 36);
}

objects.fov = utility.new_drawing("Circle"){
    Thickness = aimsp_settings.esp_thickness,
    Transparency = 1,
    Visible = true,
    Color = white,
    Position = center_screen,
    NumSides = 64,
    Radius = aimsp_settings.fov_size;
}

objects.crosshair.top = utility.new_drawing("Line"){
    Visible = aimsp_settings.crosshair.use,
    Thickness = aimsp_settings.crosshair.thickness,
    Transparency = 1,
    Color = white,
    From = vector2_new(center_screen.X, center_screen.Y - aimsp_settings.crosshair.length - aimsp_settings.crosshair.distance),
    To = vector2_new(center_screen.X, center_screen.Y - aimsp_settings.crosshair.distance);
}

objects.crosshair.bottom = utility.new_drawing("Line"){
    Visible = aimsp_settings.crosshair.use,
    Thickness = aimsp_settings.crosshair.thickness,
    Transparency = 1,
    Color = white,
    From = vector2_new(center_screen.X, center_screen.Y + aimsp_settings.crosshair.length + aimsp_settings.crosshair.distance + 1),
    To = vector2_new(center_screen.X, center_screen.Y + aimsp_settings.crosshair.distance + 1);
}

objects.crosshair.left = utility.new_drawing("Line"){
    Visible = aimsp_settings.crosshair.use,
    Thickness = aimsp_settings.crosshair.thickness,
    Transparency = 1,
    Color = white,
    From = vector2_new(center_screen.X - aimsp_settings.crosshair.length - aimsp_settings.crosshair.distance, center_screen.Y),
    To = vector2_new(center_screen.X - aimsp_settings.crosshair.distance, center_screen.Y);
}

objects.crosshair.right = utility.new_drawing("Line"){
    Visible = aimsp_settings.crosshair.use,
    Thickness = aimsp_settings.crosshair.thickness,
    Transparency = 1,
    Color = white,
    From = vector2_new(center_screen.X + aimsp_settings.crosshair.length + aimsp_settings.crosshair.distance + 1, center_screen.Y),
    To = vector2_new(center_screen.X + aimsp_settings.crosshair.distance + 1, center_screen.Y);
}

players.PlayerRemoving:Connect(function(plr)
    utility.remove_esp(plr.Name)
end)

uis.InputBegan:Connect(function(key, gmp)
    if gmp then return end

    if key.KeyCode == aimsp_settings.toggle.key and not aimsp_settings.toggle.r_mouse_button then
        debounces.start_aim = not debounces.start_aim
        
        utility.update("toggled aimbot: " .. tostring(debounces.start_aim))
    elseif key.KeyCode == aimsp_settings.toggle_hud_key then
        objects.fov.Visible = not objects.fov.Visible
    elseif key.KeyCode == aimsp_settings.esp_toggle_key then
        aimsp_settings.use_esp = not aimsp_settings.use_esp

        utility.update("toggled esp: " .. tostring(aimsp_settings.use_esp))
    end
end)

mouse.Button2Down:Connect(function()
    if aimsp_settings.toggle.r_mouse_button then
        debounces.start_aim = true
    end
end)

mouse.Button2Up:Connect(function()
    if aimsp_settings.toggle.r_mouse_button then
        debounces.start_aim = false
    end
end)

local get_players; -- create custom function for every game so that it doesnt check placeid every frame

local humanoid_holders = {}
if aimsp_settings.loop_all_humanoids then -- self explanitory
    for idx, val in pairs(workspace:GetDescendants()) do
        if val:IsA("Model") and val:FindFirstChildOfClass("Humanoid") then
            humanoid_holders[val.Parent:GetDebugId()] = val.Parent -- prevent setting dupes with GetDebugId
        end
    end

    get_players = function()
        local instance_table = {}

        for _, parent in pairs(humanoid_holders) do
            for _, val in pairs(parent:GetChildren()) do
                if val:IsA("Model") and val:FindFirstChildOfClass("Humanoid") then
                    instance_table[#instance_table + 1] = val
                end
            end
        end

        return instance_table
    end
elseif game.PlaceId == 18164449 then -- base wars
    debounces.spoofs_hum_health = true
elseif game.PlaceId == 292439477 then -- phantom forces
    get_players = function()
        local leaderboard = local_player.PlayerGui.Leaderboard.Main -- ik you're looking pf devs ;)

        if leaderboard then
            if aimsp_settings.team_check then
                local is_ghost = pcall(function()
                    return leaderboard.Ghosts.DataFrame.Data[local_player.Name]
                end)

                return workspace.Players[(is_ghost and "Phantoms") or "Ghosts"]:GetChildren()
            else
                local instance_table = {}

                for idx, val in pairs(workspace.Players.Phantoms:GetChildren()) do
                    if val:IsA("Model") then
                        instance_table[#instance_table + 1] = val
                    end
                end

                for idx, val in pairs(workspace.Players.Ghosts:GetChildren()) do
                    if val:IsA("Model") then
                        instance_table[#instance_table + 1] = val
                    end
                end

                return instance_table -- return both teams
            end
        end

        return {} -- wtf???
    end
--[[
    elseif game.PlaceId == 3233893879 then -- bad business

    local TS = require(rep_storage:WaitForChild("TS"))
    local characters = TS.Characters
    local teams = TS.Teams
    
    function get_team(plr)
        return teams:GetPlayerTeam(plr)
    end

    local lp_meta = {} -- only set once so its fine ;)
    setmetatable(lp_meta, {
        __index = function(...)
            local char = characters:GetCharacter(local_player)
            local char_body = char.Body

            local self, idx = ...

            if idx == "Humanoid" then
                return {
                    Health = char.Health.Value,
                    MaxHealth = char.Health.MaxHealth.Value
                }
                
            elseif idx == "HumanoidRootPart" then
                return char.Root
            elseif idx == "GetDebugId" then
                return function()
                    return char:GetDebugId()
                end
            end

            return char_body[idx]
        end
    })

    local old_index;
    old_index = hookmetamethod(local_player, "__index", function(...)
        local self, idx = ...

        if idx == "Character" and checkcaller() then
            return lp_meta
        end

        return old_index(...)
    end)

    get_players = function()
        local instance_table = {}

        for idx, val in pairs(players:GetChildren()) do
            local lp_team = get_team(local_player)
            if lp_team == get_team(val) then continue; end

            local char = characters:GetCharacter(val)
            if not char then continue; end

            local mt = {}

            setmetatable(mt, {
                __index = function(...)
                    local char = characters:GetCharacter(val)
                    local char_body = char.Body

                    local self, idx = ...

                    if idx == "Humanoid" then
                        return {
                            Health = char.Health.Value,
                            MaxHealth = char.Health.MaxHealth.Value
                        }
                        
                    elseif idx == "HumanoidRootPart" then
                        return char.Root
                    elseif idx == "GetDebugId" then
                        return function()
                            return char:GetDebugId()
                        end
                    elseif idx == "GetChildren" then
                        return function()
                            return char_body:GetChildren()
                        end
                    elseif idx == "FindFirstChild" then
                        return function(self, child)
                            return char_body:FindFirstChild(child)
                        end
                    elseif idx == "FindFirstChildOfClass" then
                        return function(self, class)
                            if class == "Humanoid" then
                                return {
                                    Health = char.Health.Value,
                                    MaxHealth = char.Health.MaxHealth.Value
                                }
                            end

                            return char_body:FindFirstChildOfClass(class)
                        end
                    end

                    return char_body[idx]
                end
            })

            instance_table[#instance_table + 1] = mt
        end

        return instance_table
    end
]]
else -- normal players
    debounces.custom_players = false

    get_players = function()
        return players:GetChildren()
    end
end

frame_wait:Connect(function()
    utility.run_player_check()

    utility.update_drawing(objects, "fov", {
        Radius = aimsp_settings.fov_size,
        Thickness = aimsp_settings.esp_thickness,
        Color = (aimsp_settings.use_rainbow and utility.get_rainbow()) or white,
        instance = "Circle";
    })

    utility.update_drawing(objects.crosshair, "top", {
        Visible = aimsp_settings.crosshair.use,
        Thickness = aimsp_settings.crosshair.thickness,
        Color = (aimsp_settings.use_rainbow and utility.get_rainbow()) or white,
        From = vector2_new(center_screen.X, center_screen.Y - aimsp_settings.crosshair.length - aimsp_settings.crosshair.distance),
        To = vector2_new(center_screen.X, center_screen.Y - aimsp_settings.crosshair.distance),
        instance = "Line";
    })

    utility.update_drawing(objects.crosshair, "bottom", {
        Visible = aimsp_settings.crosshair.use,
        Thickness = aimsp_settings.crosshair.thickness,
        Color = (aimsp_settings.use_rainbow and utility.get_rainbow()) or white,
        From = vector2_new(center_screen.X, center_screen.Y + aimsp_settings.crosshair.length + aimsp_settings.crosshair.distance + 1),
        To = vector2_new(center_screen.X, center_screen.Y + aimsp_settings.crosshair.distance + 1),
        instance = "Line";
    })

    utility.update_drawing(objects.crosshair, "left", {
        Visible = aimsp_settings.crosshair.use,
        Thickness = aimsp_settings.crosshair.thickness,
        Color = (aimsp_settings.use_rainbow and utility.get_rainbow()) or white,
        From = vector2_new(center_screen.X - aimsp_settings.crosshair.length - aimsp_settings.crosshair.distance, center_screen.Y),
        To = vector2_new(center_screen.X - aimsp_settings.crosshair.distance, center_screen.Y),
        instance = "Line";
    })
    
    utility.update_drawing(objects.crosshair, "right", {
        Visible = aimsp_settings.crosshair.use,
        Thickness = aimsp_settings.crosshair.thickness,
        Color = (aimsp_settings.use_rainbow and utility.get_rainbow()) or white,
        From = vector2_new(center_screen.X + aimsp_settings.crosshair.length + aimsp_settings.crosshair.distance + 1, center_screen.Y),
        To = vector2_new(center_screen.X + aimsp_settings.crosshair.distance + 1, center_screen.Y),
        instance = "Line";
    })

    local closest_players = {}
    local ignored_index = 0

    local function run_table_teamcheck(tbl)
        if not aimsp_settings.team_check then
            return tbl
        end

        local checked = {}

        for idx, plr in pairs(tbl) do
            if not aimsp_settings.loop_all_humanoids and not debounces.custom_players and plr.Team then
                if plr.TeamColor == local_player.TeamColor then continue; end
                if plr.Team == local_player.Team then continue; end
            end

            checked[#checked + 1] = plr
        end

        return checked
    end

    local function sort_table_distance(tbl) -- also does esp
        local sorted = {}

        for idx, plr in pairs(tbl) do
            if plr == local_player then continue; end

            local plr_char = ((aimsp_settings.loop_all_humanoids or debounces.custom_players) and plr) or plr.Character
            if plr_char == nil then continue; end

            local root_part = plr_char:FindFirstChild("HumanoidRootPart") or plr_char:FindFirstChild("UpperTorso") or plr_char:FindFirstChild("LowerTorso") or plr_char:FindFirstChild("Torso") or plr_char.PrimaryPart
            if root_part == nil then continue; end
            
            local head = plr_char:FindFirstChild("Head") or root_part

            local plr_screen, scr_z, visible, rage = utility.to_screen(root_part.Position)
            local mag = (root_part.Position - local_player.Character.HumanoidRootPart.Position).Magnitude

            if aimsp_settings.use_esp and ignored_index == 0 then
                local col = (aimsp_settings.use_rainbow and utility.get_rainbow()) or white
                local corners = utility.get_part_corners(root_part)

                local point_a_scr, a_z, a_visible = utility.to_screen(corners.top_left)
                local point_b_scr, b_z, b_visible = utility.to_screen(corners.top_right)
                local point_c_scr, c_z, c_visible = utility.to_screen(corners.bottom_right)
                local point_d_scr, d_z, d_visible = utility.to_screen(corners.bottom_left)

                if aimsp_settings.tracers then
                    local object_space_pos = camera.CFrame:pointToObjectSpace(vector3_new(
                        (corners.top_left.X + corners.top_right.X) / 2, 
                        (corners.top_left.Y + corners.top_right.Y) / 2, 
                        (corners.top_left.Z + corners.top_right.Z) / 2
                    ))
					
					if scr_z.Z < 0 then -- thanks unnamed esp for the math
						local angle = math_atan2(object_space_pos.Y, object_space_pos.X) + pi
                        object_space_pos = cframe_angles(0, 0, angle):vectorToWorldSpace((cframe_angles(0, math_rad(89.9), 0).LookVector))
					end
					
					local tracer_pos = utility.to_screen(camera.CFrame:pointToWorldSpace(object_space_pos))
                    
                    utility.update_drawing(objects.tracers, plr_char:GetDebugId(), {
                        Visible = objects.fov.Visible,
                        Thickness = aimsp_settings.esp_thickness,
                        Color = (aimsp_settings.use_rainbow and utility.get_rainbow()) or color3_new(255 / mag, mag / 255, 0),
                        To = vector2_new(tracer_pos.X, tracer_pos.Y),
                        From = vector2_new(screen_size.X / 2, screen_size.Y - 36),
                        instance = "Line";
                    })
                end
                
                if aimsp_settings.box then
                    if a_visible and b_visible and c_visible and d_visible then
                        utility.update_drawing(objects.quads, plr_char:GetDebugId(), {
                            Visible = objects.fov.Visible,
                            Thickness = aimsp_settings.esp_thickness,
                            Color = col,
                            PointA = point_a_scr,
                            PointB = point_b_scr,
                            PointC = point_c_scr,
                            PointD = point_d_scr,
                            instance = "Quad";
                        })
                    else
                        utility.update_drawing(objects.quads, plr_char:GetDebugId(), {
                            Visible = false,
                            instance = "Quad";
                        })
                    end
                end

                if aimsp_settings.looking_at_tracers.use then
                    local point_a_src, _, a_visible = utility.to_screen(head.Position)
                    local point_b_src, _, b_visible = utility.to_screen(head.Position + head.CFrame.LookVector * aimsp_settings.looking_at_tracers.length)

                    if a_visible and b_visible then
                        utility.update_drawing(objects.looking_at_tracers, plr_char:GetDebugId(), {
                            Visible = objects.fov.Visible,
                            Thickness = aimsp_settings.looking_at_tracers.thickness,
                            Color = aimsp_settings.looking_at_tracers.color or white,
                            To = point_a_src,
                            From = point_b_src,
                            instance = "Line";
                        })
                    else
                        utility.update_drawing(objects.looking_at_tracers, plr_char:GetDebugId(), {
                            Visible = false,
                            instance = "Line";
                        })
                    end
                end

                local plr_info = ""

                if aimsp_settings.name then
                    plr_info = plr_info .. (plr.Name .. "\n")
                end
                if aimsp_settings.dist then
                    plr_info = plr_info .. ("[" .. tostring(math_floor(mag)) .. "]\n")
                end
                if aimsp_settings.health then
                    local hum = plr_char:FindFirstChildOfClass("Humanoid")

                    plr_info = (hum and plr_info .. ("[" .. tostring(math_ceil(hum.Health)) .. "/" .. tostring(math_ceil(hum.MaxHealth)) .. "]" )) or plr_info
                end

                if plr_info ~= "" then
                    local cam_mag = (camera.CFrame.Position - root_part.CFrame.Position).Magnitude / 20

                    local scr_pos, _, visible = utility.to_screen(vector3_new(
                        (corners.bottom_right.X + corners.bottom_left.X) / 2,
                        ((corners.top_right.Y + corners.bottom_right.Y) / 2) + (corners.bottom_right.Y - corners.top_right.Y) + cam_mag,
                        (corners.bottom_right.Z + corners.bottom_left.Z) / 2
                    ))

                    if visible then
                        utility.update_drawing(objects.labels, plr_char:GetDebugId(), {
                            Visible = objects.fov.Visible,
                            Color = col,
                            Position = scr_pos,
                            Text = plr_info,
                            Center = true,
                            instance = "Text";
                        })
                    else
                        utility.update_drawing(objects.labels, plr_char:GetDebugId(), {
                            Visible = false,
                            instance = "Text";
                        })
                    end
                end
            else
                if ignored_index == 0 then
                    utility.update_drawing(objects.tracers, plr_char:GetDebugId(), {
                        Visible = false,
                        instance = "Line";
                    })
    
                    utility.update_drawing(objects.quads, plr_char:GetDebugId(), {
                        Visible = false,
                        instance = "Quad";
                    })
    
                    utility.update_drawing(objects.labels, plr_char:GetDebugId(), {
                        Visible = false,
                        instance = "Text";
                    })
                end
            end

            if visible or rage then
                if aimsp_settings.prefer.looking_at_you then
                    sorted[((root_part.Position + (root_part.CFrame.LookVector * mag)) - local_player.Character.HumanoidRootPart.Position).Magnitude] = plr
                elseif aimsp_settings.prefer.closest_to_center_screen then
                    sorted[(center_screen - plr_screen).Magnitude] = plr
                elseif aimsp_settings.prefer.closest_to_you then
                    sorted[mag] = plr
                end
            end
        end

        local mags = {}

        for idx in pairs(sorted) do
            mags[#mags + 1] = idx
        end

        table.sort(mags)

        local idx_sorted = {}

        for _, idx in pairs(mags) do
            idx_sorted[#idx_sorted + 1] = sorted[idx]
        end

        return idx_sorted
    end

    local get_closest_player = function()
        if ignored_index ~= 0 and aimsp_settings.use_backwards_iteration.table_index then
            local plr = closest_players[1 + ignored_index]

            return ((aimsp_settings.loop_all_humanoids or debounces.custom_players) and plr) or (plr and plr.Character)
        end

        local closest_players = sort_table_distance(run_table_teamcheck(get_players()))

        if #closest_players ~= 0 then
            local plr = closest_players[1 + ignored_index]

            return ((aimsp_settings.loop_all_humanoids or debounces.custom_players) and plr) or (plr and plr.Character)
        end
    end
    
    local run_aimbot;
    run_aimbot = function(closest_player)
        local visible_parts = {}
        local last
        
        if aimsp_settings.use_aimbot and closest_player then
            for idx, part in pairs(closest_player:GetChildren()) do
                if part:IsA("BasePart") then
                    local screen_pos, src_pos_z, on_screen, rage = utility.to_screen(part.Position)

                    if on_screen or rage then
                        if utility.is_inside_fov(screen_pos) and utility.is_part_visible(part, local_player.Character.HumanoidRootPart) then
                            last = {
                                scr_pos = screen_pos,
                                on_screen = on_screen,
                                obj = part;
                            };
                            visible_parts[part.Name] = last
                        end
                    end
                end
            end
            
            if aimsp_settings.headshot_odds.use_odds then
                local aim_head = (aimsp_settings.rage_mode.use and true) or aimsp_settings.headshot_odds.func()

                if visible_parts["Head"] and aim_head then
                    visible_parts[0] = visible_parts["Head"]

                elseif visible_parts["UpperTorso"] or visible_parts["Torso"] then
                    visible_parts[0] = visible_parts["UpperTorso"] or visible_parts["Torso"]

                elseif not aim_head and visible_parts["Head"] then -- torso is not visible, aim on head
                    visible_parts[0] = visible_parts["Head"]
                end
            else
                if visible_parts["Head"] then
                    visible_parts[0] = visible_parts["Head"]

                elseif visible_parts["UpperTorso"] or visible_parts["Torso"] then
                    visible_parts[0] = visible_parts["UpperTorso"] or visible_parts["Torso"]
                end
            end

            local lock_part = visible_parts[0] or last

            if lock_part then
                local scale = (lock_part.obj.Size.Y / 2)

                local top, top_z, top_visible = utility.to_screen((lock_part.obj.CFrame * cframe_new(0, scale, 0)).Position);
                local bottom, bottom_z, bottom_visible = utility.to_screen((lock_part.obj.CFrame * cframe_new(0, -scale, 0)).Position);
                local radius = -(top - bottom).y;

                utility.update_drawing(objects.look_at, "point", {
                    Transparency = 1,
                    Thickness = aimsp_settings.esp_thickness,
                    Radius = radius / 2,
                    Visible = objects.fov.Visible,
                    Color = (debounces.start_aim and green) or white,
                    Position = lock_part.scr_pos,
                    instance = "Circle";
                })

                if debounces.start_aim then
                    utility.update_drawing(objects.look_at, "tracer", {
                        Transparency = 1,
                        Thickness = aimsp_settings.esp_thickness,
                        Visible = objects.fov.Visible,
                        Color = green,
                        From = center_screen,
                        To = lock_part.scr_pos,
                        instance = "Line";
                    })

                    if aimsp_settings.rage_mode.use then
                        local should_move = true

                        local move_to_x = lock_part.scr_pos.X
                        local move_to_y = lock_part.scr_pos.Y 

                        if not lock_part.on_screen then
                            if aimsp_settings.rage_mode.flip_cframe then
                                camera.CFrame = cframe_new(camera.CFrame.p, camera.CFrame.p - camera.CFrame.LookVector)
                            end

                            if aimsp_settings.rage_mode.flip_mouse then
                                mousemoverel(screen_size.X / 4, (move_to_y - mouse.Y) / 4)

                                local position, on_screen = camera:WorldToViewportPoint(lock_part.obj.Position)
                                should_move = on_screen
    
                                move_to_x = position.X
                                move_to_y = position.Y
                            end
                        end

                        if should_move then
                            mousemoverel((move_to_x - mouse.X) / 2, (move_to_y - (mouse.Y + 36)) / 2)
                        end
                    else
                        mousemoverel((lock_part.scr_pos.X - mouse.X) / aimsp_settings.smoothness, (lock_part.scr_pos.Y - (mouse.Y + 36)) / aimsp_settings.smoothness)
                    end
                else
                    utility.update_drawing(objects.look_at, "tracer", {
                        Visible = false,
                        instance = "Line";
                    })
                end
            else
                -- find another player
                utility.update_drawing(objects.look_at, "point", {
                    Visible = false,
                    instance = "Circle";
                })

                utility.update_drawing(objects.look_at, "tracer", {
                    Visible = false,
                    instance = "Line";
                })

                if aimsp_settings.use_aimbot and aimsp_settings.use_backwards_iteration.use then
                    ignored_index = ignored_index + 1
                    run_aimbot(get_closest_player())
                end
            end
        end
    end
    run_aimbot(get_closest_player())
end)
