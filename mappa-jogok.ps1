# AD modul bet�lt�se
Import-Module ActiveDirectory

# CSV beolvas�sa
$csv = Import-Csv -Path "E:\rpg_maker_feltoltes\AD szkript\student.csv" -Delimiter ";"

foreach ($sor in $csv) {
    $nev = $sor.Nev.Trim()
    $osztaly = $sor.Osztaly.Trim()

    # Felhaszn�l� SamAccountName
    $sam = ($nev -replace '\s+', '.').ToLower()

    # Ellen�rz�s, hogy a felhaszn�l� l�tezik az AD-ben
    $adUser = Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue
    if (-not $adUser) {
        Write-Warning "Felhaszn�l� nem tal�lhat� az AD-ben: $sam"
        continue
    }

    # Mappa el�r�si �t
    $folderPath = "E:\Diak\$osztaly\$nev"

    # Ellen�rz�s, hogy a mappa l�tezik
    if (-not (Test-Path $folderPath)) {
        Write-Warning "Mappa nem l�tezik: $folderPath"
        continue
    }

    Write-Host "`n--- Feldolgoz�s: $folderPath ---`n"

    # Tulajdon �tv�tele
    Write-Host "Tulajdon �tv�tele..."
    takeown /F "$folderPath" /R /D Y | Out-Null

    # ACL resetel�se
    Write-Host "ACL resetel�se..."
    cmd.exe /c "icacls `"$folderPath`" /reset /T /C" | Out-Null

    # Administrators ideiglenes teljes hozz�f�r�s
    cmd.exe /c "icacls `"$folderPath`" /grant Administrators:F /T" | Out-Null

    # ACL lek�r�se
    $acl = Get-Acl $folderPath

    # �r�kl�d�s tilt�sa �s kor�bbi szab�lyok t�rl�se
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in $acl.Access) {
        $acl.RemoveAccessRuleAll($rule)
    }

    # Speci�lis jogok a di�knak
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

    # Di�k szab�ly
    $ruleStudent = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $sam,
        $rights,
        $inherit,
        $propagation,
        "Allow"
    )
    $acl.SetAccessRule($ruleStudent)

    # Rendszergazda teljes hozz�f�r�s
    $ruleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "LETENYEY\Rendszergazda",
        "FullControl",
        $inherit,
        $propagation,
        "Allow"
    )
    $acl.AddAccessRule($ruleAdmin)

    # ACL alkalmaz�sa
    try {
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "Jogosults�g be�ll�tva: $folderPath - $sam + LETENEY\Rendszergazda" -ForegroundColor Green
    }
    catch {
        Write-Warning "Hiba t�rt�nt az ACL alkalmaz�sakor: $folderPath - $($_.Exception.Message)"
    }
}

Write-Host "`n--- Szkript futtat�s k�sz ---`n"
