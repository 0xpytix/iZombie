-- Viewmodel für die Ego-Perspektive: Hände mit Handschuhen und die Waffe direkt vor der Kamera.
-- Die echte Waffe am Charakter sehen nur die anderen Spieler.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WeaponData = require(ReplicatedStorage.Shared.WeaponData)

local player = Players.LocalPlayer

local WAFFEN_SKALIERUNG = 0.55
local AERMEL_FARBE = Color3.fromRGB(55, 58, 64)
local HANDSCHUH_FARBE = Color3.fromRGB(95, 98, 104)
local HAUT_FARBE = Color3.fromRGB(225, 185, 155)

-- Wo die rechte Hand vor der Kamera ist (x = rechts, y = oben, -z = nach vorne)
local RECHTE_HAND = CFrame.new(0.62, -0.62, -1.45)
local RECHTER_ELLBOGEN = Vector3.new(1.3, -1.5, -0.35)
local LINKE_HAND_RUHE = Vector3.new(-0.7, -0.8, -1.45)
local LINKER_ELLBOGEN = Vector3.new(-1.35, -1.55, -0.35)

-- Wie die Waffe in der Hand liegt (relativ zur Hand). Waffenmodelle: vorne = -Z, oben = +Y.
local HALTUNG = {
	-- Karambit wie in CS:GO: Ring links am Zeigefinger, Klinge zeigt nach rechts und biegt sich nach oben
	Karambit = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, -1), Vector3.new(0, -1, 0))
		* CFrame.Angles(math.rad(-15), 0, 0),
	-- Schläger und Machete schräg nach oben-vorne
	Nahkampf = CFrame.Angles(math.rad(55), math.rad(10), 0),
	-- Schusswaffen gerade nach vorne
	Schusswaffe = CFrame.new(),
}

local ViewModel = {}

local ordner -- Folder in der Kamera
local waffenTeile = {} -- { teil = Part, relativ = CFrame (zum Griff) }
local spur -- Leuchtspur der Waffe (falls vorhanden)
local haende = {}
local aktuellesTool
local aktuelleDaten

local schlagStart = -10
local rueckstoss = 0
local wackelZeit = 0

function ViewModel.Angriff(daten)
	if daten.Typ == "Nahkampf" then
		schlagStart = os.clock()
	else
		rueckstoss = math.min(1, rueckstoss + 0.6)
	end
end

local function neuesTeil(groesse, farbe, material)
	local teil = Instance.new("Part")
	teil.Anchored = true
	teil.CanCollide = false
	teil.CanQuery = false
	teil.CanTouch = false
	teil.CastShadow = false
	teil.Size = groesse
	teil.Color = farbe
	teil.Material = material or Enum.Material.SmoothPlastic
	teil.Parent = ordner
	return teil
end

-- Unterarm (Ärmel) + Handschuh + Finger
local function baueHand()
	return {
		aermel = neuesTeil(Vector3.new(0.32, 0.32, 1), AERMEL_FARBE, Enum.Material.Fabric),
		handschuh = neuesTeil(Vector3.new(0.3, 0.26, 0.34), HANDSCHUH_FARBE, Enum.Material.Fabric),
		finger = neuesTeil(Vector3.new(0.28, 0.08, 0.12), HAUT_FARBE),
	}
end

local function setzeHand(hand, handCFrame, ellbogen)
	-- Ärmel vom Ellbogen bis zum Handgelenk
	local handgelenk = (handCFrame * CFrame.new(0, 0, 0.16)).Position
	local laenge = (handgelenk - ellbogen).Magnitude
	hand.aermel.Size = Vector3.new(0.32, 0.32, laenge)
	hand.aermel.CFrame = CFrame.lookAt((handgelenk + ellbogen) / 2, handgelenk)
	hand.handschuh.CFrame = handCFrame
	hand.finger.CFrame = handCFrame * CFrame.new(0, 0.12, -0.12)
end

local function entferneWaffe()
	for _, eintrag in waffenTeile do
		eintrag.teil:Destroy()
	end
	waffenTeile = {}
	spur = nil
	aktuellesTool = nil
	aktuelleDaten = nil
end

-- Kopiert die Teile des Tools verkleinert ins Viewmodel
local function baueWaffe(tool, daten)
	entferneWaffe()
	aktuellesTool = tool
	aktuelleDaten = daten

	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return
	end
	local griffInvers = handle.CFrame:Inverse()

	for _, original in tool:GetDescendants() do
		if original:IsA("BasePart") then
			local kopie = original:Clone()
			for _, kind in kopie:GetChildren() do
				if not kind:IsA("Attachment") and not kind:IsA("Trail") then
					kind:Destroy()
				end
			end
			kopie.Anchored = true
			kopie.CanCollide = false
			kopie.CanQuery = false
			kopie.CanTouch = false
			kopie.CastShadow = false
			kopie.Size *= WAFFEN_SKALIERUNG
			for _, anhang in kopie:GetChildren() do
				if anhang:IsA("Attachment") then
					anhang.Position *= WAFFEN_SKALIERUNG
				elseif anhang:IsA("Trail") then
					spur = anhang
					anhang.Enabled = false
				end
			end
			kopie.Parent = ordner

			local relativ = griffInvers * original.CFrame
			relativ = relativ - relativ.Position + relativ.Position * WAFFEN_SKALIERUNG
			table.insert(waffenTeile, { teil = kopie, relativ = relativ })
		end
	end
end

local function haltung(daten)
	if daten.Modell and HALTUNG[daten.Modell] then
		return HALTUNG[daten.Modell]
	end
	return HALTUNG[daten.Typ] or CFrame.new()
end

function ViewModel.Start()
	local kamera = workspace.CurrentCamera
	ordner = Instance.new("Folder")
	ordner.Name = "Viewmodel"
	ordner.Parent = kamera
	player:GetMouse().TargetFilter = ordner

	haende.rechts = baueHand()
	haende.links = baueHand()

	RunService:BindToRenderStep("iZombieViewmodel", Enum.RenderPriority.Camera.Value + 2, function(dt)
		local char = player.Character
		local kopf = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local tool = char and char:FindFirstChildOfClass("Tool")
		local daten = tool and WeaponData.NachId[tool:GetAttribute("Waffe") or ""]
		local ersteperson = kopf ~= nil and (kamera.CFrame.Position - kopf.Position).Magnitude < 2
		local sichtbar = ersteperson and hum ~= nil and hum.Health > 0 and daten ~= nil

		ordner.Parent = sichtbar and kamera or nil
		if not sichtbar then
			return
		end

		if tool ~= aktuellesTool then
			baueWaffe(tool, daten)
		end

		-- Echte Waffe in der Ego-Perspektive ausblenden (andere Spieler sehen sie weiterhin)
		for _, teil in tool:GetDescendants() do
			if teil:IsA("BasePart") then
				teil.LocalTransparencyModifier = 1
			end
		end

		-- Wackeln beim Laufen
		local wurzel = char:FindFirstChild("HumanoidRootPart")
		local tempo = wurzel and Vector3.new(wurzel.AssemblyLinearVelocity.X, 0, wurzel.AssemblyLinearVelocity.Z).Magnitude or 0
		local staerke = math.clamp(tempo / 16, 0, 1)
		wackelZeit += dt * (4 + 6 * staerke)
		local wackeln = CFrame.new(
			math.sin(wackelZeit) * 0.025 * (0.3 + staerke),
			-math.abs(math.cos(wackelZeit)) * 0.03 * (0.3 + staerke),
			0
		)

		-- Schlag-Animation: Hand zieht schräg nach links durch
		local schlag = CFrame.new()
		local t = (os.clock() - schlagStart) / 0.3
		if t >= 0 and t < 1 then
			local a = math.sin(t * math.pi)
			schlag = CFrame.new(-0.45 * a, 0.12 * a, -0.25 * a) * CFrame.Angles(math.rad(-10) * a, math.rad(30) * a, math.rad(-35) * a)
		end
		if spur then
			spur.Enabled = t >= 0 and t < 1
		end

		-- Rückstoß bei Schusswaffen
		rueckstoss = math.max(0, rueckstoss - dt * 8)
		local stoss = CFrame.new(0, 0, 0.12 * rueckstoss) * CFrame.Angles(math.rad(5) * rueckstoss, 0, 0)

		local basis = kamera.CFrame * wackeln
		local handCFrame = basis * RECHTE_HAND * schlag * stoss

		-- Waffe: Griffmitte liegt in der Hand
		local griff = handCFrame * haltung(aktuelleDaten)
		if aktuelleDaten.Typ ~= "Nahkampf" or not aktuelleDaten.Modell then
			-- Lange Waffen: Hand am hinteren Teil des Griffs
			griff *= CFrame.new(0, 0, -aktuelleDaten.Groesse.Z * WAFFEN_SKALIERUNG * 0.3)
		end
		for _, eintrag in waffenTeile do
			eintrag.teil.CFrame = griff * eintrag.relativ
		end

		setzeHand(haende.rechts, handCFrame, (basis * CFrame.new(RECHTER_ELLBOGEN)).Position)

		-- Linke Hand: bei Schusswaffen vorne am Lauf, sonst locker links
		local linkeHand
		if aktuelleDaten.Typ == "Schusswaffe" and aktuelleDaten.Groesse.Z > 1.6 then
			linkeHand = griff * CFrame.new(0, -0.08, -aktuelleDaten.Groesse.Z * WAFFEN_SKALIERUNG * 0.35)
		else
			linkeHand = basis * CFrame.new(LINKE_HAND_RUHE) * CFrame.Angles(0, math.rad(-10), math.rad(15))
		end
		setzeHand(haende.links, linkeHand, (basis * CFrame.new(LINKER_ELLBOGEN)).Position)
	end)

	player.CharacterAdded:Connect(entferneWaffe)
end

return ViewModel
