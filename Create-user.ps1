# CSV beolvas�sa
$csv = Import-Csv -Path "E:\rpg_maker_feltoltes\AD szkript\student.csv" -Delimiter ";"

# Domain �s alap OU
$domain = "letenyey.local"
$rootOU = "OU=2025-26,OU=Felhasznalok,DC=letenyey,DC=local"

foreach ($sor in $csv) {
    $nev = $sor.Nev.Trim()
    $osztaly = $sor.Osztaly.Trim()

    # OU
    $userOU = "OU=$osztaly,$rootOU"

    # Ellen�rizz�k, hogy l�tezik-e az OU
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$osztaly'" -SearchBase $rootOU -ErrorAction SilentlyContinue)) {
        Write-Host "OU nem l�tezett, l�trehozom: $userOU"
        New-ADOrganizationalUnit -Name $osztaly -Path $rootOU
    }

    # N�v r�szek
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

    # Egyedi Name / CN az OU-n bel�l
    $name = $nev
    $index = 1
    while (Get-ADUser -Filter { Name -eq $name } -SearchBase $userOU -ErrorAction SilentlyContinue) {
        $name = "$nev$index"
        $index++
    }

    # Ellen�rz�s: l�tezik-e m�r az OU-ban
    $l�tezik = Get-ADUser -Filter { Name -eq $nev } -SearchBase $userOU -ErrorAction SilentlyContinue

    if ($l�tezik) {
        Write-Host "A felhaszn�l� m�r l�tezik: $nev"
    } else {
        # Felhaszn�l� l�trehoz�sa
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

        Write-Host "Felhaszn�l� l�trehozva: $nev"
    }
}
