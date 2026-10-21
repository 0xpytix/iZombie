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

local MODELLE = {
	Karambit = karambit,
}

function WaffenModelle.Bauen(name, tool, handle, daten)
	local bauen = MODELLE[name]
	if bauen then
		bauen(tool, handle, daten)
	end
end

return WaffenModelle
