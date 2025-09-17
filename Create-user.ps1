# CSV beolvasása
$csv = Import-Csv -Path "E:\rpg_maker_feltoltes\AD szkript\student.csv" -Delimiter ";"

# Domain és alap OU
$domain = "letenyey.local"
$rootOU = "OU=2025-26,OU=Felhasznalok,DC=letenyey,DC=local"

foreach ($sor in $csv) {
    $nev = $sor.Nev.Trim()
    $osztaly = $sor.Osztaly.Trim()

    # OU
    $userOU = "OU=$osztaly,$rootOU"

    # Ellenõrizzük, hogy létezik-e az OU
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$osztaly'" -SearchBase $rootOU -ErrorAction SilentlyContinue)) {
        Write-Host "OU nem létezett, létrehozom: $userOU"
        New-ADOrganizationalUnit -Name $osztaly -Path $rootOU
    }

    # Név részek
    $nevReszek = $nev.Split(" ")
    $givenName = $nevReszek[0]
    $surname = if ($nevReszek.Count -gt 1) { $nevReszek[1] } else { "" }

    # Alap SamAccountName
    $baseSam = ($nev -replace '\s+', '.').ToLower()
    if ($baseSam.Length -gt 20) { $baseSam = $baseSam.Substring(0,20) }

    # Egyedi SamAccountName
    $sam = $baseSam
    $index = 1
    while (Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue) {
        $sam = $baseSam + $index
        if ($sam.Length -gt 20) { $sam = $sam.Substring(0,20) }
        $index++
    }
    $upn = "$sam@$domain"

    # Egyedi Name / CN az OU-n belül
    $name = $nev
    $index = 1
    while (Get-ADUser -Filter { Name -eq $name } -SearchBase $userOU -ErrorAction SilentlyContinue) {
        $name = "$nev$index"
        $index++
    }

    # Ellenõrzés: létezik-e már az OU-ban
    $létezik = Get-ADUser -Filter { Name -eq $nev } -SearchBase $userOU -ErrorAction SilentlyContinue

    if ($létezik) {
        Write-Host "A felhasználó már létezik: $nev"
    } else {
        # Felhasználó létrehozása
        New-ADUser `
            -Name $name `
            -SamAccountName $sam `
            -UserPrincipalName $upn `
            -Path $userOU `
            -AccountPassword (ConvertTo-SecureString "letenyey2025" -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -GivenName $givenName `
            -Surname $surname `
            -DisplayName $nev

        Write-Host "Felhasználó létrehozva: $nev"
    }
}
