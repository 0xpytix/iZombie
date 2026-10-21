-- Erstellt Zombies (Normal, Schnell, Panzer, Hund, Boss) und steuert ihre KI.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ZombieService = {}
ZombieService.WellenFaktor = 1 -- Lebens-Multiplikator der aktuellen Welle (für vom Boss gerufene Zombies)
ZombieService.BeiTod = nil -- function(typName, daten, killer), wird von Main gesetzt

local ordner = Instance.new("Folder")
ordner.Name = "Zombies"
ordner.Parent = workspace

local zombies = {} -- [model] = Zustand
local anzahl = 0

local BOSS_NAMEN = { "Brutus", "Der Schlächter", "Koloss", "Moder-König", "Fleischberg" }

local bodenParams = RaycastParams.new()
bodenParams.FilterType = Enum.RaycastFilterType.Exclude

-- Körper bauen ---------------------------------------------------------------

local function neuesTeil(model, wurzel, name, groesse, farbe, cframe, material)
	local teil = Instance.new("Part")
	teil.Name = name
	teil.Size = groesse
	teil.Color = farbe
	teil.Material = material or Enum.Material.SmoothPlastic
	teil.CFrame = cframe
	teil.CanCollide = false
	teil.Massless = true
	teil.TopSurface = Enum.SurfaceType.Smooth
	teil.BottomSurface = Enum.SurfaceType.Smooth
	teil.Parent = model
	if wurzel then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = wurzel
		weld.Part1 = teil
		weld.Parent = teil
	end
	return teil
end

local function neueWurzel(model, groesse, farbe, cframe)
	local wurzel = neuesTeil(model, nil, "HumanoidRootPart", groesse, farbe, cframe)
	wurzel.Massless = false
	wurzel.CanCollide = true
	return wurzel
end

-- Zombie auf zwei Beinen mit ausgestreckten Armen
local function baueMensch(model, boden, s, farbe, augenFarbe)
	local hueft = 2 * s
	local basis = CFrame.new(boden + Vector3.new(0, hueft + s, 0))
	local kleidung = farbe:Lerp(Color3.fromRGB(50, 40, 35), 0.6)

	local wurzel = neueWurzel(model, Vector3.new(2, 2, 1) * s, kleidung, basis)
	neuesTeil(model, wurzel, "Bein", Vector3.new(1, 2, 1) * s, kleidung, basis * CFrame.new(-0.5 * s, -2 * s, 0))
	neuesTeil(model, wurzel, "Bein", Vector3.new(1, 2, 1) * s, kleidung, basis * CFrame.new(0.5 * s, -2 * s, 0))
	neuesTeil(model, wurzel, "Arm", Vector3.new(1, 1, 2.2) * s, farbe, basis * CFrame.new(-1.5 * s, 0.5 * s, -0.8 * s))
	neuesTeil(model, wurzel, "Arm", Vector3.new(1, 1, 2.2) * s, farbe, basis * CFrame.new(1.5 * s, 0.5 * s, -0.8 * s))
	local kopf = neuesTeil(model, wurzel, "Head", Vector3.new(1.2, 1.2, 1.2) * s, farbe, basis * CFrame.new(0, 1.6 * s, 0))
	neuesTeil(model, wurzel, "Auge", Vector3.new(0.25, 0.2, 0.1) * s, augenFarbe, basis * CFrame.new(-0.25 * s, 1.7 * s, -0.62 * s), Enum.Material.Neon)
	neuesTeil(model, wurzel, "Auge", Vector3.new(0.25, 0.2, 0.1) * s, augenFarbe, basis * CFrame.new(0.25 * s, 1.7 * s, -0.62 * s), Enum.Material.Neon)

	return wurzel, kopf, hueft
end

-- Zombie-Hund auf vier Beinen
local function baueHund(model, boden, s, farbe, augenFarbe)
	local hueft = 1 * s
	local basis = CFrame.new(boden + Vector3.new(0, hueft + 0.7 * s, 0))

	local wurzel = neueWurzel(model, Vector3.new(1.4, 1.4, 3) * s, farbe, basis)
	for _, x in { -0.45, 0.45 } do
		for _, z in { -1.1, 1.1 } do
			neuesTeil(model, wurzel, "Bein", Vector3.new(0.5, 1, 0.5) * s, farbe, basis * CFrame.new(x * s, -1.2 * s, z * s))
		end
	end
	local kopf = neuesTeil(model, wurzel, "Head", Vector3.new(1.1, 1.1, 1.3) * s, farbe, basis * CFrame.new(0, 0.5 * s, -1.9 * s))
	neuesTeil(model, wurzel, "Schnauze", Vector3.new(0.7, 0.5, 0.6) * s, farbe:Lerp(Color3.new(0, 0, 0), 0.3), basis * CFrame.new(0, 0.3 * s, -2.75 * s))
	neuesTeil(model, wurzel, "Ohr", Vector3.new(0.3, 0.4, 0.2) * s, farbe, basis * CFrame.new(-0.35 * s, 1.15 * s, -1.8 * s))
	neuesTeil(model, wurzel, "Ohr", Vector3.new(0.3, 0.4, 0.2) * s, farbe, basis * CFrame.new(0.35 * s, 1.15 * s, -1.8 * s))
	neuesTeil(model, wurzel, "Schwanz", Vector3.new(0.25, 0.25, 1) * s, farbe, basis * CFrame.new(0, 0.6 * s, 1.8 * s))
	neuesTeil(model, wurzel, "Auge", Vector3.new(0.2, 0.2, 0.1) * s, augenFarbe, basis * CFrame.new(-0.3 * s, 0.7 * s, -2.56 * s), Enum.Material.Neon)
	neuesTeil(model, wurzel, "Auge", Vector3.new(0.2, 0.2, 0.1) * s, augenFarbe, basis * CFrame.new(0.3 * s, 0.7 * s, -2.56 * s), Enum.Material.Neon)

	return wurzel, kopf, hueft
end

local function lebensbalken(kopf, humanoid, s, istBoss)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Lebensbalken"
	gui.Size = UDim2.new(3 * s, 0, 0.35 * s, 0)
	gui.StudsOffset = Vector3.new(0, 1.2 * s, 0)
	gui.MaxDistance = istBoss and 300 or 70
	gui.Adornee = kopf

	local hintergrund = Instance.new("Frame")
	hintergrund.Size = UDim2.fromScale(1, 1)
	hintergrund.BackgroundColor3 = Color3.new(0, 0, 0)
	hintergrund.BackgroundTransparency = 0.4
	hintergrund.BorderSizePixel = 0
	hintergrund.Parent = gui

	local balken = Instance.new("Frame")
	balken.Size = UDim2.fromScale(1, 1)
	balken.BackgroundColor3 = istBoss and Color3.fromRGB(200, 40, 40) or Color3.fromRGB(90, 220, 90)
	balken.BorderSizePixel = 0
	balken.Parent = hintergrund

	humanoid.HealthChanged:Connect(function(leben)
		balken.Size = UDim2.fromScale(math.clamp(leben / humanoid.MaxHealth, 0, 1), 1)
	end)

	gui.Parent = kopf
end

-- Spawnen / Entfernen ---------------------------------------------------------

local function entferne(model, getoetet)
	local z = zombies[model]
	if not z then
		return
	end
	zombies[model] = nil
	anzahl -= 1

	if getoetet then
		if ZombieService.BeiTod then
			ZombieService.BeiTod(z.typ, z.daten, z.letzterAngreifer)
		end
		for _, teil in model:GetChildren() do
			if teil:IsA("BasePart") then
				teil.Color = teil.Color:Lerp(Color3.new(0.1, 0.1, 0.1), 0.6)
			end
		end
		task.delay(1.5, function()
			model:Destroy()
		end)
	end
end

function ZombieService.Spawn(typName, boden, lebensFaktor)
	local daten = Config.ZombieTypen[typName]
	local s = daten.Groesse
	local augenFarbe = daten.IstBoss and Color3.fromRGB(255, 120, 0) or Color3.fromRGB(255, 30, 30)

	local model = Instance.new("Model")
	model.Name = typName

	local wurzel, kopf, hueft
	if daten.Form == "Hund" then
		wurzel, kopf, hueft = baueHund(model, boden, s, daten.Farbe, augenFarbe)
	else
		wurzel, kopf, hueft = baueMensch(model, boden, s, daten.Farbe, augenFarbe)
	end
	model.PrimaryPart = wurzel

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15 -- nötig, damit HipHeight bei eigenen Körpern funktioniert
	humanoid.HipHeight = hueft
	humanoid.MaxHealth = math.floor(daten.Leben * (lebensFaktor or 1))
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = daten.Tempo
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.Parent = model

	lebensbalken(kopf, humanoid, s, daten.IstBoss)
	CollectionService:AddTag(model, "Zombie")
	if daten.IstBoss then
		CollectionService:AddTag(model, "Boss")
		model:SetAttribute("BossName", BOSS_NAMEN[math.random(#BOSS_NAMEN)])
	end

	model.Parent = ordner
	wurzel:SetNetworkOwner(nil) -- Server steuert die Bewegung, damit sie für alle gleich aussieht

	local jetzt = os.clock()
	zombies[model] = {
		model = model,
		humanoid = humanoid,
		wurzel = wurzel,
		typ = typName,
		daten = daten,
		letzterAngriff = 0,
		letzterAngreifer = nil,
		blockiertBis = 0,
		ansturmBis = 0,
		wut = false,
		naechstesStampfen = jetzt + 5,
		naechsterRuf = jetzt + 10,
		naechsterAnsturm = jetzt + 7,
	}
	anzahl += 1

	humanoid.Died:Connect(function()
		entferne(model, true)
	end)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			entferne(model, false) -- z. B. aus der Map gefallen: keine Belohnung
		end
	end)

	return model
end

function ZombieService.Anzahl()
	return anzahl
end

function ZombieService.Alle()
	return zombies
end

function ZombieService.ZombieVonTeil(teil)
	local model = teil:FindFirstAncestorWhichIsA("Model")
	if model and zombies[model] then
		return model
	end
	return nil
end

-- Gibt den tatsächlich verursachten Schaden zurück
function ZombieService.Schaden(model, menge, spieler)
	local z = zombies[model]
	if not z or z.humanoid.Health <= 0 then
		return 0
	end
	if spieler then
		z.letzterAngreifer = spieler
	end
	local vorher = z.humanoid.Health
	z.humanoid:TakeDamage(menge)
	return math.min(menge, vorher)
end

function ZombieService.AlleEntfernen()
	local liste = {}
	for model in zombies do
		table.insert(liste, model)
	end
	for _, model in liste do
		entferne(model, false)
		model:Destroy()
	end
end

-- Findet den Boden unter einer Position (für Spawnpunkte)
function ZombieService.Boden(position)
	local ausschluss = { ordner }
	for _, spieler in Players:GetPlayers() do
		if spieler.Character then
			table.insert(ausschluss, spieler.Character)
		end
	end
	bodenParams.FilterDescendantsInstances = ausschluss
	local treffer = workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), bodenParams)
	return treffer and treffer.Position or Vector3.new(position.X, 0, position.Z)
end

-- KI --------------------------------------------------------------------------

local function naechsterSpieler(position)
	local besterHum, besteWurzel, besteDist = nil, nil, math.huge
	for _, spieler in Players:GetPlayers() do
		local char = spieler.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local wurzel = char and char:FindFirstChild("HumanoidRootPart")
		if hum and wurzel and hum.Health > 0 then
			local dist = (wurzel.Position - position).Magnitude
			if dist < besteDist then
				besterHum, besteWurzel, besteDist = hum, wurzel, dist
			end
		end
	end
	return besterHum, besteWurzel, besteDist
end

-- Boss-Fähigkeit: Bodenstampfer mit Vorwarnung, Schaden und Rückstoß
local function stampfen(z)
	local d = z.daten
	z.blockiertBis = os.clock() + 1.1
	Remotes.Effect:FireAllClients("Warnung", z.wurzel.Position, d.StampfenRadius)

	task.delay(0.8, function()
		if not zombies[z.model] then
			return
		end
		local mitte = z.wurzel.Position
		Remotes.Effect:FireAllClients("Stampfen", mitte, d.StampfenRadius)
		for _, spieler in Players:GetPlayers() do
			local char = spieler.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local wurzel = char and char:FindFirstChild("HumanoidRootPart")
			if hum and wurzel and hum.Health > 0 then
				local abstand = wurzel.Position - mitte
				if abstand.Magnitude <= d.StampfenRadius then
					hum:TakeDamage(d.StampfenSchaden)
					local flach = Vector3.new(abstand.X, 0, abstand.Z)
					local richtung = flach.Magnitude > 0.1 and flach.Unit or Vector3.new(0, 0, 1)
					Remotes.Effect:FireClient(spieler, "Rueckstoss", richtung * 70 + Vector3.new(0, 45, 0))
				end
			end
		end
	end)
end

-- Boss-Fähigkeit: ruft normale Zombies zu Hilfe
local function rufen(z)
	if not zombies[z.model] then
		return
	end
	for _ = 1, z.daten.RufAnzahl do
		if anzahl >= Config.MaxZombiesGleichzeitig then
			break
		end
		local winkel = math.random() * math.pi * 2
		local position = z.wurzel.Position + Vector3.new(math.cos(winkel) * 8, 0, math.sin(winkel) * 8)
		ZombieService.Spawn("Normal", ZombieService.Boden(position), ZombieService.WellenFaktor)
	end
end

local function bossFaehigkeiten(z, jetzt, zielDist)
	local d = z.daten

	-- Unter 50 % Leben wird der Boss wütend: schneller und rot
	if not z.wut and z.humanoid.Health < z.humanoid.MaxHealth * 0.5 then
		z.wut = true
		for _, teil in z.model:GetChildren() do
			if teil:IsA("BasePart") and teil.Name ~= "Auge" then
				teil.Color = teil.Color:Lerp(Color3.fromRGB(170, 20, 20), 0.5)
			end
		end
		local name = z.model:GetAttribute("BossName") or "Der Boss"
		Remotes.Notify:FireAllClients(name .. " ist wütend!", Color3.fromRGB(255, 70, 40))
	end

	if jetzt >= z.naechstesStampfen and zielDist < d.StampfenRadius * 1.5 then
		z.naechstesStampfen = jetzt + d.StampfenCooldown
		stampfen(z)
	end

	if jetzt >= z.naechsterRuf then
		z.naechsterRuf = jetzt + d.RufCooldown
		task.defer(rufen, z) -- nicht während der Schleife über alle Zombies neue hinzufügen
	end

	-- Ansturm: rennt auf weit entfernte Spieler zu
	if jetzt >= z.naechsterAnsturm and zielDist > 25 and zielDist < math.huge then
		z.naechsterAnsturm = jetzt + d.AnsturmCooldown
		z.ansturmBis = jetzt + 2.5
	end
end

local TICK = 0.2
local akku = 0

RunService.Heartbeat:Connect(function(dt)
	akku += dt
	if akku < TICK then
		return
	end
	akku = 0

	local jetzt = os.clock()
	for _, z in zombies do
		if z.humanoid.Health <= 0 then
			continue
		end

		local zielHum, zielWurzel, dist = naechsterSpieler(z.wurzel.Position)

		local tempo = z.daten.Tempo
		if z.wut then
			tempo *= 1.35
		end
		if jetzt < z.ansturmBis then
			tempo *= 2.5
		end
		if jetzt < z.blockiertBis then
			tempo = 0
		end
		z.humanoid.WalkSpeed = tempo

		if zielHum then
			z.humanoid:MoveTo(zielWurzel.Position)
			if dist <= z.daten.Reichweite then
				if jetzt - z.letzterAngriff >= z.daten.AngriffsCooldown then
					z.letzterAngriff = jetzt
					zielHum:TakeDamage(z.daten.Schaden)
				end
			elseif tempo > 0 and z.wurzel.AssemblyLinearVelocity.Magnitude < 1 then
				z.humanoid.Jump = true -- steckt fest: drüberspringen versuchen
			end
		end

		if z.daten.IstBoss then
			bossFaehigkeiten(z, jetzt, dist)
		end
	end
end)

return ZombieService
