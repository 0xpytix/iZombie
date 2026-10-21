-- Anzeige: Welle oben, Leben/Geld/Kills unten links, Boss-Leiste, Meldungen, roter Treffer-Blitz.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local UI = require(script.Parent.UI)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer

local DUNKEL = Color3.fromRGB(16, 16, 20)
local RAND = Color3.fromRGB(70, 70, 80)
local WEISS = Color3.new(1, 1, 1)
local GRAU = Color3.fromRGB(180, 180, 190)
local GRUEN = Color3.fromRGB(80, 210, 100)
local GELB = Color3.fromRGB(240, 200, 60)
local ROT = Color3.fromRGB(220, 50, 50)

local HUD = {}

local function panel(eigenschaften)
	local rahmen = UI.neu("Frame", eigenschaften, {
		UI.ecken(10),
		UI.neu("UIStroke", { Color = RAND, Thickness = 1.5, Transparency = 0.3 }),
	})
	rahmen.BackgroundColor3 = DUNKEL
	rahmen.BackgroundTransparency = 0.2
	return rahmen
end

local function leiste(eltern, position, groesse, farbe)
	local hintergrund = UI.neu("Frame", {
		Position = position,
		Size = groesse,
		BackgroundColor3 = Color3.fromRGB(40, 40, 48),
		BorderSizePixel = 0,
		Parent = eltern,
	}, { UI.ecken(6) })
	local fuellung = UI.neu("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = farbe,
		BorderSizePixel = 0,
		Parent = hintergrund,
	}, { UI.ecken(6) })
	return hintergrund, fuellung
end

-- Oben: Welle + Fortschritt ------------------------------------------------------

local function welleAnzeige(gui)
	local rahmen = panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(280, 78),
		Parent = gui,
	})

	local titel = UI.neu("TextLabel", {
		Position = UDim2.fromOffset(0, 4),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Font = Enum.Font.Creepster,
		TextScaled = true,
		TextColor3 = WEISS,
		TextStrokeTransparency = 0.5,
		Parent = rahmen,
	})

	local unter = UI.neu("TextLabel", {
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextScaled = true,
		TextColor3 = GRAU,
		Parent = rahmen,
	})

	local _, fortschritt = leiste(rahmen, UDim2.new(0, 14, 1, -14), UDim2.new(1, -28, 0, 6), ROT)

	local function aktualisiere()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		local welle = ReplicatedStorage:GetAttribute("Welle") or 0
		local art = ReplicatedStorage:GetAttribute("WellenArt")

		if phase == "Welle" then
			local uebrig = ReplicatedStorage:GetAttribute("ZombiesUebrig") or 0
			local gesamt = math.max(ReplicatedStorage:GetAttribute("ZombiesGesamt") or 1, uebrig, 1)
			titel.Text = (art == "Boss" and "BOSS-WELLE " or art == "Hunde" and "HUNDE-WELLE " or "WELLE ") .. welle
			titel.TextColor3 = art == "Boss" and ROT or art == "Hunde" and Color3.fromRGB(255, 170, 60) or WEISS
			unter.Text = "🧟 " .. uebrig .. " übrig"
			fortschritt.BackgroundColor3 = ROT
			fortschritt.Size = UDim2.fromScale(uebrig / gesamt, 1)
		elseif phase == "GameOver" then
			titel.Text = "GAME OVER"
			titel.TextColor3 = ROT
			unter.Text = "Welle " .. welle .. " erreicht"
			fortschritt.Size = UDim2.fromScale(0, 1)
		else
			local countdown = ReplicatedStorage:GetAttribute("Countdown") or 0
			local laenge = math.max(ReplicatedStorage:GetAttribute("PauseLaenge") or 1, 1)
			titel.Text = welle == 0 and "MACHT EUCH BEREIT" or "PAUSE"
			titel.TextColor3 = WEISS
			unter.Text = "Nächste Welle in " .. countdown .. "s  ·  Shop: B"
			fortschritt.BackgroundColor3 = GELB
			fortschritt.Size = UDim2.fromScale(countdown / laenge, 1)
		end
	end

	for _, name in { "Phase", "Welle", "WellenArt", "ZombiesUebrig", "ZombiesGesamt", "Countdown" } do
		ReplicatedStorage:GetAttributeChangedSignal(name):Connect(aktualisiere)
	end
	aktualisiere()
end

-- Unten links: Leben, Geld, Kills ----------------------------------------------------

local function spielerAnzeige(gui)
	local rahmen = panel({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(250, 84),
		Parent = gui,
	})

	-- Lebensleiste
	local lebenHintergrund, lebenFuellung = leiste(rahmen, UDim2.fromOffset(10, 10), UDim2.new(1, -20, 0, 26), GRUEN)
	local lebenText = UI.neu("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = WEISS,
		TextStrokeTransparency = 0.5,
		ZIndex = 2,
		Parent = lebenHintergrund,
	}, { UI.innenabstand(4) })

	local geldText = UI.neu("TextLabel", {
		Position = UDim2.fromOffset(10, 44),
		Size = UDim2.new(0.6, -10, 0, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = GELB,
		Parent = rahmen,
	})

	local killText = UI.neu("TextLabel", {
		Position = UDim2.new(0.6, 0, 0, 48),
		Size = UDim2.new(0.4, -10, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = GRAU,
		Parent = rahmen,
	})

	local stats = player:WaitForChild("leaderstats")
	local geld = stats:WaitForChild("Geld")
	local kills = stats:WaitForChild("Kills")
	local function geldAktualisieren()
		geldText.Text = "💰 " .. UI.zahl(geld.Value)
	end
	local function killsAktualisieren()
		killText.Text = "☠ " .. kills.Value
	end
	geld.Changed:Connect(geldAktualisieren)
	kills.Changed:Connect(killsAktualisieren)
	geldAktualisieren()
	killsAktualisieren()

	-- Leben jede Frame vom eigenen Humanoid lesen
	local puls = 0
	RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		local anteil = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		lebenFuellung.Size = UDim2.fromScale(anteil, 1)

		local farbe = anteil > 0.5 and GRUEN or anteil > 0.25 and GELB or ROT
		if hum:GetAttribute("Regeneriert") then
			-- sanftes Pulsieren, während man heilt
			puls += dt * 6
			farbe = farbe:Lerp(WEISS, (math.sin(puls) + 1) * 0.15)
			lebenText.Text = "❤ " .. math.ceil(hum.Health) .. " / " .. hum.MaxHealth .. "  +"
		else
			lebenText.Text = "❤ " .. math.ceil(hum.Health) .. " / " .. hum.MaxHealth
		end
		lebenFuellung.BackgroundColor3 = farbe
	end)
end

-- Roter Rand, wenn man getroffen wird ---------------------------------------------------

local function trefferBlitz(gui)
	local blitz = UI.neu("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = ROT,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = gui,
	}, {
		-- Mitte durchsichtig, Ränder rot
		UI.neu("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.25, 1),
				NumberSequenceKeypoint.new(0.75, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}),
	})

	local function beobachte(char)
		local hum = char:WaitForChild("Humanoid")
		local vorher = hum.Health
		hum.HealthChanged:Connect(function(leben)
			if leben < vorher then
				blitz.BackgroundTransparency = 0.45
				TweenService:Create(blitz, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
			end
			vorher = leben
		end)
	end
	player.CharacterAdded:Connect(beobachte)
	if player.Character then
		task.spawn(beobachte, player.Character)
	end
end

-- Boss-Leiste ---------------------------------------------------------------------------

local function bossLeiste(gui)
	local rahmen = panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 94),
		Size = UDim2.new(0.8, 0, 0, 40),
		Visible = false,
		Parent = gui,
	})
	UI.neu("UISizeConstraint", { MaxSize = Vector2.new(460, 40), Parent = rahmen })

	local _, balken = leiste(rahmen, UDim2.fromOffset(6, 6), UDim2.new(1, -12, 1, -12), Color3.fromRGB(170, 25, 25))

	local text = UI.neu("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = WEISS,
		TextStrokeTransparency = 0.4,
		ZIndex = 3,
		Parent = rahmen,
	}, { UI.innenabstand(8) })

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
			balken.Size = UDim2.fromScale(math.clamp(bossHum.Health / bossHum.MaxHealth, 0, 1), 1)
			text.Text = "💀 " .. (boss:GetAttribute("BossName") or "Boss") .. "  " .. UI.zahl(bossHum.Health) .. " / " .. UI.zahl(bossHum.MaxHealth)
		end
	end)
end

-- Meldungen in der Bildschirmmitte ------------------------------------------------------

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
		label.TextColor3 = farbe or WEISS
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
	-- Die Standard-Lebensanzeige von Roblox ausblenden, wir haben unsere eigene
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	local gui = UI.neu("ScreenGui", {
		Name = "iZombieHUD",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})

	trefferBlitz(gui)
	welleAnzeige(gui)
	bossLeiste(gui)
	meldungen(gui)
	spielerAnzeige(gui)
end

return HUD
