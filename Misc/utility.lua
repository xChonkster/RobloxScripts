-- might make a hub out of this ngl

local string_format = string.format
local math_ceil = math.ceil
local math_clamp = math.clamp
local math_floor = math.floor
local math_rad = math.rad
local math_tan = math.tan
local math_sqrt = math.sqrt
local cframe_new = CFrame.new
local vector3_new = Vector3.new
local vector2_new = Vector2.new
local string_find = string.find
local string_lower = string.lower

local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")

local local_player = game:GetService("Players").LocalPlayer
local mouse = local_player:GetMouse()

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")

local http = game:GetService("HttpService")

local stepped = rs.Heartbeat
math.randomseed(tick())

local spoof = (function()
	loadstring(game:HttpGet("https://github.com/xChonkster/hub/blob/main/libs/meta.lua?raw=true"))()

	local spoof = {
		types = {
			impersonator = 0,
			reverse_impersonator = 1,
			get_hook = 2,
			set_hook = 3,
			lock = 4,
		},
		hooks = {};
	}

	function spoof.add_hook(hook_type, args, on_remove)
		local idx = #spoof.hooks + 1

		spoof.hooks[idx] = {type = hook_type, args = args}

		return {
			remove = function()
				(on_remove or function()end)()
				spoof.hooks[idx] = nil
			end,

			spoof.hooks,
			idx;
		}
	end
	
	local old_index;
	old_index = meta.main.__index.append(function(...)
		local self, index = ...

		if checkcaller() then
			return old_index(...)
		end

		for idx, hook in pairs(spoof.hooks) do
			
			if hook and self == hook.args.instance and index == hook.args.property then
				if hook.type == spoof.types.impersonator then
					return hook.args.fake
				end
				
				if hook.type == spoof.types.reverse_impersonator then
					return hook.args.real
				end
			end
		end

		return old_index(...)
	end)

	local old_new_index;
	old_new_index = meta.main.__newindex.append(function(...)
		local self, index, val = ...

		for idx, hook in pairs(spoof.hooks) do
			if hook and self == hook.args.instance and index == hook.args.property then
				if hook.type == spoof.types.impersonator then
					if checkcaller() then
						hook.real = val
						return old_new_index(...)
					end
					hook.args.fake = val

					return old_new_index(self, index, hook.args.real)
				end
				
				if hook.type == spoof.types.reverse_impersonator then
					if checkcaller() then
						hook.args.real = val
					end

					return nil
				end
				
				if hook.type == spoof.types.lock then
					if checkcaller() then
						return old_new_index(...)
					end

					return nil
				end

				if hook.type == spoof.types.set_hook then
					if checkcaller() then
						return old_new_index(...)
					end
					
					return hook.args.callback(...)
				end
			end
		end

		return old_new_index(...)
	end)
	
	function spoof.impersonator(inst, prop, real)
		return spoof.add_hook(spoof.types.impersonator, {
			instance = inst,
			property = prop,
			real = real,
			fake = inst[prop];
		}, function()
			inst[prop] = real
		end)
	end
	
	function spoof.reverse_impersonator(inst, prop, real)
		return spoof.add_hook(spoof.types.reverse_impersonator, {
			instance = inst,
			property = prop,
			real = real,
		}, function()end)
	end

	function spoof.lock(inst, prop)
		return spoof.add_hook(spoof.types.lock, {
			instance = inst,
			property = prop,
		}, function()end)
	end

	function spoof.set_hook(inst, prop, func)
		return spoof.add_hook(spoof.types.set_hook, {
			instance = inst,
			property = prop,
			callback = func;
		}, function()end), old_new_index
	end
	
	return spoof	
end)()

local input = (function()
	local input = {}
	
	function input.handle_keys(key_states)
		local began = uis.InputBegan:Connect(function(inp, gmp)
			if gmp then return end
			
			if key_states[inp.KeyCode.Name] then
				key_states[inp.KeyCode.Name] = 1
			end
		end)
		
		local ended = uis.InputEnded:Connect(function(inp, gmp)
			if gmp then return end
			
			if key_states[inp.KeyCode.Name] then
				key_states[inp.KeyCode.Name] = 0
			end
		end)
		
		local function remove()
			began:Disconnect()
			ended:Disconnect()
		end
		
		return {
			remove = remove,
			disconnect = remove;
		}
	end
	
	return input	
end)()

local effects = (function()
	local effects = {}
	
	function effects.button(button)
		
	end
	
	return effects	
end)()

local library = {}

function save()
	local parse;

	parse = function(tbl)
		local ret = {}

		for idx, val in pairs(tbl) do
			local set = val

			if type(val) == "userdata" then
				local func, result = pcall(function()
					return Enum.KeyCode[val.Name]
				end)

				if func then
					set = result.Name
				end
			end

			if type(val) == "table" then
				set = parse(val)
			end

			ret[idx] = set
		end

		return ret
	end

	local parsed = parse(library.json)

	writefile("uilib.mc", http:JSONEncode(parsed))
end

function read()
	local reader = (readfile or function() return "" end)
	local func, data = pcall(reader, "uilib.mc")

	local tbl = (func and http:JSONDecode(data)) or nil
	if tbl then
		local parse;

		parse = function(tbl)
			local ret = {}

			for idx, val in pairs(tbl) do
				local set = val

				if type(val) == "string" then
					local func, result = pcall(function()
						return Enum.KeyCode[val]
					end)
					
					if func then
						set = result
					end
				end

				if type(val) == "table" then
					set = parse(val)
				end

				ret[idx] = set
			end

			return ret
		end

		return parse(tbl)
	end	

	return nil
end

library.json = read() or {}

function library:create(name)
	local main = Instance.new("ScreenGui")
	local main_2 = Instance.new("Frame")
	local tab_holder = Instance.new("Frame")
	local tab_gridder = Instance.new("UIGridLayout")
	
	local function get_keybind()
		local select_key = Instance.new("Frame")
		local press = Instance.new("TextLabel")
		local remove = Instance.new("TextButton")
		local esc = Instance.new("TextLabel")

		select_key.Name = "select_key"
		select_key.Parent = main_2
		select_key.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		select_key.BackgroundTransparency = 0.500
		select_key.BorderColor3 = Color3.fromRGB(255, 255, 255)
		select_key.BorderSizePixel = 0
		select_key.Size = UDim2.new(1, 0, 1, 0)
		select_key.ZIndex = 2

		press.Name = "press"
		press.Parent = select_key
		press.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		press.BackgroundTransparency = 1.000
		press.BorderColor3 = Color3.fromRGB(255, 255, 255)
		press.BorderSizePixel = 0
		press.Position = UDim2.new(0, 0, 0.375, 0)
		press.Size = UDim2.new(1, 0, 0.07, 0)
		press.ZIndex = 2
		press.Font = Enum.Font.Gotham
		press.Text = "Press any key to set it as your keybind"
		press.TextColor3 = Color3.fromRGB(255, 255, 255)
		press.TextSize = 30.000

		remove.Name = "remove"
		remove.Parent = select_key
		remove.Active = false
		remove.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		remove.BackgroundTransparency = 1.000
		remove.BorderColor3 = Color3.fromRGB(255, 255, 255)
		remove.BorderSizePixel = 0
		remove.Position = UDim2.new(0, 0, 0.464202464, 0)
		remove.Selectable = false
		remove.Size = UDim2.new(1, 0, 0.07, 0)
		remove.ZIndex = 2
		remove.RichText = true
		remove.Font = Enum.Font.Gotham
		remove.Text = "<u>Or remove your keybind</u>"
		remove.TextColor3 = Color3.fromRGB(255, 255, 255)
		remove.TextSize = 20.000
		
		esc.Name = "esc"
		esc.Parent = select_key
		esc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		esc.BackgroundTransparency = 1.000
		esc.BorderColor3 = Color3.fromRGB(255, 255, 255)
		esc.BorderSizePixel = 0
		esc.Position = UDim2.new(0, 0, 0.53, 0)
		esc.Size = UDim2.new(1, 0, 0.07, 0)
		esc.ZIndex = 2
		esc.Font = Enum.Font.Gotham
		esc.Text = "ESC to exit"
		esc.TextColor3 = Color3.fromRGB(255, 255, 255)
		esc.TextSize = 15.000

		local key_pressed = -1
		
		local connection = uis.InputBegan:Connect(function(inp)
			if inp.KeyCode == Enum.KeyCode.Escape then
				key_pressed = nil
				
				return;
			end
			
			if inp.KeyCode ~= Enum.KeyCode.Unknown then
				key_pressed = inp.KeyCode
			end
		end)
		
		remove.MouseButton1Click:Connect(function()
			key_pressed = -2
		end)

		repeat stepped:wait() until key_pressed ~= -1

		connection:Disconnect()
		select_key:Destroy()

		return key_pressed
	end
	
	local i_no_have = Instance.new("TextButton")
	
	main.Name = "main"
	((syn and syn.protect_gui) or function()end)(main)
	main.Parent = game.CoreGui
	main.ResetOnSpawn = false
	main.IgnoreGuiInset = true
	main.ZIndexBehavior = Enum.ZIndexBehavior.Global
	
	local visible = true
	main_2.Visible = true
	library.json.hide_show_keybind = library.json.hide_show_keybind or Enum.KeyCode.Insert
	
	local old_mouse = true
	
	local _, sth_new_index;
	_, sth_new_index = spoof.set_hook(uis, "MouseIconEnabled", function(...)
		local self, index, val = ...
		
		old_mouse = val
		
		if visible then
			return sth_new_index(self, index, true)
		end
		
		return sth_new_index(self, index, val)
	end)
	
	uis.InputBegan:Connect(function(inp, gmp)
		if gmp then return end

		if inp.KeyCode == library.json.hide_show_keybind then
			visible = not visible
			
			main_2.Visible = visible
			i_no_have.Modal = visible
			
			if visible then
				uis.MouseIconEnabled = true
			else
				uis.MouseIconEnabled = old_mouse
			end
		end
	end)
	
	i_no_have.Name = "i_no_have"
	i_no_have.Parent = main_2
	i_no_have.AnchorPoint = Vector2.new(0.5, 0.5)
	i_no_have.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	i_no_have.BackgroundTransparency = 1.000
	i_no_have.BorderColor3 = Color3.fromRGB(255, 255, 255)
	i_no_have.BorderSizePixel = 0
	i_no_have.Position = UDim2.new(0.5, 0, 0.96, 0)
	i_no_have.Size = UDim2.new(0, 200, 0, 65)
	i_no_have.RichText = true
	i_no_have.Font = Enum.Font.Gotham
	i_no_have.Text = string_format("Press %s to hide\n\n<u>I don't have this key</u>", library.json.hide_show_keybind.Name)
	i_no_have.TextColor3 = Color3.fromRGB(150, 150, 150)
	i_no_have.TextSize = 15.000
	i_no_have.Modal = true

	i_no_have.MouseButton1Click:Connect(function()
		local m_key = get_keybind()

		if m_key == nil or m_key == -2 then return end

		library.json.hide_show_keybind = m_key

		i_no_have.Text = string_format("Press %s to hide\n\n<u>I don't have this key</u>", library.json.hide_show_keybind.Name)

		save()
	end)
	
	main_2.Name = "main"
	main_2.Parent = main
	main_2.Active = true
	main_2.AnchorPoint = Vector2.new(0.5, 0.5)
	main_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	main_2.BackgroundTransparency = 0.500
	main_2.BorderColor3 = Color3.fromRGB(255, 255, 255)
	main_2.BorderSizePixel = 0
	main_2.Position = UDim2.new(0.5, 0, 0.5, 0)
	main_2.Size = UDim2.new(1, 0, 1, 0)
	
	tab_holder.Name = "tab_holder"
	tab_holder.Parent = main_2
	tab_holder.Active = true
	tab_holder.AnchorPoint = Vector2.new(0.5, 0.5)
	tab_holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tab_holder.BackgroundTransparency = 1.000
	tab_holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
	tab_holder.BorderSizePixel = 0
	tab_holder.Position = UDim2.new(0.5, 0, 0.5, 36)
	tab_holder.Size = UDim2.new(0.95, 0, 0.95, 0)

	tab_gridder.Name = "tab_gridder"
	tab_gridder.Parent = tab_holder
	tab_gridder.SortOrder = Enum.SortOrder.LayoutOrder
	tab_gridder.CellPadding = UDim2.new(0, 20, 0, 10)
	tab_gridder.CellSize = UDim2.new(0, 175, 0, 300)

	local running = Instance.new("Frame")
	local running_gridder = Instance.new("UIGridLayout")

	running.Name = "running"
	running.Parent = main
	running.AnchorPoint = Vector2.new(1, 0)
	running.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	running.BackgroundTransparency = 1.000
	running.BorderColor3 = Color3.fromRGB(255, 255, 255)
	running.Position = UDim2.new(1, 0, 0, 36)
	running.Size = UDim2.new(0, 250, 1, 0)

	running_gridder.Name = "running_gridder"
	running_gridder.Parent = running
	running_gridder.FillDirection = Enum.FillDirection.Vertical
	running_gridder.HorizontalAlignment = Enum.HorizontalAlignment.Right
	running_gridder.SortOrder = Enum.SortOrder.LayoutOrder
	running_gridder.CellPadding = UDim2.new(0, 5, 0, 0)
	running_gridder.CellSize = UDim2.new(0, 100, 0, 30)
	running_gridder.StartCorner = Enum.StartCorner.TopRight

	local game_info = Instance.new("Frame")
	local game_position = Instance.new("TextButton")
	local game_name = Instance.new("TextButton")
	local game_time = Instance.new("TextButton")

	game_info.Name = "game_info"
	--game_info.Parent = main
	game_info.AnchorPoint = Vector2.new(0, 1)
	game_info.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	game_info.BackgroundTransparency = 1.000
	game_info.BorderColor3 = Color3.fromRGB(255, 255, 255)
	game_info.BorderSizePixel = 0
	game_info.Position = UDim2.new(0.005, 0, 1, 0)
	game_info.Size = UDim2.new(0, 250, 0, 150)

	game_position.Name = "game_position"
	game_position.Parent = game_info
	game_position.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	game_position.BackgroundTransparency = 1.000
	game_position.BorderColor3 = Color3.fromRGB(255, 255, 255)
	game_position.BorderSizePixel = 0
	game_position.Position = UDim2.new(0, 0, 0.866666675, 0)
	game_position.Size = UDim2.new(1, 0, 0, 20)
	game_position.Font = Enum.Font.Gotham
	game_position.Text = "position"
	game_position.TextColor3 = Color3.fromRGB(255, 255, 255)
	game_position.TextSize = 15.000
	game_position.TextXAlignment = Enum.TextXAlignment.Left
	
	--[[
	stepped:Connect(function()
		local char = local_player.Character
		
		if char then
			local root_part = char:FindFirstChild("HumanoidRootPart") 
				or char:FindFirstChild("Torso") 
				or char:FindFirstChild("UpperTorso") 
				or char:FindFirstChild("LowerTorso") 
				or char:FindFirstChildOfClass("BasePart")
				or char:FindFirstChildOfClass("Part") 
				or char.PrimaryPart
				
			game_position.Text = string_format("%s, %s, %s", 
				tostring(math_floor(root_part.Position.X)),
				tostring(math_floor(root_part.Position.Y)),
				tostring(math_floor(root_part.Position.Z))
			)
			
			return;
		end
		
		game_position.Text = "N/A"
	end)]]
	
	game_name.Name = "game_name"
	game_name.Parent = game_info
	game_name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	game_name.BackgroundTransparency = 1.000
	game_name.BorderColor3 = Color3.fromRGB(255, 255, 255)
	game_name.BorderSizePixel = 0
	game_name.Position = UDim2.new(0, 0, 0.599999964, 0)
	game_name.Size = UDim2.new(1, 0, 0, 20)
	game_name.Font = Enum.Font.Gotham
	game_name.Text = "name"
	game_name.TextColor3 = Color3.fromRGB(255, 255, 255)
	game_name.TextSize = 15.000
	game_name.TextXAlignment = Enum.TextXAlignment.Left

	game_time.Name = "game_time"
	game_time.Parent = game_info
	game_time.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	game_time.BackgroundTransparency = 1.000
	game_time.BorderColor3 = Color3.fromRGB(255, 255, 255)
	game_time.BorderSizePixel = 0
	game_time.Position = UDim2.new(0, 0, 0.733333349, 0)
	game_time.Size = UDim2.new(1, 0, 0, 20)
	game_time.Font = Enum.Font.Gotham
	game_time.Text = "time"
	game_time.TextColor3 = Color3.fromRGB(255, 255, 255)
	game_time.TextSize = 15.000
	game_time.TextXAlignment = Enum.TextXAlignment.Left
	
	local mc = {}
	
	local tabs = {}
	
	function mc:tab(name_)
		local tab = Instance.new("Frame")
		local main = Instance.new("ImageLabel")
		local top = Instance.new("Frame")
		local name = Instance.new("TextLabel")
		local hide = Instance.new("TextButton")
		local shadow_holder = Instance.new("Frame")
		local umbra_shadow = Instance.new("ImageLabel")
		local penumbra_shadow = Instance.new("ImageLabel")
		local ambient_shadow = Instance.new("ImageLabel")
		local holder = Instance.new("ScrollingFrame")
		local scroll = Instance.new("ScrollingFrame")
		
		local current_tab_idx = #tabs + 1
		tabs[current_tab_idx] = tab
		
		tab.Name = "tab"
		tab.Parent = tab_holder
		tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		tab.BackgroundTransparency = 1.000
		tab.BorderColor3 = Color3.fromRGB(255, 255, 255)
		tab.BorderSizePixel = 0
		tab.Size = UDim2.new(0, 175, 0, 300)

		main.Name = "main"
		main.Parent = tab
		main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		main.BackgroundTransparency = 1.000
		main.BorderColor3 = Color3.fromRGB(255, 255, 255)
		main.BorderSizePixel = 0
		main.Size = UDim2.new(1, 0, 1, 0)
		main.Image = "rbxassetid://3570695787"
		main.ImageColor3 = Color3.fromRGB(26, 25, 26)
		main.ScaleType = Enum.ScaleType.Slice
		main.SliceCenter = Rect.new(100, 100, 100, 100)
		main.SliceScale = 0.050

		top.Name = "top"
		top.Parent = main
		top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		top.BackgroundTransparency = 1.000
		top.BorderColor3 = Color3.fromRGB(255, 255, 255)
		top.BorderSizePixel = 0
		top.Size = UDim2.new(0, 175, 0, 35)

		name.Name = "name"
		name.Text = name_
		name.Parent = top
		name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		name.BackgroundTransparency = 1.000
		name.BorderColor3 = Color3.fromRGB(255, 255, 255)
		name.BorderSizePixel = 0
		name.Position = UDim2.new(0.0571428575, 0, 0, 0)
		name.Size = UDim2.new(0, 135, 0, 35)
		name.Font = Enum.Font.Gotham
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.TextSize = 20.000
		name.TextWrapped = true
		name.TextXAlignment = Enum.TextXAlignment.Left

		hide.Name = "hide"
		hide.Parent = top
		hide.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hide.BackgroundTransparency = 1.000
		hide.BorderColor3 = Color3.fromRGB(255, 255, 255)
		hide.BorderSizePixel = 0
		hide.Position = UDim2.new(0.828571439, 0, 0, 0)
		hide.Rotation = 90.000
		hide.Size = UDim2.new(0, 30, 0, 35)
		hide.Font = Enum.Font.Jura
		hide.Text = ">"
		hide.TextColor3 = Color3.fromRGB(116, 116, 116)
		hide.TextSize = 30.000

		shadow_holder.Name = "shadow_holder"
		shadow_holder.Parent = main
		shadow_holder.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow_holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		shadow_holder.BackgroundTransparency = 1.000
		shadow_holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
		shadow_holder.BorderSizePixel = 0
		shadow_holder.Position = UDim2.new(0.5, 0, 0.5, 0)
		shadow_holder.Size = UDim2.new(1, 0, 1, 0)
		shadow_holder.ZIndex = 0

		umbra_shadow.Name = "umbra_shadow"
		umbra_shadow.Parent = shadow_holder
		umbra_shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		umbra_shadow.BackgroundTransparency = 1.000
		umbra_shadow.BorderColor3 = Color3.fromRGB(255, 255, 255)
		umbra_shadow.BorderSizePixel = 0
		umbra_shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
		umbra_shadow.Size = UDim2.new(1, 10, 1, 10)
		umbra_shadow.ZIndex = 0
		umbra_shadow.Image = "rbxassetid://1316045217"
		umbra_shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		umbra_shadow.ImageTransparency = 0
		umbra_shadow.ScaleType = Enum.ScaleType.Slice
		umbra_shadow.SliceCenter = Rect.new(10, 10, 118, 118)

		penumbra_shadow.Name = "penumbra_shadow"
		penumbra_shadow.Parent = shadow_holder
		penumbra_shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		penumbra_shadow.BackgroundTransparency = 1.000
		penumbra_shadow.BorderColor3 = Color3.fromRGB(255, 255, 255)
		penumbra_shadow.BorderSizePixel = 0
		penumbra_shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
		penumbra_shadow.Size = UDim2.new(1, 10, 1, 10)
		penumbra_shadow.ZIndex = 0
		penumbra_shadow.Image = "rbxassetid://1316045217"
		penumbra_shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		penumbra_shadow.ImageTransparency = 0
		penumbra_shadow.ScaleType = Enum.ScaleType.Slice
		penumbra_shadow.SliceCenter = Rect.new(10, 10, 118, 118)

		ambient_shadow.Name = "ambient_shadow"
		ambient_shadow.Parent = shadow_holder
		ambient_shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		ambient_shadow.BackgroundTransparency = 1.000
		ambient_shadow.BorderColor3 = Color3.fromRGB(255, 255, 255)
		ambient_shadow.BorderSizePixel = 0
		ambient_shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
		ambient_shadow.Size = UDim2.new(1, 10, 1, 10)
		ambient_shadow.ZIndex = 0
		ambient_shadow.Image = "rbxassetid://1316045217"
		ambient_shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		ambient_shadow.ImageTransparency = 0
		ambient_shadow.ScaleType = Enum.ScaleType.Slice
		ambient_shadow.SliceCenter = Rect.new(10, 10, 118, 118)

		holder.Name = "holder"
		holder.Parent = main
		holder.Active = true
		holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		holder.BackgroundTransparency = 1.000
		holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
		holder.BorderSizePixel = 0
		holder.Size = UDim2.new(2.006, 0, 0.85, 0)
		holder.Position = UDim2.new(0, 0, 0, 35)
		holder.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		holder.CanvasSize = UDim2.new(0, 0, 0, 0)
		holder.ScrollBarThickness = 0
		holder.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

		scroll.Name = "scroll"
		scroll.Parent = holder
		scroll.Active = true
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		scroll.BackgroundTransparency = 1.000
		scroll.BorderColor3 = Color3.fromRGB(255, 255, 255)
		scroll.BorderSizePixel = 0
		scroll.ClipsDescendants = false
		scroll.Size = UDim2.new(0, 175, 0, 250)
		scroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		scroll.CanvasSize = UDim2.new(0.25, 0, 0, 0)
		scroll.ScrollBarThickness = 0
		scroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		
		local mc = {}
		
		local modules = {}
		
		local dummy_frame = Instance.new("Frame", nil)
		dummy_frame.Position = UDim2.new(0, 0, 0, -35)
		
		local current_settings_tab = {
			tab = -1,
			mod = -1,
			open = false,
			show = function()end,
			hide = function()end;
		}
		
		function mc:module(m_name, no_toggle)
			local module = Instance.new("Frame")
			local button = Instance.new("TextButton")
			local keybind = Instance.new("Frame")
			local body = Instance.new("ImageLabel")
			local key = Instance.new("TextButton")
			local dots_click = Instance.new("TextButton")
			local dot3 = Instance.new("TextLabel")
			local dot2 = Instance.new("TextLabel")
			local dot1 = Instance.new("TextLabel")

			module.Name = m_name
			module.Parent = scroll
			module.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			module.BackgroundTransparency = 1.000
			module.BorderColor3 = Color3.fromRGB(255, 255, 255)
			module.BorderSizePixel = 0
			module.Size = UDim2.new(1, 0, 0, 30)
			
			local previous = modules[#modules]
			module.Position = UDim2.new(0, 0, 0, ((previous and previous.mod) or dummy_frame).Position.Y.Offset + 35)
			
			local current_idx = #modules + 1
			modules[current_idx] = {
				origin_pos = module.Position,
				mod = module;
			}
			
			button.Name = "button"
			button.Parent = module
			button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			button.BackgroundTransparency = 1.000
			button.BorderColor3 = Color3.fromRGB(255, 255, 255)
			button.BorderSizePixel = 0
			button.Position = UDim2.new(0.0571429022, 0, 0, 0)
			button.Size = UDim2.new(0.599999964, 0, 1, 0)
			button.Font = Enum.Font.Gotham
			button.Text = m_name
			button.TextColor3 = Color3.fromRGB(200, 200, 200)
			button.TextSize = 15.000
			button.TextWrapped = true
			button.TextXAlignment = Enum.TextXAlignment.Left

			keybind.Name = "keybind"
			keybind.Parent = module
			keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			keybind.BackgroundTransparency = 1.000
			keybind.BorderColor3 = Color3.fromRGB(255, 255, 255)
			keybind.BorderSizePixel = 0
			keybind.Position = UDim2.new(0.657142878, 0, 0, 0)
			keybind.Size = UDim2.new(0, 30, 0, 30)

			body.Name = "body"
			body.Parent = keybind
			body.AnchorPoint = Vector2.new(0.5, 0.5)
			body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			body.BackgroundTransparency = 1.000
			body.BorderColor3 = Color3.fromRGB(255, 255, 255)
			body.BorderSizePixel = 0
			body.Position = UDim2.new(0.5, 0, 0.5, 0)
			body.Size = UDim2.new(1, -5, 1, -5)
			body.Image = "rbxassetid://3570695787"
			body.ImageColor3 = Color3.fromRGB(40, 39, 40)
			body.ScaleType = Enum.ScaleType.Slice
			body.SliceCenter = Rect.new(100, 100, 100, 100)
			body.SliceScale = 0.075

			key.Name = "key"
			key.Parent = body
			key.Active = false
			key.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			key.BackgroundTransparency = 1.000
			key.BorderColor3 = Color3.fromRGB(255, 255, 255)
			key.BorderSizePixel = 0
			key.Selectable = false
			key.Size = UDim2.new(1, 0, 1, 0)
			key.Font = Enum.Font.Gotham
			key.Text = "..."
			key.TextColor3 = Color3.fromRGB(200, 200, 200)
			key.TextSize = 16.000
			key.TextWrapped = true
			key.MouseButton1Click:Connect(function()
				local m_key = get_keybind()
				
				if m_key == -2 then
					library.json[m_name].keybind = nil
					key.Text = "..."
					
					return save()
				end
				
				if m_key == nil then return end
				
				key.Text = m_key.Name

				library.json[m_name].keybind = m_key

				save()
			end)
			
			dots_click.Name = "dots_click"
			dots_click.Visible = false
			dots_click.Parent = module
			dots_click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			dots_click.BackgroundTransparency = 1.000
			dots_click.BorderColor3 = Color3.fromRGB(255, 255, 255)
			dots_click.BorderSizePixel = 0
			dots_click.Position = UDim2.new(0.823285699, 0, 0, 0)
			dots_click.Size = UDim2.new(0, 30, 0, 30)
			dots_click.Font = Enum.Font.SourceSans
			dots_click.Text = ""
			dots_click.TextColor3 = Color3.fromRGB(255, 255, 255)
			dots_click.TextSize = 1.000
			dots_click.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)

			dot3.Name = "dot3"
			dot3.Parent = dots_click
			dot3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			dot3.BackgroundTransparency = 1.000
			dot3.BorderColor3 = Color3.fromRGB(255, 255, 255)
			dot3.BorderSizePixel = 0
			dot3.Position = UDim2.new(5.08626329e-07, 0, 0, 0)
			dot3.Size = UDim2.new(0, 30, 0, 29)
			dot3.Font = Enum.Font.Code
			dot3.Text = "."
			dot3.TextColor3 = Color3.fromRGB(175, 175, 175)
			dot3.TextSize = 30.000

			dot2.Name = "dot2"
			dot2.Parent = dots_click
			dot2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			dot2.BackgroundTransparency = 1.000
			dot2.BorderColor3 = Color3.fromRGB(255, 255, 255)
			dot2.BorderSizePixel = 0
			dot2.Position = UDim2.new(5.08626329e-07, 0, 0, 0)
			dot2.Size = UDim2.new(0, 30, 0, 15)
			dot2.Font = Enum.Font.Code
			dot2.Text = "."
			dot2.TextColor3 = Color3.fromRGB(175, 175, 175)
			dot2.TextSize = 30.000

			dot1.Name = "dot1"
			dot1.Parent = dots_click
			dot1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			dot1.BackgroundTransparency = 1.000
			dot1.BorderColor3 = Color3.fromRGB(255, 255, 255)
			dot1.BorderSizePixel = 0
			dot1.Position = UDim2.new(5.08626329e-07, 0, 0, 0)
			dot1.Size = UDim2.new(0, 30, 0, 1)
			dot1.Font = Enum.Font.Code
			dot1.Text = "."
			dot1.TextColor3 = Color3.fromRGB(175, 175, 175)
			dot1.TextSize = 30.000

			local module_running = Instance.new("Frame")
			local m_running_name = Instance.new("TextLabel")

			module_running.Name = "module_running"
			module_running.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			module_running.BackgroundTransparency = 1.000
			module_running.BorderColor3 = Color3.fromRGB(255, 255, 255)
			module_running.BorderSizePixel = 0
			module_running.Size = UDim2.new(0, 200, 0, 30)

			m_running_name.Name = "m_running_name"
			m_running_name.Text = m_name
			m_running_name.Parent = module_running
			m_running_name.AnchorPoint = Vector2.new(0.5, 0.5)
			m_running_name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			m_running_name.BackgroundTransparency = 1.000
			m_running_name.BorderColor3 = Color3.fromRGB(255, 255, 255)
			m_running_name.BorderSizePixel = 0
			m_running_name.Position = UDim2.new(0.45, 0, 0.55, 0)
			m_running_name.Size = UDim2.new(1, 0, 1, 0)
			m_running_name.Font = Enum.Font.Gotham
			m_running_name.TextColor3 = Color3.fromRGB(255, 255, 255)
			m_running_name.TextSize = 20.000
			m_running_name.TextXAlignment = Enum.TextXAlignment.Right
			
			local settings_frame = Instance.new("Frame")

			settings_frame.Name = "settings"
			settings_frame.Parent = module
			settings_frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			settings_frame.BackgroundTransparency = 1.000
			settings_frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
			settings_frame.BorderSizePixel = 0
			settings_frame.ClipsDescendants = true
			settings_frame.Position = UDim2.new(0, 0, 1, 0)
			settings_frame.Size = UDim2.new(0, 175, 0, 0)
			
			local text_colors = {
				[false] = Color3.fromRGB(175, 175, 175),
				[true] = Color3.fromRGB(15, 175, 50);
			}

			library.json[m_name] = library.json[m_name] or {
				toggled = false,
				keybind = nil,
				callback = nil,
				settings = {};
			}
			
			do -- read saved keybind
				local bind = library.json[m_name].keybind
				if bind then
					keybind.Visible = true

					key.Text = bind.Name
				end
			end
			
			local function off()
				button.TextColor3 = text_colors[false]

				module_running.Parent = nil
				
				local func = (library.json[m_name].callback or function()end)
				func(false)--pcall(func, false)
			end
			
			local function on()
				
				button.TextColor3 = text_colors[true]
				module_running.Parent = running
				
				local func = (library.json[m_name].callback or function()end)
				func(true)--pcall(func, true)
			end
			
			local function toggle()
				if no_toggle then
					(library.json[m_name].callback or function()end)()
					
					return
				end
				
				library.json[m_name].toggled = not library.json[m_name].toggled

				local f = (library.json[m_name].toggled and on) or off
				
				f()
					
				save()
			end

			uis.InputBegan:Connect(function(inp, gmp)
				if gmp then return end

				if inp.KeyCode == library.json[m_name].keybind and not visible then
					toggle()
				end
			end)

			button.MouseButton1Click:Connect(toggle)

			local m = {settings = library.json[m_name].settings}

			function m:callback(func) -- should only be called once so no problem
				library.json[m_name].callback = func

				if library.json[m_name].toggled then
					on()
				end
			end
			
			do
				local setting_hidden = UDim2.new(0, 0, 0, -35)
				local settings_table = {}
				
				local t_info = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
				
				dots_click.MouseButton1Click:Connect(function()
					if current_settings_tab.tab == current_tab_idx and current_settings_tab.mod ~= current_idx then
						current_settings_tab.hide()
					end -- toggle current module
					
					if current_settings_tab.tab == current_tab_idx and current_settings_tab.mod == current_idx then
						if current_settings_tab.open then
							return current_settings_tab.hide()
						end
						
						return current_settings_tab.show();
					end -- already initialized, simply toggle
					
					current_settings_tab = {
						tab = current_tab_idx,
						mod = current_idx,
						open = false,
						show = function()end,
						hide = function()end;
					}

					local y_size = 35 * #settings_table
					
					function current_settings_tab.show()
						for idx = (current_idx + 1), #modules do -- iterate from next module
							local val = modules[idx]

							ts:Create(val.mod, t_info, {
								Position = UDim2.new(0, 0, 0, y_size + val.origin_pos.Y.Offset)
							}):Play()
						end
						
						for idx = 1, #settings_table do
							local val = settings_table[idx]
							
							ts:Create(val, t_info, {
								Position = UDim2.new(0, 0, 0, 35 * (idx - 1))
							}):Play()
						end
						
						current_settings_tab.open = true
					end
					
					function current_settings_tab.hide()
						for idx = (current_idx + 1), #modules do -- iterate from next module
							local val = modules[idx]
							
							ts:Create(val.mod, t_info, {
								Position = val.origin_pos
							}):Play()
						end
						
						for idx = 1, #settings_table do
							local val = settings_table[idx]

							ts:Create(val, t_info, {
								Position = setting_hidden
							}):Play()
						end
						
						current_settings_tab.open = false
					end
					
					current_settings_tab.show()
				end)
				
				function m:slider(name, s_name, current_value, minimum, maximum, step)
					dots_click.Visible = true
					
					settings_frame.Size = UDim2.new(0, 175, 0, settings_frame.Size.Y.Offset + 35)

					local slider_setting = Instance.new("Frame")
					local name_label = Instance.new("TextLabel")
					local min = Instance.new("TextLabel")
					local max = Instance.new("TextLabel")
					local slider = Instance.new("Frame")
					local bar = Instance.new("Frame")
					local ball = Instance.new("ImageLabel")
					local current = Instance.new("TextBox")
					local click = Instance.new("TextButton")
					
					settings_table[#settings_table + 1] = slider_setting
					
					slider_setting.Name = "slider_setting"
					slider_setting.Parent = settings_frame
					slider_setting.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
					slider_setting.BackgroundTransparency = 0.800
					slider_setting.BorderColor3 = Color3.fromRGB(255, 255, 255)
					slider_setting.BorderSizePixel = 0
					slider_setting.Size = UDim2.new(0, 175, 0, 30)
					slider_setting.Position = setting_hidden
					slider_setting.ZIndex = 3

					name_label.Name = "name_label"
					name_label.Parent = slider_setting
					name_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					name_label.BackgroundTransparency = 1.000
					name_label.BorderColor3 = Color3.fromRGB(255, 255, 255)
					name_label.BorderSizePixel = 0
					name_label.Size = UDim2.new(0, 125, 0, 15)
					name_label.ZIndex = 3
					name_label.Font = Enum.Font.Gotham
					name_label.Text = name
					name_label.TextColor3 = Color3.fromRGB(255, 255, 255)
					name_label.TextSize = 14.000

					min.Name = "min"
					min.Parent = slider_setting
					min.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					min.BackgroundTransparency = 1.000
					min.BorderColor3 = Color3.fromRGB(255, 255, 255)
					min.BorderSizePixel = 0
					min.Position = UDim2.new(0.00600000005, 0, 0.5, 0)
					min.Size = UDim2.new(0, 25, 0, 15)
					min.ZIndex = 3
					min.Font = Enum.Font.Gotham
					min.Text = tostring(minimum)
					min.TextColor3 = Color3.fromRGB(175, 175, 175)
					min.TextSize = 12.000

					max.Name = "max"
					max.Parent = slider_setting
					max.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					max.BackgroundTransparency = 1.000
					max.BorderColor3 = Color3.fromRGB(255, 255, 255)
					max.BorderSizePixel = 0
					max.Position = UDim2.new(0.832948565, 0, 0.5, 0)
					max.Size = UDim2.new(0, 25, 0, 15)
					max.ZIndex = 3
					max.Font = Enum.Font.Gotham
					max.Text = tostring(maximum)
					max.TextColor3 = Color3.fromRGB(175, 175, 175)
					max.TextSize = 12.000

					slider.Name = "slider"
					slider.Parent = slider_setting
					slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					slider.BackgroundTransparency = 1.000
					slider.BorderColor3 = Color3.fromRGB(255, 255, 255)
					slider.BorderSizePixel = 0
					slider.Position = UDim2.new(0.159999996, 0, 0.5, 0)
					slider.Size = UDim2.new(0, 115, 0, 15)
					slider.ZIndex = 2

					bar.Name = "bar"
					bar.Parent = slider
					bar.AnchorPoint = Vector2.new(0.5, 0.5)
					bar.BackgroundColor3 = Color3.fromRGB(116, 116, 116)
					bar.BorderColor3 = Color3.fromRGB(255, 255, 255)
					bar.BorderSizePixel = 0
					bar.Position = UDim2.new(0.5, 0, 0.5, 0)
					bar.Size = UDim2.new(1, 0, 0, 2)
					bar.ZIndex = 2

					ball.Name = "ball"
					ball.Parent = slider
					ball.AnchorPoint = Vector2.new(0, 0.5)
					ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					ball.BackgroundTransparency = 1.000
					ball.BorderColor3 = Color3.fromRGB(255, 255, 255)
					ball.BorderSizePixel = 0
					ball.Position = UDim2.new(0, 0, 0.5, 0)
					ball.Size = UDim2.new(0, 10, 0, 10)
					ball.ZIndex = 2
					ball.Image = "rbxassetid://3570695787"
					ball.ImageColor3 = Color3.fromRGB(0, 170, 255)
					ball.ScaleType = Enum.ScaleType.Slice
					ball.SliceCenter = Rect.new(100, 100, 100, 100)

					click.Name = "click"
					click.Parent = ball
					click.AnchorPoint = Vector2.new(0.5, 0.5)
					click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					click.BackgroundTransparency = 1.000
					click.BorderColor3 = Color3.fromRGB(255, 255, 255)
					click.BorderSizePixel = 0
					click.Position = UDim2.new(0.5, 0, 0.5, 0)
					click.Size = UDim2.new(2, 0, 2, 0)
					click.ZIndex = 2
					click.Font = Enum.Font.SourceSans
					click.Text = ""
					click.TextColor3 = Color3.fromRGB(0, 0, 0)
					click.TextSize = 1.000

					current.Name = "current"
					current.Parent = slider_setting
					current.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					current.BackgroundTransparency = 1.000
					current.BorderColor3 = Color3.fromRGB(255, 255, 255)
					current.BorderSizePixel = 0
					current.Position = UDim2.new(0.626666665, 0, 0, 0)
					current.Size = UDim2.new(0, 47, 0, 15)
					current.ZIndex = 3
					current.Font = Enum.Font.Gotham
					current.Text = tostring(library.json[m_name].settings[s_name] or current_value)
					current.TextColor3 = Color3.fromRGB(200, 200, 200)
					current.TextSize = 12.000
					current.TextXAlignment = Enum.TextXAlignment.Right
					
					local function snap(number, factor)
						if factor == 0 then
							return number
						else
							return math_floor(number/factor+0.5)*factor
						end
					end

					local old_value = library.json[m_name].settings[s_name] or current_value
					
					local size_x = 105
					if library.json[m_name].settings[s_name] then
						ball.Position = UDim2.new(0, library.json[m_name].settings[s_name] / maximum * size_x, 0.5, 0)
					else
						library.json[m_name].settings[s_name] = current_value
					end
					
					current.Focused:Connect(function()
						old_value = current.Text
					end)
					
					current:GetPropertyChangedSignal("Text"):Connect(function()
						current.Text = current.Text:gsub('[^%d{.}]', '') -- thx devforum
					end)
					
					current.FocusLost:Connect(function(enter)
						if enter then
							local val = tonumber(current.Text)
							
							local pos = math_clamp(snap(val, step), 0, size_x)
							local value = math_clamp(snap(maximum / size_x * val, step), minimum, maximum)	
							
							current.Text = tostring(value)
							ball.Position = UDim2.new(0, pos, 0.5, 0)

							library.json[m_name].settings[s_name] = value
							save()
						else
							current.Text = tostring(old_value)
						end
					end)

					local held = false
					click.MouseButton1Down:Connect(function()
						held = true
					end)

					stepped:Connect(function()
						local pressed, found = uis:GetMouseButtonsPressed(), false

						for _, val in pairs(pressed) do
							if val.UserInputType.Name == "MouseButton1" then
								found = true

								break;
							end
						end

						if not found then
							held = false
						end

						if held then
							local x_mouse = mouse.X - slider.AbsolutePosition.X - (ball.AbsoluteSize.X / 2)

							local pos = math_clamp(snap(x_mouse, step), 0, size_x)
							local value = math_clamp(snap(maximum / size_x * x_mouse, step), minimum, maximum)

							current.Text = tostring(value)

							ball.Position = UDim2.new(0, pos, 0.5, 0)

							library.json[m_name].settings[s_name] = value
							save()
						end
					end)
				end

				function m:checkbox(name, s_name, checked)
					dots_click.Visible = true
					
					settings_frame.Size = UDim2.new(0, 175, 0, settings_frame.Size.Y.Offset + 35)
					
					local checkbox_setting = Instance.new("Frame")
					local name_label = Instance.new("TextLabel")
					local check = Instance.new("Frame")
					local body = Instance.new("ImageLabel")
					local ball = Instance.new("ImageLabel")
					local ball_click = Instance.new("TextButton")
					
					settings_table[#settings_table + 1] = checkbox_setting
					
					checkbox_setting.Name = "checkbox_setting"
					checkbox_setting.Parent = settings_frame
					checkbox_setting.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
					checkbox_setting.BackgroundTransparency = 0.800
					checkbox_setting.BorderColor3 = Color3.fromRGB(255, 255, 255)
					checkbox_setting.BorderSizePixel = 0
					checkbox_setting.Position = setting_hidden
					checkbox_setting.Size = UDim2.new(0, 175, 0, 30)
					checkbox_setting.ZIndex = 3

					name_label.Name = "name_label"
					name_label.Parent = checkbox_setting
					name_label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					name_label.BackgroundTransparency = 1.000
					name_label.BorderColor3 = Color3.fromRGB(255, 255, 255)
					name_label.BorderSizePixel = 0
					name_label.Size = UDim2.new(0, 90, 0, 30)
					name_label.ZIndex = 3
					name_label.Font = Enum.Font.Gotham
					name_label.Text = name
					name_label.TextColor3 = Color3.fromRGB(255, 255, 255)
					name_label.TextSize = 15.000

					check.Name = "check"
					check.Parent = checkbox_setting
					check.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					check.BackgroundTransparency = 1.000
					check.BorderColor3 = Color3.fromRGB(255, 255, 255)
					check.BorderSizePixel = 0
					check.Position = UDim2.new(0.600000024, 0, 0, 0)
					check.Size = UDim2.new(0, 60, 0, 30)
					check.ZIndex = 3

					body.Name = "body"
					body.Parent = check
					body.AnchorPoint = Vector2.new(0.5, 0.5)
					body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					body.BackgroundTransparency = 1.000
					body.BorderColor3 = Color3.fromRGB(255, 255, 255)
					body.BorderSizePixel = 0
					body.Position = UDim2.new(0.5, 0, 0.5, 0)
					body.Size = UDim2.new(1, -25, 1, -14)
					body.ZIndex = 3
					body.Image = "rbxassetid://3570695787"
					body.ImageColor3 = Color3.fromRGB(40, 40, 40)
					body.ScaleType = Enum.ScaleType.Slice
					body.SliceCenter = Rect.new(100, 100, 100, 100)
					body.SliceScale = 0.120

					ball.Name = "ball"
					ball.Parent = body
					ball.AnchorPoint = Vector2.new(0, 0.5)
					ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					ball.BackgroundTransparency = 1.000
					ball.BorderColor3 = Color3.fromRGB(255, 255, 255)
					ball.BorderSizePixel = 0
					ball.Position = UDim2.new(0, 3, 0.5, 0)
					ball.Size = UDim2.new(0, 12, 0, 12)
					ball.ZIndex = 3
					ball.Image = "rbxassetid://3570695787"
					ball.ImageColor3 = Color3.fromRGB(20, 20, 20)
					ball.ScaleType = Enum.ScaleType.Slice
					ball.SliceCenter = Rect.new(100, 100, 100, 100)
					ball.SliceScale = 0.120

					ball_click.Name = "ball_click"
					ball_click.Parent = ball
					ball_click.AnchorPoint = Vector2.new(0.5, 0.5)
					ball_click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					ball_click.BackgroundTransparency = 1.000
					ball_click.BorderColor3 = Color3.fromRGB(255, 255, 255)
					ball_click.BorderSizePixel = 0
					ball_click.Position = UDim2.new(0.5, 0, 0.5, 0)
					ball_click.Size = UDim2.new(2, 0, 2, 0)
					ball_click.ZIndex = 3
					ball_click.Font = Enum.Font.Gotham
					ball_click.Text = ""
					ball_click.TextColor3 = Color3.fromRGB(255, 255, 255)
					ball_click.TextSize = 1.000

					local on_pos = UDim2.new(0, 20, 0.5, 0)
					local on_bod_col = Color3.fromRGB(60, 60, 60)
					local on_ball_col = Color3.fromRGB(116, 116, 116)

					local off_pos = UDim2.new(0, 3, 0.5, 0)
					local off_bod_col = Color3.fromRGB(40, 40, 40)
					local off_ball_col = Color3.fromRGB(20, 20, 20)

					local t_info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local function toggle(tween_only)
						if tween_only ~= true then
							library.json[m_name].settings[s_name] = not library.json[m_name].settings[s_name]
							save()
						end

						ts:Create(ball, t_info, {
							Position = (library.json[m_name].settings[s_name] and on_pos) or off_pos,
							ImageColor3 = (library.json[m_name].settings[s_name] and on_ball_col) or off_ball_col;
						}):Play()

						ts:Create(body, t_info, {
							ImageColor3 = (library.json[m_name].settings[s_name] and on_bod_col) or off_bod_col;
						}):Play()
					end

					if checked then
						library.json[m_name].settings[s_name] = true
					end

					if library.json[m_name].settings[s_name] then
						toggle(true)
					else
						library.json[m_name].settings[s_name] = checked
					end

					ball_click.MouseButton1Click:Connect(toggle)
				end

			end -- settings
			
			return m
		end

		return mc
	end
	return mc
end

--return mc

do
	local main = library:create()
	
	local movement = main:tab("Movement")
	do
		local speed = movement:module("Walkspeed")
		
		do -- walkspeed
			local spoofed = nil;
			local connection = nil;

			local function step(step_time)
				local char = local_player.Character

				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")

					if hum then
						spoofed = spoofed or spoof.impersonator(hum, "WalkSpeed", hum.WalkSpeed)

						hum.WalkSpeed = speed.settings.speed_value
					end
				end
			end

			speed:slider("Value", "speed_value", 16, 1, 250, 0.5)

			speed:callback(function(toggle)
				if toggle then
					connection = stepped:Connect(step)
				end

				if not toggle then
					connection:Disconnect()

					spoofed:remove()
					spoofed = nil
				end
			end)
		end
		
		local jump = movement:module("Jumppower")
		do -- jump power
			local spoofed = nil;
			local connection = nil;

			local function step(step_time)
				local char = local_player.Character

				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")

					if hum then
						spoofed = spoofed or spoof.impersonator(hum, "JumpPower", hum.JumpPower)

						hum.JumpPower = jump.settings.jump_value
					end
				end
			end

			jump:slider("Value", "jump_value", 50, 1, 250, 1)

			jump:callback(function(toggle)
				if toggle then
					connection = stepped:Connect(step)
				end

				if not toggle then
					connection:Disconnect()

					spoofed:remove()
					spoofed = nil
				end
			end)
		end
		
		local bhop = movement:module("Bhop")
		do -- bunnyhop
			local key = Enum.KeyCode.Space
			
			local air = Enum.Material.Air
			
			local spoofed = nil;
			local connection = nil;
			
			local function step(ste_time)
				local char = local_player.Character

				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					local root = char:FindFirstChild("HumanoidRootPart")
					
					if hum and root and hum.FloorMaterial ~= air and uis:IsKeyDown(key) then
						root.Velocity = vector3_new(root.Velocity.X, hum.JumpPower, root.Velocity.Z)
					end
				end
			end
			
			bhop:callback(function(toggle)
				if toggle then
					connection = stepped:Connect(step)
				end
				
				if not toggle then
					connection:Disconnect()
				end
			end)
		end
		
		local velocity = movement:module("Velocity")
		do -- velocity
			local cas = game:GetService("ContextActionService")
			
			local cas_pass = Enum.ContextActionResult.Pass
			local cas_priority = Enum.ContextActionPriority.High.Value
			local uis_b = Enum.UserInputState.Begin
			
			local render_stepped = rs.RenderStepped
			
			local inp_handler = nil;
			local connection = nil;
			local spoofed = nil;

			local key_states = {
				["W"] = 0,
				["A"] = 0,
				["S"] = 0,
				["D"] = 0,
				["E"] = 0,
				["Q"] = 0;
			}

			local function step(step_time)
				local char = local_player.Character

				if char then
					local root = char:FindFirstChild("HumanoidRootPart")
					
					if root then
						spoofed = spoofed or spoof.impersonator(root, "Velocity", root.Velocity)

						local r_vec = (key_states.D - key_states.A)
						local l_vec = (key_states.W - key_states.S)
						local u_vec = (key_states.E - key_states.Q)

						local look_vector = root.CFrame.LookVector * velocity.settings.velocity_mult
						local right_vector = root.CFrame.RightVector * velocity.settings.velocity_mult
						local up_vector = root.CFrame.UpVector * velocity.settings.vertical_mult

						local calc_vec = vector3_new(
							(look_vector.X * l_vec) + (right_vector.X * r_vec),
							root.Velocity.Y + ((up_vector.Y * u_vec) / 10), 
							(look_vector.Z * l_vec) + (right_vector.Z * r_vec)
						)
						
						root.Velocity = calc_vec
					end
				end
			end

			velocity:slider("Multiplier", "velocity_mult", 16, 1, 250, 0.5)
			velocity:slider("Vertical", "vertical_mult", 6, 0, 64, 0.5)

			velocity:callback(function(toggle)
				if toggle then
					inp_handler = input.handle_keys(key_states)
					connection = render_stepped:Connect(step)
					
					for idx, val in pairs(key_states) do
						key_states[idx] = (uis:IsKeyDown(Enum.KeyCode[idx]) and 1) or 0
					end
				end

				if not toggle then
					inp_handler:remove()
					connection:Disconnect()

					spoofed:remove()
					spoofed = nil
					
					for idx, val in pairs(key_states) do
						key_states[idx] = 0
					end
				end
			end)
		end
		
		local tele_cam = movement:module("Teleport to camera", true)
		do
			local t_info = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
			local cam = workspace:FindFirstChildOfClass("Camera")
			
			tele_cam:callback(function()
				cam = cam or workspace:FindFirstChildOfClass("Camera")
				
				ts:Create(
					local_player.Character.HumanoidRootPart,
					t_info,
					{CFrame = cam.CFrame}
				):Play()
			end)
		end -- tele_cam
		
		local no_fall = movement:module("No Fall")
		do
			local connection = nil;
			local set = false
			
			local function step(step_time)
				local char = local_player.Character

				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")

					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, set)
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, set)
				end
			end
			
			no_fall:callback(function(toggle)
				if toggle then
					set = false
					
					connection = stepped:Connect(step)
				end
				
				if not toggle then
					connection:Disconnect()
					
					set = true
					step() -- set back to true
				end
			end)
		end -- no fall
	end -- movement
	
	local spoofing = main:tab("Spoofing")
	do
		local invisible = spoofing:module("Invisible")
		do
			local clone = nil;
			local character = nil;
			local root = nil;
			local clone_root = nil;
			
			invisible:callback(function(toggle)
				if toggle then
					character = local_player.Character
					character.Archivable = true

					clone = character:Clone()
					clone.Parent = workspace
					
					for idx, val in pairs(clone:GetDescendants()) do
						if val:IsA("BasePart") or val:IsA("MeshPart") then
							val.Transparency = 1
						end
					end

					root = character.HumanoidRootPart
					clone_root = clone.HumanoidRootPart
					
					clone_root.Parent = character
					
					root.RootPriority = root.RootPriority + 1
					root.Parent = clone
				end
				
				if not toggle then
					character = local_player.Character
					
					root.RootPriority = root.RootPriority - 1
					root.Parent = character
					
					clone_root:Destroy()
					clone:Destroy()
					
					root = nil
					clone = nil
				end
			end)
		end -- invisible
	end -- end
	
	local visuals = main:tab("Visuals")
	do
		local freecam = visuals:module("Freecam")
		do
			local move_speed = 1
			local sensitivity = 16

			local workspace = game:GetService("Workspace")
			local cas = game:GetService("ContextActionService")
			
			local cf_orientation = CFrame.fromOrientation

			local cas_sink = Enum.ContextActionResult.Sink
			local cas_priority = Enum.ContextActionPriority.High.Value
			local uis_b = Enum.UserInputState.Begin
			
			local render_stepped = rs.RenderStepped
			
			local cam_type = nil;
			local cam_cframe = nil;
			local cam_focus = nil;
			local guis_visible = nil;
			local spoofed = nil;
			
			local inp_handler = nil;
			local connection = nil;

			local pan_speed = vector2_new(1, 1) * (math.pi / sensitivity)
			local pan_gain = vector2_new(1, 1) * 8
			local focus_offset = cframe_new(0, 0, -16)
			local cam_pos = vector3_new();

			local delta = vector2_new()
			local cam_rot = vector2_new()
			local cam = workspace:FindFirstChildOfClass("Camera")

			local key_states = {
				["W"] = 0,
				["A"] = 0,
				["S"] = 0,
				["D"] = 0,
				["Q"] = 0,
				["E"] = 0,
				["Space"] = 0,
				["LeftShift"] = 0;
			}

			local cas_inputs = {
				look = "cam_handle_look",
				inputs = "cam_handle_inputs";
			}

			local function handle_look(name, state, obj)
				local delt = obj.Delta
				delta = vector2_new(-delt.Y, -delt.X)

				return cas_sink
			end


			local function handle_inputs(name, state, obj)
				key_states[obj.KeyCode.Name] = (state == uis_b and 1) or 0

				return cas_sink
			end

			local function step(step_time)
				cam = cam or workspace:FindFirstChildOfClass("Camera")
				spoofed = spoofed or spoof.lock(cam, "CFrame", cam.CFrame)
				
				pan_gain = vector2_new(1, 1) * freecam.settings.sens_mult
				
				local delt = pan_speed * delta
				delta = vector2_new()

				local fov_factor = math_sqrt(math_tan(math_rad(70/2))/math_tan(math_rad(cam.FieldOfView/2)))

				cam_rot = cam_rot + delt * pan_gain * (step_time / fov_factor)

				local r_vec = (key_states.D - key_states.A)
				local u_vec = ((key_states.E + key_states.Space) - (key_states.Q + key_states.LeftShift))
				local l_vec = (key_states.W - key_states.S)
				
				local right_vector = cam.CFrame.RightVector * freecam.settings.speed_mult
				local up_vector = cam.CFrame.UpVector * freecam.settings.speed_mult
				local look_vector = cam.CFrame.LookVector * freecam.settings.speed_mult
				
				local _cam_pos = cframe_new(cam_pos)
				
				cam.CFrame = cframe_new(
					_cam_pos.X + (look_vector.X * l_vec) + (right_vector.X * r_vec) + (up_vector.X * u_vec),
					_cam_pos.Y + (look_vector.Y * l_vec) + (right_vector.Y * r_vec) + (up_vector.Y * u_vec), 
					_cam_pos.Z + (look_vector.Z * l_vec) + (right_vector.Z * r_vec) + (up_vector.Z * u_vec)
				) * cf_orientation(cam_rot.x, cam_rot.y, 0)
				
				cam_pos = cam.CFrame.p
			end
			
			freecam:slider("Speed", "speed_mult", 0.1, 0.1, 8, 0.1)
			freecam:slider("Sensitivity", "sens_mult", 8, 2, 64, 2)
			
			freecam:callback(function(toggle)
				if toggle then -- turn on
					cam_cframe = cam.CFrame
					cam_focus = cam.Focus

					cam_pos = cam_cframe.p

					cam_type = cam.CameraType
					cam.CameraType = Enum.CameraType.Custom

					connection = render_stepped:Connect(step)

					cas:BindActionAtPriority(cas_inputs.look, handle_look, false, cas_priority, Enum.UserInputType.MouseMovement)
					cas:BindActionAtPriority(cas_inputs.inputs, handle_inputs, false, cas_priority, 
						Enum.KeyCode.W,
						Enum.KeyCode.A,
						Enum.KeyCode.S,
						Enum.KeyCode.D,
						Enum.KeyCode.Q,
						Enum.KeyCode.E,
						Enum.KeyCode.Space,
						Enum.KeyCode.LeftShift
					)
				end

				if not toggle then -- turn off
					connection:Disconnect()
					cas:UnbindAction(cas_inputs.look)
					cas:UnbindAction(cas_inputs.inputs)

					cam_pos = cam_cframe.p
					cam.CFrame = cam_cframe

					cam.Focus = cam_focus
					cam_focus = nil

					cam.CameraType = cam_type
					cam_type = nil
					
					spoofed:remove()
					spoofed = nil;
				end
			end)
		end -- freecam
		
		local esp = visuals:module("ESP")
		do
			local esp_table = {}
			
			
		end -- esp
	end -- visuals
	
	local world = main:tab("World")
	do
		local gravity = world:module("Gravity")
		do -- gravity
			local connection = nil;
			local old_grav = nil;
			
			local function step(step_time)
				workspace.Gravity = gravity.settings.g_val
			end
			
			gravity:slider("Value", "g_val", workspace.Gravity, 0, 300, 5)
			
			gravity:callback(function(toggle)
				if toggle then
					old_grav = workspace.Gravity
					
					connection = stepped:Connect(step)
				end
				
				if not toggle then
					connection:Disconnect()
					
					workspace.Gravity = old_grav
				end
			end)
		end
	end -- world
	
	local other = main:tab("Other")
	do
		local rejoin = other:module("Rejoin", true)
		do
			rejoin:callback(function()
				game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
			end)
		end -- rejoin
		
		--[[
		local antikick = other:module("AntiKick")
		do
			local namecall_old, nmc_undo = nil, nil;
			
			local hook_old, undo = nil, nil;
			
			function __namecall(...)
				local self = ...
				local idx = getnamecallmethod()

				if self == local_player and str_find(str_lower(idx), "kick") then
					wait(9e9)
				end

				return namecall_old(...)
			end
			
			function nullsub()end
			
			antikick:callback(function(toggle)
				if toggle then
					hook_old, undo = spoof.hook_func(local_player.Kick, nullsub)
					
					namecall_old, nmc_undo = spoof.hook_func(getrawmetatable(game).__namecall, __namecall)
				end
				
				if not toggle then
					nmc_undo()
					
					undo()
				end
			end)
		end -- antikick]]
	end -- other
end
