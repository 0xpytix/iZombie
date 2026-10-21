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
			local teil = stueck(tool, handle, letzter, punkt, 0.05, hoehe, klinge, Enum.Material.Metal)
			teil.Reflectance = 0.3
		end
		letzter = punkt
	end

	-- Klingenrücken in Akzentfarbe am Ansatz
	anbauen(tool, handle, Vector3.new(0.08, 0.06, 0.35), akzent, CFrame.new(0, 0.16, -halbeLaenge + 0.1), Enum.Material.Neon)

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

	-- Griffrillen
	for z = -0.3, 0.3, 0.2 do
		anbauen(tool, handle, Vector3.new(0.24, 0.34, 0.05), akzent:Lerp(Color3.new(0, 0, 0), 0.5), CFrame.new(0, 0, z), Enum.Material.SmoothPlastic)
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
