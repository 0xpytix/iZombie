-- Eigene Hotbar unten in der Mitte: 9 Felder mit 3D-Vorschau der Waffen.
-- Tasten 1-9 oder Klick zum Ausrüsten, nochmal drücken zum Wegstecken.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)
local WeaponData = require(ReplicatedStorage.Shared.WeaponData)

local player = Players.LocalPlayer

local FELDER = 9
local FELD_GROESSE = 60
local ABSTAND = 6
local FELD_FARBE = Color3.fromRGB(30, 32, 40)
local AKTIV_FARBE = Color3.fromRGB(55, 58, 70)

local TASTEN = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
	Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
	Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
}

local Hotbar = {}

-- Reihenfolge wie im Shop (Karambit zuerst, Minigun zuletzt)
local reihenfolge = {}
for index, daten in WeaponData.Liste do
	reihenfolge[daten.Id] = index
end

local function rang(tool)
	return reihenfolge[tool:GetAttribute("Waffe") or ""] or 1000
end

-- 3D-Vorschau einer Waffe in einem ViewportFrame
local function vorschau(tool, eltern)
	local ansicht = UI.neu("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 180),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
		Parent = eltern,
	})

	local kopie = tool:Clone()
	local modell = Instance.new("Model")
	for _, kind in kopie:GetChildren() do
		if kind:IsA("BasePart") then
			kind.Parent = modell
		end
	end
	kopie:Destroy()
	modell.Parent = ansicht

	local handle = modell:FindFirstChild("Handle")
	if not handle then
		return
	end

	-- Von der Seite und leicht von oben auf die Waffe schauen
	local mitte, groesse = modell:GetBoundingBox()
	local kamera = Instance.new("Camera")
	kamera.FieldOfView = 30
	local entfernung = groesse.Magnitude / (2 * math.tan(math.rad(kamera.FieldOfView / 2))) * 0.95
	local blick = (handle.CFrame.RightVector + handle.CFrame.UpVector * 0.35).Unit
	kamera.CFrame = CFrame.lookAt(mitte.Position + blick * entfernung, mitte.Position, handle.CFrame.UpVector)
	kamera.Parent = ansicht
	ansicht.CurrentCamera = kamera
end

function Hotbar.Start()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	local gui = UI.neu("ScreenGui", {
		Name = "iZombieHotbar",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local breite = FELDER * FELD_GROESSE + (FELDER - 1) * ABSTAND
	local leiste = UI.neu("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(breite, FELD_GROESSE),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.neu("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, ABSTAND),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Name der ausgerüsteten Waffe über der Hotbar
	local waffenName = UI.neu("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -FELD_GROESSE - 20),
		Size = UDim2.fromOffset(300, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4,
		TextTransparency = 1,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		Parent = gui,
	})

	local felder = {}
	for i = 1, FELDER do
		local feld = UI.neu("TextButton", {
			Size = UDim2.fromOffset(FELD_GROESSE, FELD_GROESSE),
			BackgroundColor3 = FELD_FARBE,
			BackgroundTransparency = 0.15,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = i,
			Parent = leiste,
		}, { UI.ecken(10) })

		local rand = UI.neu("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 2,
			Enabled = false,
			Parent = feld,
		})

		local inhalt = UI.neu("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = feld,
		}, { UI.innenabstand(6) })

		UI.neu("TextLabel", {
			Position = UDim2.new(0, 5, 1, -18),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0.5,
			Text = tostring(i),
			ZIndex = 2,
			Parent = feld,
		})

		felder[i] = { knopf = feld, rand = rand, inhalt = inhalt, tool = nil }
	end

	local tools = {}
	local letzteAusgeruestet = nil
	local namensZaehler = 0

	local function zeigeName(text)
		namensZaehler += 1
		local meins = namensZaehler
		waffenName.Text = text
		waffenName.TextTransparency = 0
		waffenName.TextStrokeTransparency = 0.4
		task.delay(1.5, function()
			if meins == namensZaehler then
				TweenService:Create(waffenName, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
	end

	local function aktualisiere()
		local char = player.Character
		local rucksack = player:FindFirstChildOfClass("Backpack")

		tools = {}
		for _, behaelter in { rucksack, char } do
			if behaelter then
				for _, kind in behaelter:GetChildren() do
					if kind:IsA("Tool") then
						table.insert(tools, kind)
					end
				end
			end
		end
		table.sort(tools, function(a, b)
			return rang(a) < rang(b)
		end)

		local ausgeruestet = char and char:FindFirstChildOfClass("Tool")
		for i, feld in felder do
			local tool = tools[i]
			-- Vorschau nur neu bauen, wenn sich das Tool im Feld geändert hat
			if feld.tool ~= tool then
				feld.inhalt:ClearAllChildren()
				UI.innenabstand(6).Parent = feld.inhalt
				if tool then
					vorschau(tool, feld.inhalt)
				end
				feld.tool = tool
			end
			local aktiv = tool ~= nil and tool == ausgeruestet
			feld.rand.Enabled = aktiv
			feld.knopf.BackgroundColor3 = aktiv and AKTIV_FARBE or FELD_FARBE
		end

		if ausgeruestet and ausgeruestet ~= letzteAusgeruestet then
			zeigeName(ausgeruestet.Name)
		end
		letzteAusgeruestet = ausgeruestet
	end

	local function waehle(index)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local tool = tools[index]
		if not hum or hum.Health <= 0 or not tool then
			return
		end
		if tool.Parent == char then
			hum:UnequipTools()
		else
			hum:EquipTool(tool)
		end
	end

	for i, feld in felder do
		feld.knopf.Activated:Connect(function()
			waehle(i)
		end)
	end

	UserInputService.InputBegan:Connect(function(eingabe, verarbeitet)
		if verarbeitet then
			return
		end
		local index = table.find(TASTEN, eingabe.KeyCode)
		if index then
			waehle(index)
		end
	end)

	-- Mausrad: nächste / vorherige Waffe
	UserInputService.InputChanged:Connect(function(eingabe, verarbeitet)
		if verarbeitet or eingabe.UserInputType ~= Enum.UserInputType.MouseWheel or #tools == 0 then
			return
		end
		local char = player.Character
		local aktuell = char and table.find(tools, char:FindFirstChildOfClass("Tool")) or 0
		local richtung = eingabe.Position.Z > 0 and -1 or 1
		local neu = (aktuell - 1 + richtung) % #tools + 1
		if neu ~= aktuell then
			waehle(neu)
		end
	end)

	-- Auf Änderungen in Rucksack und Charakter reagieren
	local verbindungen = {}
	local function beobachte()
		for _, verbindung in verbindungen do
			verbindung:Disconnect()
		end
		verbindungen = {}
		for _, behaelter in { player:FindFirstChildOfClass("Backpack"), player.Character } do
			if behaelter then
				table.insert(verbindungen, behaelter.ChildAdded:Connect(aktualisiere))
				table.insert(verbindungen, behaelter.ChildRemoved:Connect(aktualisiere))
			end
		end
		aktualisiere()
	end

	player.CharacterAdded:Connect(function()
		player:WaitForChild("Backpack")
		beobachte()
	end)
	player.ChildAdded:Connect(function(kind)
		if kind:IsA("Backpack") then
			beobachte()
		end
	end)
	beobachte()
end

return Hotbar
