-- Alle wichtigen Einstellungen für iZombie an einem Ort.
-- Hier kannst du das Spiel ausbalancieren, ohne den restlichen Code anzufassen.

local Config = {}

-- Spielablauf
Config.StartGeld = 0
Config.UnendlichGeldInStudio = true -- zum Testen: in Roblox Studio unbegrenzt Geld (im echten Spiel nie)
Config.StartWaffe = "Messer"
Config.ErstePause = 20 -- Sekunden bis zur ersten Welle
Config.PauseZwischenWellen = 15
Config.RespawnZeit = 3 -- nur in Pausen; wer in einer Welle stirbt, kommt in der nächsten Pause zurück
Config.ResetBeiGameOver = true -- Geld und Waffen zurücksetzen, wenn alle tot sind

-- Leben
Config.RegenVerzoegerung = 5 -- so viele Sekunden ohne Treffer, dann heilt man
Config.RegenProSekunde = 8 -- Lebenspunkte pro Sekunde

-- Mystery Box (zufällige Waffe wie in Call of Duty Zombies)
Config.MysteryBoxPreis = 950
Config.MysteryBoxAbholzeit = 10 -- Sekunden, um die gezogene Waffe zu nehmen
Config.MysteryBoxMinNutzungen = 4 -- erst danach kann der Teddy kommen (Box zieht um)
Config.MysteryBoxUmzugChance = 0.2 -- Chance pro Zug auf den Teddy

-- Wellen
Config.HundeWelleAlle = 5 -- jede 5. Welle: nur Zombie-Hunde
Config.BossWelleAlle = 10 -- jede 10. Welle: Boss
Config.WellenBonus = 25 -- Geld für alle nach jeder Welle = WellenBonus * Wellennummer
Config.LebenProWelle = 0.15 -- +15 % Zombie-Leben pro Welle
Config.MaxZombiesGleichzeitig = 80
Config.SpawnsProTick = 3
Config.SpawnRadius = 180 -- nur wenn es keinen Ordner "ZombieSpawns" im Workspace gibt

-- Map (wird beim Spielstart erzeugt)
Config.Map = {
	Aktiv = true, -- auf false setzen, wenn du die Map lieber selbst in Studio baust
	Groesse = 800, -- Seitenlänge der Wüste (Terrain) in Studs, Nuketown liegt in der Mitte
	Fahrzeuge = true, -- Schulbus, Lieferwagen und Oldtimer als Deckung
	Felsen = 45, -- Felsbrocken in der Wüste
	Bueschel = 60, -- trockene Büsche in der Wüste
	Strommast = true, -- Hochspannungsmast neben dem Grundstück
}

-- Sounds: Hier kannst du eigene Sound-IDs eintragen, z. B. "rbxassetid://123456"
-- So tauschst du einen Sound aus: In Studio Toolbox öffnen → Reiter "Audio" (Creator Store) →
-- z. B. nach "gun shot", "shotgun" oder "music box" suchen → anhören → Rechtsklick → "Asset-ID kopieren"
-- → hier als "rbxassetid://<ID>" eintragen. "rbxasset://sounds/..." sind Dateien, die jeder Roblox-Client mitbringt.
-- Welche Waffe welchen Schuss-Sound benutzt (und wie hoch/tief), steht in src/shared/WeaponData.luau (Sound = ...).
Config.Sounds = {
	-- "uuhhh.mp3" gibt es im Roblox-Client nicht mehr, "oof.ogg" ist der Nachfolger (tief abgespielt = Zombie)
	ZombieTreffer = "rbxasset://sounds/oof.ogg",
	ZombieTod = "rbxasset://sounds/oof.ogg",
	ZombieStoehnen = "rbxasset://sounds/oof.ogg",
	Schlag = "rbxassetid://12222208", -- klassischer Roblox-Schwert-Schwung (swordlunge)

	-- Schüsse (Sound-Effekte von Pro Sound Effects, von Roblox frei für alle Spiele)
	Pistole = "rbxassetid://9114729026", -- "Gun Single Shots 6 (SFX)": Einzelschuss (Mini-Uzi)
	Gewehr = "rbxassetid://9114726695", -- "Gun Single Shots 5 (SFX)": Einzelschuss (AK-47)
	Schrotflinte = "rbxassetid://9112910543", -- "12 Gauge Shotgun 3 (SFX)"
	MG = "rbxassetid://9114726695", -- wie Gewehr, aber tiefer und mit mehr Bass (siehe WeaponData)
	Minigun = "rbxassetid://9114729026", -- wie Pistole, aber schnell und kurz abgespielt

	Treffer = "rbxassetid://144884872", -- "bullet_hit_flesh": Einschlag, wenn du einen Zombie triffst
	Ausruesten = "rbxassetid://12222225", -- klassisches Roblox-"unsheath" (Waffe ziehen)

	-- Mystery Box: kleine Spieluhr-Melodie, solange die Waffen durchwechseln.
	-- Standard: ein eingebauter kurzer Ton wird Note für Note in verschiedenen Tonhöhen gespielt.
	-- Eigene Musik: ID hier eintragen und Config.MysteryBoxSpieluhr = false setzen.
	MysteryBoxMusik = "rbxasset://sounds/volume_slider.ogg",
}
Config.MysteryBoxSpieluhr = true -- true = Melodie aus Einzeltönen, false = MysteryBoxMusik einfach abspielen

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
