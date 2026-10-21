-- Baut beim Spielstart eine große Wiese mit Bäumen und Steinen.
-- Abschalten: Config.Map.Aktiv = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

local zufall = Random.new(42) -- feste Zahl = jedes Mal die gleiche Map

local function teil(eltern, groesse, farbe, cframe, material, form)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = groesse
	p.Color = farbe
	p.CFrame = cframe
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if form then
		p.Shape = form
	end
	p.Parent = eltern
	return p
end

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

local function zufallsPunkt(groesse, freierRadius)
	while true do
		local x = zufall:NextNumber(-groesse / 2 + 10, groesse / 2 - 10)
		local z = zufall:NextNumber(-groesse / 2 + 10, groesse / 2 - 10)
		if Vector2.new(x, z).Magnitude > freierRadius then
			return Vector3.new(x, 0, z)
		end
	end
end

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

	-- Wiese aus Terrain (Oberkante bei Höhe 0), mit Grashalmen
	local terrain = workspace.Terrain
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(groesse, 12, groesse), Enum.Material.Grass)
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(80, 120, 55))
	terrain.Decoration = true

	local deko = Instance.new("Folder")
	deko.Name = "Deko"
	deko.Parent = workspace

	for _ = 1, einstellungen.Baeume do
		baum(deko, zufallsPunkt(groesse, einstellungen.FreierRadius))
	end
	for _ = 1, einstellungen.Steine do
		stein(deko, zufallsPunkt(groesse, einstellungen.FreierRadius))
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
