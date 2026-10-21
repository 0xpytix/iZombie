-- Waffen-Shop: Knopf unten rechts oder Taste B.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.UI)
local WeaponData = require(ReplicatedStorage.Shared.WeaponData)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer

local DUNKEL = Color3.fromRGB(20, 20, 25)
local ZEILE = Color3.fromRGB(38, 38, 46)
local GRUEN = Color3.fromRGB(60, 170, 80)
local ROT = Color3.fromRGB(150, 60, 60)
local GRAU = Color3.fromRGB(80, 80, 90)

local Shop = {}

local function beschreibung(daten)
	local teile = { daten.Typ, "Schaden " .. daten.Schaden .. (daten.Kugeln and (" ×" .. daten.Kugeln) or "") }
	if daten.Automatik then
		table.insert(teile, "Automatik")
	end
	table.insert(teile, string.format("%.1f/s", 1 / daten.Cooldown))
	return table.concat(teile, " · ")
end

function Shop.Start()
	local geld = player:WaitForChild("leaderstats"):WaitForChild("Geld")

	local gui = UI.neu("ScreenGui", {
		Name = "iZombieShop",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local knopf = UI.neu("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.fromOffset(150, 44),
		BackgroundColor3 = Color3.fromRGB(200, 140, 30),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "🛒 Shop [B]",
		Parent = gui,
	}, { UI.ecken(10), UI.innenabstand(6) })

	local fenster = UI.neu("Frame", {
		Name = "Fenster",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.75),
		BackgroundColor3 = DUNKEL,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = gui,
	}, { UI.ecken(12), UI.neu("UISizeConstraint", { MaxSize = Vector2.new(480, 500) }) })

	UI.neu("TextLabel", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -70, 0, 36),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "Waffen-Shop",
		Parent = fenster,
	})

	local schliessen = UI.neu("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = ROT,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "X",
		Parent = fenster,
	}, { UI.ecken(8) })

	local liste = UI.neu("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 52),
		Size = UDim2.new(1, -20, 1, -94),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = fenster,
	}, { UI.neu("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local status = UI.neu("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -8),
		Size = UDim2.new(1, -28, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		Text = "",
		Parent = fenster,
	})

	local eintraege = {}

	local function aktualisiere()
		for id, eintrag in eintraege do
			local kaufen = eintrag.knopf
			if player:GetAttribute("Waffe_" .. id) then
				kaufen.Text = "✔ Gekauft"
				kaufen.BackgroundColor3 = GRAU
				kaufen.AutoButtonColor = false
			else
				kaufen.Text = "💰 " .. UI.zahl(eintrag.daten.Preis)
				kaufen.BackgroundColor3 = geld.Value >= eintrag.daten.Preis and GRUEN or ROT
				kaufen.AutoButtonColor = true
			end
		end
	end

	for reihenfolge, daten in WeaponData.Liste do
		local zeile = UI.neu("Frame", {
			Size = UDim2.new(1, -8, 0, 58),
			BackgroundColor3 = ZEILE,
			LayoutOrder = reihenfolge,
			Parent = liste,
		}, { UI.ecken(8) })

		UI.neu("TextLabel", {
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -150, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.new(1, 1, 1),
			Text = daten.Name,
			Parent = zeile,
		})

		UI.neu("TextLabel", {
			Position = UDim2.fromOffset(10, 32),
			Size = UDim2.new(1, -150, 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(170, 170, 180),
			Text = beschreibung(daten),
			Parent = zeile,
		})

		local kaufen = UI.neu("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(126, 40),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			Parent = zeile,
		}, { UI.ecken(8), UI.innenabstand(6) })

		kaufen.Activated:Connect(function()
			if player:GetAttribute("Waffe_" .. daten.Id) then
				return
			end
			local ok, nachricht = Remotes.BuyWeapon:InvokeServer(daten.Id)
			status.Text = nachricht or ""
			status.TextColor3 = ok and Color3.fromRGB(120, 230, 120) or Color3.fromRGB(255, 110, 110)
			aktualisiere()
		end)

		eintraege[daten.Id] = { knopf = kaufen, daten = daten }
	end

	geld.Changed:Connect(aktualisiere)
	player.AttributeChanged:Connect(aktualisiere)
	aktualisiere()

	local function umschalten()
		fenster.Visible = not fenster.Visible
		status.Text = ""
	end
	knopf.Activated:Connect(umschalten)
	schliessen.Activated:Connect(umschalten)
	UserInputService.InputBegan:Connect(function(eingabe, verarbeitet)
		if not verarbeitet and eingabe.KeyCode == Enum.KeyCode.B then
			umschalten()
		end
	end)
end

return Shop
