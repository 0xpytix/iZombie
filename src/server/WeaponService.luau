-- Erstellt die Waffen-Tools, verarbeitet Schüsse/Schläge und den Shop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local WeaponData = require(ReplicatedStorage.Shared.WeaponData)
local PlayerData = require(script.Parent.PlayerData)
local ZombieService = require(script.Parent.ZombieService)
local WaffenModelle = require(script.Parent.WaffenModelle)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local WeaponService = {}

local letzterAngriff = {} -- [player] = os.clock()

local strahlParams = RaycastParams.new()
strahlParams.FilterType = Enum.RaycastFilterType.Exclude

local function erstelleTool(daten)
	local tool = Instance.new("Tool")
	tool.Name = daten.Name
	tool.CanBeDropped = false
	tool.ToolTip = daten.Typ
	tool:SetAttribute("Waffe", daten.Id)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = daten.Groesse
	handle.Color = daten.Farbe
	handle.Material = daten.Material or Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	if daten.Typ == "Nahkampf" then
		local schlag = Instance.new("Sound")
		schlag.Name = "Schlag"
		schlag.SoundId = Config.Sounds.Schlag
		schlag.Volume = 0.6
		schlag.Parent = handle
	end

	if daten.Modell then
		WaffenModelle.Bauen(daten.Modell, tool, handle, daten)
	end

	-- Schuss-Sound als Vorlage im Griff (wird pro Schuss geklont, siehe spieleSchuss)
	local schussId = daten.Sound and Config.Sounds[daten.Sound]
	if schussId then
		local schuss = Instance.new("Sound")
		schuss.Name = "Schuss"
		schuss.SoundId = schussId
		schuss.Volume = daten.SoundLautstaerke or 0.7
		schuss.PlaybackSpeed = daten.SoundTempo or 1
		schuss.RollOffMinDistance = 8
		schuss.RollOffMaxDistance = 250
		schuss.Parent = handle
		if daten.SoundBass then
			local eq = Instance.new("EqualizerSoundEffect")
			eq.LowGain = daten.SoundBass
			eq.MidGain = 0
			eq.HighGain = -2
			eq.Parent = schuss
		end
		if daten.SoundVerzerrung then
			local verzerrung = Instance.new("DistortionSoundEffect")
			verzerrung.Level = daten.SoundVerzerrung
			verzerrung.Parent = schuss
		end
	end

	-- Sound beim Ausrüsten (bei Schusswaffen höher, klingt dann eher nach Metall-Klacken)
	if Config.Sounds.Ausruesten then
		local ziehen = Instance.new("Sound")
		ziehen.Name = "Ausruesten"
		ziehen.SoundId = Config.Sounds.Ausruesten
		ziehen.Volume = 0.4
		ziehen.PlaybackSpeed = daten.Typ == "Nahkampf" and 1 or 1.6
		ziehen.RollOffMaxDistance = 60
		ziehen.Parent = handle
		tool.Equipped:Connect(function()
			ziehen:Play()
		end)
	end

	-- Waffe um 180° drehen (vorne = -Z des Griffs). Hat das Modell einen Punkt "Griff",
	-- liegt genau dieser in der Hand, sonst wird die Waffe nach vorne aus der Hand geschoben.
	local griffPunkt = handle:FindFirstChild("Griff")
	if griffPunkt and griffPunkt:IsA("Attachment") then
		tool.Grip = CFrame.new(griffPunkt.Position) * CFrame.Angles(0, math.pi, 0)
	else
		tool.Grip = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, -(daten.Groesse.Z / 2 - 0.4))
	end
	return tool
end

-- Spielt den Schuss-Sound als eigene Kopie ab, damit sich schnelle Schüsse nicht gegenseitig abschneiden
local function spieleSchuss(handle, daten)
	local vorlage = handle:FindFirstChild("Schuss")
	if not vorlage or not vorlage:IsA("Sound") then
		return
	end
	local sound = vorlage:Clone()
	sound.PlaybackSpeed = (daten.SoundTempo or 1) * (0.94 + math.random() * 0.12)
	sound.Parent = handle
	sound:Play()
	Debris:AddItem(sound, daten.SoundDauer or 2)
end

-- Reines Anzeigemodell einer Waffe (z. B. für die Mystery Box): verankert, ohne Kollision,
-- Drehpunkt = Griff (vorne = -Z). Gibt nil zurück, wenn die Waffe unbekannt ist.
function WeaponService.Vorschau(id)
	local daten = WeaponData.NachId[id]
	if not daten then
		return nil
	end

	local tool = erstelleTool(daten)
	local modell = Instance.new("Model")
	modell.Name = "Vorschau_" .. daten.Id

	for _, objekt in tool:GetDescendants() do
		if objekt:IsA("WeldConstraint") or objekt:IsA("Sound") or objekt:IsA("Trail") then
			objekt:Destroy()
		end
	end
	for _, teil in tool:GetChildren() do
		if teil:IsA("BasePart") then
			teil.Anchored = true
			teil.CanCollide = false
			teil.CanQuery = false
			teil.CanTouch = false
			teil.Parent = modell
		end
	end
	modell.PrimaryPart = modell:FindFirstChild("Handle") :: BasePart?
	tool:Destroy()
	return modell
end

-- Legt die Waffe in StarterGear (bleibt nach dem Tod) und, falls der Spieler lebt, in den Rucksack
function WeaponService.GibWaffe(player, id)
	local daten = WeaponData.NachId[id]
	if not daten then
		return
	end

	local gear = player:FindFirstChild("StarterGear")
	if gear and not gear:FindFirstChild(daten.Name) then
		erstelleTool(daten).Parent = gear
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local rucksack = player:FindFirstChildOfClass("Backpack")
	if hum and hum.Health > 0 and rucksack and not rucksack:FindFirstChild(daten.Name) and not char:FindFirstChild(daten.Name) then
		erstelleTool(daten).Parent = rucksack
	end
end

function WeaponService.Zuruecksetzen(player, startWaffe)
	local gear = player:FindFirstChild("StarterGear")
	if gear then
		gear:ClearAllChildren()
	end
	local rucksack = player:FindFirstChildOfClass("Backpack")
	if rucksack then
		rucksack:ClearAllChildren()
	end
	PlayerData.MerkeWaffe(player, startWaffe)
	WeaponService.GibWaffe(player, startWaffe)
end

function WeaponService.Entfernen(player)
	letzterAngriff[player] = nil
end

local function spielerCharaktere()
	local liste = {}
	for _, spieler in Players:GetPlayers() do
		if spieler.Character then
			table.insert(liste, spieler.Character)
		end
	end
	return liste
end

local function schiessen(player, tool, daten, zielPos)
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return
	end

	local muendung = handle:FindFirstChild("Muendung")
	local start = if muendung and muendung:IsA("Attachment")
		then muendung.WorldPosition
		else (handle.CFrame * CFrame.new(0, 0, -handle.Size.Z / 2)).Position
	spieleSchuss(handle, daten)
	local grundRichtung = zielPos - start
	if grundRichtung.Magnitude < 0.1 then
		return
	end
	grundRichtung = grundRichtung.Unit
	strahlParams.FilterDescendantsInstances = spielerCharaktere()

	local streuung = math.rad(daten.Streuung or 0)
	local enden = {}
	for _ = 1, daten.Kugeln or 1 do
		local richtung = grundRichtung
		if streuung > 0 then
			local versatz = CFrame.Angles((math.random() * 2 - 1) * streuung, (math.random() * 2 - 1) * streuung, 0)
			richtung = (CFrame.lookAt(Vector3.zero, grundRichtung) * versatz).LookVector
		end

		local treffer = workspace:Raycast(start, richtung * daten.Reichweite, strahlParams)
		local ende = start + richtung * daten.Reichweite
		if treffer then
			ende = treffer.Position
			local zombie = ZombieService.ZombieVonTeil(treffer.Instance)
			if zombie then
				local kopfschuss = treffer.Instance.Name == "Head"
				local schaden = kopfschuss and daten.Schaden * 1.5 or daten.Schaden
				local stoss = daten.Rueckstoss and richtung * daten.Rueckstoss or nil
				if ZombieService.Schaden(zombie, schaden, player, stoss) > 0 then
					Remotes.Effect:FireClient(player, "Treffer", ende, math.floor(schaden), kopfschuss)
				end
			end
		end
		table.insert(enden, ende)
	end

	Remotes.Effect:FireAllClients("Schuss", start, enden, player)
end

local function nahkampf(player, char, tool, daten)
	local wurzel = char:FindFirstChild("HumanoidRootPart")
	if not wurzel then
		return
	end

	local handle = tool:FindFirstChild("Handle")
	local schlagSound = handle and handle:FindFirstChild("Schlag")
	if schlagSound then
		schlagSound.PlaybackSpeed = 0.9 + math.random() * 0.2
		schlagSound:Play()
	end

	-- Leuchtspur nur während des Schlags zeigen
	local spur = handle and handle:FindFirstChildOfClass("Trail")
	if spur then
		spur.Enabled = true
		task.delay(0.25, function()
			spur.Enabled = false
		end)
	end
	local vorne = wurzel.CFrame.LookVector

	-- Erst sammeln, dann Schaden machen (Tote werden sonst während der Schleife entfernt)
	local getroffen = {}
	for model, z in ZombieService.Alle() do
		if z.humanoid.Health > 0 then
			local abstand = z.wurzel.Position - wurzel.Position
			local flach = Vector3.new(abstand.X, 0, abstand.Z)
			local groesse = z.daten.Groesse
			local inReichweite = flach.Magnitude <= daten.Reichweite + groesse and math.abs(abstand.Y) < 4 * groesse
			local vorMir = flach.Magnitude < 2 or flach.Unit:Dot(vorne) > 0.3
			if inReichweite and vorMir then
				table.insert(getroffen, model)
			end
		end
	end

	for _, model in getroffen do
		local wurzelZombie = model.PrimaryPart
		local stoss
		if wurzelZombie then
			local weg = wurzelZombie.Position - wurzel.Position
			weg = Vector3.new(weg.X, 0, weg.Z)
			local richtung = weg.Magnitude > 0.1 and weg.Unit or vorne
			stoss = richtung * (daten.Rueckstoss or 0)
		end
		if ZombieService.Schaden(model, daten.Schaden, player, stoss) > 0 and wurzelZombie then
			Remotes.Effect:FireClient(player, "Treffer", wurzelZombie.Position, daten.Schaden, false)
		end
	end
end

Remotes.Fire.OnServerEvent:Connect(function(player, id, zielPos)
	if typeof(id) ~= "string" or typeof(zielPos) ~= "Vector3" then
		return
	end
	if zielPos.X ~= zielPos.X or zielPos.Y ~= zielPos.Y or zielPos.Z ~= zielPos.Z then
		return -- NaN
	end

	local daten = WeaponData.NachId[id]
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not daten or not hum or hum.Health <= 0 then
		return
	end

	local tool = char:FindFirstChildOfClass("Tool")
	if not tool or tool:GetAttribute("Waffe") ~= id then
		return
	end

	-- Schutz gegen zu schnelles Feuern (etwas Toleranz für Lag)
	local jetzt = os.clock()
	if jetzt - (letzterAngriff[player] or 0) < daten.Cooldown * 0.8 then
		return
	end
	letzterAngriff[player] = jetzt

	if daten.Typ == "Nahkampf" then
		nahkampf(player, char, tool, daten)
	else
		schiessen(player, tool, daten, zielPos)
	end
end)

Remotes.BuyWeapon.OnServerInvoke = function(player, id)
	if typeof(id) ~= "string" then
		return false, "Fehler"
	end
	local daten = WeaponData.NachId[id]
	if not daten then
		return false, "Unbekannte Waffe"
	end
	if PlayerData.HatWaffe(player, id) then
		return false, "Hast du schon!"
	end
	if not PlayerData.Ausgeben(player, daten.Preis) then
		return false, "Nicht genug Geld!"
	end
	PlayerData.MerkeWaffe(player, id)
	WeaponService.GibWaffe(player, id)
	return true, daten.Name .. " gekauft!"
end

return WeaponService
