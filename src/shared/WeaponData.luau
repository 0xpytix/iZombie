-- Alle Waffen im Shop, sortiert von schwach nach stark.
-- Id: interner Name (nur Buchstaben), Name: wird im Spiel angezeigt.
-- Cooldown: Sekunden zwischen zwei Schüssen/Schlägen. Streuung in Grad.
-- Rueckstoss: wie weit getroffene Zombies weggestoßen werden.
-- Modell: Name des 3D-Modells in src/server/WaffenModelle.luau (Groesse = Hauptkörper/Griff des Modells).
-- Sound: Schlüssel aus Config.Sounds für den Schuss. SoundTempo < 1 = tiefer/wuchtiger, > 1 = heller.
-- SoundDauer: Schuss-Sound nach so vielen Sekunden abschneiden (für schnelle Automatikwaffen).
-- SoundBass: zusätzlicher Bass in dB, SoundVerzerrung: 0 bis 1 (macht den Knall rauer).

local WeaponData = {}

WeaponData.Liste = {
	{
		Id = "Messer", Name = "Karambit | Crimson Web", Typ = "Nahkampf", Preis = 0,
		Schaden = 25, Cooldown = 0.4, Reichweite = 6, Rueckstoss = 55,
		Groesse = Vector3.new(0.22, 0.32, 1), Farbe = Color3.fromRGB(25, 25, 30), Material = Enum.Material.SmoothPlastic,
		-- eigenes 3D-Modell (siehe src/server/WaffenModelle.luau)
		Modell = "Karambit",
		KlingenFarbe = Color3.fromRGB(170, 18, 24),
		AkzentFarbe = Color3.fromRGB(170, 18, 24),
		NetzFarbe = Color3.fromRGB(20, 10, 10), -- Spinnennetz-Linien auf der Klinge
	},
	{
		Id = "Schlaeger", Name = "Baseballschläger", Typ = "Nahkampf", Preis = 150,
		Schaden = 45, Cooldown = 0.7, Reichweite = 7, Rueckstoss = 100,
		Groesse = Vector3.new(0.26, 0.26, 0.8), Farbe = Color3.fromRGB(128, 78, 40), Material = Enum.Material.Wood,
		Modell = "Schlaeger",
	},
	{
		Id = "Pistole", Name = "Pistole", Typ = "Schusswaffe", Preis = 400,
		Schaden = 25, Cooldown = 0.3, Reichweite = 200,
		Groesse = Vector3.new(0.26, 0.3, 1.2), Farbe = Color3.fromRGB(60, 62, 68),
		Modell = "Pistole", Sound = "Pistole", SoundTempo = 1.1, SoundLautstaerke = 0.7,
	},
	{
		Id = "Machete", Name = "Machete", Typ = "Nahkampf", Preis = 600,
		Schaden = 70, Cooldown = 0.55, Reichweite = 7.5, Rueckstoss = 70,
		Groesse = Vector3.new(0.06, 0.4, 1.7), Farbe = Color3.fromRGB(125, 128, 135),
		Modell = "Machete",
	},
	{
		Id = "Revolver", Name = "Revolver", Typ = "Schusswaffe", Preis = 1200,
		Schaden = 75, Cooldown = 0.65, Reichweite = 220,
		Groesse = Vector3.new(0.24, 0.34, 1), Farbe = Color3.fromRGB(125, 128, 135),
		Modell = "Revolver", Sound = "Gewehr", SoundTempo = 0.8, SoundLautstaerke = 0.9, SoundBass = 6, SoundVerzerrung = 0.25,
	},
	{
		Id = "MP", Name = "Maschinenpistole", Typ = "Schusswaffe", Preis = 2500,
		Schaden = 18, Cooldown = 0.09, Reichweite = 150, Automatik = true, Streuung = 3,
		Groesse = Vector3.new(0.24, 0.3, 1.4), Farbe = Color3.fromRGB(60, 62, 68),
		Modell = "MP", Sound = "Pistole", SoundTempo = 1.25, SoundLautstaerke = 0.55, SoundDauer = 0.6,
	},
	{
		Id = "Schrotflinte", Name = "Schrotflinte", Typ = "Schusswaffe", Preis = 4000,
		Schaden = 18, Kugeln = 8, Cooldown = 0.9, Reichweite = 60, Streuung = 7, Rueckstoss = 12,
		Groesse = Vector3.new(0.26, 0.34, 1), Farbe = Color3.fromRGB(60, 62, 68),
		Modell = "Schrotflinte", Sound = "Schrotflinte", SoundTempo = 0.9, SoundLautstaerke = 1, SoundBass = 8, SoundDauer = 0.7,
	},
	{
		Id = "Sturmgewehr", Name = "Sturmgewehr", Typ = "Schusswaffe", Preis = 7000,
		Schaden = 32, Cooldown = 0.11, Reichweite = 300, Automatik = true, Streuung = 1.5,
		Groesse = Vector3.new(0.24, 0.32, 1.3), Farbe = Color3.fromRGB(44, 45, 50),
		Modell = "Sturmgewehr", Sound = "Gewehr", SoundTempo = 1.05, SoundLautstaerke = 0.6, SoundDauer = 0.8,
	},
	{
		Id = "MG", Name = "Maschinengewehr", Typ = "Schusswaffe", Preis = 15000,
		Schaden = 40, Cooldown = 0.07, Reichweite = 300, Automatik = true, Streuung = 3.5,
		Groesse = Vector3.new(0.32, 0.4, 1.6), Farbe = Color3.fromRGB(30, 31, 35),
		Modell = "MG", Sound = "MG", SoundTempo = 0.88, SoundLautstaerke = 0.65, SoundBass = 5, SoundDauer = 0.6,
	},
	{
		Id = "Minigun", Name = "Minigun", Typ = "Schusswaffe", Preis = 40000,
		Schaden = 45, Cooldown = 0.04, Reichweite = 250, Automatik = true, Streuung = 5,
		Groesse = Vector3.new(0.62, 0.62, 1.3), Farbe = Color3.fromRGB(60, 62, 68),
		Modell = "Minigun", Sound = "Minigun", SoundTempo = 1.4, SoundLautstaerke = 0.45, SoundDauer = 0.3, SoundVerzerrung = 0.15,
	},
}

WeaponData.NachId = {}
for _, daten in WeaponData.Liste do
	WeaponData.NachId[daten.Id] = daten
end

return WeaponData
