-- Anzeige: Welle, Countdown, Geld, Boss-Lebensleiste und Meldungen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local DUNKEL = Color3.fromRGB(20, 20, 25)

local HUD = {}

local function welleAnzeige(gui)
	local rahmen = UI.neu("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(260, 64),
		BackgroundColor3 = DUNKEL,
		BackgroundTransparency = 0.25,
		Parent = gui,
	}, { UI.ecken(10) })

	local titel = UI.neu("TextLabel", {
		Size = UDim2.new(1, 0, 0.55, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = rahmen,
	}, { UI.innenabstand(4) })

	local unter = UI.neu("TextLabel", {
		Position = UDim2.fromScale(0, 0.55),
		Size = UDim2.new(1, 0, 0.4, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		Parent = rahmen,
	}, { UI.innenabstand(2) })

	local function aktualisiere()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		local welle = ReplicatedStorage:GetAttribute("Welle") or 0
		local art = ReplicatedStorage:GetAttribute("WellenArt")

		if phase == "Welle" then
			local symbol = art == "Boss" and "💀 " or art == "Hunde" and "🐕 " or ""
			titel.Text = symbol .. "Welle " .. welle
			titel.TextColor3 = art == "Boss" and Color3.fromRGB(255, 90, 90) or Color3.new(1, 1, 1)
			unter.Text = "Zombies übrig: " .. (ReplicatedStorage:GetAttribute("ZombiesUebrig") or 0)
		elseif phase == "GameOver" then
			titel.Text = "GAME OVER"
			titel.TextColor3 = Color3.fromRGB(255, 70, 70)
			unter.Text = "Welle " .. welle .. " erreicht"
		else
			titel.Text = welle == 0 and "Macht euch bereit!" or "Pause"
			titel.TextColor3 = Color3.new(1, 1, 1)
			unter.Text = "Nächste Welle in " .. (ReplicatedStorage:GetAttribute("Countdown") or 0) .. "s"
		end
	end

	for _, name in { "Phase", "Welle", "WellenArt", "ZombiesUebrig", "Countdown" } do
		ReplicatedStorage:GetAttributeChangedSignal(name):Connect(aktualisiere)
	end
	aktualisiere()
end

local function geldAnzeige(gui)
	local label = UI.neu("TextLabel", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(190, 44),
		BackgroundColor3 = DUNKEL,
		BackgroundTransparency = 0.25,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 215, 80),
		Parent = gui,
	}, { UI.ecken(10), UI.innenabstand(6) })

	local geld = player:WaitForChild("leaderstats"):WaitForChild("Geld")
	local function aktualisiere()
		label.Text = "💰 " .. UI.zahl(geld.Value)
	end
	geld.Changed:Connect(aktualisiere)
	aktualisiere()
end

local function bossLeiste(gui)
	local rahmen = UI.neu("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 80),
		Size = UDim2.new(0.8, 0, 0, 40),
		BackgroundColor3 = DUNKEL,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = gui,
	}, { UI.ecken(8), UI.neu("UISizeConstraint", { MaxSize = Vector2.new(460, 40) }) })

	local balken = UI.neu("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundColor3 = Color3.fromRGB(190, 30, 30),
		BorderSizePixel = 0,
		Parent = rahmen,
	}, { UI.ecken(6) })

	local text = UI.neu("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4,
		ZIndex = 2,
		Parent = rahmen,
	}, { UI.innenabstand(6) })

	RunService.Heartbeat:Connect(function()
		local boss, bossHum
		for _, model in CollectionService:GetTagged("Boss") do
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and model:IsDescendantOf(workspace) then
				boss, bossHum = model, hum
				break
			end
		end

		rahmen.Visible = boss ~= nil
		if boss then
			local anteil = math.clamp(bossHum.Health / bossHum.MaxHealth, 0, 1)
			balken.Size = UDim2.new(anteil, -8, 1, -8)
			text.Text = "💀 " .. (boss:GetAttribute("BossName") or "Boss") .. "  " .. UI.zahl(bossHum.Health) .. " / " .. UI.zahl(bossHum.MaxHealth)
		end
	end)
end

local function meldungen(gui)
	local label = UI.neu("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.9, 0, 0, 50),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Parent = gui,
	}, { UI.neu("UITextSizeConstraint", { MaxTextSize = 42 }) })

	local zaehler = 0
	Remotes.Notify.OnClientEvent:Connect(function(text, farbe)
		zaehler += 1
		local meine = zaehler
		label.Text = text
		label.TextColor3 = farbe or Color3.new(1, 1, 1)
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.3
		task.delay(3, function()
			if meine == zaehler then
				TweenService:Create(label, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
	end)
end

function HUD.Start()
	local gui = UI.neu("ScreenGui", {
		Name = "iZombieHUD",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	welleAnzeige(gui)
	bossLeiste(gui)
	meldungen(gui)
	geldAnzeige(gui)
end

return HUD
