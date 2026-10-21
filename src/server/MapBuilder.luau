-- Baut beim Spielstart die Map: Wiese, Straßen, Häuser, Bäume und Steine.
-- Abschalten: Config.Map.Aktiv = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

local zufall = Random.new(42) -- feste Zahl = jedes Mal die gleiche Map

local HAUS_FARBEN = {
	Color3.fromRGB(220, 205, 175),
	Color3.fromRGB(190, 120, 100),
	Color3.fromRGB(160, 170, 180),
	Color3.fromRGB(205, 190, 140),
}

local belegt = {} -- Flächen, auf die keine Bäume/Steine sollen: { mitte = Vector3, radius = Zahl }

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

-- Straßen ---------------------------------------------------------------------

local function strassen(deko, groesse, breite)
	local terrain = workspace.Terrain
	local markierungen = Instance.new("Folder")
	markierungen.Name = "Strassenmarkierung"
	markierungen.Parent = deko

	-- Zwei Straßen, die sich in der Mitte kreuzen
	for _, entlangX in { true, false } do
		local masse = entlangX and Vector3.new(groesse, 12, breite) or Vector3.new(breite, 12, groesse)
		terrain:FillBlock(CFrame.new(0, -6, 0), masse, Enum.Material.Asphalt)

		-- Gestrichelte Mittellinie
		for d = -groesse / 2 + 6, groesse / 2 - 6, 12 do
			if math.abs(d) > breite / 2 + 2 then
				local position = entlangX and Vector3.new(d, 0.05, 0) or Vector3.new(0, 0.05, d)
				local linie = teil(markierungen, entlangX and Vector3.new(6, 0.1, 0.5) or Vector3.new(0.5, 0.1, 6),
					Color3.fromRGB(235, 235, 220), CFrame.new(position))
				linie.CanCollide = false
				linie.CanQuery = false
			end
		end
	end
end

local function aufStrasse(position, breite)
	local abstand = breite / 2 + 6
	return math.abs(position.X) < abstand or math.abs(position.Z) < abstand
end

-- Häuser ----------------------------------------------------------------------

-- Ein kleines Haus mit Tür (vorne = Richtung -Z, bevor es gedreht wird)
local function haus(eltern, mitte, drehung)
	local modell = Instance.new("Model")
	modell.Name = "Haus"

	local b, t, h, dicke = 16, 14, 10, 1 -- Breite, Tiefe, Höhe, Wanddicke
	local tuerBreite, tuerHoehe = 5, 7
	local basis = CFrame.new(mitte) * CFrame.Angles(0, drehung, 0)
	local wandFarbe = HAUS_FARBEN[zufall:NextInteger(1, #HAUS_FARBEN)]
	local fensterFarbe = Color3.fromRGB(150, 190, 210)

	local function stueck(groesse, versatz, farbe, material)
		return teil(modell, groesse, farbe or wandFarbe, basis * CFrame.new(versatz), material or Enum.Material.Plaster)
	end

	-- Boden
	stueck(Vector3.new(b, 0.4, t), Vector3.new(0, 0.2, 0), Color3.fromRGB(120, 95, 70), Enum.Material.WoodPlanks)

	-- Rückwand und Seitenwände
	stueck(Vector3.new(b, h, dicke), Vector3.new(0, h / 2, t / 2 - dicke / 2))
	stueck(Vector3.new(dicke, h, t), Vector3.new(-b / 2 + dicke / 2, h / 2, 0))
	stueck(Vector3.new(dicke, h, t), Vector3.new(b / 2 - dicke / 2, h / 2, 0))

	-- Vorderwand mit Türöffnung
	local seite = (b - tuerBreite) / 2
	stueck(Vector3.new(seite, h, dicke), Vector3.new(-tuerBreite / 2 - seite / 2, h / 2, -t / 2 + dicke / 2))
	stueck(Vector3.new(seite, h, dicke), Vector3.new(tuerBreite / 2 + seite / 2, h / 2, -t / 2 + dicke / 2))
	stueck(Vector3.new(tuerBreite, h - tuerHoehe, dicke), Vector3.new(0, tuerHoehe + (h - tuerHoehe) / 2, -t / 2 + dicke / 2))

	-- Fenster (nur Deko, leicht vor der Wand)
	for _, x in { -b / 2 - 0.05, b / 2 + 0.05 } do
		local fenster = stueck(Vector3.new(0.2, 3, 4), Vector3.new(x, 5.5, 0), fensterFarbe, Enum.Material.Glass)
		fenster.Transparency = 0.3
	end
	for _, x in { -5.5, 5.5 } do
		local fenster = stueck(Vector3.new(3, 3, 0.2), Vector3.new(x, 5.5, -t / 2 - 0.05), fensterFarbe, Enum.Material.Glass)
		fenster.Transparency = 0.3
	end

	-- Flachdach mit Rand
	stueck(Vector3.new(b + 2, 0.8, t + 2), Vector3.new(0, h + 0.4, 0), Color3.fromRGB(70, 65, 65), Enum.Material.Slate)

	modell.Parent = eltern
	table.insert(belegt, { mitte = mitte, radius = 16 })
end

local function haeuser(deko, breite)
	local abstand = breite / 2 + 14 -- Abstand der Hausmitte zur Straßenmitte
	local entlangX = { -220, -150, -90, 90, 150, 220 }
	local entlangZ = { -200, -120, 120, 200 }

	for i, x in entlangX do
		-- abwechselnd links und rechts der Straße, Tür zeigt zur Straße
		local norden = i % 2 == 0
		haus(deko, Vector3.new(x, 0, norden and abstand or -abstand), norden and 0 or math.pi)
	end
	for i, z in entlangZ do
		local osten = i % 2 == 0
		haus(deko, Vector3.new(osten and abstand or -abstand, 0, z), osten and math.rad(90) or math.rad(-90))
	end
end

-- Bäume und Steine ------------------------------------------------------------

local function baum(eltern, position)
	local hoehe = zufall:NextNumber(10, 18)
	local dicke = zufall:NextNumber(1.5, 2.5)
	local modell = Instance.new("Model")
	modell.Name = "Baum"

	-- Zylinder liegen auf der Seite, deshalb um 90° drehen
	teil(modell, Vector3.new(hoehe, dicke, dicke), Color3.fromRGB(95, 70, 45),
		CFrame.new(position + Vector3.new(0, hoehe / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Enum.Material.Wood, Enum.PartType.Cylinder)

	local gruen = Color3.fromRGB(zufall:NextInteger(45, 70), zufall:NextInteger(100, 135), zufall:NextInteger(40, 60))
	for i = 1, 3 do
		local d = zufall:NextNumber(7, 11) - i
		local versatz = Vector3.new(zufall:NextNumber(-2, 2), hoehe + i * 2 - 2, zufall:NextNumber(-2, 2))
		local krone = teil(modell, Vector3.new(d, d, d), gruen, CFrame.new(position + versatz),
			Enum.Material.Grass, Enum.PartType.Ball)
		krone.CanCollide = false
	end

	modell.Parent = eltern
end

local function stein(eltern, position)
	local groesse = Vector3.new(zufall:NextNumber(2, 6), zufall:NextNumber(1.5, 4), zufall:NextNumber(2, 6))
	local grau = zufall:NextInteger(95, 130)
	local drehung = CFrame.Angles(zufall:NextNumber(-0.3, 0.3), zufall:NextNumber(0, math.pi * 2), zufall:NextNumber(-0.3, 0.3))
	teil(eltern, groesse, Color3.fromRGB(grau, grau, grau - 5),
		CFrame.new(position + Vector3.new(0, groesse.Y * 0.3, 0)) * drehung, Enum.Material.Slate)
end

local function freierPunkt(einstellungen)
	local groesse = einstellungen.Groesse
	for _ = 1, 50 do
		local position = Vector3.new(
			zufall:NextNumber(-groesse / 2 + 10, groesse / 2 - 10),
			0,
			zufall:NextNumber(-groesse / 2 + 10, groesse / 2 - 10)
		)
		local frei = position.Magnitude > einstellungen.FreierRadius
		if frei and einstellungen.Strassen and aufStrasse(position, einstellungen.StrassenBreite) then
			frei = false
		end
		for _, flaeche in belegt do
			if (position - flaeche.mitte).Magnitude < flaeche.radius then
				frei = false
				break
			end
		end
		if frei then
			return position
		end
	end
	return nil
end

-- Start -----------------------------------------------------------------------

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

	-- Wiese aus Terrain (Oberkante bei Höhe 0)
	local terrain = workspace.Terrain
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(groesse, 12, groesse), Enum.Material.Grass)
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(80, 120, 55))
	end)

	local deko = Instance.new("Folder")
	deko.Name = "Deko"
	deko.Parent = workspace

	if einstellungen.Strassen then
		strassen(deko, groesse, einstellungen.StrassenBreite)
	end
	if einstellungen.Haeuser then
		haeuser(deko, einstellungen.StrassenBreite)
	end

	for _ = 1, einstellungen.Baeume do
		local position = freierPunkt(einstellungen)
		if position then
			baum(deko, position)
		end
	end
	for _ = 1, einstellungen.Steine do
		local position = freierPunkt(einstellungen)
		if position then
			stein(deko, position)
		end
	end

	-- Leicht düstere Abendstimmung
	Lighting.ClockTime = 17.2
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphaere = Instance.new("Atmosphere")
		atmosphaere.Density = 0.35
		atmosphaere.Haze = 1.5
		atmosphaere.Color = Color3.fromRGB(200, 190, 170)
		atmosphaere.Parent = Lighting
	end
end

return MapBuilder
