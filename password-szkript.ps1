Import-Module ActiveDirectory

# CSV beolvasása
$users = Import-Csv -Path "$PSScriptRoot\student.csv"

# Új jelszó minden felhasználónak
$Password = ConvertTo-SecureString "letenyey2025" -AsPlainText -Force

foreach ($user in $users) {
    $FullName = $user.Name

    # Felhasználó lekérése AD-ből név alapján
    $ADUser = Get-ADUser -Filter { Name -eq $FullName } -ErrorAction SilentlyContinue

    if ($ADUser) {
        # Jelszó beállítása
        Set-ADAccountPassword -Identity $ADUser -NewPassword $Password -Reset
        # Kötelező jelszócsere a következő belépéskor
        Set-ADUser -Identity $ADUser -ChangePasswordAtLogon $true

        Write-Host "Jelszó beállítva: $FullName"
    } else {
        Write-Host "Felhasználó nem található: $FullName"
    }
}
