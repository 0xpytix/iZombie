-- Kleine Hilfsfunktionen zum Bauen von Benutzeroberflächen per Code.

local UI = {}

-- UI.neu("TextLabel", { Text = "Hallo", Parent = gui }, { UI.ecken(8) })
function UI.neu(klasse, eigenschaften, kinder)
	local objekt = Instance.new(klasse)
	local eltern
	for name, wert in eigenschaften or {} do
		if name == "Parent" then
			eltern = wert
		else
			objekt[name] = wert
		end
	end
	for _, kind in kinder or {} do
		kind.Parent = objekt
	end
	if eltern then
		objekt.Parent = eltern
	end
	return objekt
end

function UI.ecken(radius)
	return UI.neu("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function UI.innenabstand(pixel)
	local abstand = UDim.new(0, pixel)
	return UI.neu("UIPadding", {
		PaddingLeft = abstand, PaddingRight = abstand, PaddingTop = abstand, PaddingBottom = abstand,
	})
end

-- 12500 -> "12.500"
function UI.zahl(n)
	local text = tostring(math.floor(n))
	local ergebnis = text:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if ergebnis:sub(1, 1) == "." then
		ergebnis = ergebnis:sub(2)
	end
	return ergebnis
end

return UI
