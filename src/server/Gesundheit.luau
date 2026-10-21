-- Leben regenerieren, wenn man eine Weile nicht getroffen wurde.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Gesundheit = {}

local letzterTreffer = {} -- [humanoid] = os.clock()

function Gesundheit.Beobachte(humanoid)
	letzterTreffer[humanoid] = 0
	local vorher = humanoid.Health

	humanoid.HealthChanged:Connect(function(leben)
		if leben < vorher then
			letzterTreffer[humanoid] = os.clock()
		end
		vorher = leben
	end)

	humanoid.Destroying:Connect(function()
		letzterTreffer[humanoid] = nil
	end)
	humanoid.Died:Connect(function()
		letzterTreffer[humanoid] = nil
		humanoid:SetAttribute("Regeneriert", false)
	end)
end

RunService.Heartbeat:Connect(function(dt)
	local jetzt = os.clock()
	for humanoid, zeit in letzterTreffer do
		local heilt = humanoid.Health > 0
			and humanoid.Health < humanoid.MaxHealth
			and jetzt - zeit >= Config.RegenVerzoegerung
		if heilt then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + Config.RegenProSekunde * dt)
		end
		-- Attribut nur bei Änderung setzen, damit nicht ständig etwas übertragen wird
		if humanoid:GetAttribute("Regeneriert") ~= heilt then
			humanoid:SetAttribute("Regeneriert", heilt)
		end
	end
end)

return Gesundheit
