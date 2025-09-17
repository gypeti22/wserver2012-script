# AD modul betöltése
Import-Module ActiveDirectory

# CSV beolvasása
$csv = Import-Csv -Path "E:\rpg_maker_feltoltes\AD szkript\student.csv" -Delimiter ";"

foreach ($sor in $csv) {
    $nev = $sor.Nev.Trim()
    $osztaly = $sor.Osztaly.Trim()

    # Felhasználó SamAccountName
    $sam = ($nev -replace '\s+', '.').ToLower()

    # Ellenõrzés, hogy a felhasználó létezik az AD-ben
    $adUser = Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue
    if (-not $adUser) {
        Write-Warning "Felhasználó nem található az AD-ben: $sam"
        continue
    }

    # Mappa elérési út
    $folderPath = "E:\Diak\$osztaly\$nev"

    # Ellenõrzés, hogy a mappa létezik
    if (-not (Test-Path $folderPath)) {
        Write-Warning "Mappa nem létezik: $folderPath"
        continue
    }

    Write-Host "`n--- Feldolgozás: $folderPath ---`n"

    # Tulajdon átvétele
    Write-Host "Tulajdon átvétele..."
    takeown /F "$folderPath" /R /D Y | Out-Null

    # ACL resetelése
    Write-Host "ACL resetelése..."
    cmd.exe /c "icacls `"$folderPath`" /reset /T /C" | Out-Null

    # Administrators ideiglenes teljes hozzáférés
    cmd.exe /c "icacls `"$folderPath`" /grant Administrators:F /T" | Out-Null

    # ACL lekérése
    $acl = Get-Acl $folderPath

    # Öröklõdés tiltása és korábbi szabályok törlése
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in $acl.Access) {
        $acl.RemoveAccessRuleAll($rule)
    }

    # Speciális jogok a diáknak
    $rights = [System.Security.AccessControl.FileSystemRights]::ReadData `
            -bor [System.Security.AccessControl.FileSystemRights]::WriteData `
            -bor [System.Security.AccessControl.FileSystemRights]::AppendData `
            -bor [System.Security.AccessControl.FileSystemRights]::ReadExtendedAttributes `
            -bor [System.Security.AccessControl.FileSystemRights]::WriteExtendedAttributes `
            -bor [System.Security.AccessControl.FileSystemRights]::ReadAttributes `
            -bor [System.Security.AccessControl.FileSystemRights]::WriteAttributes `
            -bor [System.Security.AccessControl.FileSystemRights]::ReadPermissions `
            -bor [System.Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles

    $inherit = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit `
             -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $propagation = [System.Security.AccessControl.PropagationFlags]::None

    # Diák szabály
    $ruleStudent = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $sam,
        $rights,
        $inherit,
        $propagation,
        "Allow"
    )
    $acl.SetAccessRule($ruleStudent)

    # Rendszergazda teljes hozzáférés
    $ruleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "LETENYEY\Rendszergazda",
        "FullControl",
        $inherit,
        $propagation,
        "Allow"
    )
    $acl.AddAccessRule($ruleAdmin)

    # ACL alkalmazása
    try {
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "Jogosultság beállítva: $folderPath - $sam + LETENEY\Rendszergazda" -ForegroundColor Green
    }
    catch {
        Write-Warning "Hiba történt az ACL alkalmazásakor: $folderPath - $($_.Exception.Message)"
    }
}

Write-Host "`n--- Szkript futtatás kész ---`n"
