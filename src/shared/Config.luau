-- Alle wichtigen Einstellungen für iZombie an einem Ort.
-- Hier kannst du das Spiel ausbalancieren, ohne den restlichen Code anzufassen.

local Config = {}

-- Spielablauf
Config.StartGeld = 0
Config.StartWaffe = "Messer"
Config.ErstePause = 20 -- Sekunden bis zur ersten Welle
Config.PauseZwischenWellen = 15
Config.RespawnZeit = 3 -- nur in Pausen; wer in einer Welle stirbt, kommt in der nächsten Pause zurück
Config.ResetBeiGameOver = true -- Geld und Waffen zurücksetzen, wenn alle tot sind

-- Wellen
Config.HundeWelleAlle = 5 -- jede 5. Welle: nur Zombie-Hunde
Config.BossWelleAlle = 10 -- jede 10. Welle: Boss
Config.WellenBonus = 25 -- Geld für alle nach jeder Welle = WellenBonus * Wellennummer
Config.LebenProWelle = 0.15 -- +15 % Zombie-Leben pro Welle
Config.MaxZombiesGleichzeitig = 80
Config.SpawnsProTick = 3
Config.SpawnRadius = 110 -- nur wenn es keinen Ordner "ZombieSpawns" im Workspace gibt

-- Sounds: Hier kannst du eigene Sound-IDs eintragen, z. B. "rbxassetid://123456"
-- (in Studio: Toolbox → Audio → nach "zombie" suchen → Rechtsklick → Asset-ID kopieren)
Config.Sounds = {
	ZombieTreffer = "rbxasset://sounds/uuhhh.mp3", -- tief abgespielt klingt es wie ein Zombie
	ZombieTod = "rbxasset://sounds/uuhhh.mp3",
	ZombieStoehnen = "rbxasset://sounds/uuhhh.mp3",
	Schlag = "rbxasset://sounds/swordlunge.wav",
}

Config.ZombieTypen = {
	Normal = {
		Leben = 100, Tempo = 10, Schaden = 10, Reichweite = 4.5, AngriffsCooldown = 1,
		Belohnung = 10, Groesse = 1, Farbe = Color3.fromRGB(95, 140, 75),
	},
	Schnell = {
		Leben = 60, Tempo = 18, Schaden = 6, Reichweite = 4, AngriffsCooldown = 0.8,
		Belohnung = 12, Groesse = 0.85, Farbe = Color3.fromRGB(150, 170, 80),
	},
	Panzer = {
		Leben = 450, Tempo = 7, Schaden = 25, Reichweite = 5.5, AngriffsCooldown = 1.4,
		Belohnung = 35, Groesse = 1.5, Farbe = Color3.fromRGB(70, 95, 60),
	},
	Hund = {
		Leben = 50, Tempo = 24, Schaden = 8, Reichweite = 4.5, AngriffsCooldown = 0.7,
		Belohnung = 15, Groesse = 1, Farbe = Color3.fromRGB(85, 70, 60), Form = "Hund",
	},
	Boss = {
		Leben = 2500, Tempo = 9, Schaden = 35, Reichweite = 8, AngriffsCooldown = 1.5,
		Belohnung = 500, Groesse = 2.6, Farbe = Color3.fromRGB(80, 60, 90), IstBoss = true,
		-- Fähigkeiten
		StampfenCooldown = 8, StampfenRadius = 18, StampfenSchaden = 25,
		RufCooldown = 15, RufAnzahl = 3,
		AnsturmCooldown = 10,
	},
}

return Config
