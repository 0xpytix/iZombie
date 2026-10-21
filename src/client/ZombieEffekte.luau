-- Treffer-Effekte an Zombies (nur beim Spieler gezeichnet): kurzes rotes Aufblitzen und Blutspritzer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ZombieEffekte = {}

local blitze = {} -- [model] = Highlight

local function aufblitzen(model)
	local highlight = blitze[model]
	if not highlight or not highlight.Parent then
		highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 40, 40)
		highlight.OutlineTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = model
		highlight.Parent = model
		blitze[model] = highlight
		model.Destroying:Connect(function()
			blitze[model] = nil
		end)
	end
	highlight.FillTransparency = 0.35
	TweenService:Create(highlight, TweenInfo.new(0.18), { FillTransparency = 1 }):Play()
end

local function blutspritzer(position, groesse)
	local anker = Instance.new("Part")
	anker.Anchored = true
	anker.CanCollide = false
	anker.CanQuery = false
	anker.CanTouch = false
	anker.Transparency = 1
	anker.Size = Vector3.new(0.2, 0.2, 0.2)
	anker.CFrame = CFrame.new(position)
	anker.Parent = workspace.CurrentCamera

	local partikel = Instance.new("ParticleEmitter")
	partikel.Color = ColorSequence.new(Color3.fromRGB(140, 10, 10), Color3.fromRGB(70, 0, 0))
	partikel.Size = NumberSequence.new(0.35 * groesse, 0)
	partikel.Lifetime = NumberRange.new(0.3, 0.6)
	partikel.Speed = NumberRange.new(6, 14)
	partikel.SpreadAngle = Vector2.new(70, 70)
	partikel.Acceleration = Vector3.new(0, -45, 0)
	partikel.Drag = 2
	partikel.LightEmission = 0
	partikel.Rate = 0
	partikel.EmissionDirection = Enum.NormalId.Top
	partikel.Parent = anker
	partikel:Emit(12)

	Debris:AddItem(anker, 1)
end

function ZombieEffekte.Start()
	Remotes.Effect.OnClientEvent:Connect(function(art, model)
		if art ~= "ZombieGetroffen" or typeof(model) ~= "Instance" or not model.Parent then
			return
		end
		aufblitzen(model)
		local wurzel = model.PrimaryPart
		if wurzel then
			blutspritzer(wurzel.Position + Vector3.new(0, wurzel.Size.Y * 0.3, 0), wurzel.Size.Y / 2)
		end
	end)
end

return ZombieEffekte
