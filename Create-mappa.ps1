# CSV betöltése
$csv = Import-Csv -Path "E:\rpg_maker_feltoltes\AD szkript\student.csv" -Delimiter ";"

# Alap mappa
$basePath = "E:\Diak"

# Tanuló mappák létrehozása és jogosultság beállítása
foreach ($row in $csv) {
    $tanuloPath = Join-Path $basePath (Join-Path $row.Osztaly $row.Nev)

    # Mappa létrehozása, ha nem létezik
    if (-not (Test-Path $tanuloPath)) {
        New-Item -ItemType Directory -Path $tanuloPath | Out-Null
        Write-Host "Létrehozva: $tanuloPath" -ForegroundColor Green
    } else {
        Write-Host "Már létezik: $tanuloPath" -ForegroundColor Yellow
    }

    # Öröklődés kikapcsolása és minden meglévő jog eltávolítása
    icacls $tanuloPath /inheritance:r /remove:g * 

    # Csak a Rendszergazda hozzáadása teljes joggal
    icacls $tanuloPath /grant Rendszergazda:(OI)(CI)F
}