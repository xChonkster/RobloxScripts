--[[
ORIGINAL AUTHOR

Ch0nky#9785 - 579306070040641546
]]--

-- < Aliases > --
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new
local Color3_new = Color3.new
local Color3_fromRGB = Color3.fromRGB
local CFrame_new = CFrame.new
local Instance_new = Instance.new
local table_insert = table.insert
local table_foreach = table.foreach
local table_remove = table.remove
local Drawing_new = Drawing.new

-- < Services > --
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Camera = Workspace:FindFirstChildOfClass("Camera")

-- < Misc > --
local RenderStepped = RunService.RenderStepped
local PartESPLibrary = {}
local WrappedParts = {}

function PartESPLibrary:AddPart(Part, Offset)
    --self:RemovePart(Part)
    WrappedParts[#WrappedParts + 1] = {
        ["Drawings"] = {
            ["Box"] = {
                ["Top"] = nil,
                ["Bottom"] = nil,
                ["Right"] = nil,
                ["Left"] = nil
            }
        },
        ["Offset"] = (Offset or Vector3_new(1, 1, 1)),
        ["Instance"] = Part,
    }
end

function PartESPLibrary:RemovePart(Part)
    for PartIndex, PartValue in pairs(WrappedParts) do
        if PartValue.Instance:GetFullName() == Part:GetFullName() and PartValue.Drawings.Top and PartValue.Drawings.Bottom and PartValue.Drawings.Right and PartValue.Drawings.Left then
            PartValue.Drawings.Top:Remove()
            PartValue.Drawings.Bottom:Remove()
            PartValue.Drawings.Right:Remove()
            PartValue.Drawings.Left:Remove()
            table_remove(WrappedParts, PartIndex)
        end
    end
end

function PartESPLibrary:GetRendererWaitTime()
    RenderStepped:Wait()
    RenderStepped:Wait()
    return true
end

local function create_drawing(class)
    return function(properties)
        local create = Drawing_new(class)
        for i,v in pairs(properties) do
            create[i] = v
        end
        return create
    end
end

local function get_instance_corners(part, offset)
	local corner_vertices = {
		{1, 1, -1},  --v1 - top front right
		{1, -1, -1}, --v2 - bottom front right
		{-1, -1, -1},--v3 - bottom front left
		{-1, 1, -1}, --v4 - top front left
		
		{1, 1, 1},  --v5 - top back right
		{1, -1, 1}, --v6 - bottom back right
		{-1, -1, 1},--v7 - bottom back left
		{-1, 1, 1}  --v8 - top back left
	}
	local vertices = {}
	local size = part.Size * offset
	for _, vector in pairs(corner_vertices) do
	    table_insert(vertices, (part.CFrame * CFrame_new(size .X/2 * vector[1], size .Y/2 * vector[2], size .Z/2 * vector[3])).Position)
	end
	return unpack(vertices)
end

local function position_to_screen(position)
    local screen_position, in_screen_bounds = Camera:WorldToViewportPoint(position)
    return Vector2_new(screen_position.X, screen_position.Y), in_screen_bounds
end

coroutine.resume(coroutine.create(function()
    while PartESPLibrary:GetRendererWaitTime() do
        local func, result = pcall(function()
            for PartIndex, PartValue in pairs(WrappedParts) do
                PartValue.Drawings.Box.Top = PartValue.Drawings.Box.Top or create_drawing("Quad")({
                    ["Visible"] = true,
                    ["Transparency"] = 1,
                    ["Thickness"] = 1,
                    ["Filled"] = false,
                    ["Color"] = Color3_fromRGB(255, 255, 255),
                })
                
                PartValue.Drawings.Box.Bottom = PartValue.Drawings.Box.Bottom or create_drawing("Quad")({
                    ["Visible"] = true,
                    ["Transparency"] = 1,
                    ["Thickness"] = 1,
                    ["Filled"] = false,
                    ["Color"] = Color3_fromRGB(255, 255, 255),
                })
                
                PartValue.Drawings.Box.Right = PartValue.Drawings.Box.Right or create_drawing("Quad")({
                    ["Visible"] = true,
                    ["Transparency"] = 1,
                    ["Thickness"] = 1,
                    ["Filled"] = false,
                    ["Color"] = Color3_fromRGB(255, 255, 255),
                })
                
                PartValue.Drawings.Box.Left = PartValue.Drawings.Box.Left or create_drawing("Quad")({
                    ["Visible"] = true,
                    ["Transparency"] = 1,
                    ["Thickness"] = 1,
                    ["Filled"] = false,
                    ["Color"] = Color3_fromRGB(255, 255, 255),
                })

                local 
                    top_front_right,
                    bottom_front_right,
                    bottom_front_left,
                    top_front_left,
                    top_back_right,
                    bottom_back_right,
                    bottom_back_left,
                    top_back_left
                = get_instance_corners(PartValue.Instance, PartValue.Offset)

                local scr_top_front_right, isb_top_front_right = position_to_screen(top_front_right)
                local scr_bottom_front_right, isb_bottom_front_right = position_to_screen(bottom_front_right)
                local scr_bottom_front_left, isb_bottom_front_left = position_to_screen(bottom_front_left)
                local scr_top_front_left, isb_top_front_left = position_to_screen(top_front_left)
                local scr_top_back_right, isb_top_back_right = position_to_screen(top_back_right)
                local scr_bottom_back_right, isb_bottom_back_right = position_to_screen(bottom_back_right)
                local scr_bottom_back_left, isb_bottom_back_left = position_to_screen(bottom_back_left)
                local scr_top_back_left, isb_top_back_left = position_to_screen(top_back_left)
                
                local Top = PartValue.Drawings.Box.Top
                local Bottom = PartValue.Drawings.Box.Bottom
                local Right = PartValue.Drawings.Box.Right
                local Left = PartValue.Drawings.Box.Left

                if (
                    isb_top_front_right and
                    isb_bottom_front_right and
                    isb_bottom_front_left and
                    isb_top_front_left and
                    isb_top_back_right and
                    isb_bottom_back_right and
                    isb_bottom_back_left and
                    isb_top_back_left
                ) then

                    Top["PointA"] = scr_top_back_right
                    Top["PointB"] = scr_top_back_left
                    Top["PointC"] = scr_top_front_left
                    Top["PointD"] = scr_top_front_right
                    Top["Visible"] = true

                    Bottom["PointA"] = scr_bottom_back_right
                    Bottom["PointB"] = scr_bottom_back_left
                    Bottom["PointC"] = scr_bottom_front_left
                    Bottom["PointD"] = scr_bottom_front_right
                    Bottom["Visible"] = true

                    Right["PointA"] = scr_top_back_right
                    Right["PointB"] = scr_bottom_back_right
                    Right["PointC"] = scr_bottom_front_right
                    Right["PointD"] = scr_top_front_right
                    Right["Visible"] = true

                    Left["PointA"] = scr_top_back_left
                    Left["PointB"] = scr_bottom_back_left
                    Left["PointC"] = scr_bottom_front_left
                    Left["PointD"] = scr_top_front_left
                    Left["Visible"] = true
                else
                    Top["Visible"] = false
                    Bottom["Visible"] = false
                    Right["Visible"] = false
                    Left["Visible"] = false
                end
            end
        end)
        
        if not func then warn(result) end
    end
end))

return PartESPLibrary
