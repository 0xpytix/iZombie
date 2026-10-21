-- Ego-Perspektive: eigene Arme und Waffe bleiben sichtbar und folgen dem Blick nach oben/unten.
-- (Die Kamera selbst wird vom Server auf LockFirstPerson gestellt.)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local ARM_TEILE = {
	RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
	["Right Arm"] = true, ["Left Arm"] = true, -- R6
}
local SCHULTERN = { "RightShoulder", "LeftShoulder", "Right Shoulder", "Left Shoulder" }

local ErstePerson = {}

function ErstePerson.Start()
	local kamera = workspace.CurrentCamera
	local original = {} -- [Motor6D] = ursprüngliches C0
	local aktuellerCharakter

	local function schulterMotoren(char)
		if char ~= aktuellerCharakter then
			aktuellerCharakter = char
			original = {}
		end
		for _, name in SCHULTERN do
			local motor = char:FindFirstChild(name, true)
			if motor and motor:IsA("Motor6D") and not original[motor] then
				original[motor] = motor.C0
			end
		end
		return original
	end

	-- Nach der Kamera ausführen, damit unsere Sichtbarkeit nicht überschrieben wird
	RunService:BindToRenderStep("iZombieErstePerson", Enum.RenderPriority.Camera.Value + 1, function()
		local char = player.Character
		local kopf = char and char:FindFirstChild("Head")
		if not kopf then
			return
		end

		local motoren = schulterMotoren(char)
		local ersteperson = (kamera.CFrame.Position - kopf.Position).Magnitude < 2
		local neigung = ersteperson and math.asin(math.clamp(kamera.CFrame.LookVector.Y, -1, 1)) or 0

		-- Arme um das Schultergelenk mit dem Blick nach oben/unten drehen
		for motor, c0 in motoren do
			if motor.Parent then
				motor.C0 = CFrame.new(c0.Position) * CFrame.Angles(neigung, 0, 0) * c0.Rotation
			end
		end

		if not ersteperson then
			return
		end

		-- Arme und Waffe sichtbar machen (Roblox blendet in der Ego-Perspektive den ganzen Körper aus)
		for _, teil in char:GetChildren() do
			if teil:IsA("BasePart") and ARM_TEILE[teil.Name] then
				teil.LocalTransparencyModifier = 0
			elseif teil:IsA("Tool") then
				for _, toolTeil in teil:GetDescendants() do
					if toolTeil:IsA("BasePart") then
						toolTeil.LocalTransparencyModifier = 0
					end
				end
			end
		end
	end)
end

return ErstePerson
