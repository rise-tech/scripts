# Variáveis obrigatórias

Param (
    [Parameter (Mandatory = $true)]
    [string] $userName
)

Param (
    [Parameter (Mandatory = $true)]
    [string] $preyToken
)

Param (
    [Parameter (Mandatory = $true)]
    [string] $JumpCloudConnectKey
)

# Declaração de variáveis

$teamviewerURL = "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"
$googleDriveURL = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
$googleChromeURL = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B65DEC826-D254-2DE3-F93A-A6C0BB8157FB%7D%26lang%3Dpt-PT%26browser%3D5%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Dempty/update2/installers/ChromeSetup.exe"
$firefoxURL = "https://cdn.stubdownloader.services.mozilla.com/builds/firefox-stub/pt-PT/win/7a4edbc2923ced0a26263bdd4d8cc55b27e233280a52e1bc10976a9258f282c1/Firefox%20Installer.exe"
$preyURL = "https://prey.io/dl/" + $preyToken
$slackURL = "https://downloads.slack-edge.com/desktop-releases/windows/x64/4.38.115/SlackSetup.exe"
$wingetURL = "https://github.com/rise-tech/scripts/raw/master/source.msix"

$tempPath = 'C:\Windows\Temp\'

# $currentUser = (whoami).Split('\\')[1]

$teamviewerPath = $tempPath + "teamviewer.exe"
$googleChromePath = $tempPath + "chrome.exe"
$googleDrivePath = $tempPath + "drive.exe"
$firefoxPath = $tempPath + "firefox.exe"
$preyPath = $tempPath + "prey.exe"
$slackPath = $tempPath + "slack.exe"
$wingetPath = $tempPath + "winget.msix"


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

# Remover OneDrive
Write-Host "Removendo OneDrive..."
winget uninstall Microsoft. -Wait
Write-Host "Remoção concluída."

# Criar um novo usuário
Write-Host "Criando o usuário..."
$userName = Read-Host "Nome de usuário"
$userPassword = Read-Host "Senha" -AsSecureString

New-LocalUser -Name $userName -Password $userPassword

# Adicionar o novo usuário ao grupo de Usuários
Add-LocalGroupMember -Group Usuários -Member $userName\$userName

# Copiar o perfil do usuário padrão
$sourceProfilePath = "C:\Users\Default"
$targetProfilePath = "C:\Users\$userName"

Copy-Item -Path $sourceProfilePath -Destination $targetProfilePath -Exclude "AppData\Local\Microsoft\Windows\Shell\Roaming", "AppData\Roaming\Microsoft\Windows\StartMenu"

# Atualizar o registro do Windows
$userSID = (Get-WMIObject Win32_UserAccount -Filter "Name='$userName'").SID
$HKLMPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
New-ItemProperty -Path $HKLMPath -Name $userSID -Value $userName -PropertyType String -Force

# Solicitar o token do Prey
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
}

# Instalar softwares
Function InstallSoftwares(){
    # Winget
    Add-AppxPackage -Path $wingetPath

    # TeamViewer
    Start-Process -FilePath $teamviewerPath -ArgumentList "/S /L pt-BR" -PassThru -NoNewWindow

    # Chrome
    Start-Process -FilePath $googleChromePath -PassThru -NoNewWindow -Wait

    # Firefox
    Start-Process -FilePath $firefoxPath -PassThru -NoNewWindow -Wait
}

Write-Host "Baixando softwares..."
DownloadInstallers

Write-Host "Instalando softwares 3/5..."
InstallSoftwares

# Renomear o computador
Write-Host "Renomeando o computador..."
Rename-Computer -NewName $userName.ToUpper()

# Remove OneDrive
winget uninstall Microsoft.OneDrive

# Criar scripts de inicialização automática
Write-Host "Criando scripts de inicialização automática..."

$startupFolder = "C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Startup"

$autonboardPS1Path = "C:\Windows\Temp\autonboard.ps1"
$autonboardBATPath = "$startupFolder\autonboard.bat"

# Criar o script autonboard.ps1
$autonboardPS1Content = $@"
# Baixar e instalar softwares
Write-Host "Baixando e instalando softwares..."

# Slack
Start-Process -FilePath $slackPath -ArgumentList "/INSTALLDIR=\"C:\Program Files (x86)\Slack\" /HIDECONSOLE" -PassThru -NoNewWindow

# Prey
Start-Process -FilePath $preyPath -PassThru -NoNewWindow

# Drive
Write-Host "Necessário logar o usuário no Google Drive após a instalação!"
Write-Host "Esta ação irá alterar o local das pastas do usuário para o disco G:"

Start-Process -FilePath $googleDrivePath -PassThru -NoNewWindow -Wait

$response = Read-Host "O usuário $userName foi logado no Google Drive? [S][N]" -ToUpper

if ($response -eq "S") {
    Write-Host "Alterando local das pastas para o Google Drive"

    # Altera Local das pastas do usuário
    $documentsFolder = "Meus Documentos"
    $downloadsFolder = "Downloads"
    $imagesFolder = "Minhas Imagens"
    $newDocumentsLocation = "G:\$documentsFolder"
    $newDownloadsLocation = "G:\$downloadsFolder"
    $newImagesLocation = "G:\$imagesFolder"
    
    Set-ItemProperty -Path "$env:USERPROFILE\$documentsFolder" -Name TargetPath -Value $newDocumentsLocation
    Set-ItemProperty -Path "$env:USERPROFILE\$downloadsFolder" -Name TargetPath -Value $newDownloadsLocation
    Set-ItemProperty -Path "$env:USERPROFILE\$imagesFolder" -Name TargetPath -Value $newImagesLocation

    Write-Host "Alterações efetuadas com sucesso!"
} else {
    Write-Host "Local das pastas do usuário não foram alteradas"
    Write-Host "Faça o processo manualmente após logar a conta do usuário"
}

# Apagar arquivos temporários
Write-Host "Apagando arquivos temporários..."

# Remove-Item -Path "C:\Windows\Temp" -Recurse -Force
# Remove-Item C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Startup\autonboard.bat
"@

Out-File -FilePath $autonboardPS1Path -InputObject $autonboardPS1Content -Encoding UTF8

# Criar o script autonboard.bat

# Verifique se a pasta Startup já existe
if (!(Test-Path -Path $startupFolder)) {
    # Crie a pasta Startup
    New-Item -Path $startupFolder -ItemType Directory
}

$autonboardBATContent = @"
runas /noprofile /user:user "powershell.exe -noexit -command $autonboardPS1Path"
"@

Out-File -FilePath $autonboardBATPath -InputObject $autonboardBATContent -Encoding UTF8

# Reiniciar o computador
Write-Host "Reiniciando o computador..."
# Restart-Computer -Force

Invoke-Expression; 
Invoke-RestMethod -Method Get -URI https://raw.githubusercontent.com/TheJumpCloud/support/master/scripts/windows/autonboard_2.ps1 -OutFile autonboard_2.ps1
Invoke-Expression; ./autonboard_2.ps1 -JumpCloudConnectKey $JumpCloudConnectKey
