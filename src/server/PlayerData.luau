-- Geld, Kills und gekaufte Waffen der Spieler (nur für die aktuelle Sitzung).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerData = {}

local waffen = {} -- [player] = { [waffenId] = true }

-- Testmodus: nur in Studio, damit es im veröffentlichten Spiel nie aktiv ist
local UNENDLICH = Config.UnendlichGeldInStudio and RunService:IsStudio()
local UNENDLICH_BETRAG = 999999999

local function startGeld()
	return UNENDLICH and UNENDLICH_BETRAG or Config.StartGeld
end

local function wert(player, name)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(name)
end

function PlayerData.Init(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local geld = Instance.new("IntValue")
	geld.Name = "Geld"
	geld.Value = startGeld()
	geld.Parent = stats

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = stats

	stats.Parent = player
	waffen[player] = {}
end

function PlayerData.GeldDazu(player, menge)
	local geld = wert(player, "Geld")
	if geld then
		geld.Value += menge
	end
end

function PlayerData.Ausgeben(player, menge)
	local geld = wert(player, "Geld")
	if geld and UNENDLICH then
		return true
	end
	if geld and geld.Value >= menge then
		geld.Value -= menge
		return true
	end
	return false
end

function PlayerData.KillDazu(player)
	local kills = wert(player, "Kills")
	if kills then
		kills.Value += 1
	end
end

function PlayerData.HatWaffe(player, id)
	return waffen[player] ~= nil and waffen[player][id] == true
end

function PlayerData.MerkeWaffe(player, id)
	if waffen[player] then
		waffen[player][id] = true
		-- Attribut, damit der Shop beim Spieler "Gekauft" anzeigen kann
		player:SetAttribute("Waffe_" .. id, true)
	end
end

function PlayerData.Zuruecksetzen(player)
	local geld = wert(player, "Geld")
	if geld then
		geld.Value = startGeld()
	end
	if waffen[player] then
		for id in waffen[player] do
			player:SetAttribute("Waffe_" .. id, nil)
		end
		waffen[player] = {}
	end
end

function PlayerData.Entfernen(player)
	waffen[player] = nil
end

return PlayerData
