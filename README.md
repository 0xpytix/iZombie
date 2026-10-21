# iZombie

Wellen-Survival gegen Zombies für Roblox, synchronisiert mit [Rojo](https://rojo.space).

## Starten
1. `.\rojo.exe serve` im Projektordner ausführen.
2. In Roblox Studio: **Plug-ins → Rojo → Connect**.
3. Neuen Code holen: `git pull` (in einem zweiten Terminal).

## Inhalt
- Wellen mit Pausen dazwischen, Zombies werden mit jeder Welle stärker
- Zombie-Typen: Normal, Schnell, Panzer, Hund, Boss
- Jede 5. Welle: Hunde-Welle · jede 10. Welle: Boss-Welle
- Boss-Fähigkeiten: Stampfer (mit Rückstoß), Verstärkung rufen, Ansturm, Wut unter 50 % Leben
- Geld pro Kill + Wellen-Bonus, Waffen-Shop (Taste **B**) vom Messer bis zur Minigun
- Game Over, wenn alle Spieler tot sind

## Einstellungen
- Spielbalance: `src/shared/Config.luau`
- Waffen und Preise: `src/shared/WeaponData.luau`
- Eigene Zombie-Spawnpunkte: Ordner `ZombieSpawns` im Workspace anlegen und Parts hineinlegen
- Max. 50 Spieler: in Roblox Studio unter Spieleinstellungen bzw. im Creator Dashboard (Server-Größe) einstellen

## Struktur
- `src/server` → ServerScriptService
- `src/client` → StarterPlayerScripts
- `src/shared` → ReplicatedStorage
