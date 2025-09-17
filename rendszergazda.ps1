# Teljes elérési utak
$takeownPath = "$env:SystemRoot\System32\takeown.exe"
$icaclsPath = "$env:SystemRoot\System32\icacls.exe"

# Mappa, ahol a szkript található
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Felhasználók listája, akiknek hozzá kell adni FullControl-t
$usersToAdd = @(
    "BUILTIN\Administrators",
    "LETENEY\ikzs",
    "LETENEY\gka",
    "LETENEY\tamaskaedit",
    "LETENEY\pz"  # Papp Zoltán belépési neve
)

# Lekéri az összes almappát a könyvtárban
$Folders = Get-ChildItem -Path $scriptDir -Directory

foreach ($folder in $Folders) {
    $folderPath = $folder.FullName
    Write-Host "`n--- Feldolgozás: $folderPath ---`n"

    try {
        # Tulajdon átvétele
        Write-Host "Tulajdon átvétele..."
        & "$takeownPath" /F "$folderPath" /R /D Y | Out-Null

        # ACL resetelése és öröklõdés letiltása (csak a mappa gyökérre)
        Write-Host "Öröklõdés letiltása..."
        & "$icaclsPath" "`"$folderPath`"" /inheritance:r /C | Out-Null

        # ACL lekérése
        $acl = Get-Acl $folderPath

        # Új felhasználók hozzáadása (megõrizve a meglévõket)
        foreach ($user in $usersToAdd) {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $user,
                [System.Security.AccessControl.FileSystemRights]::FullControl,
                [System.Security.AccessControl.InheritanceFlags]::None,   # nincs öröklõdés
                [System.Security.AccessControl.PropagationFlags]::None,
                "Allow"
            )
            $acl.AddAccessRule($rule)
            Write-Host " › Hozzáadva: $user"
        }

        # ACL alkalmazása
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "Jogosultságok hozzáadva: $folderPath" -ForegroundColor Green
    }
    catch {
        Write-Warning "Hiba történt: $folderPath - $($_.Exception.Message)"
    }
}

Write-Host "`n--- Minden mappa feldolgozva ---`n"
