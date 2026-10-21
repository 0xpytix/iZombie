-- Erstellt die Waffen-Tools, verarbeitet Schüsse/Schläge und den Shop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponData = require(ReplicatedStorage.Shared.WeaponData)
local PlayerData = require(script.Parent.PlayerData)
local ZombieService = require(script.Parent.ZombieService)
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

	-- Waffe nach vorne aus der Hand schieben
	tool.Grip = CFrame.new(0, 0, daten.Groesse.Z / 2 - 0.4)
	return tool
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

	local start = (handle.CFrame * CFrame.new(0, 0, -handle.Size.Z / 2)).Position
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
				if ZombieService.Schaden(zombie, schaden, player) > 0 then
					Remotes.Effect:FireClient(player, "Treffer", ende, math.floor(schaden), kopfschuss)
				end
			end
		end
		table.insert(enden, ende)
	end

	Remotes.Effect:FireAllClients("Schuss", start, enden)
end

local function nahkampf(player, char, daten)
	local wurzel = char:FindFirstChild("HumanoidRootPart")
	if not wurzel then
		return
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
		if ZombieService.Schaden(model, daten.Schaden, player) > 0 and wurzelZombie then
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
		nahkampf(player, char, daten)
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
