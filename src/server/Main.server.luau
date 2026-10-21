-- iZombie Server: Spieler, Wellen und Spielablauf.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local ZombieService = require(script.Parent.ZombieService)
local WeaponService = require(script.Parent.WeaponService)
local MapBuilder = require(script.Parent.MapBuilder)
local Gesundheit = require(script.Parent.Gesundheit)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ROT = Color3.fromRGB(255, 70, 70)
local ORANGE = Color3.fromRGB(255, 170, 60)
local GRUEN = Color3.fromRGB(110, 230, 110)
local WEISS = Color3.new(1, 1, 1)

-- Fehler in der Map dürfen nie das ganze Spiel stoppen
local mapOk, mapFehler = pcall(MapBuilder.Bauen)
if not mapOk then
	warn("[iZombie] Map konnte nicht gebaut werden: " .. tostring(mapFehler))
end

-- Wir steuern das Respawnen selbst: wer in einer Welle stirbt, wartet bis zur Pause
Players.CharacterAutoLoads = false

local phase = "Pause"

local function setzeStatus(name, wert)
	ReplicatedStorage:SetAttribute(name, wert)
end

local function melde(text, farbe)
	Remotes.Notify:FireAllClients(text, farbe)
end

local function lebt(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function spawne(player)
	if player.Parent == Players then
		player:LoadCharacter()
	end
end

-- Spieler ---------------------------------------------------------------------

local function spielerBeigetreten(player)
	-- Ego-Perspektive: Maus ist in der Bildmitte gesperrt, man schießt dorthin, wo man hinschaut
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	PlayerData.Init(player)
	player:WaitForChild("StarterGear", 10)
	PlayerData.MerkeWaffe(player, Config.StartWaffe)
	WeaponService.GibWaffe(player, Config.StartWaffe)

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		Gesundheit.Beobachte(hum)
		hum.Died:Connect(function()
			if phase == "Welle" then
				Remotes.Notify:FireClient(player, "Du bist gestorben! Du kommst in der nächsten Pause zurück.", ROT)
			else
				task.delay(Config.RespawnZeit, function()
					if not lebt(player) then
						spawne(player)
					end
				end)
			end
		end)
	end)

	spawne(player)
end

Players.PlayerAdded:Connect(spielerBeigetreten)
for _, player in Players:GetPlayers() do
	task.spawn(spielerBeigetreten, player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.Entfernen(player)
	WeaponService.Entfernen(player)
end)

ZombieService.BeiTod = function(_typName, daten, killer)
	if killer and killer.Parent == Players then
		PlayerData.GeldDazu(killer, daten.Belohnung)
		PlayerData.KillDazu(killer)
	end
	if daten.IstBoss then
		-- Boss-Bonus für alle
		local bonus = math.floor(daten.Belohnung / 2)
		for _, player in Players:GetPlayers() do
			PlayerData.GeldDazu(player, bonus)
		end
		melde("💀 Boss besiegt! Alle bekommen +" .. bonus .. " Geld", GRUEN)
	end
end

-- Wellen ----------------------------------------------------------------------

local function spawnPunkt()
	local spawns = workspace:FindFirstChild("ZombieSpawns")
	if spawns then
		local teile = {}
		for _, teil in spawns:GetChildren() do
			if teil:IsA("BasePart") then
				table.insert(teile, teil)
			end
		end
		if #teile > 0 then
			local teil = teile[math.random(#teile)]
			local versatz = Vector3.new((math.random() - 0.5) * teil.Size.X, 0, (math.random() - 0.5) * teil.Size.Z)
			return ZombieService.Boden(teil.Position + versatz)
		end
	end

	-- Kein Spawn-Ordner: im Kreis um den Spawnpunkt der Spieler
	local mitte = Vector3.zero
	local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		mitte = spawnLocation.Position
	end
	local winkel = math.random() * math.pi * 2
	local r = Config.SpawnRadius
	return ZombieService.Boden(mitte + Vector3.new(math.cos(winkel) * r, 0, math.sin(winkel) * r))
end

local function zusammensetzung(welle, spielerAnzahl)
	local liste = {}
	local anzahl = math.floor((5 + welle * 3) * (1 + 0.3 * (spielerAnzahl - 1)))
	anzahl = math.min(anzahl, 400)

	if welle % Config.BossWelleAlle == 0 then
		local bosse = 1 + math.floor(spielerAnzahl / 10) + math.floor(welle / (Config.BossWelleAlle * 2))
		for _ = 1, bosse do
			table.insert(liste, "Boss")
		end
		anzahl = math.floor(anzahl / 2)
	elseif welle % Config.HundeWelleAlle == 0 then
		for _ = 1, anzahl do
			table.insert(liste, "Hund")
		end
		return liste, "Hunde"
	end

	for _ = 1, anzahl do
		local zufall = math.random()
		if welle >= 6 and zufall < 0.12 then
			table.insert(liste, "Panzer")
		elseif welle >= 3 and zufall < 0.35 then
			table.insert(liste, "Schnell")
		elseif welle > 5 and zufall < 0.45 then
			table.insert(liste, "Hund")
		else
			table.insert(liste, "Normal")
		end
	end

	return liste, (welle % Config.BossWelleAlle == 0) and "Boss" or "Normal"
end

local function jemandLebt()
	for _, player in Players:GetPlayers() do
		if lebt(player) then
			return true
		end
	end
	return false
end

local function pause(sekunden)
	phase = "Pause"
	setzeStatus("Phase", "Pause")
	for _, player in Players:GetPlayers() do
		if not lebt(player) then
			spawne(player)
		end
	end
	setzeStatus("PauseLaenge", sekunden)
	for t = sekunden, 1, -1 do
		setzeStatus("Countdown", t)
		task.wait(1)
	end
	setzeStatus("Countdown", 0)
end

-- Gibt true zurück, wenn die Welle geschafft wurde, false bei Game Over
local function spieleWelle(welle)
	local spielerAnzahl = math.max(#Players:GetPlayers(), 1)
	local liste, art = zusammensetzung(welle, spielerAnzahl)
	local faktor = 1 + Config.LebenProWelle * (welle - 1)
	local bossFaktor = faktor * (1 + 0.25 * (spielerAnzahl - 1))
	ZombieService.WellenFaktor = faktor

	setzeStatus("Welle", welle)
	setzeStatus("WellenArt", art)
	setzeStatus("ZombiesUebrig", #liste)
	setzeStatus("ZombiesGesamt", #liste)
	phase = "Welle"
	setzeStatus("Phase", "Welle")

	if art == "Boss" then
		melde("💀 BOSS-WELLE " .. welle .. " 💀", ROT)
	elseif art == "Hunde" then
		melde("🐕 Hunde-Welle " .. welle .. "!", ORANGE)
	else
		melde("Welle " .. welle, WEISS)
	end

	local index = 1
	while true do
		for _ = 1, Config.SpawnsProTick do
			if index > #liste or ZombieService.Anzahl() >= Config.MaxZombiesGleichzeitig then
				break
			end
			local typ = liste[index]
			ZombieService.Spawn(typ, spawnPunkt(), typ == "Boss" and bossFaktor or faktor)
			index += 1
		end

		setzeStatus("ZombiesUebrig", (#liste - index + 1) + ZombieService.Anzahl())

		if index > #liste and ZombieService.Anzahl() == 0 then
			return true
		end
		if not jemandLebt() then
			return false
		end
		task.wait(0.5)
	end
end

-- Spielablauf -----------------------------------------------------------------

local function warteAufSpieler()
	while #Players:GetPlayers() == 0 do
		task.wait(1)
	end
end

local welle = 0
setzeStatus("Welle", 0)
warteAufSpieler()
pause(Config.ErstePause)

while true do
	warteAufSpieler()
	welle += 1

	if spieleWelle(welle) then
		local bonus = Config.WellenBonus * welle
		for _, player in Players:GetPlayers() do
			PlayerData.GeldDazu(player, bonus)
		end
		melde("✅ Welle " .. welle .. " geschafft! +" .. bonus .. " Geld", GRUEN)
		pause(Config.PauseZwischenWellen)
	else
		phase = "GameOver"
		setzeStatus("Phase", "GameOver")
		melde("☠️ GAME OVER – ihr habt Welle " .. welle .. " erreicht", ROT)
		ZombieService.AlleEntfernen()
		task.wait(6)

		if Config.ResetBeiGameOver then
			for _, player in Players:GetPlayers() do
				PlayerData.Zuruecksetzen(player)
				WeaponService.Zuruecksetzen(player, Config.StartWaffe)
			end
		end
		welle = 0
		setzeStatus("Welle", 0)
		pause(Config.ErstePause)
	end
end
