-- Startpunkt des Clients (läuft bei jedem Spieler)

local module = script.Parent

for _, name in { "HUD", "Shop", "Effects", "WeaponClient" } do
	task.spawn(function()
		require(module:WaitForChild(name)).Start()
	end)
end

print("[iZombie] Client gestartet")
