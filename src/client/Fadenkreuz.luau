-- Fadenkreuz in der Bildmitte (Ego-Perspektive, die Maus ist dort gesperrt).
-- Geht beim Schießen kurz auseinander und zeigt ein X bei Treffern (rot bei Kopfschuss).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local LAENGE = 8
local DICKE = 2
local GRUND_ABSTAND = 5
local MAX_ABSTAND = 16

local Fadenkreuz = {}

local streuung = 0 -- 0 bis 1, wird beim Schießen erhöht und sinkt wieder
local trefferZeit = 0
local kopfschuss = false

function Fadenkreuz.Schuss(staerke)
	streuung = math.min(1, streuung + (staerke or 0.35))
end

function Fadenkreuz.Treffer(istKopfschuss)
	trefferZeit = os.clock()
	kopfschuss = istKopfschuss == true
end

local function balken(eltern, groesse, drehung, farbe)
	return UI.neu("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = groesse,
		Rotation = drehung or 0,
		BackgroundColor3 = farbe or Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = eltern,
	}, { UI.neu("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.4 }) })
end

local function shopOffen()
	local gui = player.PlayerGui:FindFirstChild("iZombieShop")
	local fenster = gui and gui:FindFirstChild("Fenster")
	return fenster ~= nil and fenster.Visible
end

function Fadenkreuz.Start()
	local gui = UI.neu("ScreenGui", {
		Name = "iZombieFadenkreuz",
		ResetOnSpawn = false,
		IgnoreGuiInset = true, -- damit die Mausposition genau passt
		DisplayOrder = 10,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local mitte = UI.neu("Frame", {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})

	local oben = balken(mitte, UDim2.fromOffset(DICKE, LAENGE))
	local unten = balken(mitte, UDim2.fromOffset(DICKE, LAENGE))
	local links = balken(mitte, UDim2.fromOffset(LAENGE, DICKE))
	local rechts = balken(mitte, UDim2.fromOffset(LAENGE, DICKE))
	balken(mitte, UDim2.fromOffset(DICKE, DICKE))

	-- Treffer-X
	local treffer = {}
	for i, drehung in { 45, -45, 45, -45 } do
		local teil = balken(mitte, UDim2.fromOffset(DICKE, 7), drehung)
		local x = (i == 1 or i == 4) and 1 or -1
		local y = i <= 2 and -1 or 1
		if drehung == -45 then
			x = -x
		end
		teil.Position = UDim2.fromOffset(x * 7, y * 7)
		table.insert(treffer, teil)
	end

	RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local sichtbar = hum ~= nil and hum.Health > 0 and not shopOffen()

		mitte.Visible = sichtbar
		UserInputService.MouseIconEnabled = not sichtbar
		if not sichtbar then
			return
		end

		local maus = UserInputService:GetMouseLocation()
		mitte.Position = UDim2.fromOffset(maus.X, maus.Y)

		-- Streuung langsam zurückgehen lassen
		streuung = math.max(0, streuung - dt * 3)
		local abstand = GRUND_ABSTAND + (MAX_ABSTAND - GRUND_ABSTAND) * streuung
		local versatz = abstand + LAENGE / 2
		oben.Position = UDim2.fromOffset(0, -versatz)
		unten.Position = UDim2.fromOffset(0, versatz)
		links.Position = UDim2.fromOffset(-versatz, 0)
		rechts.Position = UDim2.fromOffset(versatz, 0)

		-- Treffer-X kurz einblenden
		local alter = os.clock() - trefferZeit
		local transparenz = math.clamp(alter / 0.25, 0, 1)
		local farbe = kopfschuss and Color3.fromRGB(255, 60, 60) or Color3.new(1, 1, 1)
		for _, teil in treffer do
			teil.BackgroundTransparency = transparenz
			teil.BackgroundColor3 = farbe
			teil:FindFirstChildOfClass("UIStroke").Transparency = math.max(0.4, transparenz)
		end
	end)
end

return Fadenkreuz
