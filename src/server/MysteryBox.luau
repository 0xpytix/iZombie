-- Mystery Box wie in Call of Duty Zombies: Für Geld eine zufällige Waffe ziehen.
-- Die Box steht auf einem Platz aus workspace.MysteryBoxPunkte (vorne = LookVector des Platzes).
-- Nach ein paar Nutzungen kann der Teddy kommen – dann zieht die Box an einen anderen Platz um.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WeaponData = require(ReplicatedStorage.Shared.WeaponData)
local PlayerData = require(script.Parent.PlayerData)
local WeaponService = require(script.Parent.WeaponService)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MysteryBox = {}

local ROT = Color3.fromRGB(255, 70, 70)
local GRUEN = Color3.fromRGB(110, 230, 110)
local ORANGE = Color3.fromRGB(255, 170, 60)
local BLAU = Color3.fromRGB(90, 170, 255)
local HOLZ = Color3.fromRGB(72, 46, 26)
local METALL = Color3.fromRGB(70, 70, 78)

-- Maße der Kiste (Studs)
local BREITE = 5
local HOEHE = 2.2 -- Korpus ohne Deckel
local TIEFE = 2.5
local DECKEL = 0.6
local OEFFNUNGS_WINKEL = math.rad(105)
local ROLL_DAUER = 4.5 -- Sekunden, in denen die Waffen durchwechseln
local UMZUG_PAUSE = 5 -- Sekunden, bis die Box am neuen Platz auftaucht

local ordner: Folder? = nil -- workspace.MysteryBox
local kiste: Model? = nil
local korpus: BasePart? = nil
local prompt: ProximityPrompt? = nil
local deckelWinkel: NumberValue? = nil
local deckelTeile = {} -- { { teil, versatz } } relativ zum Scharnier
local basis = CFrame.identity -- Boden-Mitte der Kiste, vorne = LookVector
local scharnier = CFrame.identity -- hintere obere Kante des Korpus
local platzIndex = nil

-- Zustand: "Aus", "Bereit", "Rollt", "Abholen", "Schliesst", "Umzug"
local zustand = "Aus"
local runde = 0
local nutzungen = 0
local besitzer = nil
local gewinnId = nil

-- Schwebendes Modell über der Kiste (Waffe oder Teddy)
local anzeigeModell: Model? = nil
local anzeigeHoehe = 0
local anzeigeZiel = 0
local anzeigeDrehung = 0

local function preis()
	return Config.MysteryBoxPreis or 950
end

local function oeffnenText()
	return "Öffnen (💰" .. preis() .. ")"
end

local function spielerOk(player)
	if player.Parent ~= Players then
		return false
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

-- Bauteile --------------------------------------------------------------------

local function teil(name, groesse, farbe, material, cf, eltern, form)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = groesse
	p.Color = farbe
	p.Material = material
	p.Shape = form or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = cf
	p.Parent = eltern
	return p
end

local function fragezeichen(flaeche, seite)
	local gui = Instance.new("SurfaceGui")
	gui.Face = seite
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = flaeche

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Text = "?"
	text.TextScaled = true
	text.Font = Enum.Font.GothamBlack
	text.TextColor3 = BLAU
	text.TextStrokeTransparency = 0.3
	text.TextStrokeColor3 = Color3.fromRGB(10, 30, 60)
	text.Parent = gui
	return gui
end

local function teddyBauen()
	local modell = Instance.new("Model")
	modell.Name = "Teddy"
	local braun = Color3.fromRGB(140, 90, 50)
	local hell = Color3.fromRGB(205, 160, 110)
	local schwarz = Color3.fromRGB(20, 15, 10)
	local ball = Enum.PartType.Ball
	local stoff = Enum.Material.Fabric

	local koerper = teil("Koerper", Vector3.one * 1.6, braun, stoff, CFrame.identity, modell, ball)
	teil("Bauch", Vector3.one * 1.0, hell, stoff, CFrame.new(0, -0.05, -0.42), modell, ball)
	teil("Kopf", Vector3.one * 1.25, braun, stoff, CFrame.new(0, 1.2, 0), modell, ball)
	teil("Schnauze", Vector3.one * 0.55, hell, stoff, CFrame.new(0, 1.05, -0.52), modell, ball)
	teil("Nase", Vector3.one * 0.2, schwarz, Enum.Material.SmoothPlastic, CFrame.new(0, 1.15, -0.8), modell, ball)
	for _, x in { -1, 1 } do
		teil("Ohr", Vector3.one * 0.45, braun, stoff, CFrame.new(0.45 * x, 1.78, 0), modell, ball)
		teil("Auge", Vector3.one * 0.16, schwarz, Enum.Material.SmoothPlastic, CFrame.new(0.24 * x, 1.4, -0.55), modell, ball)
		teil("Arm", Vector3.one * 0.6, braun, stoff, CFrame.new(0.82 * x, 0.25, -0.1), modell, ball)
		teil("Bein", Vector3.one * 0.7, braun, stoff, CFrame.new(0.5 * x, -0.72, -0.25), modell, ball)
	end
	for _, p in modell:GetChildren() do
		if p:IsA("BasePart") then
			p.CanQuery = false
		end
	end
	modell.PrimaryPart = koerper
	return modell
end

-- Anzeige über der Kiste ------------------------------------------------------

local function zeige(modell, drehung)
	if anzeigeModell then
		anzeigeModell:Destroy()
	end
	anzeigeModell = modell
	anzeigeDrehung = drehung or 0
	if modell then
		modell.Parent = ordner
	end
end

local function aktualisiereAnzeige(dt)
	local modell = anzeigeModell
	if not modell or not modell.Parent or not modell.PrimaryPart then
		return
	end
	anzeigeHoehe += (anzeigeZiel - anzeigeHoehe) * math.min(1, dt * 3)
	local wackeln = math.sin(os.clock() * 1.5) * 0.3
	modell:PivotTo(basis * CFrame.new(0, HOEHE + anzeigeHoehe, 0) * CFrame.Angles(0, anzeigeDrehung + wackeln, 0))
end

-- Deckel ----------------------------------------------------------------------

local function setzeDeckel(winkel)
	local dreh = scharnier * CFrame.Angles(winkel, 0, 0)
	for _, eintrag in deckelTeile do
		eintrag[1].CFrame = dreh * eintrag[2]
	end
end

local function deckel(ziel, dauer)
	if deckelWinkel then
		TweenService:Create(deckelWinkel, TweenInfo.new(dauer, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = ziel }):Play()
	end
end

local function spieleSound()
	if not korpus or not Config.Sounds or not Config.Sounds.Schlag then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = Config.Sounds.Schlag
	sound.PlaybackSpeed = 0.45
	sound.Volume = 0.8
	sound.RollOffMaxDistance = 80
	sound.Parent = korpus
	sound:Play()
	task.delay(3, function()
		sound:Destroy()
	end)
end

-- Spieluhr-Melodie während des Rollens (eigene kleine Melodie, keine CoD-Musik)
-- Jede Note: { Halbtöne über dem Grundton, Länge in Schlägen }. Walzer im 3/4-Takt, ca. 4,3 s.
local MELODIE = {
	{ 0, 1 }, { 4, 1 }, { 7, 1 }, { 12, 2 }, { 11, 1 }, { 9, 1 }, { 7, 1 }, { 4, 1 }, { 5, 2 }, { 9, 1 },
	{ 7, 1 }, { 4, 1 }, { 0, 1 }, { 2, 2 }, { 7, 1 }, { 12, 1 }, { 11, 1 }, { 9, 1 }, { 7, 3 },
}
local SCHLAG_DAUER = 0.18 -- Sekunden pro Schlag
local SPIELUHR_TONHOEHE = 1.6 -- PlaybackSpeed des Grundtons (höher = heller, mehr nach Spieluhr)
local musikNummer = 0
local musikSound: Sound? = nil

local function neuerMusikSound(tempo, lautstaerke)
	local sound = Instance.new("Sound")
	sound.Name = "MysteryBoxMusik"
	sound.SoundId = Config.Sounds.MysteryBoxMusik
	sound.PlaybackSpeed = tempo
	sound.Volume = lautstaerke
	sound.RollOffMinDistance = 6
	sound.RollOffMaxDistance = 60
	sound.Parent = korpus
	return sound
end

local function spieleNote(halbtoene, lautstaerke)
	if not korpus then
		return
	end
	local note = neuerMusikSound(SPIELUHR_TONHOEHE * 2 ^ (halbtoene / 12), lautstaerke)
	local echo = Instance.new("EchoSoundEffect")
	echo.Delay = 0.12
	echo.Feedback = 0.3
	echo.WetLevel = -6
	echo.Parent = note
	note:Play()
	task.delay(1.5, function()
		note:Destroy()
	end)
end

local function stoppeMusik(schlusston)
	musikNummer += 1
	if musikSound then
		musikSound:Destroy()
		musikSound = nil
	end
	if schlusston and Config.MysteryBoxSpieluhr ~= false and Config.Sounds.MysteryBoxMusik then
		spieleNote(12, 0.8)
		spieleNote(19, 0.5)
	end
end

local function starteMusik()
	stoppeMusik(false)
	if not korpus or not Config.Sounds or not Config.Sounds.MysteryBoxMusik then
		return
	end
	if Config.MysteryBoxSpieluhr == false then
		-- Eigene Musik-ID einfach abspielen
		musikSound = neuerMusikSound(1, 0.7)
		musikSound:Play()
		return
	end
	local meineNummer = musikNummer
	task.spawn(function()
		for _, note in MELODIE do
			if musikNummer ~= meineNummer then
				return
			end
			spieleNote(note[1], 0.6)
			task.wait(note[2] * SCHLAG_DAUER)
		end
	end)
end

-- Plätze ----------------------------------------------------------------------

local function punkteListe()
	local liste = {}
	local punkte = workspace:FindFirstChild("MysteryBoxPunkte")
	if punkte then
		for _, p in punkte:GetChildren() do
			if p:IsA("BasePart") then
				table.insert(liste, p)
			end
		end
	end
	return liste
end

local function bodenUnter(pos)
	local ausschluss = {}
	for _, objekt in { ordner, workspace:FindFirstChild("Zombies"), workspace:FindFirstChild("MysteryBoxPunkte") } do
		table.insert(ausschluss, objekt)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ausschluss, player.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ausschluss
	local treffer = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -80, 0), params)
	return treffer and treffer.Position or pos
end

local function flach(richtung, ersatz)
	local f = Vector3.new(richtung.X, 0, richtung.Z)
	if f.Magnitude < 0.01 then
		return ersatz
	end
	return f.Unit
end

local function platzCFrame(index)
	local punkte = punkteListe()
	local punkt = index and punkte[index]
	if punkt then
		-- Die Map legt die Unterkante der Platz-Teile genau auf den Boden: die nehmen wir direkt
		-- (ein Raycast würde durch Teile ohne CanQuery fallen und die Kiste im Boden versenken)
		local boden = punkt.Position - Vector3.new(0, punkt.Size.Y / 2, 0)
		return CFrame.lookAt(boden, boden + flach(punkt.CFrame.LookVector, Vector3.new(0, 0, -1)))
	end

	-- Kein Platz vorhanden: neben dem Spawnpunkt, Vorderseite zum Spawn
	local mitte = Vector3.zero
	local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		mitte = spawnLocation.Position
	end
	local boden = bodenUnter(mitte + Vector3.new(14, 0, 0))
	return CFrame.lookAt(boden, boden + flach(mitte - boden, Vector3.new(-1, 0, 0)))
end

-- Kiste bauen -----------------------------------------------------------------

local ausgeloest -- vorwärts deklariert

local function baueKiste(index)
	platzIndex = index
	basis = platzCFrame(index)
	scharnier = basis * CFrame.new(0, HOEHE, TIEFE / 2)
	deckelTeile = {}

	local modell = Instance.new("Model")
	modell.Name = "Kiste"

	-- Korpus
	local k = teil("Korpus", Vector3.new(BREITE, HOEHE, TIEFE), HOLZ, Enum.Material.WoodPlanks, basis * CFrame.new(0, HOEHE / 2, 0), modell)
	k.CanCollide = true
	k.CastShadow = true
	modell.PrimaryPart = k
	fragezeichen(k, Enum.NormalId.Front)
	fragezeichen(k, Enum.NormalId.Back)

	-- Metallkanten an den Ecken und Bänder oben/unten
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			teil("Kante", Vector3.new(0.25, HOEHE + 0.04, 0.25), METALL, Enum.Material.Metal,
				basis * CFrame.new(x * (BREITE / 2 - 0.08), HOEHE / 2, z * (TIEFE / 2 - 0.08)), modell)
		end
	end
	for _, y in { 0.15, HOEHE - 0.15 } do
		teil("Band", Vector3.new(BREITE + 0.06, 0.22, TIEFE + 0.06), METALL, Enum.Material.Metal, basis * CFrame.new(0, y, 0), modell)
	end

	-- Leuchtendes Inneres (sieht man, wenn der Deckel offen ist)
	teil("Inneres", Vector3.new(BREITE - 0.4, 0.1, TIEFE - 0.4), BLAU, Enum.Material.Neon, basis * CFrame.new(0, HOEHE - 0.08, 0), modell)

	-- Deckel (dreht sich um die hintere obere Kante)
	local function deckelTeil(name, groesse, farbe, material, lokal)
		local cf = basis * lokal
		local p = teil(name, groesse, farbe, material, cf, modell)
		table.insert(deckelTeile, { p, scharnier:ToObjectSpace(cf) })
		return p
	end
	local d = deckelTeil("Deckel", Vector3.new(BREITE, DECKEL, TIEFE), HOLZ, Enum.Material.WoodPlanks, CFrame.new(0, HOEHE + DECKEL / 2, 0))
	d.CanCollide = true
	d.CastShadow = true
	fragezeichen(d, Enum.NormalId.Top)
	deckelTeil("DeckelBand", Vector3.new(BREITE + 0.06, 0.18, TIEFE + 0.06), METALL, Enum.Material.Metal, CFrame.new(0, HOEHE + 0.12, 0))
	deckelTeil("Schloss", Vector3.new(0.5, 0.55, 0.15), Color3.fromRGB(200, 170, 70), Enum.Material.Metal,
		CFrame.new(0, HOEHE + 0.05, -TIEFE / 2 - 0.08))

	-- Lichtsäule, damit man die Box von weitem findet
	local saeule = teil("Lichtsaeule", Vector3.new(60, 1.4, 1.4), BLAU, Enum.Material.Neon,
		basis * CFrame.new(0, HOEHE + 8 + 30, 0) * CFrame.Angles(0, 0, math.pi / 2), modell, Enum.PartType.Cylinder)
	saeule.Transparency = 0.6
	saeule.CanQuery = false

	local licht = Instance.new("PointLight")
	licht.Color = BLAU
	licht.Brightness = 2
	licht.Range = 16
	licht.Parent = k

	-- Winkel des Deckels (wird per Tween animiert)
	local wert = Instance.new("NumberValue")
	wert.Name = "DeckelWinkel"
	wert.Value = 0
	wert.Parent = modell
	wert.Changed:Connect(setzeDeckel)
	deckelWinkel = wert

	local p = Instance.new("ProximityPrompt")
	p.ObjectText = "Mystery Box"
	p.ActionText = oeffnenText()
	p.HoldDuration = 0.3
	p.MaxActivationDistance = 8
	p.RequiresLineOfSight = false
	p.Parent = k
	p.Triggered:Connect(function(player)
		ausgeloest(player)
	end)

	modell.Parent = ordner
	kiste = modell
	korpus = k
	prompt = p
end

-- Ablauf ----------------------------------------------------------------------

local function waffenPools(player)
	local neu, alle = {}, {}
	for _, daten in WeaponData.Liste do
		if daten.Id ~= Config.StartWaffe then
			table.insert(alle, daten.Id)
			if not PlayerData.HatWaffe(player, daten.Id) then
				table.insert(neu, daten.Id)
			end
		end
	end
	return (#neu > 0 and neu or alle), alle
end

-- Waffe weg, Deckel zu, Box wieder bereit
local function schliessen()
	local meineRunde = runde
	stoppeMusik(false)
	zustand = "Schliesst"
	besitzer, gewinnId = nil, nil
	zeige(nil)
	if prompt then
		prompt.Enabled = false
	end
	deckel(0, 0.6)
	task.wait(0.7)
	if runde == meineRunde and zustand == "Schliesst" and prompt then
		zustand = "Bereit"
		prompt.ActionText = oeffnenText()
		prompt.Enabled = true
	end
end

local function boxWegfliegen(dauer)
	local modell = kiste
	if not modell then
		return
	end
	local teile = {}
	for _, objekt in modell:GetDescendants() do
		if objekt:IsA("BasePart") then
			table.insert(teile, { objekt, objekt.Transparency })
		elseif objekt:IsA("SurfaceGui") or objekt:IsA("Light") then
			objekt.Enabled = false
		end
	end
	local start = modell:GetPivot()
	local beginn = os.clock()
	while true do
		local a = math.min((os.clock() - beginn) / dauer, 1)
		modell:PivotTo(start * CFrame.new(0, 25 * a * a, 0) * CFrame.Angles(0, a * math.pi * 2, 0))
		for _, eintrag in teile do
			eintrag[1].Transparency = eintrag[2] + (1 - eintrag[2]) * a
		end
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

local function umziehen()
	zustand = "Umzug"
	besitzer, gewinnId = nil, nil
	if prompt then
		prompt.Enabled = false
	end

	-- Teddy schwebt davon, Deckel zu
	anzeigeZiel = 9
	task.wait(1.2)
	zeige(nil)
	deckel(0, 0.5)
	task.wait(0.7)

	-- Box hebt ab und verblasst
	boxWegfliegen(2)
	if kiste then
		kiste:Destroy()
	end
	kiste, korpus, prompt, deckelWinkel = nil, nil, nil, nil
	task.wait(UMZUG_PAUSE)

	-- Neuer Platz (nie derselbe wie vorher)
	local punkte = punkteListe()
	local auswahl = {}
	for i = 1, #punkte do
		if i ~= platzIndex then
			table.insert(auswahl, i)
		end
	end
	local neu = #auswahl > 0 and auswahl[math.random(#auswahl)] or (#punkte > 0 and 1 or nil)
	baueKiste(neu)
	nutzungen = 0
	zustand = "Bereit"
end

local function rollen(player)
	runde += 1
	local meineRunde = runde
	zustand = "Rollt"
	besitzer = player
	gewinnId = nil
	if prompt then
		prompt.Enabled = false
	end

	local bisher = nutzungen
	nutzungen += 1
	local mitTeddy = bisher >= Config.MysteryBoxMinNutzungen
		and #punkteListe() > 1
		and math.random() < Config.MysteryBoxUmzugChance

	local function abgebrochen()
		return runde ~= meineRunde or not spielerOk(player)
	end

	deckel(OEFFNUNGS_WINKEL, 0.6)
	spieleSound()
	starteMusik()
	task.wait(0.35)

	-- Waffen wechseln schnell durch und werden zum Ende hin langsamer
	local pool, alle = waffenPools(player)
	anzeigeHoehe = 0.3
	anzeigeZiel = 0.3
	local beginn = os.clock()
	local letzteId = nil
	while true do
		local vergangen = os.clock() - beginn
		if vergangen >= ROLL_DAUER then
			break
		end
		if abgebrochen() then
			if runde == meineRunde then
				schliessen()
			end
			return
		end
		local id = alle[math.random(#alle)]
		if #alle > 1 then
			while id == letzteId do
				id = alle[math.random(#alle)]
			end
		end
		letzteId = id
		zeige(WeaponService.Vorschau(id), math.pi / 2)
		local anteil = vergangen / ROLL_DAUER
		anzeigeZiel = 0.3 + 2.7 * anteil
		task.wait(0.05 + 0.4 * anteil ^ 3)
	end

	if abgebrochen() then
		if runde == meineRunde then
			schliessen()
		end
		return
	end

	stoppeMusik(true)

	-- Teddy: Geld zurück, Box zieht um
	if mitTeddy then
		zeige(teddyBauen(), 0)
		anzeigeZiel = 3
		PlayerData.GeldDazu(player, preis())
		Remotes.Notify:FireAllClients("🧸 Die Mystery Box zieht um!", ORANGE)
		Remotes.Notify:FireClient(player, "Du bekommst dein Geld zurück (💰" .. preis() .. ")", GRUEN)
		task.wait(2)
		if runde == meineRunde then
			umziehen()
		end
		return
	end

	-- Gewinn: Waffe bleibt schweben und sinkt langsam zurück in die Kiste
	local id = pool[math.random(#pool)]
	local daten = WeaponData.NachId[id]
	zeige(WeaponService.Vorschau(id), math.pi / 2)
	anzeigeZiel = 3
	gewinnId = id
	zustand = "Abholen"
	if prompt then
		prompt.ActionText = daten.Name .. " nehmen"
		prompt.Enabled = true
	end

	local abholzeit = Config.MysteryBoxAbholzeit
	local start = os.clock()
	while true do
		task.wait(0.1)
		if runde ~= meineRunde or zustand ~= "Abholen" then
			return -- abgeholt (oder neue Runde)
		end
		local anteil = (os.clock() - start) / abholzeit
		if anteil >= 1 or not spielerOk(player) then
			schliessen()
			return
		end
		anzeigeZiel = 3 - 2.6 * anteil
	end
end

ausgeloest = function(player)
	if zustand == "Bereit" then
		if not spielerOk(player) then
			return
		end
		if not PlayerData.Ausgeben(player, preis()) then
			Remotes.Notify:FireClient(player, "Nicht genug Geld! (" .. preis() .. " benötigt)", ROT)
			return
		end
		rollen(player)
	elseif zustand == "Abholen" then
		if player ~= besitzer then
			Remotes.Notify:FireClient(player, "Das ist nicht deine Waffe!", ROT)
			return
		end
		local id = gewinnId
		local daten = id and WeaponData.NachId[id]
		zustand = "Schliesst" -- sofort, damit doppeltes Auslösen nichts doppelt gibt
		if daten then
			PlayerData.MerkeWaffe(player, id)
			WeaponService.GibWaffe(player, id)
			Remotes.Notify:FireClient(player, daten.Name .. " erhalten!", GRUEN)
		end
		schliessen()
	end
end

function MysteryBox.Start()
	if zustand ~= "Aus" then
		return
	end
	zustand = "Start"

	local f = workspace:FindFirstChild("MysteryBox")
	if not f then
		f = Instance.new("Folder")
		f.Name = "MysteryBox"
		f.Parent = workspace
	end
	ordner = f :: Folder

	-- Die Map baut die Plätze beim Serverstart, kurz darauf warten
	local punkteOrdner = workspace:WaitForChild("MysteryBoxPunkte", 10)
	if punkteOrdner and #punkteListe() == 0 then
		task.wait(1)
	end

	RunService.Heartbeat:Connect(aktualisiereAnzeige)

	local punkte = punkteListe()
	baueKiste(#punkte > 0 and math.random(#punkte) or nil)
	zustand = "Bereit"
end

return MysteryBox
