# Variáveis obrigatórias
Param (
    [Parameter (Mandatory = $true)]
    [string] $UserName,
    [string] $JumpCloudConnectKey
)

# Declaração de variáveis
$teamviewerURL = "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"
$googleChromeURL = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B65DEC826-D254-2DE3-F93A-A6C0BB8157FB%7D%26lang%3Dpt-PT%26browser%3D5%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Dempty/update2/installers/ChromeSetup.exe"
$firefoxURL = "https://cdn.stubdownloader.services.mozilla.com/builds/firefox-stub/pt-PT/win/7a4edbc2923ced0a26263bdd4d8cc55b27e233280a52e1bc10976a9258f282c1/Firefox%20Installer.exe"
$wingetURL = "https://github.com/rise-tech/scripts/raw/master/source.msix"
$winrarURL = "https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-700br.exe"

$userName = $UserName.ToLower()
$jumpCloudConnectKey = $JumpCloudConnectKey

$teamviewerPath = $env:TEMP + "\teamviewer.exe"
$googleChromePath = $env:TEMP + "\chrome.exe"
$firefoxPath = $env:TEMP + "\firefox.exe"
$wingetPath = $env:TEMP + "\winget.msix"
$winrarPath = $env:TEMP + "\winrar.exe"
$googleDrivePath = $env:TEMP + "\drive.exe"
$preyPath = $env:TEMP + "\prey.exe"
$slackPath = $env:TEMP + "\slack.exe"

$sourceProfilePath = "C:\Users\Default"
$targetProfilePath = "C:\Users\$userName"

$startupFolder = "C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$autonboardBATPath = "$startupFolder\autonboard.bat"

# Verificar se há atualizações do Windows
Install-Module -Name PSWindowsUpdate -Force
$updates = Get-WUInstall | Where-Object {$_.State -eq "Available"}

if ($updates) {
    Write-Host "Atualizações do Windows disponíveis."
    Write-Host "Baixando e instalando atualizações..."
    Start-WUInstall -Install
    Write-Host "Atualizações instaladas com sucesso."
} else {
    Write-Host "Não há atualizações do Windows disponíveis."
}

# Criar um novo usuário
Write-Host "Criando o usuário..."
$userName = Read-Host "Nome de usuário"
$userPassword = Read-Host "Senha" -AsSecureString

New-LocalUser -Name $userName -Password $userPassword

# Adicionar o novo usuário ao grupo de Usuários
Add-LocalGroupMember -Group Usuários -Member $userName

# Copiar o perfil do usuário padrão
New-Item -Path $targetProfilePath -ItemType Directory
Copy-Item -Path $sourceProfilePath -Destination $targetProfilePath -Exclude "AppData\Local\Microsoft\Windows\Shell\Roaming", "AppData\Roaming\Microsoft\Windows\StartMenu"

# # Atualizar o registro do Windows
# $userSID = (Get-WMIObject Win32_UserAccount -Filter "Name='$userName'").SID
# $HKLMPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
# New-ItemProperty -Path $HKLMPath -Name $userSID -Value $userName -PropertyType String -Force

# Solicita o token do Prey
Write-Host "Digite/Cole o token do Prey:"
$preyToken = Read-Host
$preyURL = $preyURL + $preyToken

# Baixar softwares
Function DownloadInstallers() {
    (New-Object System.Net.WebClient).DownloadFile("${teamviewerURL}", "${teamviewerPath}")
    (New-Object System.Net.WebClient).DownloadFile("${googleChromeURL}", "${googleChromePath}")
    (New-Object System.Net.WebClient).DownloadFile("${googleDriveURL}", "${googleDrivePath}")
    (New-Object System.Net.WebClient).DownloadFile("${firefoxURL}", "${firefoxPath}")
    (New-Object System.Net.WebClient).DownloadFile("${preyURL}", "${preyPath}")
    (New-Object System.Net.WebClient).DownloadFile("${slackURL}", "${slackPath}")
    (New-Object System.Net.WebClient).DownloadFile("${wingetURL}", "${wingetPath}")
    (New-Object System.Net.WebClient).DownloadFile("${winrarURL}", "${winrarPath}")
}

# Instalar softwares
Function InstallSoftwares(){
    # Winget
    Add-AppxPackage -Path $wingetPath -wait
    Write-Host "Winget instalado."

    # TeamViewer
    Start-Process -FilePath $teamviewerPath -ArgumentList "/S /L pt-BR" -PassThru -NoNewWindow
    Write-Host "TeamViewer instalado."

    # Chrome
    Start-Process -FilePath $googleChromePath -PassThru -NoNewWindow -Wait
    Write-Host "Chrome instalado."

    # Firefox
    Start-Process -FilePath $firefoxPath -PassThru -NoNewWindow -Wait
    Write-Host "Firefox instalado."

    # Winrar
    Start-Process -FilePath $winrarPath -PassThru -NoNewWindow -Wait
    Write-Host "Winrar instalado."
}

Write-Host "Baixando softwares..."
DownloadInstallers

Write-Host "Instalando softwares..."
InstallSoftwares

# Renomear o computador
Write-Host "Renomeando o computador..."
Rename-Computer -NewName $userName.ToUpper()

# Remove OneDrive
winget uninstall Microsoft.OneDrive

# Criar o script on_user_script.bat

# Verifique se a pasta Startup já existe
if (!(Test-Path -Path $startupFolder)) {
    # Crie a pasta Startup
    New-Item -Path $startupFolder -ItemType Directory
}

$run = "cd $env:temp | Invoke-Expression; Invoke-RestMethod -Method Get -URI https://github.com/rise-tech/scripts/raw/master/windows/on_user.ps1 -OutFile on_user.ps1 | Invoke-Expression; ./on_user.ps1 -JumpCloudConnectKey $jumpCloudConnectKey"

$autonboardBATContent = @"
runas /noprofile /user:user "powershell.exe -noexit -command $run"
"@

Out-File -FilePath $autonboardBATPath -InputObject $autonboardBATContent -Encoding UTF8

# Reiniciar o computador
Write-Host "Reiniciando o computador..."
# Restart-Computer -Force