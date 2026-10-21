-- 3D-Modelle für Waffen, aus mehreren Teilen zusammengebaut.
-- Koordinaten sind relativ zum Griff (Handle): vorne = -Z, oben = +Y.

local WaffenModelle = {}

local function anbauen(tool, handle, groesse, farbe, lokal, material)
	local teil = Instance.new("Part")
	teil.Name = "Modellteil"
	teil.Size = groesse
	teil.Color = farbe
	teil.Material = material or Enum.Material.Metal
	teil.CanCollide = false
	teil.CanQuery = false
	teil.CanTouch = false
	teil.Massless = true
	teil.CFrame = handle.CFrame * lokal

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = teil
	weld.Parent = teil

	teil.Parent = tool
	return teil
end

-- Verbindet zwei Punkte mit einem dünnen Block (für Kurven aus vielen Stücken)
local function stueck(tool, handle, von, bis, breite, hoehe, farbe, material)
	local laenge = (bis - von).Magnitude
	local mitte = (von + bis) / 2
	return anbauen(tool, handle, Vector3.new(breite, hoehe, laenge + 0.02), farbe, CFrame.lookAt(mitte, bis), material)
end

-- Karambit: gebogene Klinge wie eine Kralle, Ring am Griffende
local function karambit(tool, handle, daten)
	local klinge = daten.KlingenFarbe
	local akzent = daten.AkzentFarbe
	local halbeLaenge = handle.Size.Z / 2

	-- Gebogene Klinge: Kreisbogen nach vorne und unten
	local radius = 0.9
	local mitte = Vector3.new(0, -radius, -halbeLaenge)
	local schritte = 8
	local letzter
	for i = 0, schritte do
		local winkel = math.rad(110) * i / schritte
		local punkt = mitte + Vector3.new(0, radius * math.cos(winkel), -radius * math.sin(winkel))
		if letzter then
			-- Klinge wird zur Spitze hin schmaler
			local hoehe = 0.26 * (1 - i / (schritte + 2))
			local teil = stueck(tool, handle, letzter, punkt, 0.05, hoehe, klinge, Enum.Material.SmoothPlastic)
			teil.Reflectance = 0.15

			-- Spinnennetz-Muster (Crimson Web): dünne dunkle Linien auf beiden Seiten
			if daten.NetzFarbe then
				local laenge = (punkt - letzter).Magnitude
				for _, seite in { -1, 1 } do
					for n = 1, 2 do
						local netzWinkel = math.rad((n == 1 and 35 or -50) + (i * 17) % 30)
						anbauen(tool, handle, Vector3.new(0.01, 0.015, math.min(hoehe, laenge) * 1.1), daten.NetzFarbe,
							handle.CFrame:ToObjectSpace(teil.CFrame)
								* CFrame.new(seite * 0.03, (n - 1.5) * hoehe * 0.35, 0) * CFrame.Angles(netzWinkel, 0, 0),
							Enum.Material.SmoothPlastic)
					end
				end
			end
		end
		letzter = punkt
	end

	-- Schwarzer Klingenansatz (Übergang Griff -> Klinge)
	anbauen(tool, handle, Vector3.new(0.1, 0.34, 0.12), Color3.fromRGB(20, 20, 22), CFrame.new(0, 0, -halbeLaenge - 0.02), Enum.Material.SmoothPlastic)

	-- Ring am Griffende
	local ringMitte = Vector3.new(0, 0, halbeLaenge + 0.28)
	local ringRadius = 0.26
	local teile = 12
	for i = 0, teile - 1 do
		local a1 = math.pi * 2 * i / teile
		local a2 = math.pi * 2 * (i + 1) / teile
		local p1 = ringMitte + Vector3.new(0, ringRadius * math.cos(a1), ringRadius * math.sin(a1))
		local p2 = ringMitte + Vector3.new(0, ringRadius * math.cos(a2), ringRadius * math.sin(a2))
		stueck(tool, handle, p1, p2, 0.09, 0.09, akzent, Enum.Material.Metal)
	end

	-- Griffrillen (dunkelgrau auf schwarz)
	for z = -0.3, 0.3, 0.2 do
		anbauen(tool, handle, Vector3.new(0.24, 0.34, 0.05), Color3.fromRGB(45, 45, 50), CFrame.new(0, 0, z), Enum.Material.SmoothPlastic)
	end

	-- Leuchtspur beim Zuschlagen (vom Klingenansatz bis zur Spitze), wird nur beim Schlag eingeschaltet
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, -halbeLaenge)
	a0.Parent = handle
	local a1 = Instance.new("Attachment")
	a1.Position = letzter
	a1.Parent = handle

	local spur = Instance.new("Trail")
	spur.Attachment0 = a0
	spur.Attachment1 = a1
	spur.Lifetime = 0.15
	spur.MinLength = 0.05
	spur.FaceCamera = true
	spur.LightEmission = 0.6
	spur.Color = ColorSequence.new(Color3.new(1, 1, 1), akzent)
	spur.Transparency = NumberSequence.new(0.3, 1)
	spur.Enabled = false
	spur.Parent = handle
end

-- Pixel-Waffen ----------------------------------------------------------------
-- Alle folgenden Modelle sind im klotzigen Voxel-Stil aus vielen kleinen Blöcken gebaut.
-- Der Griff (Handle) ist immer der Hauptkörper der Waffe (Verschluss/Gehäuse).
-- Besondere Punkte am Griff (Attachments):
--   "Griff"     = hier hält die rechte Hand die Waffe (Ego-Ansicht und 3. Person)
--   "LinkeHand" = hier greift die linke Hand (z. B. Pumpe oder Handschutz)
--   "Muendung"  = Laufende, hier kommen die Kugeln und das Mündungsfeuer heraus

local SCHWARZ = Color3.fromRGB(30, 31, 35)
local POLYMER = Color3.fromRGB(44, 45, 50)
local STAHL_DUNKEL = Color3.fromRGB(60, 62, 68)
local STAHL = Color3.fromRGB(125, 128, 135)
local CHROM = Color3.fromRGB(190, 194, 200)
local HOLZ = Color3.fromRGB(128, 78, 40)
local HOLZ_DUNKEL = Color3.fromRGB(86, 50, 26)
local HOLZ_HELL = Color3.fromRGB(178, 126, 74)
local OLIV = Color3.fromRGB(92, 102, 64)
local OLIV_DUNKEL = Color3.fromRGB(64, 72, 46)
local MESSING = Color3.fromRGB(210, 165, 62)
local KUPFER = Color3.fromRGB(184, 104, 58)
local ROT = Color3.fromRGB(205, 38, 38)
local BLUT = Color3.fromRGB(105, 12, 12)
local LEUCHT_GRUEN = Color3.fromRGB(90, 255, 120)
local LEUCHT_ORANGE = Color3.fromRGB(255, 150, 40)

local METALL = Enum.Material.Metal
local PLASTIK = Enum.Material.SmoothPlastic
local HOLZ_MAT = Enum.Material.Wood
local STOFF = Enum.Material.Fabric
local NEON = Enum.Material.Neon

-- Kurzform: Block mit Größe, Farbe, Position (relativ zum Griff) und optionaler Drehung in Grad
local function baukasten(tool, handle)
	return function(sx, sy, sz, farbe, x, y, z, material, rx, ry, rz)
		local lokal = CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
		return anbauen(tool, handle, Vector3.new(sx, sy, sz), farbe, lokal, material or METALL)
	end
end

local function punkt(handle, name, position)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = position
	a.Parent = handle
	return a
end

local function griffAussehen(handle, farbe, material)
	handle.Color = farbe
	handle.Material = material
end

-- Abzugsbügel + Abzug: z = Mitte des Bügels, oben = Unterkante des Gehäuses
local function abzug(b, z, oben, farbe)
	b(0.05, 0.035, 0.3, farbe, 0, oben - 0.16, z) -- unten
	b(0.05, 0.16, 0.035, farbe, 0, oben - 0.08, z - 0.14) -- vorne
	b(0.035, 0.11, 0.035, SCHWARZ, 0, oben - 0.07, z + 0.01, METALL, 15) -- Abzug
end

-- Leuchtspur beim Zuschlagen (wie beim Karambit, wird nur beim Schlag eingeschaltet)
local function schlagSpur(handle, von, bis, farbe)
	local a0 = Instance.new("Attachment")
	a0.Position = von
	a0.Parent = handle
	local a1 = Instance.new("Attachment")
	a1.Position = bis
	a1.Parent = handle

	local spur = Instance.new("Trail")
	spur.Attachment0 = a0
	spur.Attachment1 = a1
	spur.Lifetime = 0.15
	spur.MinLength = 0.05
	spur.FaceCamera = true
	spur.LightEmission = 0.5
	spur.Color = ColorSequence.new(Color3.new(1, 1, 1), farbe)
	spur.Transparency = NumberSequence.new(0.4, 1)
	spur.Enabled = false
	spur.Parent = handle
end

-- Baseballschläger: Holz wird nach vorne dicker, Griffband hinten, ein paar Nägel
local function schlaeger(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, HOLZ, HOLZ_MAT) -- Griff = Mittelstück (0.26 x 0.26 x 0.8)

	-- Schlagfläche: Stufen werden nach vorne dicker (Pixel-Look)
	b(0.32, 0.32, 0.5, HOLZ_HELL, 0, 0, -0.65, HOLZ_MAT)
	b(0.38, 0.38, 0.6, HOLZ, 0, 0, -1.2, HOLZ_MAT)
	b(0.42, 0.42, 0.7, HOLZ_HELL, 0, 0, -1.85, HOLZ_MAT)
	b(0.36, 0.36, 0.08, HOLZ_DUNKEL, 0, 0, -2.23, HOLZ_MAT)
	-- Markenzeichen (dunkler Streifen)
	b(0.43, 0.1, 0.3, HOLZ_DUNKEL, 0, 0.0, -1.6, HOLZ_MAT)

	-- Dünner Griffteil mit schwarzem Griffband und rotem Streifen
	b(0.2, 0.2, 0.9, HOLZ, 0, 0, 0.85, HOLZ_MAT)
	b(0.23, 0.23, 0.62, SCHWARZ, 0, 0, 0.98, STOFF)
	b(0.24, 0.24, 0.05, ROT, 0, 0, 0.72, STOFF)
	b(0.24, 0.24, 0.05, ROT, 0, 0, 1.24, STOFF)
	-- Knauf
	b(0.32, 0.32, 0.1, HOLZ_DUNKEL, 0, 0, 1.33, HOLZ_MAT)

	-- Nägel (stehen schräg aus dem dicken Ende heraus)
	local naegel = {
		{ -1.5, 0 }, { -1.75, 90 }, { -1.95, 200 }, { -2.05, 300 }, { -1.3, 150 }, { -1.65, 250 },
	}
	for _, n in naegel do
		local winkel = math.rad(n[2])
		local radius = 0.24
		local richtung = Vector3.new(math.cos(winkel), math.sin(winkel), 0)
		local von = Vector3.new(0, 0, n[1]) + richtung * 0.12
		local bis = von + richtung * 0.22 + Vector3.new(0, 0, 0.03)
		stueck(tool, handle, von, bis, 0.035, 0.035, STAHL, METALL)
		anbauen(tool, handle, Vector3.new(0.07, 0.07, 0.07), STAHL, CFrame.new(Vector3.new(0, 0, n[1]) + richtung * radius * 0.92), METALL)
	end

	-- Blutflecken
	b(0.44, 0.12, 0.14, BLUT, 0, 0.06, -2.0, PLASTIK)
	b(0.1, 0.43, 0.2, BLUT, 0.02, -0.05, -1.75, PLASTIK)

	schlagSpur(handle, Vector3.new(0, 0, -0.9), Vector3.new(0, 0, -2.2), Color3.fromRGB(255, 220, 180))
	punkt(handle, "Griff", Vector3.new(0, 0, 0.95))
end

-- Machete: lange breite Klinge mit leichtem Bogen, dunkler Griff mit Parierstück
local function machete(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, STAHL, METALL) -- Griff = Klingenmitte (0.06 x 0.4 x 1.7)
	handle.Reflectance = 0.1

	-- Rücken (dunkler) und Schneide (hell)
	b(0.075, 0.06, 1.7, STAHL_DUNKEL, 0, 0.18, 0)
	b(0.04, 0.06, 1.7, CHROM, 0, -0.2, 0).Reflectance = 0.25

	-- Vorderer Teil: Klinge wird breiter und biegt sich leicht nach oben
	b(0.06, 0.46, 0.3, STAHL, 0, 0.0, -0.98, METALL, -4)
	b(0.04, 0.06, 0.3, CHROM, 0, -0.24, -0.97, METALL, -4).Reflectance = 0.25
	b(0.06, 0.4, 0.22, STAHL, 0, 0.04, -1.22, METALL, -8)
	b(0.04, 0.06, 0.22, CHROM, 0, -0.18, -1.23, METALL, -8).Reflectance = 0.25
	-- Spitze (schräg abgeschnitten)
	b(0.06, 0.24, 0.24, STAHL, 0, 0.0, -1.38, METALL, 45)
	b(0.06, 0.12, 0.12, CHROM, 0, -0.08, -1.5, METALL, 45)

	-- Rost/Blut auf der Klinge
	b(0.07, 0.1, 0.16, BLUT, 0, -0.08, -0.6, PLASTIK)
	b(0.07, 0.06, 0.1, BLUT, 0, 0.02, -0.75, PLASTIK)
	b(0.07, 0.08, 0.2, Color3.fromRGB(130, 80, 45), 0, 0.06, 0.4, PLASTIK)

	-- Parierstück, Griff mit Messingnieten, Knauf
	b(0.16, 0.5, 0.07, SCHWARZ, 0, 0.0, 0.88)
	b(0.15, 0.26, 0.7, POLYMER, 0, -0.03, 1.27, PLASTIK)
	for _, z in { 1.05, 1.27, 1.49 } do
		b(0.17, 0.06, 0.06, MESSING, 0, -0.03, z)
	end
	b(0.17, 0.32, 0.1, SCHWARZ, 0, -0.07, 1.66, METALL)
	-- Griffrillen
	for _, z in { 1.16, 1.38 } do
		b(0.16, 0.04, 0.05, SCHWARZ, 0, -0.17, z, PLASTIK)
	end

	schlagSpur(handle, Vector3.new(0, 0, -0.5), Vector3.new(0, 0, -1.5), Color3.fromRGB(220, 230, 255))
	punkt(handle, "Griff", Vector3.new(0, -0.03, 1.28))
end

-- Pistole (Glock-artig): Griff = Schlitten
local function pistole(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, STAHL_DUNKEL, METALL) -- 0.26 x 0.3 x 1.2
	local hz = handle.Size.Z / 2

	-- Rahmen aus Kunststoff unter dem Schlitten + Laufmündung
	b(0.24, 0.14, 1.08, POLYMER, 0, -0.22, -0.04, PLASTIK)
	b(0.13, 0.13, 0.06, SCHWARZ, 0, 0.0, -hz - 0.02)
	b(0.06, 0.06, 0.02, Color3.fromRGB(10, 10, 10), 0, 0.0, -hz - 0.05, PLASTIK)
	-- Schiene vorne unter dem Rahmen
	b(0.2, 0.05, 0.3, POLYMER, 0, -0.31, -0.42, PLASTIK)

	-- Griff (schräg) mit Riffelung und Magazinboden
	b(0.24, 0.62, 0.3, POLYMER, 0, -0.56, 0.36, PLASTIK, -15)
	for i = 0, 2 do
		b(0.25, 0.04, 0.24, SCHWARZ, 0, -0.42 - i * 0.14, 0.34 + i * 0.037, PLASTIK, -15)
	end
	b(0.26, 0.06, 0.32, SCHWARZ, 0, -0.86, 0.45, PLASTIK, -15)
	abzug(b, -0.08, -0.29, POLYMER)

	-- Visier vorne/hinten mit Leuchtpunkten
	b(0.05, 0.06, 0.06, SCHWARZ, 0, 0.18, -hz + 0.08)
	b(0.03, 0.03, 0.01, LEUCHT_GRUEN, 0, 0.19, -hz + 0.045, NEON)
	b(0.06, 0.06, 0.06, SCHWARZ, -0.06, 0.18, hz - 0.08)
	b(0.06, 0.06, 0.06, SCHWARZ, 0.06, 0.18, hz - 0.08)

	-- Griffrillen am Schlitten + Auswurffenster rechts
	for i = 0, 2 do
		for _, x in { -1, 1 } do
			b(0.01, 0.2, 0.03, SCHWARZ, x * 0.132, 0.0, hz - 0.1 - i * 0.07)
		end
	end
	b(0.01, 0.1, 0.26, SCHWARZ, 0.132, 0.06, -0.08)
	b(0.012, 0.06, 0.16, MESSING, 0.135, 0.06, -0.08) -- Patrone sichtbar

	punkt(handle, "Muendung", Vector3.new(0, 0, -hz - 0.06))
	punkt(handle, "Griff", Vector3.new(0, -0.38, 0.33))
end

-- Revolver: Rahmen aus Stahl, Trommel, langer Lauf, Holzgriff
local function revolver(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, STAHL, METALL) -- Rahmen 0.24 x 0.34 x 1.0
	handle.Reflectance = 0.1

	-- Trommel (achteckig aus zwei gedrehten Blöcken) mit Kammern vorne
	b(0.36, 0.36, 0.42, STAHL_DUNKEL, 0, -0.01, -0.06)
	b(0.36, 0.36, 0.42, STAHL_DUNKEL, 0, -0.01, -0.06, METALL, 0, 0, 45)
	for i = 0, 5 do
		local w = math.rad(i * 60 + 30)
		b(0.07, 0.07, 0.02, SCHWARZ, math.cos(w) * 0.12, -0.01 + math.sin(w) * 0.12, -0.28)
	end
	b(0.06, 0.06, 0.1, STAHL, 0, -0.01, -0.3) -- Achse

	-- Langer Lauf mit Unterlauf, Korn vorne
	b(0.15, 0.15, 1.0, STAHL, 0, 0.09, -1.0).Reflectance = 0.15
	b(0.11, 0.1, 0.92, STAHL_DUNKEL, 0, -0.03, -0.96)
	b(0.17, 0.04, 0.9, STAHL_DUNKEL, 0, 0.18, -0.98) -- Laufschiene
	b(0.04, 0.09, 0.1, SCHWARZ, 0, 0.23, -1.44)
	b(0.07, 0.07, 0.02, Color3.fromRGB(8, 8, 8), 0, 0.09, -1.505, PLASTIK)

	-- Hahn hinten, Kimme oben
	b(0.07, 0.14, 0.09, STAHL_DUNKEL, 0, 0.2, 0.5, METALL, 25)
	b(0.04, 0.06, 0.08, STAHL_DUNKEL, -0.05, 0.2, 0.36)
	b(0.04, 0.06, 0.08, STAHL_DUNKEL, 0.05, 0.2, 0.36)

	-- Holzgriff (schräg) mit Messing-Medaillon und Kappe
	b(0.26, 0.62, 0.3, HOLZ, 0, -0.43, 0.42, HOLZ_MAT, -22)
	b(0.27, 0.12, 0.31, HOLZ_DUNKEL, 0, -0.32, 0.38, HOLZ_MAT, -22)
	b(0.28, 0.06, 0.06, MESSING, 0, -0.45, 0.43, METALL, -22)
	b(0.27, 0.06, 0.32, STAHL_DUNKEL, 0, -0.74, 0.55, METALL, -22)
	abzug(b, 0.12, -0.17, STAHL)

	punkt(handle, "Muendung", Vector3.new(0, 0.09, -1.53))
	punkt(handle, "Griff", Vector3.new(0, -0.32, 0.38))
end

-- Gebogenes Magazin aus mehreren Stücken (von oben nach unten)
local function bogenMagazin(tool, handle, punkte, breite, tiefe, farbe)
	for i = 1, #punkte - 1 do
		stueck(tool, handle, punkte[i], punkte[i + 1], breite, tiefe, farbe, METALL)
	end
end

-- Maschinenpistole (MP5-artig)
local function mp(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, STAHL_DUNKEL, METALL) -- Gehäuse 0.24 x 0.3 x 1.4

	-- Obere Kante, Visiere
	b(0.1, 0.04, 1.2, SCHWARZ, 0, 0.17, 0)
	b(0.03, 0.12, 0.06, SCHWARZ, -0.05, 0.24, -0.6)
	b(0.03, 0.12, 0.06, SCHWARZ, 0.05, 0.24, -0.6)
	b(0.02, 0.07, 0.04, SCHWARZ, 0, 0.21, -0.6)
	b(0.14, 0.12, 0.12, SCHWARZ, 0, 0.23, 0.55)

	-- Handschutz mit Rillen
	b(0.3, 0.24, 0.55, POLYMER, 0, -0.06, -0.42, PLASTIK)
	for i = 0, 2 do
		b(0.31, 0.03, 0.05, SCHWARZ, 0, -0.06, -0.58 + i * 0.16, PLASTIK)
	end

	-- Lauf und Mündung
	b(0.1, 0.1, 0.3, SCHWARZ, 0, 0.03, -0.85)
	b(0.14, 0.14, 0.07, STAHL_DUNKEL, 0, 0.03, -1.02)

	-- Spannhebel links
	b(0.06, 0.06, 0.5, STAHL_DUNKEL, -0.12, 0.12, -0.45)
	b(0.1, 0.04, 0.04, SCHWARZ, -0.18, 0.12, -0.6)

	-- Magazinschacht + gebogenes Magazin
	b(0.18, 0.12, 0.22, SCHWARZ, 0, -0.2, -0.05)
	bogenMagazin(tool, handle, {
		Vector3.new(0, -0.24, -0.05),
		Vector3.new(0, -0.46, -0.1),
		Vector3.new(0, -0.66, -0.19),
		Vector3.new(0, -0.84, -0.32),
	}, 0.14, 0.22, POLYMER)
	b(0.16, 0.05, 0.25, SCHWARZ, 0, -0.86, -0.34, METALL, -35)

	-- Griffstück, Pistolengriff, Abzug, Feuerwahlhebel (rot)
	b(0.22, 0.14, 0.55, POLYMER, 0, -0.21, 0.4, PLASTIK)
	b(0.2, 0.46, 0.24, POLYMER, 0, -0.5, 0.52, PLASTIK, -12)
	b(0.21, 0.04, 0.2, SCHWARZ, 0, -0.42, 0.5, PLASTIK, -12)
	abzug(b, 0.24, -0.28, POLYMER)
	b(0.02, 0.06, 0.06, ROT, -0.12, -0.21, 0.5, PLASTIK)

	-- Auswurffenster rechts
	b(0.01, 0.08, 0.22, SCHWARZ, 0.125, 0.05, -0.15)

	-- Schulterstütze aus zwei Stangen
	for _, x in { -0.09, 0.09 } do
		b(0.04, 0.04, 0.65, STAHL, x, 0.0, 1.02)
	end
	b(0.28, 0.36, 0.07, SCHWARZ, 0, -0.04, 1.36)
	b(0.3, 0.38, 0.04, POLYMER, 0, -0.04, 1.41, PLASTIK)

	punkt(handle, "Muendung", Vector3.new(0, 0.03, -1.07))
	punkt(handle, "Griff", Vector3.new(0, -0.36, 0.5))
	punkt(handle, "LinkeHand", Vector3.new(0, -0.2, -0.45))
end

-- Pump-Schrotflinte: Holzpumpe und Holzschaft
local function schrotflinte(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, STAHL_DUNKEL, METALL) -- Gehäuse 0.26 x 0.34 x 1.0

	-- Lauf mit Laufschiene und Messing-Korn, Röhrenmagazin darunter
	b(0.13, 0.13, 1.9, SCHWARZ, 0, 0.08, -1.45)
	b(0.04, 0.03, 1.8, STAHL_DUNKEL, 0, 0.155, -1.45)
	b(0.045, 0.045, 0.045, MESSING, 0, 0.18, -2.34)
	b(0.06, 0.06, 0.02, Color3.fromRGB(8, 8, 8), 0, 0.08, -2.405, PLASTIK)
	b(0.12, 0.12, 1.5, STAHL_DUNKEL, 0, -0.08, -1.25)
	b(0.14, 0.14, 0.06, STAHL, 0, -0.08, -2.02)
	b(0.17, 0.3, 0.07, STAHL_DUNKEL, 0, 0.0, -1.9) -- Laufschelle

	-- Pumpe aus Holz mit Rillen
	b(0.24, 0.22, 0.6, HOLZ, 0, -0.1, -1.05, HOLZ_MAT)
	for i = 0, 3 do
		b(0.25, 0.02, 0.04, HOLZ_DUNKEL, 0, -0.1, -1.27 + i * 0.15, HOLZ_MAT)
	end

	-- Auswurffenster, Ladeöffnung, Abzug
	b(0.01, 0.12, 0.3, SCHWARZ, 0.135, 0.04, -0.05)
	b(0.14, 0.01, 0.32, SCHWARZ, 0, -0.175, -0.12)
	abzug(b, 0.3, -0.17, STAHL_DUNKEL)

	-- Holzschaft: Hals, Kolben, Gummikappe
	b(0.2, 0.26, 0.5, HOLZ, 0, -0.13, 0.72, HOLZ_MAT, 12)
	b(0.22, 0.38, 0.75, HOLZ_HELL, 0, -0.23, 1.25, HOLZ_MAT, 10)
	b(0.23, 0.08, 0.6, HOLZ_DUNKEL, 0, -0.08, 1.25, HOLZ_MAT, 10)
	b(0.24, 0.42, 0.06, SCHWARZ, 0, -0.3, 1.64, PLASTIK, 10)

	-- Ein paar rote Schrotpatronen seitlich am Schaft (Patronenhalter)
	b(0.03, 0.2, 0.42, SCHWARZ, -0.125, -0.22, 1.25, STOFF, 10)
	for i = 0, 2 do
		local z = 1.12 + i * 0.13
		b(0.06, 0.16, 0.08, ROT, -0.15, -0.21 - (z - 1.25) * 0.17, z, PLASTIK, 10)
		b(0.065, 0.04, 0.085, MESSING, -0.15, -0.3 - (z - 1.25) * 0.17, z, METALL, 10)
	end

	punkt(handle, "Muendung", Vector3.new(0, 0.08, -2.42))
	punkt(handle, "Griff", Vector3.new(0, -0.22, 0.62))
	punkt(handle, "LinkeHand", Vector3.new(0, -0.22, -1.05))
end

-- Sturmgewehr (M4-artig) mit Leuchtpunktvisier
local function sturmgewehr(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, POLYMER, METALL) -- Gehäuse 0.24 x 0.32 x 1.3

	-- Schiene oben mit Zähnen
	b(0.14, 0.04, 1.2, SCHWARZ, 0, 0.18, 0)
	for i = 0, 5 do
		b(0.16, 0.03, 0.05, SCHWARZ, 0, 0.21, -0.5 + i * 0.2)
	end

	-- Leuchtpunktvisier (Rahmen, Glas, roter Punkt)
	b(0.16, 0.06, 0.3, SCHWARZ, 0, 0.24, 0.05)
	b(0.03, 0.2, 0.26, OLIV_DUNKEL, -0.085, 0.36, 0.05)
	b(0.03, 0.2, 0.26, OLIV_DUNKEL, 0.085, 0.36, 0.05)
	b(0.2, 0.03, 0.26, OLIV_DUNKEL, 0, 0.475, 0.05)
	local glas = b(0.14, 0.17, 0.01, Color3.fromRGB(120, 200, 255), 0, 0.36, -0.02, Enum.Material.Glass)
	glas.Transparency = 0.6
	b(0.025, 0.025, 0.01, Color3.fromRGB(255, 40, 40), 0, 0.37, 0.0, NEON)

	-- Handschutz mit Lüftungslöchern
	b(0.3, 0.3, 0.9, OLIV, 0, 0.0, -1.1, PLASTIK)
	for i = 0, 2 do
		for _, x in { -1, 1 } do
			b(0.01, 0.08, 0.12, SCHWARZ, x * 0.152, 0.03, -1.4 + i * 0.3, PLASTIK)
		end
	end

	-- Lauf, Kornträger, Mündungsfeuerdämpfer
	b(0.08, 0.08, 0.6, SCHWARZ, 0, 0.04, -1.85)
	b(0.08, 0.24, 0.07, SCHWARZ, 0, 0.12, -1.65)
	b(0.03, 0.06, 0.03, SCHWARZ, 0, 0.27, -1.65)
	b(0.12, 0.12, 0.16, STAHL_DUNKEL, 0, 0.04, -2.2)
	b(0.13, 0.02, 0.1, SCHWARZ, 0, 0.04, -2.22)

	-- Magazinschacht + gebogenes Magazin
	b(0.2, 0.16, 0.28, POLYMER, 0, -0.2, -0.25, PLASTIK)
	bogenMagazin(tool, handle, {
		Vector3.new(0, -0.26, -0.25),
		Vector3.new(0, -0.5, -0.29),
		Vector3.new(0, -0.72, -0.37),
	}, 0.15, 0.24, SCHWARZ)
	b(0.17, 0.05, 0.27, POLYMER, 0, -0.74, -0.39, PLASTIK, -20)

	-- Pistolengriff, Abzug, Spannhebel, Schließhilfe, Auswurffenster
	b(0.18, 0.42, 0.22, OLIV, 0, -0.38, 0.38, PLASTIK, -15)
	abzug(b, 0.12, -0.16, POLYMER)
	b(0.2, 0.04, 0.06, SCHWARZ, 0, 0.15, 0.66)
	b(0.06, 0.06, 0.1, SCHWARZ, 0.14, 0.08, 0.3)
	b(0.01, 0.1, 0.24, SCHWARZ, 0.122, 0.04, -0.05)

	-- Puffer-Rohr und Schaft
	b(0.12, 0.12, 0.6, SCHWARZ, 0, 0.04, 0.95)
	b(0.22, 0.36, 0.5, OLIV, 0, -0.04, 1.15, PLASTIK)
	b(0.24, 0.4, 0.05, SCHWARZ, 0, -0.04, 1.42, PLASTIK)

	punkt(handle, "Muendung", Vector3.new(0, 0.04, -2.3))
	punkt(handle, "Griff", Vector3.new(0, -0.27, 0.35))
	punkt(handle, "LinkeHand", Vector3.new(0, -0.17, -1.0))
end

-- Maschinengewehr (M249-artig): Kastenmagazin, Patronengurt, Zweibein
local function mg(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, SCHWARZ, METALL) -- Gehäuse 0.32 x 0.4 x 1.6

	-- Zuführdeckel mit Schiene und Kimme
	b(0.34, 0.08, 0.7, STAHL_DUNKEL, 0, 0.24, 0.15)
	b(0.14, 0.04, 0.6, SCHWARZ, 0, 0.3, 0.15)
	b(0.12, 0.1, 0.08, SCHWARZ, 0, 0.33, 0.48)

	-- Lauf mit Hitzeschutz, Tragegriff, Korn und Mündungsfeuerdämpfer
	b(0.12, 0.12, 1.6, STAHL_DUNKEL, 0, 0.06, -1.6)
	b(0.17, 0.06, 0.9, SCHWARZ, 0, 0.15, -1.2)
	for i = 0, 3 do
		b(0.18, 0.02, 0.06, STAHL, 0, 0.18, -1.55 + i * 0.22)
	end
	b(0.05, 0.16, 0.05, SCHWARZ, 0.0, 0.25, -0.95)
	b(0.05, 0.16, 0.05, SCHWARZ, 0.0, 0.25, -1.4)
	b(0.07, 0.05, 0.55, POLYMER, 0.0, 0.34, -1.17, PLASTIK)
	b(0.06, 0.2, 0.06, SCHWARZ, 0, 0.17, -2.25)
	b(0.16, 0.16, 0.2, STAHL_DUNKEL, 0, 0.06, -2.48)

	-- Gasrohr und Handschutz unten
	b(0.1, 0.1, 1.0, SCHWARZ, 0, -0.09, -1.3)
	b(0.3, 0.18, 0.5, POLYMER, 0, -0.16, -1.05, PLASTIK)

	-- Zweibein (eingeklappt unter dem Lauf)
	b(0.16, 0.08, 0.1, SCHWARZ, 0, -0.15, -1.95)
	for _, x in { -0.08, 0.08 } do
		b(0.05, 0.05, 0.65, STAHL, x, -0.2, -1.6)
		b(0.08, 0.04, 0.08, SCHWARZ, x, -0.24, -1.3)
	end

	-- Kastenmagazin (oliv, mit Gurt) und Patronengurt zur Zuführung
	b(0.36, 0.5, 0.55, OLIV, -0.06, -0.45, -0.3, STOFF)
	b(0.37, 0.06, 0.56, OLIV_DUNKEL, -0.06, -0.38, -0.3, STOFF)
	b(0.37, 0.5, 0.06, OLIV_DUNKEL, -0.06, -0.45, -0.3, STOFF)
	for i = 0, 3 do
		local y = -0.18 + i * 0.1
		b(0.06, 0.06, 0.16, MESSING, -0.22, y, -0.3 + 0.02 * i)
		b(0.04, 0.04, 0.05, KUPFER, -0.22, y, -0.4 + 0.02 * i)
	end

	-- Pistolengriff und Abzug
	b(0.2, 0.46, 0.24, POLYMER, 0, -0.43, 0.5, PLASTIK, -15)
	abzug(b, 0.25, -0.2, POLYMER)

	-- Schaft: obere Röhre, schräge Strebe, Kolbenplatte
	b(0.14, 0.12, 0.75, POLYMER, 0, 0.06, 1.17, PLASTIK)
	stueck(tool, handle, Vector3.new(0, -0.18, 0.8), Vector3.new(0, -0.14, 1.5), 0.1, 0.1, POLYMER, PLASTIK)
	b(0.26, 0.5, 0.08, SCHWARZ, 0, -0.05, 1.56, PLASTIK)

	punkt(handle, "Muendung", Vector3.new(0, 0.06, -2.6))
	punkt(handle, "Griff", Vector3.new(0, -0.32, 0.48))
	punkt(handle, "LinkeHand", Vector3.new(0, -0.27, -1.05))
end

-- Minigun: 6 Läufe im Kreis, Motorgehäuse, Tragegriff, Munitionskasten
-- Teile mit dem Attribut "Rotor" drehen sich in der Ego-Ansicht beim Schießen um die Längsachse.
local function minigun(tool, handle, _daten)
	local b = baukasten(tool, handle)
	griffAussehen(handle, STAHL_DUNKEL, METALL) -- Gehäuse 0.62 x 0.62 x 1.3

	local function rotor(teil)
		teil:SetAttribute("Rotor", true)
		return teil
	end

	-- Drehender Teil: Lager, Mittelachse, 6 Läufe, 2 Laufschellen
	rotor(b(0.5, 0.5, 0.25, STAHL, 0, 0, -0.78))
	rotor(b(0.5, 0.5, 0.25, STAHL, 0, 0, -0.78, METALL, 0, 0, 45))
	rotor(b(0.12, 0.12, 2.0, SCHWARZ, 0, 0, -1.75))
	for i = 0, 5 do
		local w = math.rad(i * 60)
		rotor(b(0.1, 0.1, 2.0, STAHL_DUNKEL, math.cos(w) * 0.17, math.sin(w) * 0.17, -1.75))
		rotor(b(0.06, 0.06, 0.02, Color3.fromRGB(8, 8, 8), math.cos(w) * 0.17, math.sin(w) * 0.17, -2.755, PLASTIK))
	end
	for _, z in { -1.25, -2.45 } do
		rotor(b(0.46, 0.46, 0.08, STAHL, 0, 0, z))
		rotor(b(0.46, 0.46, 0.08, STAHL, 0, 0, z, METALL, 0, 0, 45))
	end

	-- Warnstreifen am Gehäuse
	b(0.64, 0.64, 0.08, LEUCHT_ORANGE, 0, 0, -0.45, PLASTIK)
	b(0.64, 0.64, 0.08, SCHWARZ, 0, 0, -0.35, PLASTIK)

	-- Elektromotor rechts
	b(0.26, 0.26, 0.5, POLYMER, 0.42, 0.05, 0.2, PLASTIK)
	b(0.28, 0.08, 0.08, STAHL, 0.42, 0.05, 0.42)

	-- Tragegriff oben
	b(0.08, 0.25, 0.08, SCHWARZ, 0, 0.42, -0.3)
	b(0.08, 0.25, 0.08, SCHWARZ, 0, 0.42, 0.4)
	b(0.1, 0.08, 0.8, POLYMER, 0, 0.56, 0.05, STOFF)

	-- Hintere Griffe (Spatengriff) mit rotem Feuerknopf
	b(0.56, 0.08, 0.3, SCHWARZ, 0, -0.12, 0.8)
	for _, x in { -0.22, 0.22 } do
		b(0.12, 0.42, 0.12, POLYMER, x, -0.3, 0.95, PLASTIK)
	end
	b(0.07, 0.06, 0.07, ROT, 0.22, -0.06, 0.95, NEON)

	-- Munitionskasten links unten und Zuführschlauch
	b(0.5, 0.5, 0.6, OLIV, -0.5, -0.6, 0.2, METALL)
	b(0.52, 0.06, 0.62, OLIV_DUNKEL, -0.5, -0.38, 0.2, METALL)
	b(0.2, 0.06, 0.06, SCHWARZ, -0.5, -0.32, 0.2)
	stueck(tool, handle, Vector3.new(-0.3, -0.05, -0.1), Vector3.new(-0.45, -0.2, 0.0), 0.2, 0.14, SCHWARZ, STOFF)
	stueck(tool, handle, Vector3.new(-0.45, -0.2, 0.0), Vector3.new(-0.5, -0.35, 0.1), 0.2, 0.14, SCHWARZ, STOFF)
	for i = 0, 2 do
		b(0.14, 0.05, 0.05, MESSING, -0.36 - i * 0.05, -0.1 - i * 0.08, -0.06 + i * 0.05)
	end

	punkt(handle, "Muendung", Vector3.new(0, 0, -2.8))
	punkt(handle, "Griff", Vector3.new(0.22, -0.2, 0.95))
	punkt(handle, "LinkeHand", Vector3.new(0, 0.5, -0.1))
end

local MODELLE = {
	Karambit = karambit,
	Schlaeger = schlaeger,
	Machete = machete,
	Pistole = pistole,
	Revolver = revolver,
	MP = mp,
	Schrotflinte = schrotflinte,
	Sturmgewehr = sturmgewehr,
	MG = mg,
	Minigun = minigun,
}

function WaffenModelle.Bauen(name, tool, handle, daten)
	local bauen = MODELLE[name]
	if bauen then
		bauen(tool, handle, daten)
	end
end

return WaffenModelle
