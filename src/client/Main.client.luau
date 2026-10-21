-- Startpunkt des Clients (läuft bei jedem Spieler)

local module = script.Parent

for _, name in { "HUD", "Hotbar", "Shop", "Effects", "WeaponClient", "Fadenkreuz" } do
	task.spawn(function()
		require(module:WaitForChild(name)).Start()
	end)
end

print("[iZombie] Client gestartet")
