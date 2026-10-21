-- Effekte, die nur beim Spieler gezeichnet werden: Schussspuren, Schadenszahlen, Boss-Stampfer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Fadenkreuz = require(script.Parent.Fadenkreuz)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local Effects = {}

local function effektTeil(groesse, farbe, cframe, transparenz)
	local teil = Instance.new("Part")
	teil.Anchored = true
	teil.CanCollide = false
	teil.CanQuery = false
	teil.CanTouch = false
	teil.CastShadow = false
	teil.Material = Enum.Material.Neon
	teil.Size = groesse
	teil.Color = farbe
	teil.CFrame = cframe
	teil.Transparency = transparenz or 0
	teil.Parent = workspace.CurrentCamera -- nur lokal sichtbar
	return teil
end

local function schuss(start, enden)
	for _, ende in enden do
		local laenge = (ende - start).Magnitude
		if laenge > 0.5 then
			local cframe = CFrame.lookAt(start, ende) * CFrame.new(0, 0, -laenge / 2)
			local spur = effektTeil(Vector3.new(0.08, 0.08, laenge), Color3.fromRGB(255, 220, 120), cframe, 0.2)
			Debris:AddItem(spur, 0.05)
		end
	end
end

local function treffer(position, schaden, kopfschuss)
	Fadenkreuz.Treffer(kopfschuss)
	local anker = effektTeil(Vector3.new(0.1, 0.1, 0.1), Color3.new(), CFrame.new(position), 1)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(80, 30)
	gui.AlwaysOnTop = true
	gui.StudsOffset = Vector3.new(math.random() - 0.5, 1, 0)
	gui.Parent = anker

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = tostring(schaden)
	label.TextColor3 = kopfschuss and Color3.fromRGB(255, 80, 60) or Color3.fromRGB(255, 240, 120)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui

	local info = TweenInfo.new(0.6)
	TweenService:Create(gui, info, { StudsOffset = gui.StudsOffset + Vector3.new(0, 2.5, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anker, 0.7)
end

local function bodenScheibe(position, durchmesser, farbe, transparenz)
	-- Zylinder liegen standardmäßig auf der Seite, deshalb um 90° drehen
	local cframe = CFrame.new(position - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local scheibe = effektTeil(Vector3.new(0.3, durchmesser, durchmesser), farbe, cframe, transparenz)
	scheibe.Shape = Enum.PartType.Cylinder
	return scheibe
end

-- Rote Fläche als Vorwarnung, bevor der Boss stampft
local function warnung(position, radius)
	local scheibe = bodenScheibe(position, radius * 2, Color3.fromRGB(255, 40, 40), 0.7)
	Debris:AddItem(scheibe, 0.8)
end

local function stampfen(position, radius)
	local ring = bodenScheibe(position, 2, Color3.fromRGB(255, 150, 60), 0.2)
	TweenService:Create(ring, TweenInfo.new(0.4), {
		Size = Vector3.new(0.3, radius * 2, radius * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.5)
end

local function rueckstoss(geschwindigkeit)
	local char = player.Character
	local wurzel = char and char:FindFirstChild("HumanoidRootPart")
	if wurzel then
		wurzel.AssemblyLinearVelocity = geschwindigkeit
	end
end

function Effects.Start()
	Remotes.Effect.OnClientEvent:Connect(function(art, ...)
		if art == "Schuss" then
			schuss(...)
		elseif art == "Treffer" then
			treffer(...)
		elseif art == "Warnung" then
			warnung(...)
		elseif art == "Stampfen" then
			stampfen(...)
		elseif art == "Rueckstoss" then
			rueckstoss(...)
		end
	end)
end

return Effects
