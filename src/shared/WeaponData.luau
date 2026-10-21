-- Alle Waffen im Shop, sortiert von schwach nach stark.
-- Id: interner Name (nur Buchstaben), Name: wird im Spiel angezeigt.
-- Cooldown: Sekunden zwischen zwei Schüssen/Schlägen. Streuung in Grad.

local WeaponData = {}

WeaponData.Liste = {
	{
		Id = "Messer", Name = "Messer", Typ = "Nahkampf", Preis = 0,
		Schaden = 25, Cooldown = 0.45, Reichweite = 6,
		Groesse = Vector3.new(0.2, 0.3, 1.4), Farbe = Color3.fromRGB(200, 200, 210),
	},
	{
		Id = "Schlaeger", Name = "Baseballschläger", Typ = "Nahkampf", Preis = 150,
		Schaden = 45, Cooldown = 0.7, Reichweite = 7,
		Groesse = Vector3.new(0.35, 0.35, 3), Farbe = Color3.fromRGB(150, 105, 60), Material = Enum.Material.Wood,
	},
	{
		Id = "Pistole", Name = "Pistole", Typ = "Schusswaffe", Preis = 400,
		Schaden = 25, Cooldown = 0.3, Reichweite = 200,
		Groesse = Vector3.new(0.3, 0.6, 1.2), Farbe = Color3.fromRGB(50, 50, 55),
	},
	{
		Id = "Machete", Name = "Machete", Typ = "Nahkampf", Preis = 600,
		Schaden = 70, Cooldown = 0.55, Reichweite = 7.5,
		Groesse = Vector3.new(0.15, 0.5, 2.6), Farbe = Color3.fromRGB(170, 175, 180),
	},
	{
		Id = "Revolver", Name = "Revolver", Typ = "Schusswaffe", Preis = 1200,
		Schaden = 75, Cooldown = 0.65, Reichweite = 220,
		Groesse = Vector3.new(0.3, 0.6, 1.5), Farbe = Color3.fromRGB(120, 110, 100),
	},
	{
		Id = "MP", Name = "Maschinenpistole", Typ = "Schusswaffe", Preis = 2500,
		Schaden = 18, Cooldown = 0.09, Reichweite = 150, Automatik = true, Streuung = 3,
		Groesse = Vector3.new(0.35, 0.6, 2), Farbe = Color3.fromRGB(40, 40, 45),
	},
	{
		Id = "Schrotflinte", Name = "Schrotflinte", Typ = "Schusswaffe", Preis = 4000,
		Schaden = 18, Kugeln = 8, Cooldown = 0.9, Reichweite = 60, Streuung = 7,
		Groesse = Vector3.new(0.35, 0.5, 3), Farbe = Color3.fromRGB(90, 60, 40),
	},
	{
		Id = "Sturmgewehr", Name = "Sturmgewehr", Typ = "Schusswaffe", Preis = 7000,
		Schaden = 32, Cooldown = 0.11, Reichweite = 300, Automatik = true, Streuung = 1.5,
		Groesse = Vector3.new(0.35, 0.6, 3.2), Farbe = Color3.fromRGB(60, 70, 50),
	},
	{
		Id = "MG", Name = "Maschinengewehr", Typ = "Schusswaffe", Preis = 15000,
		Schaden = 40, Cooldown = 0.07, Reichweite = 300, Automatik = true, Streuung = 3.5,
		Groesse = Vector3.new(0.5, 0.7, 3.8), Farbe = Color3.fromRGB(35, 35, 35),
	},
	{
		Id = "Minigun", Name = "Minigun", Typ = "Schusswaffe", Preis = 40000,
		Schaden = 45, Cooldown = 0.04, Reichweite = 250, Automatik = true, Streuung = 5,
		Groesse = Vector3.new(0.9, 0.9, 3.5), Farbe = Color3.fromRGB(80, 80, 90),
	},
}

WeaponData.NachId = {}
for _, daten in WeaponData.Liste do
	WeaponData.NachId[daten.Id] = daten
end

return WeaponData
