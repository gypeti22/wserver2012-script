# Teljes el�r�si utak
$takeownPath = "$env:SystemRoot\System32\takeown.exe"
$icaclsPath = "$env:SystemRoot\System32\icacls.exe"

# Mappa, ahol a szkript tal�lhat�
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Felhaszn�l�k list�ja, akiknek hozz� kell adni FullControl-t
$usersToAdd = @(
    "BUILTIN\Administrators",
    "LETENEY\ikzs",
    "LETENEY\gka",
    "LETENEY\tamaskaedit",
    "LETENEY\pz"  # Papp Zolt�n bel�p�si neve
)

# Lek�ri az �sszes almapp�t a k�nyvt�rban
$Folders = Get-ChildItem -Path $scriptDir -Directory

foreach ($folder in $Folders) {
    $folderPath = $folder.FullName
    Write-Host "`n--- Feldolgoz�s: $folderPath ---`n"

    try {
        # Tulajdon �tv�tele
        Write-Host "Tulajdon �tv�tele..."
        & "$takeownPath" /F "$folderPath" /R /D Y | Out-Null

        # ACL resetel�se �s �r�kl�d�s letilt�sa (csak a mappa gy�k�rre)
        Write-Host "�r�kl�d�s letilt�sa..."
        & "$icaclsPath" "`"$folderPath`"" /inheritance:r /C | Out-Null

        # ACL lek�r�se
        $acl = Get-Acl $folderPath

        # �j felhaszn�l�k hozz�ad�sa (meg�rizve a megl�v�ket)
        foreach ($user in $usersToAdd) {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $user,
                [System.Security.AccessControl.FileSystemRights]::FullControl,
                [System.Security.AccessControl.InheritanceFlags]::None,   # nincs �r�kl�d�s
                [System.Security.AccessControl.PropagationFlags]::None,
                "Allow"
            )
            $acl.AddAccessRule($rule)
            Write-Host " � Hozz�adva: $user"
        }

        # ACL alkalmaz�sa
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "Jogosults�gok hozz�adva: $folderPath" -ForegroundColor Green
    }
    catch {
        Write-Warning "Hiba t�rt�nt: $folderPath - $($_.Exception.Message)"
    }
}

Write-Host "`n--- Minden mappa feldolgozva ---`n"
