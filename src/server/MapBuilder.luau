-- Baut beim Spielstart die Map: ein Nachbau von "Nuketown" im Klötzchen-Stil.
-- Zwei Häuser stehen sich an einer Sackgasse gegenüber, in der Mitte Schulbus und Lieferwagen.
-- Abschalten: Config.Map.Aktiv = false
--
-- Übersicht (Draufsicht, X nach rechts, Z nach unten):
--   HausGelb (2 Stockwerke) bei X = -78, Tür zeigt nach +X (zur Straße)
--   Ranchhaus (1 Stockwerk)  bei X = +80, Tür zeigt nach -X (zur Straße)
--   Wendeplatz (Asphalt) um X = 0, Z = 0, Straße läuft entlang Z
--   Spielfeld etwa X -130..130, Z -100..100

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

local zufall = Random.new(42) -- feste Zahl = jedes Mal die gleiche Map

-- Farben -----------------------------------------------------------------------

local FARBE = {
	Gelb = Color3.fromRGB(232, 190, 75),
	Weiss = Color3.fromRGB(236, 233, 224),
	Beige = Color3.fromRGB(205, 180, 140),
	DachBraun = Color3.fromRGB(80, 52, 38),
	DachGrau = Color3.fromRGB(70, 66, 66),
	Glas = Color3.fromRGB(110, 150, 175),
	Holzboden = Color3.fromRGB(150, 110, 75),
	Sockel = Color3.fromRGB(150, 145, 140),
	Beton = Color3.fromRGB(175, 172, 165),
	Rot = Color3.fromRGB(170, 35, 30),
	Schwarz = Color3.fromRGB(25, 25, 28),
	Zaun = Color3.fromRGB(215, 165, 105),
	Hecke = Color3.fromRGB(45, 85, 40),
	BusGelb = Color3.fromRGB(245, 190, 30),
	Dunkel = Color3.fromRGB(35, 40, 50),
}

local STRASSE_HALB = 16 -- halbe Straßenbreite
local WENDE_RADIUS = 44 -- Radius des Wendeplatzes
local GEHWEG_BREITE = 6

local function teil(eltern, groesse, farbe, cframe, material, form)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = groesse
	p.Color = farbe
	p.CFrame = cframe
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if form then
		p.Shape = form
	end
	p.Parent = eltern
	return p
end

local function modell(eltern, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = eltern
	return m
end

-- Glasscheibe (durchsichtig)
local function glas(eltern, groesse, cframe)
	local p = teil(eltern, groesse, FARBE.Glas, cframe, Enum.Material.Glass)
	p.Transparency = 0.45
	return p
end

-- Bauteile für Häuser ----------------------------------------------------------

-- Wand entlang der lokalen X-Achse. cf = Mitte der Wand an der Unterkante.
-- oeffnungen: { { x = Mitte, breite = , unten = , oben = , glas = true/false, fuellung = Color3 } }
local function wand(eltern, cf, laenge, hoehe, dicke, farbe, material, oeffnungen)
	oeffnungen = oeffnungen or {}
	table.sort(oeffnungen, function(a, b)
		return a.x < b.x
	end)

	local function block(x1, x2, y1, y2)
		if x2 - x1 > 0.01 and y2 - y1 > 0.01 then
			teil(eltern, Vector3.new(x2 - x1, y2 - y1, dicke), farbe,
				cf * CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, 0), material)
		end
	end

	local start = -laenge / 2
	for _, o in oeffnungen do
		local links, rechts = o.x - o.breite / 2, o.x + o.breite / 2
		block(start, links, 0, hoehe)
		block(links, rechts, 0, o.unten)
		block(links, rechts, o.oben, hoehe)
		local mitte = cf * CFrame.new(o.x, (o.unten + o.oben) / 2, 0)
		if o.glas then
			glas(eltern, Vector3.new(o.breite, o.oben - o.unten, 0.2), mitte)
			-- weiße Fensterbank
			teil(eltern, Vector3.new(o.breite + 0.6, 0.3, dicke + 0.4), FARBE.Weiss,
				cf * CFrame.new(o.x, o.unten - 0.15, 0))
		elseif o.fuellung then
			-- geschlossenes Garagentor
			teil(eltern, Vector3.new(o.breite, o.oben - o.unten, dicke * 0.6), o.fuellung, mitte, Enum.Material.Metal)
		end
		start = rechts
	end
	block(start, laenge / 2, 0, hoehe)
end

-- Vier Außenwände um ein Rechteck (breite entlang X, tiefe entlang Z).
-- cf = Mitte am Boden der Wände. Seitenwände: lokales x der Wand = -z des Hauses.
local function aussenwaende(eltern, cf, breite, tiefe, hoehe, farbe, material, vorne, hinten, links, rechts)
	local d = 1
	wand(eltern, cf * CFrame.new(0, 0, -tiefe / 2 + d / 2), breite, hoehe, d, farbe, material, vorne)
	wand(eltern, cf * CFrame.new(0, 0, tiefe / 2 - d / 2), breite, hoehe, d, farbe, material, hinten)
	wand(eltern, cf * CFrame.new(-breite / 2 + d / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0),
		tiefe - 2 * d, hoehe, d, farbe, material, links)
	wand(eltern, cf * CFrame.new(breite / 2 - d / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0),
		tiefe - 2 * d, hoehe, d, farbe, material, rechts)
end

-- Satteldach aus zwei gedrehten Platten (First entlang lokaler X-Achse).
-- cf = Mitte auf Höhe der Wandoberkante. Die Giebeldreiecke werden aus Stufen gebaut.
-- Gibt die CFrame der vorderen Dachplatte (Seite -Z) zurück, z. B. für Solarzellen.
local function satteldach(eltern, cf, breite, tiefe, ueberstand, winkel, dachFarbe, giebelFarbe)
	local halb = tiefe / 2
	local tanW = math.tan(winkel)
	local firstHoehe = halb * tanW -- First über der Wandoberkante
	local dachHalb = halb + ueberstand
	local laenge = dachHalb / math.cos(winkel) + 0.4
	local plattenDicke = 0.8
	local vorne = cf

	for _, seite in { -1, 1 } do
		-- Unterkante läuft von der Traufe bis zum First
		local traufe = Vector3.new(0, -ueberstand * tanW, seite * dachHalb)
		local richtung = (Vector3.new(0, firstHoehe, 0) - traufe).Unit
		local normale = Vector3.new(0, math.cos(winkel), seite * math.sin(winkel))
		local mitte = traufe + richtung * (laenge / 2) + normale * (plattenDicke / 2)
		local platteCf = cf * CFrame.new(mitte) * CFrame.Angles(seite * winkel, 0, 0)
		teil(eltern, Vector3.new(breite + 2 * ueberstand, plattenDicke, laenge), dachFarbe, platteCf, Enum.Material.Slate)
		if seite == -1 then
			vorne = platteCf
		end
	end

	-- Firstbalken
	teil(eltern, Vector3.new(breite + 2 * ueberstand, 0.6, 1.4), dachFarbe,
		cf * CFrame.new(0, firstHoehe + plattenDicke / math.cos(winkel), 0), Enum.Material.Slate)

	-- Giebel (Treppenstufen, damit nichts schief gedreht werden muss)
	local stufen = math.max(2, math.ceil(firstHoehe / 1.4))
	local stufenHoehe = firstHoehe / stufen
	for k = 0, stufen - 1 do
		local halbeBreite = halb * (1 - (k + 0.5) / stufen)
		for _, x in { -breite / 2 + 0.5, breite / 2 - 0.5 } do
			teil(eltern, Vector3.new(1, stufenHoehe, halbeBreite * 2), giebelFarbe,
				cf * CFrame.new(x, k * stufenHoehe + stufenHoehe / 2, 0), Enum.Material.Plaster)
		end
	end

	return vorne
end

-- Offene Tür (Türblatt steht aufgeklappt an der Innenwand)
local function offeneTuer(eltern, cf, farbe)
	local p = teil(eltern, Vector3.new(0.3, 7.6, 5), farbe, cf, Enum.Material.Wood)
	p.CanCollide = false
	return p
end

-- Kleine Möbel
local function sofa(eltern, cf, farbe)
	teil(eltern, Vector3.new(7, 1.6, 3), farbe, cf * CFrame.new(0, 0.8, 0), Enum.Material.Fabric)
	teil(eltern, Vector3.new(7, 2, 1), farbe, cf * CFrame.new(0, 2.6, 1), Enum.Material.Fabric)
end

local function tisch(eltern, cf)
	teil(eltern, Vector3.new(5, 0.3, 3.5), Color3.fromRGB(120, 85, 55), cf * CFrame.new(0, 2.8, 0), Enum.Material.Wood)
	teil(eltern, Vector3.new(0.8, 2.6, 0.8), Color3.fromRGB(90, 65, 45), cf * CFrame.new(0, 1.3, 0), Enum.Material.Wood)
end

-- Häuser -----------------------------------------------------------------------

-- Zweistöckiges Haus: unten gelb, oben weiß, braunes Satteldach, Garage daneben.
-- Lokal: vorne = -Z, Garage auf der +X-Seite.
local function hausGelb(deko, mitte, drehung)
	local m = modell(deko, "HausGelb")
	local cf = CFrame.new(mitte) * CFrame.Angles(0, drehung, 0)
	local b, t = 36, 26 -- Breite, Tiefe
	local s = 0.5 -- Sockelhöhe (Fußboden)
	local h1, h2 = 12, 10 -- Erdgeschoss, Obergeschoss

	-- Sockel und Holzboden
	teil(m, Vector3.new(b, 1, t), FARBE.Sockel, cf * CFrame.new(0, 0, 0), Enum.Material.Concrete)
	teil(m, Vector3.new(b - 2, 0.1, t - 2), FARBE.Holzboden, cf * CFrame.new(0, s + 0.05, 0), Enum.Material.WoodPlanks)

	-- Erdgeschoss (gelb)
	local fensterEG = function(x, breite)
		return { x = x, breite = breite, unten = 3, oben = 8.5, glas = true }
	end
	aussenwaende(m, cf * CFrame.new(0, s, 0), b, t, h1, FARBE.Gelb, Enum.Material.Plaster,
		{ fensterEG(-14.5, 4), { x = -8, breite = 6, unten = 0, oben = 8 }, fensterEG(3, 5), fensterEG(11, 5) },
		{ fensterEG(-10, 5), { x = 12, breite = 5, unten = 0, oben = 8 } },
		{ fensterEG(0, 6) },
		{ { x = 4, breite = 5, unten = 0, oben = 8 } } -- Tür zur Garage
	)

	-- Zwischendecke mit Loch für die Treppe (Treppe an der Rückwand, x -16..8, z 8..12)
	local deckeY = s + h1 - 0.5
	teil(m, Vector3.new(34, 1, 20), FARBE.Holzboden, cf * CFrame.new(0, deckeY, -2), Enum.Material.WoodPlanks)
	teil(m, Vector3.new(10.5, 1, 4), FARBE.Holzboden, cf * CFrame.new(11.75, deckeY, 10), Enum.Material.WoodPlanks)

	-- Treppe: 16 Stufen à 0,75 Studs
	local stufen = 16
	local stufenHoehe = h1 / stufen
	for k = 0, stufen - 1 do
		local hoehe = stufenHoehe * (k + 1)
		teil(m, Vector3.new(1.5, hoehe, 4), Color3.fromRGB(130, 95, 65),
			cf * CFrame.new(-16 + 1.5 * k + 0.75, s + hoehe / 2, 10), Enum.Material.Wood)
	end
	-- Geländer oben am Treppenloch
	teil(m, Vector3.new(22, 3, 0.3), Color3.fromRGB(110, 80, 55), cf * CFrame.new(-6, s + h1 + 1.5, 8), Enum.Material.Wood)

	-- Obergeschoss (weiß)
	local fensterOG = function(x)
		return { x = x, breite = 5, unten = 3, oben = 7, glas = true }
	end
	aussenwaende(m, cf * CFrame.new(0, s + h1, 0), b, t, h2, FARBE.Weiss, Enum.Material.Plaster,
		{ fensterOG(-12), fensterOG(0), fensterOG(12) },
		{ fensterOG(-10), fensterOG(10) },
		{ fensterOG(0) },
		{ fensterOG(0) }
	)

	-- Dach
	satteldach(m, cf * CFrame.new(0, s + h1 + h2, 0), b, t, 1.5, math.rad(30), FARBE.DachBraun, FARBE.Weiss)

	-- Vordach über der Haustür mit roter Tür
	teil(m, Vector3.new(10, 1, 5), FARBE.Beton, cf * CFrame.new(-8, 0, -15.5), Enum.Material.Concrete)
	for _, x in { -12.5, -3.5 } do
		teil(m, Vector3.new(0.6, 8.5, 0.6), FARBE.Weiss, cf * CFrame.new(x, s + 4.25, -17.5))
	end
	teil(m, Vector3.new(11, 0.5, 6), FARBE.DachBraun, cf * CFrame.new(-8, s + 8.75, -16), Enum.Material.Slate)
	offeneTuer(m, cf * CFrame.new(-10.8, s + 3.9, -9.6), FARBE.Rot)

	-- Möbel
	sofa(m, cf * CFrame.new(6, s, -4) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(110, 60, 50))
	tisch(m, cf * CFrame.new(-6, s, 0))
	teil(m, Vector3.new(10, 3.5, 2.5), Color3.fromRGB(200, 195, 185), cf * CFrame.new(11, s + 1.75, 6.5)) -- Küche
	tisch(m, cf * CFrame.new(-8, s + h1, -4))

	-- Garage (weiß, Tor offen), Mitte lokal x = 26
	local gcf = cf * CFrame.new(26, 0, -2)
	local gb, gt, gh = 16, 22, 9
	teil(m, Vector3.new(gb, 1, gt), FARBE.Beton, gcf, Enum.Material.Concrete)
	wand(m, gcf * CFrame.new(0, s, -gt / 2 + 0.5), gb, gh, 1, FARBE.Weiss, Enum.Material.Plaster,
		{ { x = 0, breite = 12, unten = 0, oben = 8 } })
	wand(m, gcf * CFrame.new(0, s, gt / 2 - 0.5), gb, gh, 1, FARBE.Weiss, Enum.Material.Plaster)
	wand(m, gcf * CFrame.new(gb / 2 - 0.5, s, 0) * CFrame.Angles(0, math.pi / 2, 0), gt - 2, gh, 1,
		FARBE.Weiss, Enum.Material.Plaster, { { x = 0, breite = 5, unten = 3.5, oben = 7, glas = true } })
	-- linke Garagenwand = rechte Hauswand (mit Tür ins Haus)
	-- hochgeklapptes Tor unter der Decke
	teil(m, Vector3.new(12, 0.3, 7), Color3.fromRGB(225, 222, 215), gcf * CFrame.new(0, s + 8.3, -gt / 2 + 4.5), Enum.Material.Metal)
	satteldach(m, gcf * CFrame.new(0, s + gh, 0) * CFrame.Angles(0, math.pi / 2, 0), gt, gb, 1, math.rad(25),
		FARBE.DachGrau, FARBE.Weiss)
	teil(m, Vector3.new(4, 4, 4), Color3.fromRGB(160, 120, 80), gcf * CFrame.new(5, s + 2, 7), Enum.Material.Cardboard)

	return m
end

-- Langes einstöckiges Ranchhaus: beige, dunkles Dach, Kamin, rotes Garagentor, Solarzellen.
-- Lokal: vorne = -Z, Garage auf der +X-Seite.
local function ranchhaus(deko, mitte, drehung)
	local m = modell(deko, "Ranchhaus")
	local cf = CFrame.new(mitte) * CFrame.Angles(0, drehung, 0)
	local b, t, h = 60, 24, 10
	local s = 0.5

	teil(m, Vector3.new(b, 1, t), FARBE.Sockel, cf, Enum.Material.Concrete)
	teil(m, Vector3.new(34, 0.1, t - 2), FARBE.Holzboden, cf * CFrame.new(-12, s + 0.05, 0), Enum.Material.WoodPlanks)

	local fenster = function(x, breite, unten)
		return { x = x, breite = breite, unten = unten or 3, oben = 8, glas = true }
	end
	aussenwaende(m, cf * CFrame.new(0, s, 0), b, t, h, FARBE.Beige, Enum.Material.Plaster,
		{
			fenster(-22, 9, 2.5),
			fenster(-10, 9, 2.5),
			{ x = 2, breite = 6, unten = 0, oben = 8 },
			fenster(10, 5),
			{ x = 23, breite = 11, unten = 0, oben = 8, fuellung = FARBE.Rot }, -- Garagentor (zu)
		},
		{ fenster(-20, 6), { x = -4, breite = 6, unten = 0, oben = 8 }, fenster(8, 6), fenster(23, 4) },
		{ fenster(0, 6) },
		{}
	)
	-- Trennwand zur Garage mit Tür
	wand(m, cf * CFrame.new(17, s, 0) * CFrame.Angles(0, math.pi / 2, 0), t - 2, h, 1, FARBE.Beige,
		Enum.Material.Plaster, { { x = 0, breite = 5, unten = 0, oben = 8 } })

	local vorne = satteldach(m, cf * CFrame.new(0, s + h, 0), b, t, 2, math.rad(20), FARBE.DachGrau, FARBE.Beige)

	-- Kamin
	local kaminHoehe = h + 9
	teil(m, Vector3.new(3, kaminHoehe, 3), Color3.fromRGB(140, 75, 55), cf * CFrame.new(-14, s + kaminHoehe / 2, 5),
		Enum.Material.Brick)

	-- Solarzellen auf der vorderen Dachfläche
	for _, x in { -22, -12, -2 } do
		local p = teil(m, Vector3.new(8, 0.2, 6), Color3.fromRGB(185, 200, 220), vorne * CFrame.new(x, 0.5, 0.5),
			Enum.Material.Glass)
		p.Reflectance = 0.15
	end

	-- Haustür, Treppenstufe
	offeneTuer(m, cf * CFrame.new(-1.2, s + 3.9, -8.4), Color3.fromRGB(120, 70, 45))
	teil(m, Vector3.new(8, 0.5, 3), FARBE.Beton, cf * CFrame.new(2, 0.25, -13.5), Enum.Material.Concrete)

	-- Möbel
	sofa(m, cf * CFrame.new(-16, s, 6), Color3.fromRGB(70, 90, 120))
	tisch(m, cf * CFrame.new(-16, s, -2))
	teil(m, Vector3.new(5, 3, 1), FARBE.Schwarz, cf * CFrame.new(-16, s + 1.5, -10)) -- Fernseher
	teil(m, Vector3.new(8, 3.5, 2.5), Color3.fromRGB(200, 195, 185), cf * CFrame.new(8, s + 1.75, 9.5)) -- Küche

	-- Büsche unter den Fenstern
	for _, x in { -22, -10 } do
		teil(m, Vector3.new(8, 3, 2.5), FARBE.Hecke, cf * CFrame.new(x, 1.5, -13.5), Enum.Material.Grass)
	end

	return m
end

-- Kleiner Gartenschuppen (Tür zeigt nach -Z)
local function schuppen(deko, mitte, drehung)
	local m = modell(deko, "Schuppen")
	local cf = CFrame.new(mitte) * CFrame.Angles(0, drehung, 0)
	local farbe = Color3.fromRGB(150, 95, 60)
	teil(m, Vector3.new(10, 1, 10), FARBE.Sockel, cf, Enum.Material.Concrete)
	aussenwaende(m, cf * CFrame.new(0, 0.5, 0), 10, 10, 8.5, farbe, Enum.Material.WoodPlanks,
		{ { x = 0, breite = 5, unten = 0, oben = 7.5 } }, {}, {}, { { x = 0, breite = 3, unten = 4, oben = 6.5, glas = true } })
	satteldach(m, cf * CFrame.new(0, 9, 0), 10, 10, 1, math.rad(30), FARBE.DachBraun, farbe)
	return m
end

-- Fahrzeuge (lokal: Länge entlang Z, vorne = -Z) -------------------------------

local function rad(m, cf, x, z, durchmesser, breite)
	-- Zylinder liegen mit der Achse entlang X = genau die Achsrichtung
	teil(m, Vector3.new(breite, durchmesser, durchmesser), FARBE.Schwarz, cf * CFrame.new(x, durchmesser / 2, z),
		Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
end

local function schulbus(deko, cf)
	local m = modell(deko, "Schulbus")
	local function s(groesse, pos, farbe, material)
		return teil(m, groesse, farbe, cf * CFrame.new(pos), material)
	end
	-- Aufbau
	s(Vector3.new(8, 5, 28), Vector3.new(0, 4.5, 2), FARBE.BusGelb)
	s(Vector3.new(8, 3, 28), Vector3.new(0, 8.5, 2), FARBE.BusGelb)
	s(Vector3.new(8.2, 0.5, 28.4), Vector3.new(0, 10.25, 2), Color3.fromRGB(250, 215, 90))
	-- Motorhaube und Front
	s(Vector3.new(7, 3.5, 6), Vector3.new(0, 3.75, -15), FARBE.BusGelb)
	s(Vector3.new(7.4, 2.4, 0.2), Vector3.new(0, 8.4, -12.05), FARBE.Dunkel, Enum.Material.Glass)
	s(Vector3.new(4, 2.6, 0.2), Vector3.new(0, 3.8, -18.05), Color3.fromRGB(120, 120, 125), Enum.Material.Metal)
	-- Stoßstangen
	s(Vector3.new(8, 0.8, 0.6), Vector3.new(0, 2.2, -18.3), FARBE.Schwarz)
	s(Vector3.new(8, 0.8, 0.6), Vector3.new(0, 2.2, 16.3), FARBE.Schwarz)
	for _, seite in { -1, 1 } do
		-- Fensterband und schwarze Streifen
		s(Vector3.new(0.2, 2, 25), Vector3.new(seite * 4.05, 8.6, 3), FARBE.Dunkel, Enum.Material.Glass)
		s(Vector3.new(0.15, 0.3, 28), Vector3.new(seite * 4.05, 4, 2), FARBE.Schwarz)
		s(Vector3.new(0.15, 0.3, 28), Vector3.new(seite * 4.05, 6.3, 2), FARBE.Schwarz)
		-- Lichter
		s(Vector3.new(0.8, 0.8, 0.2), Vector3.new(seite * 3, 6, 16.1), Color3.fromRGB(220, 30, 30), Enum.Material.Neon)
		s(Vector3.new(0.8, 0.8, 0.2), Vector3.new(seite * 3, 9.7, -12.1), Color3.fromRGB(220, 30, 30), Enum.Material.Neon)
		s(Vector3.new(0.8, 0.8, 0.2), Vector3.new(seite * 2.6, 4.5, -18.1), Color3.fromRGB(255, 240, 190), Enum.Material.Neon)
		for _, z in { -14, 11 } do
			rad(m, cf, seite * 3.6, z, 3.6, 1.4)
		end
	end
	-- Stoppschild an der Fahrerseite
	s(Vector3.new(0.2, 1.6, 1.6), Vector3.new(-4.25, 6, -9), Color3.fromRGB(200, 25, 25))
	return m
end

local function lieferwagen(deko, cf)
	local m = modell(deko, "Lieferwagen")
	local function s(groesse, pos, farbe, material)
		return teil(m, groesse, farbe, cf * CFrame.new(pos), material)
	end
	s(Vector3.new(8, 5.5, 7), Vector3.new(0, 4.75, -9.5), FARBE.Rot) -- Führerhaus
	s(Vector3.new(7.2, 2.2, 0.2), Vector3.new(0, 6.2, -13.05), FARBE.Dunkel, Enum.Material.Glass)
	s(Vector3.new(8.4, 8.5, 19), Vector3.new(0, 6.25, 3.5), FARBE.Weiss) -- Kofferaufbau
	s(Vector3.new(7, 1, 26), Vector3.new(0, 1.8, -0.5), Color3.fromRGB(60, 60, 65), Enum.Material.Metal) -- Fahrgestell
	s(Vector3.new(8, 0.8, 0.6), Vector3.new(0, 2.3, -13.3), Color3.fromRGB(190, 190, 195), Enum.Material.Metal)
	for _, seite in { -1, 1 } do
		s(Vector3.new(0.2, 2, 4), Vector3.new(seite * 4.05, 6.3, -10), FARBE.Dunkel, Enum.Material.Glass)
		s(Vector3.new(0.15, 1.2, 19), Vector3.new(seite * 4.25, 5, 3.5), FARBE.Rot)
		s(Vector3.new(0.8, 0.8, 0.2), Vector3.new(seite * 3, 3.5, 13.1), Color3.fromRGB(220, 30, 30), Enum.Material.Neon)
		s(Vector3.new(0.8, 0.8, 0.2), Vector3.new(seite * 2.8, 3.5, -13.1), Color3.fromRGB(255, 240, 190), Enum.Material.Neon)
		for _, z in { -10, 5, 9.5 } do
			rad(m, cf, seite * 3.6, z, 3.4, 1.4)
		end
	end
	return m
end

local function oldtimer(deko, cf)
	local m = modell(deko, "Oldtimer")
	local function s(groesse, pos, farbe, material)
		return teil(m, groesse, farbe, cf * CFrame.new(pos), material)
	end
	local rot = Color3.fromRGB(185, 30, 35)
	s(Vector3.new(6, 2.2, 15), Vector3.new(0, 2.1, 0), rot)
	s(Vector3.new(5.4, 2, 7), Vector3.new(0, 4.2, 1), rot)
	s(Vector3.new(5.6, 0.3, 7.2), Vector3.new(0, 5.35, 1), FARBE.Weiss)
	s(Vector3.new(5, 1.6, 0.2), Vector3.new(0, 4.2, -2.55), FARBE.Dunkel, Enum.Material.Glass)
	s(Vector3.new(5, 1.6, 0.2), Vector3.new(0, 4.2, 4.55), FARBE.Dunkel, Enum.Material.Glass)
	for _, seite in { -1, 1 } do
		s(Vector3.new(0.2, 1.5, 6), Vector3.new(seite * 2.75, 4.25, 1), FARBE.Dunkel, Enum.Material.Glass)
		s(Vector3.new(0.15, 0.3, 15), Vector3.new(seite * 3.05, 2.4, 0), FARBE.Weiss) -- Zierleiste
		s(Vector3.new(1, 0.8, 0.2), Vector3.new(seite * 2, 2.4, -7.55), Color3.fromRGB(255, 240, 190), Enum.Material.Neon)
		s(Vector3.new(0.8, 0.8, 0.2), Vector3.new(seite * 2.2, 2.4, 7.55), Color3.fromRGB(220, 30, 30), Enum.Material.Neon)
		for _, z in { -4.8, 4.8 } do
			rad(m, cf, seite * 2.7, z, 2.4, 1)
		end
	end
	for _, z in { -7.8, 7.8 } do
		s(Vector3.new(6.4, 0.5, 0.5), Vector3.new(0, 1.4, z), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
	end
	return m
end

-- Gartendeko -------------------------------------------------------------------

-- Lattenzaun von a nach b (auf dem Boden). luecken = { {von, bis} } in Studs ab a (für Tore).
local function zaun(eltern, a, b, luecken)
	local laenge = (b - a).Magnitude
	local richtung = (b - a).Unit
	local basis = CFrame.lookAt(a, b) -- lokale -Z zeigt von a nach b
	local hoehe = 3.5

	local function inLuecke(d)
		for _, l in luecken or {} do
			if d > l[1] and d < l[2] then
				return true
			end
		end
		return false
	end

	-- Abschnitte ohne Lücken: je zwei Querlatten
	local abschnitte = {}
	local start = 0
	for _, l in luecken or {} do
		table.insert(abschnitte, { start, l[1] })
		start = l[2]
	end
	table.insert(abschnitte, { start, laenge })
	for _, ab in abschnitte do
		local len = ab[2] - ab[1]
		if len > 0.5 then
			local mitteD = (ab[1] + ab[2]) / 2
			for _, y in { 1, 2.6 } do
				teil(eltern, Vector3.new(0.25, 0.35, len), FARBE.Zaun, basis * CFrame.new(0, y, -mitteD), Enum.Material.Wood)
			end
			for _, d in { ab[1] + 0.3, ab[2] - 0.3 } do
				teil(eltern, Vector3.new(0.6, hoehe + 0.5, 0.6), FARBE.Zaun, basis * CFrame.new(0, (hoehe + 0.5) / 2, -d),
					Enum.Material.Wood)
			end
		end
	end

	-- Latten
	local d = 0.8
	while d < laenge - 0.5 do
		if not inLuecke(d) then
			teil(eltern, Vector3.new(0.15, hoehe, 0.6), FARBE.Zaun, basis * CFrame.new(0.2, hoehe / 2, -d), Enum.Material.Wood)
		end
		d += 1.3
	end
	return richtung
end

local function hecke(eltern, mitte, groesse)
	local p = teil(eltern, groesse, FARBE.Hecke, CFrame.new(mitte + Vector3.new(0, groesse.Y / 2, 0)), Enum.Material.Grass)
	-- etwas hellere Oberseite für den Klötzchen-Look
	teil(eltern, Vector3.new(groesse.X - 1, 0.6, groesse.Z - 1), Color3.fromRGB(60, 105, 50),
		CFrame.new(mitte + Vector3.new(0, groesse.Y + 0.3, 0)), Enum.Material.Grass)
	return p
end

local function briefkasten(eltern, position)
	local m = modell(eltern, "Briefkasten")
	teil(m, Vector3.new(0.4, 3.5, 0.4), Color3.fromRGB(110, 80, 55), CFrame.new(position + Vector3.new(0, 1.75, 0)), Enum.Material.Wood)
	teil(m, Vector3.new(1.2, 1.1, 2), Color3.fromRGB(70, 90, 140), CFrame.new(position + Vector3.new(0, 4, 0)), Enum.Material.Metal)
	teil(m, Vector3.new(0.1, 0.8, 0.2), FARBE.Rot, CFrame.new(position + Vector3.new(0.65, 4.4, 0.5)))
end

local function karton(eltern, position, groesse, drehung)
	teil(eltern, groesse, Color3.fromRGB(165, 125, 80),
		CFrame.new(position + Vector3.new(0, groesse.Y / 2, 0)) * CFrame.Angles(0, drehung or 0, 0), Enum.Material.Cardboard)
end

local function baum(eltern, position)
	local hoehe = zufall:NextNumber(10, 18)
	local dicke = zufall:NextNumber(1.5, 2.5)
	local m = modell(eltern, "Baum")

	-- Zylinder liegen auf der Seite, deshalb um 90° drehen
	teil(m, Vector3.new(hoehe, dicke, dicke), Color3.fromRGB(95, 70, 45),
		CFrame.new(position + Vector3.new(0, hoehe / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Enum.Material.Wood, Enum.PartType.Cylinder)

	-- Klötzchenkrone
	local gruen = Color3.fromRGB(zufall:NextInteger(45, 70), zufall:NextInteger(100, 135), zufall:NextInteger(40, 60))
	for i = 1, 3 do
		local d = zufall:NextNumber(7, 11) - i
		local versatz = Vector3.new(zufall:NextNumber(-2, 2), hoehe + i * 2 - 2, zufall:NextNumber(-2, 2))
		local krone = teil(m, Vector3.new(d, d * 0.8, d), gruen,
			CFrame.new(position + versatz) * CFrame.Angles(0, zufall:NextNumber(0, math.pi), 0), Enum.Material.Grass)
		krone.CanCollide = false
	end
end

-- Straße und Gehwege -----------------------------------------------------------

local function strasse(deko, groesse)
	local terrain = workspace.Terrain
	-- Straße entlang Z und runder Wendeplatz (Oberkante bei 0)
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(STRASSE_HALB * 2, 12, groesse), Enum.Material.Asphalt)
	terrain:FillCylinder(CFrame.new(0, -6, 0), 12, WENDE_RADIUS, Enum.Material.Asphalt)
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Asphalt, Color3.fromRGB(55, 55, 60))
	end)

	local gehweg = Instance.new("Folder")
	gehweg.Name = "Gehweg"
	gehweg.Parent = deko

	-- Ring um den Wendeplatz (Bordstein: Oberkante 0,4)
	local r = WENDE_RADIUS + GEHWEG_BREITE / 2
	local stuecke = 28
	local bogen = 2 * math.pi * r / stuecke + 0.8
	for i = 0, stuecke - 1 do
		local winkel = i / stuecke * math.pi * 2
		local x, z = math.cos(winkel) * r, math.sin(winkel) * r
		if math.abs(x) > STRASSE_HALB + 3 then
			teil(gehweg, Vector3.new(GEHWEG_BREITE, 1, bogen), FARBE.Beton,
				CFrame.new(x, -0.1, z) * CFrame.Angles(0, -winkel, 0), Enum.Material.Concrete)
		end
	end

	-- Gerade Gehwege an der Straße
	local zStart = math.sqrt(WENDE_RADIUS ^ 2 - STRASSE_HALB ^ 2)
	local zEnde = 150
	local len = zEnde - zStart
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			teil(gehweg, Vector3.new(GEHWEG_BREITE, 1, len), FARBE.Beton,
				CFrame.new(sx * (STRASSE_HALB + GEHWEG_BREITE / 2), -0.1, sz * (zStart + len / 2)), Enum.Material.Concrete)
		end
	end

	-- Mittellinie auf den Straßenenden
	for _, sz in { -1, 1 } do
		for z = WENDE_RADIUS + 8, 140, 12 do
			local linie = teil(gehweg, Vector3.new(0.5, 0.1, 6), Color3.fromRGB(235, 225, 170), CFrame.new(0, 0.05, sz * z))
			linie.CanCollide = false
			linie.CanQuery = false
		end
	end
end

-- Einfahrt/Weg aus Beton (Oberkante 0,35, etwas unter dem Gehweg)
local function platte(eltern, von, bis)
	local groesse = Vector3.new(math.abs(bis.X - von.X), 1, math.abs(bis.Z - von.Z))
	local mitte = (von + bis) / 2
	teil(eltern, groesse, FARBE.Beton, CFrame.new(mitte.X, -0.15, mitte.Z), Enum.Material.Concrete)
end

-- Zombie-Spawns ----------------------------------------------------------------

local ZOMBIE_SPAWNS = {
	Vector3.new(-150, 0, -65), -- hinter HausGelb
	Vector3.new(-150, 0, 60),
	Vector3.new(150, 0, -65), -- hinter Ranchhaus
	Vector3.new(150, 0, 65),
	Vector3.new(0, 0, -140), -- Straßenenden
	Vector3.new(0, 0, 140),
	Vector3.new(-75, 0, 120), -- Ecken
	Vector3.new(75, 0, -120),
}

local function zombieSpawns()
	if workspace:FindFirstChild("ZombieSpawns") then
		return -- selbst gebaute Spawns nicht überschreiben
	end
	local ordner = Instance.new("Folder")
	ordner.Name = "ZombieSpawns"
	for i, position in ZOMBIE_SPAWNS do
		local p = Instance.new("Part")
		p.Name = "Spawn" .. i
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(16, 1, 16)
		p.CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0))
		p.Parent = ordner
	end
	ordner.Parent = workspace
end

local function nahAnSpawn(position, abstand)
	for _, s in ZOMBIE_SPAWNS do
		if (s - position).Magnitude < abstand then
			return true
		end
	end
	return false
end

-- Start ------------------------------------------------------------------------

function MapBuilder.Bauen()
	local einstellungen = Config.Map
	if not einstellungen.Aktiv then
		return
	end
	local groesse = einstellungen.Groesse

	-- Die graue Baseplate aus der Vorlage entfernen, die Wiese ersetzt sie
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	-- Boden aus Terrain: Meer, Strand, Wiese (Oberkante jeweils bei 0)
	local terrain = workspace.Terrain
	if einstellungen.Meer then
		terrain:FillBlock(CFrame.new(0, -5, 0), Vector3.new(groesse + 600, 10, groesse + 600), Enum.Material.Water)
		terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(groesse + 40, 12, groesse + 40), Enum.Material.Sand)
	end
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(groesse, 12, groesse), Enum.Material.Grass)
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(85, 130, 55))
	end)

	local deko = workspace:FindFirstChild("Deko")
	if not deko then
		deko = Instance.new("Folder")
		deko.Name = "Deko"
		deko.Parent = workspace
	end

	strasse(deko, groesse)

	-- Häuser: HausGelb links (Tür nach +X), Ranchhaus rechts (Tür nach -X)
	hausGelb(deko, Vector3.new(-78, 0, -12), -math.pi / 2)
	ranchhaus(deko, Vector3.new(80, 0, 8), math.pi / 2)

	-- Einfahrten und Wege zur Straße
	local wege = Instance.new("Folder")
	wege.Name = "Einfahrten"
	wege.Parent = deko
	platte(wege, Vector3.new(-65, 0, 7), Vector3.new(-46, 0, 21)) -- Garage HausGelb
	platte(wege, Vector3.new(-60, 0, -22), Vector3.new(-45, 0, -18)) -- Weg zur Haustür
	platte(wege, Vector3.new(46, 0, -21), Vector3.new(68, 0, -9)) -- Garage Ranchhaus
	platte(wege, Vector3.new(47, 0, 4), Vector3.new(66.5, 0, 8)) -- Weg zur Haustür

	-- Fahrzeuge als Deckung
	if einstellungen.Fahrzeuge then
		schulbus(deko, CFrame.new(11, 0, -17) * CFrame.Angles(0, math.rad(32), 0))
		lieferwagen(deko, CFrame.new(-9, 0, 25) * CFrame.Angles(0, math.rad(-20), 0))
		oldtimer(deko, CFrame.new(-55, 0.35, 14) * CFrame.Angles(0, -math.pi / 2, 0))
	end

	-- Kartons auf der Straße
	local kartons = modell(deko, "Kartons")
	karton(kartons, Vector3.new(14, 0, 18), Vector3.new(2.5, 2, 2.5), 0.4)
	karton(kartons, Vector3.new(-2, 0, 5), Vector3.new(3, 2.5, 3), 0.9)
	karton(kartons, Vector3.new(-2, 2.5, 5), Vector3.new(2, 1.5, 2), 0.2)
	karton(kartons, Vector3.new(-26, 0, -8), Vector3.new(2.5, 2.5, 2.5), 0.1)

	-- Briefkästen
	briefkasten(deko, Vector3.new(-46, 0.4, -25))
	briefkasten(deko, Vector3.new(48, 0.4, 11))

	-- Gärten: Zäune (mit Toren, damit Zombies durchkommen), Hecken, Schuppen
	local garten = Instance.new("Folder")
	garten.Name = "Gaerten"
	garten.Parent = deko

	-- Garten HausGelb (X -128..-91)
	zaun(garten, Vector3.new(-91, 0, -38), Vector3.new(-128, 0, -38), { { 16, 24 } })
	zaun(garten, Vector3.new(-128, 0, -38), Vector3.new(-128, 0, 34), { { 10, 18 }, { 44, 52 } })
	zaun(garten, Vector3.new(-128, 0, 34), Vector3.new(-87, 0, 34), { { 14, 22 } })
	hecke(garten, Vector3.new(-122, 0, -12), Vector3.new(6, 4, 14))
	hecke(garten, Vector3.new(-100, 0, -33), Vector3.new(12, 4, 5))
	hecke(garten, Vector3.new(-122, 0, 4), Vector3.new(5, 3.5, 6))
	schuppen(garten, Vector3.new(-114, 0, 22), -math.pi / 2) -- Tür zum Haus
	-- Trittsteine von der Hintertür zum Schuppen
	for i = 0, 5 do
		local stein = teil(garten, Vector3.new(2.2, 0.2, 2.2), Color3.fromRGB(160, 155, 150),
			CFrame.new(-94 - i * 2.8, 0.1, 0 + i * 2.6) * CFrame.Angles(0, i * 0.4, 0), Enum.Material.Slate)
		stein.CanCollide = false
	end

	-- Garten Ranchhaus (X 92..128)
	zaun(garten, Vector3.new(92, 0, -30), Vector3.new(128, 0, -30), { { 14, 22 } })
	zaun(garten, Vector3.new(128, 0, -30), Vector3.new(128, 0, 46), { { 12, 20 }, { 50, 58 } })
	zaun(garten, Vector3.new(128, 0, 46), Vector3.new(92, 0, 46), { { 12, 20 } })
	hecke(garten, Vector3.new(110, 0, 8), Vector3.new(14, 4.5, 6))
	hecke(garten, Vector3.new(121, 0, -20), Vector3.new(6, 4, 10))
	hecke(garten, Vector3.new(100, 0, 38), Vector3.new(8, 4, 6))
	-- Gartentisch
	local gartentisch = modell(garten, "Gartentisch")
	teil(gartentisch, Vector3.new(6, 0.4, 3), Color3.fromRGB(140, 100, 65), CFrame.new(108, 2.8, 26), Enum.Material.Wood)
	for _, z in { 23.8, 28.2 } do
		teil(gartentisch, Vector3.new(6, 0.4, 1.2), Color3.fromRGB(140, 100, 65), CFrame.new(108, 1.6, z), Enum.Material.Wood)
	end
	teil(gartentisch, Vector3.new(1, 2.6, 1), Color3.fromRGB(110, 80, 50), CFrame.new(108, 1.3, 26), Enum.Material.Wood)

	-- Hecken in den Vorgärten (Deckung)
	hecke(garten, Vector3.new(-58, 0, -40), Vector3.new(10, 4, 4))
	hecke(garten, Vector3.new(58, 0, 34), Vector3.new(10, 4, 4))

	-- Bäume am Rand (außerhalb des Spielfelds, nicht auf Straße oder Zombie-Spawns)
	local baeume = Instance.new("Folder")
	baeume.Name = "Baeume"
	baeume.Parent = deko
	local rand = groesse / 2 - 15
	local gesetzt = 0
	for _ = 1, einstellungen.Baeume * 20 do
		if gesetzt >= einstellungen.Baeume then
			break
		end
		local position = Vector3.new(zufall:NextNumber(-rand, rand), 0, zufall:NextNumber(-rand, rand))
		local ausserhalb = math.abs(position.X) > 138 or math.abs(position.Z) > 112
		if ausserhalb and math.abs(position.X) > STRASSE_HALB + GEHWEG_BREITE + 6 and not nahAnSpawn(position, 24) then
			baum(baeume, position)
			gesetzt += 1
		end
	end
	-- Zwei Bäume in den Vorgärten
	baum(baeume, Vector3.new(-56, 0, 40))
	baum(baeume, Vector3.new(56, 0, -42))

	zombieSpawns()

	-- Spieler-Spawn in die Mitte des Wendeplatzes setzen
	local spawnPunkt = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if not spawnPunkt then
		spawnPunkt = Instance.new("SpawnLocation")
		spawnPunkt.Size = Vector3.new(12, 1, 12)
		spawnPunkt.Parent = workspace
	end
	spawnPunkt.Anchored = true
	spawnPunkt.CFrame = CFrame.new(0, spawnPunkt.Size.Y / 2, 0)

	-- Warme Abendstimmung
	pcall(function()
		Lighting.ClockTime = 17.7
		Lighting.Brightness = 2
		Lighting.OutdoorAmbient = Color3.fromRGB(150, 125, 105)
	end)
	pcall(function()
		local atmosphaere = Lighting:FindFirstChildOfClass("Atmosphere")
		if not atmosphaere then
			atmosphaere = Instance.new("Atmosphere")
			atmosphaere.Parent = Lighting
		end
		atmosphaere.Density = 0.3
		atmosphaere.Offset = 0.1
		atmosphaere.Haze = 2
		atmosphaere.Glare = 0.4
		atmosphaere.Color = Color3.fromRGB(235, 195, 150)
		atmosphaere.Decay = Color3.fromRGB(170, 115, 90)
	end)
end

return MapBuilder
