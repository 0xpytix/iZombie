-- Baut beim Spielstart die Map: ein Nachbau von "Nuketown" (Black Ops 1) im Klötzchen-Stil.
-- Ein eingezäuntes Vorstadt-Grundstück mit grünem Rasen mitten in der trockenen Wüste.
-- Abschalten: Config.Map.Aktiv = false
--
-- Übersicht (Draufsicht, X nach rechts, Z nach unten; lange Achse = Z):
--   Grundstück etwa X -65..65, Z -150..150 (Holzzaun mit Toren, Ecken mit Einbuchtungen,
--   bei X 65..82 / Z -40..40 eine Ausbuchtung, durch die die Straße nach +X hinausführt)
--   Z -150..-93  Garten 1 mit Schuppen
--   Z  -93..-67  HausGelb (2 Stockwerke, Garage auf der -X-Seite), Tür zeigt nach +Z
--   Z  -40.. 40  Straße entlang X mit rundem Wendeplatz bei X = -18, Schulbus + Lieferwagen
--   Z   68.. 92  Ranchhaus (1 Stockwerk, Garage auf der +X-Seite), Tür zeigt nach -Z
--   Z   92..150  Garten 2 mit Holzterrasse und Schuppen
--   Rundherum Wüste (Terrain ohne Gras), Felsen, trockene Büsche, ein Strommast im Westen.
--
-- Wichtig: Nirgends Terrain-Gras (dessen Halme stachen durch die Hausböden).
-- Der Rasen besteht nur aus flachen Parts.

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
	Zaun = Color3.fromRGB(215, 170, 115),
	ZaunDunkel = Color3.fromRGB(170, 125, 80),
	RasenA = Color3.fromRGB(85, 140, 60),
	RasenB = Color3.fromRGB(78, 131, 55),
	Asphalt = Color3.fromRGB(62, 62, 66),
	Stahl = Color3.fromRGB(125, 125, 130),
	Hecke = Color3.fromRGB(45, 85, 40),
	BusGelb = Color3.fromRGB(245, 190, 30),
	Dunkel = Color3.fromRGB(35, 40, 50),
}

-- Höhen (Oberkanten): Wüsten-Terrain 0, Rasen 0,4, Straße 0,45-0,48, Einfahrten 0,6, Gehweg 0,65
local RASEN_OBEN = 0.4
local STRASSE_HALB = 12 -- halbe Straßenbreite
local WENDE_MITTE = Vector3.new(-18, 0, 0) -- Mitte des runden Wendeplatzes
local WENDE_RADIUS = 32
local GEHWEG_BREITE = 6
local STRASSE_ENDE = 156 -- hier trifft die Straße auf die Schotterpiste in der Wüste

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
	offeneTuer(m, cf * CFrame.new(-5.2, s + 3.9, -9.6), FARBE.Rot)

	-- Möbel
	sofa(m, cf * CFrame.new(6, s, -4) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(110, 60, 50))
	tisch(m, cf * CFrame.new(-2, s, 0))
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

-- Hoher Holzzaun (Bretterwand mit Pfosten) von a nach b auf dem Boden.
-- luecken = { {von, bis} } in Studs ab a (Tore, durch die Zombies kommen).
local function holzzaun(eltern, a, b, luecken, hoehe)
	local laenge = (b - a).Magnitude
	local basis = CFrame.lookAt(a, b) -- lokale -Z zeigt von a nach b
	table.sort(luecken, function(l1, l2)
		return l1[1] < l2[1]
	end)

	local abschnitte = {}
	local start = 0
	for _, l in luecken do
		table.insert(abschnitte, { start, l[1] })
		start = l[2]
	end
	table.insert(abschnitte, { start, laenge })

	local unten = RASEN_OBEN
	for _, ab in abschnitte do
		local len = ab[2] - ab[1]
		if len > 0.3 then
			local mitteD = (ab[1] + ab[2]) / 2
			-- Bretterwand und Abdeckleiste
			teil(eltern, Vector3.new(0.3, hoehe - unten, len), FARBE.Zaun,
				basis * CFrame.new(0, unten + (hoehe - unten) / 2, -mitteD), Enum.Material.WoodPlanks)
			teil(eltern, Vector3.new(0.6, 0.3, len + 0.2), FARBE.ZaunDunkel,
				basis * CFrame.new(0, hoehe + 0.15, -mitteD), Enum.Material.Wood)
			-- Pfosten höchstens alle 8 Studs
			local n = math.max(1, math.ceil(len / 8))
			for i = 0, n do
				local d = math.clamp(ab[1] + len * i / n, ab[1] + 0.4, ab[2] - 0.4)
				teil(eltern, Vector3.new(0.8, hoehe + 0.6, 0.8), FARBE.ZaunDunkel,
					basis * CFrame.new(0, (hoehe + 0.6) / 2, -d), Enum.Material.Wood)
			end
		end
	end
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

local function hydrant(eltern, position)
	local rot = Color3.fromRGB(190, 40, 35)
	teil(eltern, Vector3.new(2.6, 1.1, 1.1), rot, CFrame.new(position + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Enum.Material.Metal, Enum.PartType.Cylinder)
	teil(eltern, Vector3.new(1.4, 0.4, 0.5), rot, CFrame.new(position + Vector3.new(0, 1.6, 0)), Enum.Material.Metal)
end

local function baum(eltern, position)
	local hoehe = zufall:NextNumber(10, 16)
	local dicke = zufall:NextNumber(1.5, 2.2)
	local m = modell(eltern, "Baum")

	-- Zylinder liegen auf der Seite, deshalb um 90° drehen
	teil(m, Vector3.new(hoehe, dicke, dicke), Color3.fromRGB(95, 70, 45),
		CFrame.new(position + Vector3.new(0, hoehe / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Enum.Material.Wood, Enum.PartType.Cylinder)

	-- Klötzchenkrone
	local gruen = Color3.fromRGB(zufall:NextInteger(55, 75), zufall:NextInteger(105, 130), zufall:NextInteger(40, 55))
	for i = 1, 3 do
		local d = zufall:NextNumber(7, 10) - i
		local versatz = Vector3.new(zufall:NextNumber(-1.5, 1.5), hoehe + i * 2 - 2, zufall:NextNumber(-1.5, 1.5))
		local krone = teil(m, Vector3.new(d, d * 0.8, d), gruen,
			CFrame.new(position + versatz) * CFrame.Angles(0, zufall:NextNumber(0, math.pi), 0), Enum.Material.Grass)
		krone.CanCollide = false
	end
end

local function gartentisch(eltern, position, drehung)
	local m = modell(eltern, "Gartentisch")
	local cf = CFrame.new(position) * CFrame.Angles(0, drehung or 0, 0)
	local holz = Color3.fromRGB(140, 100, 65)
	teil(m, Vector3.new(6, 0.4, 3), holz, cf * CFrame.new(0, 2.8, 0), Enum.Material.Wood)
	for _, z in { -2.2, 2.2 } do
		teil(m, Vector3.new(6, 0.4, 1.2), holz, cf * CFrame.new(0, 1.6, z), Enum.Material.Wood)
	end
	teil(m, Vector3.new(1, 2.6, 1), Color3.fromRGB(110, 80, 50), cf * CFrame.new(0, 1.3, 0), Enum.Material.Wood)
end

-- Plantschbecken (Kinderpool)
local function pool(eltern, position)
	local m = modell(eltern, "Plantschbecken")
	teil(m, Vector3.new(1.4, 9, 9), Color3.fromRGB(70, 140, 200), CFrame.new(position + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local wasser = teil(m, Vector3.new(0.2, 8, 8), Color3.fromRGB(120, 200, 235), CFrame.new(position + Vector3.new(0, 1.42, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Enum.Material.Glass, Enum.PartType.Cylinder)
	wasser.Transparency = 0.3
end

-- Wüste ------------------------------------------------------------------------

-- Dünner Balken von a nach b (nicht genau senkrecht verwenden)
local function balken(eltern, a, b, dicke, farbe, material)
	local laenge = (b - a).Magnitude
	return teil(eltern, Vector3.new(dicke, dicke, laenge), farbe, CFrame.lookAt((a + b) / 2, b), material or Enum.Material.Metal)
end

-- Hochspannungsmast aus Stahlstreben, Leitungen laufen entlang Z
local function strommast(eltern, p)
	local m = modell(eltern, "Strommast")
	local hoehe = 62
	local unten, oben = 7, 1.8
	local function halb(y)
		return unten + (oben - unten) * (y / hoehe)
	end
	local function ecke(sx, sz, y)
		local h = halb(y)
		return p + Vector3.new(sx * h, y, sz * h)
	end
	local ecken = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }

	-- vier schräge Beine
	for _, e in ecken do
		balken(m, ecke(e[1], e[2], 0), ecke(e[1], e[2], hoehe), 0.9, FARBE.Stahl)
		teil(m, Vector3.new(2.4, 1, 2.4), FARBE.Beton, CFrame.new(ecke(e[1], e[2], 0) + Vector3.new(0, 0.3, 0)), Enum.Material.Concrete)
	end

	-- Querstreben und Diagonalen (Fachwerk)
	local stufe = 8
	for y = stufe, hoehe - 6, stufe do
		for i = 1, 4 do
			local e1, e2 = ecken[i], ecken[i % 4 + 1]
			local q = balken(m, ecke(e1[1], e1[2], y), ecke(e2[1], e2[2], y), 0.4, FARBE.Stahl)
			q.CanCollide = false
			local d = balken(m, ecke(e1[1], e1[2], y - stufe), ecke(e2[1], e2[2], y), 0.35, FARBE.Stahl)
			d.CanCollide = false
		end
	end

	-- zwei Ausleger mit Isolatoren und Leitungen
	local leitung = Color3.fromRGB(40, 40, 42)
	for _, arm in { { y = 44, l = 15 }, { y = 54, l = 10 } } do
		local h = halb(arm.y)
		for _, sz in { -1, 1 } do
			local a = teil(m, Vector3.new(arm.l * 2, 0.6, 0.6), FARBE.Stahl, CFrame.new(p + Vector3.new(0, arm.y, sz * h)))
			a.CanCollide = false
		end
		for _, sx in { -1, 1 } do
			local spitze = p + Vector3.new(sx * arm.l, arm.y, 0)
			-- Strebe von der Auslegerspitze schräg zum Mast
			local s = balken(m, spitze, ecke(sx, 1, arm.y + 5) - Vector3.new(0, 0, halb(arm.y + 5)), 0.35, FARBE.Stahl)
			s.CanCollide = false
			local iso = teil(m, Vector3.new(0.6, 3, 0.6), Color3.fromRGB(200, 205, 215), CFrame.new(spitze - Vector3.new(0, 1.8, 0)), Enum.Material.Glass)
			iso.CanCollide = false
			-- Leitungen in beide Richtungen bis weit in die Wüste (hängen leicht durch)
			for _, richtung in { -1, 1 } do
				local von = spitze - Vector3.new(0, 3.3, 0)
				local bis = p + Vector3.new(sx * arm.l, arm.y - 14, richtung * 300)
				local kabel = balken(m, von, bis, 0.15, leitung, Enum.Material.SmoothPlastic)
				kabel.CanCollide = false
				kabel.CanQuery = false
			end
		end
	end
	-- Spitze
	local spitze = teil(m, Vector3.new(oben * 2 + 0.6, 2, oben * 2 + 0.6), FARBE.Stahl, CFrame.new(p + Vector3.new(0, hoehe + 1, 0)))
	spitze.CanCollide = false
	return m
end

local function felsen(eltern, position)
	local m = modell(eltern, "Felsen")
	local farbe = Color3.fromRGB(zufall:NextInteger(140, 170), zufall:NextInteger(115, 135), zufall:NextInteger(90, 105))
	local g = zufall:NextNumber(3, 9)
	local groesse = Vector3.new(g * zufall:NextNumber(0.8, 1.4), g * zufall:NextNumber(0.5, 0.9), g * zufall:NextNumber(0.8, 1.3))
	teil(m, groesse, farbe, CFrame.new(position + Vector3.new(0, groesse.Y * 0.3, 0))
		* CFrame.Angles(zufall:NextNumber(-0.3, 0.3), zufall:NextNumber(0, math.pi), zufall:NextNumber(-0.3, 0.3)), Enum.Material.Slate)
	-- kleiner Begleitstein
	local k = g * zufall:NextNumber(0.3, 0.5)
	teil(m, Vector3.new(k, k * 0.7, k), farbe, CFrame.new(position + Vector3.new(g * 0.7, k * 0.2, g * 0.4))
		* CFrame.Angles(0, zufall:NextNumber(0, math.pi), 0.2), Enum.Material.Slate)
end

-- Trockener Wüstenbusch (kein Hindernis)
local function busch(eltern, position)
	local m = modell(eltern, "Busch")
	local farbe = Color3.fromRGB(zufall:NextInteger(120, 150), zufall:NextInteger(110, 125), zufall:NextInteger(65, 80))
	local g = zufall:NextNumber(2, 4)
	for i = 1, 2 do
		local b = teil(m, Vector3.new(g, g * 0.6, g * 0.8), farbe,
			CFrame.new(position + Vector3.new(0, g * 0.25 + (i - 1) * 0.3, 0)) * CFrame.Angles(0, i * 0.8 + zufall:NextNumber(0, 1), 0),
			Enum.Material.Grass)
		b.CanCollide = false
	end
end

local function wueste(deko, groesse, einstellungen, spawnPositionen)
	local terrain = workspace.Terrain
	local halb = groesse / 2

	-- Alte Reste über dem Boden entfernen und ebenen Wüstenboden legen (Oberkante 0).
	-- Bewusst nur Materialien ohne Grashalme.
	terrain:FillBlock(CFrame.new(0, 40, 0), Vector3.new(groesse, 80, groesse), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(groesse, 12, groesse), Enum.Material.Ground)

	-- Sandflecken außerhalb des Grundstücks
	for _ = 1, 10 do
		local x, z = zufall:NextNumber(-halb + 30, halb - 30), zufall:NextNumber(-halb + 30, halb - 30)
		if math.abs(x) > 120 or math.abs(z) > 200 then
			terrain:FillBlock(CFrame.new(x, -2, z), Vector3.new(zufall:NextNumber(30, 70), 4, zufall:NextNumber(30, 70)), Enum.Material.Sand)
		end
	end

	-- Schotterpiste entlang Z im Osten
	terrain:FillBlock(CFrame.new(STRASSE_ENDE + 6, -2, 0), Vector3.new(12, 4, groesse), Enum.Material.Mud)

	-- Hügel am Horizont (Terrain-Kugeln, zum Großteil im Boden)
	for i = 1, 16 do
		local winkel = (i + zufall:NextNumber(-0.3, 0.3)) / 16 * math.pi * 2
		local r = zufall:NextNumber(30, 60)
		local abstand = zufall:NextNumber(halb * 0.65, halb - r - 5) -- nicht über den Rand hinaus
		local x, z = math.cos(winkel) * abstand, math.sin(winkel) * abstand
		if math.abs(x - (STRASSE_ENDE + 6)) > r + 20 then
			local material = (i % 3 == 0) and Enum.Material.Rock or Enum.Material.Sandstone
			terrain:FillBall(Vector3.new(x, -r * 0.5, z), r, material)
		end
	end

	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(170, 135, 95))
		terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(205, 175, 130))
		terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(135, 108, 80))
		terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(190, 150, 105))
		terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(145, 120, 100))
	end)

	local ordner = Instance.new("Folder")
	ordner.Name = "Wueste"
	ordner.Parent = deko

	if einstellungen.Strommast then
		strommast(ordner, Vector3.new(-150, 0, 40))
	end

	-- Freie Stelle in der Wüste suchen (nicht im Grundstück, auf Straße/Piste, an Spawns oder am Mast)
	local function freiePosition()
		for _ = 1, 30 do
			local p = Vector3.new(zufall:NextNumber(-halb + 20, halb - 20), 0, zufall:NextNumber(-halb + 20, halb - 20))
			local imGrundstueck = math.abs(p.X) < 82 and math.abs(p.Z) < 168 or (p.X > 0 and p.X < 98 and math.abs(p.Z) < 50)
			local aufStrasse = p.X > 80 and p.X < STRASSE_ENDE and math.abs(p.Z) < STRASSE_HALB + 6
			local aufPiste = math.abs(p.X - (STRASSE_ENDE + 6)) < 12
			local amMast = (p - Vector3.new(-150, 0, 40)).Magnitude < 16
			local amSpawn = false
			for _, s in spawnPositionen do
				if (s - p).Magnitude < 22 then
					amSpawn = true
				end
			end
			if not (imGrundstueck or aufStrasse or aufPiste or amMast or amSpawn) then
				return p
			end
		end
		return nil
	end

	for _ = 1, einstellungen.Felsen do
		local p = freiePosition()
		if p then
			felsen(ordner, p)
		end
	end
	for _ = 1, einstellungen.Bueschel do
		local p = freiePosition()
		if p then
			busch(ordner, p)
		end
	end
end

-- Rasen, Straße und Gehwege ------------------------------------------------------

-- Rasen als flache Parts in Querstreifen (wie frisch gemäht), Oberkante RASEN_OBEN
local function rasenStreifen(eltern, x1, x2, z1, z2)
	local tiefe = 10
	local z = z1
	while z < z2 - 0.01 do
		local zEnde = math.min(z + tiefe, z2)
		local farbe = (math.floor((z + 1000) / tiefe) % 2 == 0) and FARBE.RasenA or FARBE.RasenB
		teil(eltern, Vector3.new(x2 - x1, 0.4, zEnde - z), farbe,
			CFrame.new((x1 + x2) / 2, RASEN_OBEN - 0.2, (z + zEnde) / 2), Enum.Material.Grass)
		z = zEnde
	end
end

local function rasen(deko)
	local ordner = Instance.new("Folder")
	ordner.Name = "Rasen"
	ordner.Parent = deko
	rasenStreifen(ordner, -50, 50, -150, -140)
	rasenStreifen(ordner, -65, 65, -140, -40)
	rasenStreifen(ordner, -65, 82, -40, 40) -- mit Ausbuchtung an der Straße
	rasenStreifen(ordner, -65, 65, 40, 140)
	rasenStreifen(ordner, -50, 50, 140, 150)
end

local function strasse(deko)
	local ordner = Instance.new("Folder")
	ordner.Name = "Strasse"
	ordner.Parent = deko

	-- Runder Wendeplatz (liegender Zylinder) und Straße nach +X bis zur Schotterpiste
	teil(ordner, Vector3.new(1, WENDE_RADIUS * 2, WENDE_RADIUS * 2), FARBE.Asphalt,
		CFrame.new(WENDE_MITTE + Vector3.new(0, -0.02, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Asphalt, Enum.PartType.Cylinder)
	local xStart = WENDE_MITTE.X + WENDE_RADIUS - 3
	teil(ordner, Vector3.new(STRASSE_ENDE - xStart, 1, STRASSE_HALB * 2), FARBE.Asphalt,
		CFrame.new((xStart + STRASSE_ENDE) / 2, -0.05, 0), Enum.Material.Asphalt)

	-- Gehweg-Ring um den Wendeplatz (Oberkante 0,65), offen zur Straße hin
	local r = WENDE_RADIUS + GEHWEG_BREITE / 2
	local stuecke = 32
	local bogen = 2 * math.pi * r / stuecke + 0.8
	for i = 0, stuecke - 1 do
		local winkel = i / stuecke * math.pi * 2
		local x, z = math.cos(winkel) * r, math.sin(winkel) * r
		if not (x > 0 and math.abs(z) < STRASSE_HALB + 3) then
			teil(ordner, Vector3.new(GEHWEG_BREITE, 1, bogen), FARBE.Beton,
				CFrame.new(WENDE_MITTE.X + x, 0.15, z) * CFrame.Angles(0, -winkel, 0), Enum.Material.Concrete)
		end
	end

	-- Gerade Gehwege an der Straße bis zum Zaun
	local gx1 = WENDE_MITTE.X + math.sqrt((r + GEHWEG_BREITE / 2) ^ 2 - (STRASSE_HALB + GEHWEG_BREITE) ^ 2)
	local gx2 = 82
	for _, sz in { -1, 1 } do
		teil(ordner, Vector3.new(gx2 - gx1, 1, GEHWEG_BREITE), FARBE.Beton,
			CFrame.new((gx1 + gx2) / 2, 0.15, sz * (STRASSE_HALB + GEHWEG_BREITE / 2)), Enum.Material.Concrete)
	end

	-- Gelbe Mittellinie
	for x = 20, STRASSE_ENDE - 6, 12 do
		local linie = teil(ordner, Vector3.new(6, 0.1, 0.5), Color3.fromRGB(235, 205, 90), CFrame.new(x, 0.47, 0))
		linie.CanCollide = false
		linie.CanQuery = false
	end
end

-- Einfahrt/Weg aus Beton (Oberkante 0,6)
local function platte(eltern, von, bis)
	local groesse = Vector3.new(math.abs(bis.X - von.X), 1, math.abs(bis.Z - von.Z))
	local mitte = (von + bis) / 2
	teil(eltern, groesse, FARBE.Beton, CFrame.new(mitte.X, 0.1, mitte.Z), Enum.Material.Concrete)
end

-- Grundstückszaun, Tore und Zombie-Spawns ----------------------------------------

-- Tore (8 Studs breit) im Grenzzaun. Vor den meisten liegt ein Zombie-Spawn in der Wüste.
local TOR_BREITE = 8
local TORE = {
	{ pos = Vector3.new(-25, 0, -150), spawn = Vector3.new(-25, 0, -162) }, -- Nordende (hinter HausGelb)
	{ pos = Vector3.new(25, 0, -150), spawn = Vector3.new(25, 0, -162) },
	{ pos = Vector3.new(-25, 0, 150), spawn = Vector3.new(-25, 0, 162) }, -- Südende (hinter Ranchhaus)
	{ pos = Vector3.new(25, 0, 150), spawn = Vector3.new(25, 0, 162) },
	{ pos = Vector3.new(-65, 0, -110), spawn = Vector3.new(-77, 0, -110) }, -- Westseite
	{ pos = Vector3.new(-65, 0, 20) },
	{ pos = Vector3.new(-65, 0, 110), spawn = Vector3.new(-77, 0, 110) },
	{ pos = Vector3.new(65, 0, -110), spawn = Vector3.new(77, 0, -110) }, -- Ostseite
	{ pos = Vector3.new(82, 0, 0), spawn = Vector3.new(96, 0, 0) }, -- Straßensperre
	{ pos = Vector3.new(65, 0, 110) },
}

-- Umriss des Grundstücks (im Uhrzeigersinn), mit Einbuchtungen an den Ecken
local GRENZE = {
	Vector3.new(-50, 0, -150), Vector3.new(50, 0, -150), Vector3.new(50, 0, -140), Vector3.new(65, 0, -140),
	Vector3.new(65, 0, -40), Vector3.new(82, 0, -40), Vector3.new(82, 0, 40), Vector3.new(65, 0, 40),
	Vector3.new(65, 0, 140), Vector3.new(50, 0, 140), Vector3.new(50, 0, 150), Vector3.new(-50, 0, 150),
	Vector3.new(-50, 0, 140), Vector3.new(-65, 0, 140), Vector3.new(-65, 0, -140), Vector3.new(-50, 0, -140),
}

-- Lücken für einen Zaun von a nach b: alle Tore, die auf der Strecke liegen
local function torLuecken(a, b, tore)
	local laenge = (b - a).Magnitude
	local luecken = {}
	for _, tor in tore do
		local d = (tor - a).Magnitude
		if math.abs(d + (b - tor).Magnitude - laenge) < 0.1 then
			table.insert(luecken, { d - TOR_BREITE / 2, d + TOR_BREITE / 2 })
		end
	end
	return luecken
end

local function grenzzaun(deko)
	local ordner = Instance.new("Folder")
	ordner.Name = "Grenzzaun"
	ordner.Parent = deko
	local torPositionen = {}
	for _, tor in TORE do
		table.insert(torPositionen, tor.pos)
	end
	for i, a in GRENZE do
		local b = GRENZE[i % #GRENZE + 1]
		holzzaun(ordner, a, b, torLuecken(a, b, torPositionen), 5)
	end
end

local function spawnPositionen()
	local liste = {}
	for _, tor in TORE do
		if tor.spawn then
			table.insert(liste, tor.spawn)
		end
	end
	return liste
end

local function unsichtbar(name, groesse, cframe, eltern)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = groesse
	p.CFrame = cframe
	p.Parent = eltern
	return p
end

-- Leert einen Ordner im Workspace oder legt ihn neu an
local function frischerOrdner(name)
	local ordner = workspace:FindFirstChild(name)
	if ordner then
		ordner:ClearAllChildren()
	else
		ordner = Instance.new("Folder")
		ordner.Name = name
		ordner.Parent = workspace
	end
	return ordner
end

local function zombieSpawns()
	local ordner = frischerOrdner("ZombieSpawns")
	for i, tor in TORE do
		if tor.spawn then
			-- Flach entlang des Zauns, damit Zombies direkt vor dem Tor erscheinen
			local entlangX = math.abs(tor.spawn.Z - tor.pos.Z) > 0.5
			local groesse = entlangX and Vector3.new(8, 1, 4) or Vector3.new(4, 1, 8)
			unsichtbar("Spawn" .. i, groesse, CFrame.new(tor.spawn + Vector3.new(0, 0.5, 0)), ordner)
		end
	end
end

-- Plätze für die Mystery Box. Unterkante liegt auf dem Boden, LookVector (-Z) zeigt
-- dorthin, wo die Spieler beim Benutzen stehen.
local function mysteryBoxPunkte(hausGelbCf)
	local ordner = frischerOrdner("MysteryBoxPunkte")
	local groesse = Vector3.new(6, 1, 4)
	local punkte = {
		-- HausGelb, Erdgeschoss an der Seitenwand (Holzboden Oberkante 0,6), Blick in den Raum
		{ "HausGelb", hausGelbCf * CFrame.new(-15, 1.1, -7) * CFrame.Angles(0, -math.pi / 2, 0) },
		-- Ranchhaus, Wohnzimmer an der Rückwand, Blick nach vorne (-Z)
		{ "Ranchhaus", CFrame.new(-24, 1.1, 89) },
		-- Garten 1 am hinteren Zaun, Blick zum Haus (+Z)
		{ "Garten", CFrame.new(0, RASEN_OBEN + 0.5, -146.5) * CFrame.Angles(0, math.pi, 0) },
		-- Westrand des Wendeplatzes auf dem Gehweg (Oberkante 0,65), Blick zur Straße (+X)
		{ "Wendeplatz", CFrame.new(-53, 1.15, 0) * CFrame.Angles(0, -math.pi / 2, 0) },
	}
	for _, punkt in punkte do
		unsichtbar(punkt[1], groesse, punkt[2], ordner)
	end
end

-- Start ------------------------------------------------------------------------

function MapBuilder.Bauen()
	local einstellungen = Config.Map
	if not einstellungen.Aktiv then
		return
	end

	-- Die graue Baseplate aus der Vorlage entfernen, die Wüste ersetzt sie
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	local deko = workspace:FindFirstChild("Deko")
	if not deko then
		deko = Instance.new("Folder")
		deko.Name = "Deko"
		deko.Parent = workspace
	end

	local spawns = spawnPositionen()
	wueste(deko, einstellungen.Groesse, einstellungen, spawns)
	rasen(deko)
	strasse(deko)
	grenzzaun(deko)

	-- Häuser: HausGelb im Norden (Tür nach +Z), Ranchhaus im Süden (Tür nach -Z)
	local haeuser = Instance.new("Folder")
	haeuser.Name = "Haeuser"
	haeuser.Parent = deko
	local hausGelbMitte = Vector3.new(10, 0, -80)
	hausGelb(haeuser, hausGelbMitte, math.pi)
	ranchhaus(haeuser, Vector3.new(0, 0, 80), 0)

	-- Einfahrten und Wege zur Straße
	local wege = Instance.new("Folder")
	wege.Name = "Einfahrten"
	wege.Parent = deko
	platte(wege, Vector3.new(-23, 0, -67), Vector3.new(-9, 0, -31)) -- Garage HausGelb
	platte(wege, Vector3.new(16, 0, -62), Vector3.new(20, 0, -17)) -- Weg zur Haustür
	platte(wege, Vector3.new(17, 0, 17), Vector3.new(29, 0, 68)) -- Garage Ranchhaus
	platte(wege, Vector3.new(0, 0, 31), Vector3.new(4, 0, 65)) -- Weg zur Haustür

	-- Fahrzeuge als Deckung: Bus und Lieferwagen nebeneinander auf der Straße
	if einstellungen.Fahrzeuge then
		local fahrzeuge = Instance.new("Folder")
		fahrzeuge.Name = "Fahrzeuge"
		fahrzeuge.Parent = deko
		schulbus(fahrzeuge, CFrame.new(24, 0.45, -6) * CFrame.Angles(0, math.pi / 2 + 0.06, 0))
		lieferwagen(fahrzeuge, CFrame.new(31, 0.45, 8) * CFrame.Angles(0, -math.pi / 2 + 0.05, 0))
		oldtimer(fahrzeuge, CFrame.new(-16, 0.6, -51) * CFrame.Angles(0, math.pi, 0))
	end

	-- Kleinkram auf Straße und Gehweg
	local kram = modell(deko, "Kleinkram")
	karton(kram, Vector3.new(-4, 0.48, 16), Vector3.new(3, 2.5, 3), 0.9)
	karton(kram, Vector3.new(-4, 2.98, 16), Vector3.new(2, 1.5, 2), 0.2)
	karton(kram, Vector3.new(-30, 0.48, -20), Vector3.new(2.5, 2.5, 2.5), 0.1)
	karton(kram, Vector3.new(50, 0.45, 4), Vector3.new(2.5, 2, 2.5), 0.4)
	briefkasten(kram, Vector3.new(23, 0.65, -21))
	briefkasten(kram, Vector3.new(-2, 0.4, 36))
	hydrant(kram, Vector3.new(60, 0.65, -15))
	hydrant(kram, Vector3.new(-46, RASEN_OBEN, 30))

	-- Gärten: Zäune zwischen Vorgarten und Garten (mit Toren), Hecken, Schuppen
	local garten = Instance.new("Folder")
	garten.Name = "Gaerten"
	garten.Parent = deko

	-- Garten 1 hinter HausGelb (Z -150..-93)
	holzzaun(garten, Vector3.new(28.5, 0, -93), Vector3.new(65, 0, -93), { { 14, 22 } }, 4.5)
	holzzaun(garten, Vector3.new(-8.5, 0, -93), Vector3.new(-65, 0, -93), { { 30, 38 } }, 4.5)
	schuppen(garten, Vector3.new(40, 0, -134), math.pi) -- Tür zeigt zum Haus
	hecke(garten, Vector3.new(-45, 0, -120), Vector3.new(12, 4, 5))
	hecke(garten, Vector3.new(15, 0, -118), Vector3.new(5, 4, 10))
	pool(garten, Vector3.new(-25, RASEN_OBEN - 0.4, -108))
	baum(garten, Vector3.new(-52, RASEN_OBEN, -135))
	-- Trittsteine von der Hintertür zum Schuppen
	for i = 0, 7 do
		local stein = teil(garten, Vector3.new(2.2, 0.2, 2.2), Color3.fromRGB(160, 155, 150),
			CFrame.new(-2 + i * 5.2, RASEN_OBEN + 0.05, -96 - i * 4.4) * CFrame.Angles(0, i * 0.4, 0), Enum.Material.Slate)
		stein.CanCollide = false
	end

	-- Garten 2 hinter dem Ranchhaus (Z 92..150)
	holzzaun(garten, Vector3.new(30.5, 0, 92), Vector3.new(65, 0, 92), { { 14, 22 } }, 4.5)
	holzzaun(garten, Vector3.new(-30.5, 0, 92), Vector3.new(-65, 0, 92), { { 14, 22 } }, 4.5)
	schuppen(garten, Vector3.new(-40, 0, 134), 0) -- Tür zeigt zum Haus
	hecke(garten, Vector3.new(40, 0, 120), Vector3.new(6, 4.5, 14))
	hecke(garten, Vector3.new(-10, 0, 132), Vector3.new(14, 4, 5))
	baum(garten, Vector3.new(52, RASEN_OBEN, 140))
	-- Holzterrasse an der Hintertür (Oberkante 1, also eine kleine Stufe vom Rasen)
	local terrasse = modell(garten, "Terrasse")
	local holz = Color3.fromRGB(150, 105, 70)
	teil(terrasse, Vector3.new(24, 1, 13.5), holz, CFrame.new(-6, 0.5, 98.75), Enum.Material.WoodPlanks)
	for _, x in { -17.8, 5.8 } do
		-- Seitengeländer
		teil(terrasse, Vector3.new(0.4, 0.4, 13.5), holz, CFrame.new(x, 3.8, 98.75), Enum.Material.Wood)
		for _, z in { 93, 98.75, 105.3 } do
			teil(terrasse, Vector3.new(0.5, 3, 0.5), holz, CFrame.new(x, 2.5, z), Enum.Material.Wood)
		end
	end
	gartentisch(terrasse, Vector3.new(-12, 1, 100), 0)

	-- Hecken und Bäume in den Vorgärten (Deckung)
	hecke(garten, Vector3.new(45, 0, -50), Vector3.new(12, 4, 4))
	hecke(garten, Vector3.new(-45, 0, -58), Vector3.new(10, 4, 4))
	hecke(garten, Vector3.new(-40, 0, 52), Vector3.new(10, 4, 4))
	hecke(garten, Vector3.new(48, 0, 45), Vector3.new(12, 4, 4))
	baum(garten, Vector3.new(55, RASEN_OBEN, -30))
	baum(garten, Vector3.new(-52, RASEN_OBEN, 40))

	zombieSpawns()
	mysteryBoxPunkte(CFrame.new(hausGelbMitte) * CFrame.Angles(0, math.pi, 0))

	-- Spieler-Spawn in die Mitte des Wendeplatzes setzen (Asphalt-Oberkante 0,48)
	local spawnPunkt = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if not spawnPunkt then
		spawnPunkt = Instance.new("SpawnLocation")
		spawnPunkt.Size = Vector3.new(12, 0.4, 12)
		spawnPunkt.Parent = workspace
	end
	spawnPunkt.Anchored = true
	spawnPunkt.CFrame = CFrame.new(WENDE_MITTE + Vector3.new(0, 0.48 + spawnPunkt.Size.Y / 2, 0))

	-- Warmer, leicht dunstiger Spätnachmittag in der Wüste
	pcall(function()
		Lighting.ClockTime = 16.9
		Lighting.Brightness = 2.4
		Lighting.OutdoorAmbient = Color3.fromRGB(160, 135, 110)
		Lighting.Ambient = Color3.fromRGB(95, 80, 70)
	end)
	pcall(function()
		local atmosphaere = Lighting:FindFirstChildOfClass("Atmosphere")
		if not atmosphaere then
			atmosphaere = Instance.new("Atmosphere")
			atmosphaere.Parent = Lighting
		end
		atmosphaere.Density = 0.32
		atmosphaere.Offset = 0.15
		atmosphaere.Haze = 2.2
		atmosphaere.Glare = 0.5
		atmosphaere.Color = Color3.fromRGB(240, 205, 160)
		atmosphaere.Decay = Color3.fromRGB(185, 130, 95)
	end)
	pcall(function()
		local farbe = Lighting:FindFirstChild("NuketownFarbe")
		if not farbe then
			farbe = Instance.new("ColorCorrectionEffect")
			farbe.Name = "NuketownFarbe"
			farbe.Parent = Lighting
		end
		farbe.TintColor = Color3.fromRGB(255, 240, 220)
		farbe.Saturation = 0.1
		farbe.Contrast = 0.05
	end)
end

return MapBuilder
