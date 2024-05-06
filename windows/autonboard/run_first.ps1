###########################
# Declaração de variáveis #
###########################

# Variáveis obrigatórias #
Param (
    [Parameter (Mandatory = $true)]
    [string] $UserName,
    [string] $JumpCloudConnectKey,
    [string] $PreyToken
)

$teamviewerURL = "https://github.com/rise-tech/scripts/raw/master/windows/utils/teamviewer.exe"
$googleChromeURL = "https://github.com/rise-tech/scripts/raw/master/windows/utils/chrome.exe"
$firefoxURL = "https://github.com/rise-tech/scripts/raw/master/windows/utils/firefox.exe"
$wingetURL = "https://github.com/rise-tech/scripts/raw/master/windows/utils/source.msix"
$winrarURL = "https://github.com/rise-tech/scripts/raw/master/windows/utils/winrar.exe"
$googleDriveURL = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe" # Mantido link direto, devido arquivo ultrapassar 100MB
$preyURL = "https://prey.io/dl/" + $PreyToken # Mantido link direto para que receba o token e gere o instalador
$slackURL = "https://downloads.slack-edge.com/desktop-releases/windows/x64/4.38.115/SlackSetup.exe" # Mantido link direto, devido arquivo ultrapassar 100MB

# Padronizar variáveis
$userName = $UserName.ToLower()
$jumpCloudConnectKey = $JumpCloudConnectKey

# Locais onde os downloads serão armazenados + nome do arquivo
$teamviewerPath = $env:TEMP + "\teamviewer.exe"
$googleChromePath = $env:TEMP + "\chrome.exe"
$firefoxPath = $env:TEMP + "\firefox.exe"
$wingetPath = $env:TEMP + "\winget.msix"
$winrarPath = $env:TEMP + "\winrar.exe"
$googleDrivePath = $env:TEMP + "\drive.exe"
$preyPath = $env:TEMP + "\prey.exe"
$slackPath = $env:TEMP + "\slack.exe"

# Local da pasta padrão de usuário e do novo usuário
# $sourceProfilePath = "C:\Users\Default"
# $targetProfilePath = "C:\Users\$userName"

# Local para salvar o arquivo necessário para rodar logado no usuário
$autonboardBATPath = "C:\autonboard.bat"

######################
# Início da execução #
######################

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
# $userName = Read-Host "Nome de usuário"
$userPassword = Read-Host "Digite a senha do usuário" -AsSecureString

New-LocalUser -Name $userName -Password $userPassword

# Adicionar o novo usuário ao grupo de Usuários
Add-LocalGroupMember -Group Usuários -Member $userName

# # Copiar o perfil do usuário padrão
# New-Item -Path $targetProfilePath -ItemType Directory
# Copy-Item -Path $sourceProfilePath -Destination $targetProfilePath -Exclude "AppData\Local\Microsoft\Windows\Shell\Roaming", "AppData\Roaming\Microsoft\Windows\StartMenu"

# # Atualizar o registro do Windows
# $userSID = (Get-WMIObject Win32_UserAccount -Filter "Name='$userName'").SID
# $HKLMPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
# New-ItemProperty -Path $HKLMPath -Name $userSID -Value $userName -PropertyType String -Force

# # Solicita o token do Prey
# Write-Host "Digite/Cole o token do Prey:"
# $preyToken = Read-Host
# $preyURL = $preyURL + $preyToken

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
    Write-Host "Todos os Softwares foram baixados"
}

# Instalar softwares
Function InstallSoftwares(){
    # Winget
    Add-AppxPackage -Path $wingetPath
    Write-Host "Winget instalado."

    # TeamViewer
    Start-Process -FilePath $teamviewerPath -ArgumentList "/S /L pt-BR" -PassThru -NoNewWindow
    Write-Host "TeamViewer instalado."

    # Chrome
    Start-Process -FilePath $googleChromePath -PassThru -NoNewWindow -ArgumentList "/S" -Wait
    Write-Host "Chrome instalado."

    # Firefox
    Start-Process -FilePath $firefoxPath -PassThru -NoNewWindow -ArgumentList "/S" -Wait
    Write-Host "Firefox instalado."

    # Winrar
    Start-Process -FilePath $winrarPath -PassThru -NoNewWindow -ArgumentList "/S" -Wait
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
$run = "cd $env:temp | Invoke-Expression; Invoke-RestMethod -Method Get -URI https://github.com/rise-tech/scripts/raw/master/windows/on_user.ps1 -OutFile OnUser.ps1 | Invoke-Expression; ./OnUser.ps1 -JumpCloudConnectKey $jumpCloudConnectKey"

$autonboardBATContent = @"
runas /noprofile /user:user "powershell.exe -noexit -command $run"
"@

Out-File -FilePath $autonboardBATPath -InputObject $autonboardBATContent -Encoding UTF8

# Reiniciar o computador
Write-Host "Reiniciando o computador..."
# Restart-Computer -Force