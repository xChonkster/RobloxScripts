game:GetService("Players").LocalPlayer.Idled:connect(function()
	game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),game:GetService("Workspace").CurrentCamera.CFrame)
	wait(1)
	game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),game:GetService("Workspace").CurrentCamera.CFrame)
	print("Prevented Kick(Idle) At " .. os.time())
end)