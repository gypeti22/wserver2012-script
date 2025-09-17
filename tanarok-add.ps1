# A szkript mappája
$ScriptPath = $PSScriptRoot

# Felhasználók listája
$users = @(
    "LETENYEY\Ikzs",
    "LETENYEY\gka",
    "LETENYEY\tamaskaedit",
    "LETENYEY\papp.zoltan"
)

# Lekérjük az összes almappát és a gyökér mappát
$folders = Get-ChildItem -Path $ScriptPath -Directory -Recurse
$folders += Get-Item -Path $ScriptPath  # A gyökér mappa is kell

foreach ($folder in $folders) {
    Write-Host "Módosítás: $($folder.FullName)"
    
    # Lekérjük a meglévő ACL-t
    $acl = Get-Acl $folder.FullName

    foreach ($user in $users) {
        # Új ACE létrehozása a felhasználóhoz, teljes hozzáféréssel, öröklődés letiltva
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $user,
            "FullControl",
            [System.Security.AccessControl.InheritanceFlags]::None,   # nincs öröklődés
            [System.Security.AccessControl.PropagationFlags]::None,
            "Allow"
        )

        # Hozzáadjuk a meglévő ACL-hez
        $acl.AddAccessRule($accessRule)
        Write-Host " → Hozzáadva: $user"
    }

    # Alkalmazzuk a mappára
    Set-Acl -Path $folder.FullName -AclObject $acl
}

Write-Host "Minden mappához hozzáadva a megadott felhasználók teljes jogosultsággal, öröklődés letiltva."
