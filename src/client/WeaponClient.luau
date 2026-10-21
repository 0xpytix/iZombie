-- Steuerung der Waffen: Klicken = schießen/schlagen, bei Automatik-Waffen gedrückt halten.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponData = require(ReplicatedStorage.Shared.WeaponData)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local maus = player:GetMouse()

local WeaponClient = {}

local verbunden = {} -- Tools, die schon eingerichtet sind

local function schlagAnimation(tool)
	local normal = tool.Grip
	tool.Grip = normal * CFrame.Angles(math.rad(70), 0, 0)
	task.delay(0.15, function()
		if tool.Parent then
			tool.Grip = normal
		end
	end)
end

local function einrichten(tool)
	if verbunden[tool] or not tool:IsA("Tool") then
		return
	end
	local daten = WeaponData.NachId[tool:GetAttribute("Waffe") or ""]
	if not daten then
		return
	end
	verbunden[tool] = true

	local feuert = false
	local letzter = 0

	local function angreifen()
		local jetzt = os.clock()
		if jetzt - letzter < daten.Cooldown then
			return
		end
		letzter = jetzt
		Remotes.Fire:FireServer(daten.Id, maus.Hit.Position)
		if daten.Typ == "Nahkampf" then
			schlagAnimation(tool)
		end
	end

	tool.Activated:Connect(function()
		if not daten.Automatik then
			angreifen()
			return
		end
		if feuert then
			return
		end
		feuert = true
		while feuert and tool.Parent == player.Character do
			angreifen()
			task.wait(daten.Cooldown)
		end
		feuert = false
	end)

	tool.Deactivated:Connect(function()
		feuert = false
	end)
	tool.Unequipped:Connect(function()
		feuert = false
	end)
	tool.Destroying:Connect(function()
		verbunden[tool] = nil
	end)
end

local function beobachte(behaelter)
	for _, kind in behaelter:GetChildren() do
		einrichten(kind)
	end
	behaelter.ChildAdded:Connect(einrichten)
end

function WeaponClient.Start()
	local function neuerCharakter(char)
		beobachte(char)
		beobachte(player:WaitForChild("Backpack"))
	end
	player.CharacterAdded:Connect(neuerCharakter)
	if player.Character then
		neuerCharakter(player.Character)
	end
end

return WeaponClient
