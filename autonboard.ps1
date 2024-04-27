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
$userName = Read-Host "Nome de usuário:"
$userPassword = Read-Host "Senha:" -AsSecureString

New-LocalUser -Name $userName -Password $userPassword

# Solicitar a API do Prey
Write-Host "Digite/Cole a API do Prey:"
$preyAPI = Read-Host

# Baixar e instalar softwares
Write-Host "Baixando e instalando softwares..."

# TeamViewer
Start-Process -FilePath "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe" -ArgumentList "/S /L pt-BR" -PassThru -NoNewWindow

# Chrome
Start-Process -FilePath "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B65DEC826-D254-2DE3-F93A-A6C0BB8157FB%7D%26lang%3Dpt-PT%26browser%3D5%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Dempty/update2/installers/ChromeSetup.exe" -ArgumentList "/S /Consent" -PassThru -NoNewWindow

# Firefox
Start-Process -FilePath "https://cdn.stubdownloader.services.mozilla.com/builds/firefox-stub/pt-PT/win/7a4edbc2923ced0a26263bdd4d8cc55b27e233280a52e1bc10976a9258f282c1/Firefox%20Installer.exe" -ArgumentList "/S /AH /InstallNow" -PassThru -NoNewWindow

# Renomear o computador
Write-Host "Renomeando o computador..."
Rename-Computer -NewName $userName.ToUpper()

# Criar scripts de inicialização automática
Write-Host "Criando scripts de inicialização automática..."

$startupFolder = "C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Startup"

$autonboardPS1Path = "C:\Windows\Temp\autonboard.ps1"
$autonboardBATPath = "$startupFolder\autonboard.bat"

# Criar o script autonboard.ps1
$autonboardPS1Content = @"
# Baixar e instalar softwares
Write-Host "Baixando e instalando softwares..."

# Slack
Start-Process -FilePath "https://downloads.slack-edge.com/desktop-releases/windows/x64/4.38.115/SlackSetup.exe" -ArgumentList "/INSTALLDIR=\"C:\Program Files (x86)\Slack\" /HIDECONSOLE" -PassThru -NoNewWindow

# Prey
Start-Process -FilePath "https://prey.io/dl/$preyAPI" -PassThru -NoNewWindow

# Apagar arquivos temporários
Write-Host "Apagando arquivos temporários..."

# Remove-Item -Path "C:\Windows\Temp" -Recurse -Force
# Remove-Item C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Startup\autonboard.bat
"@

Write-File -Path $autonboardPS1Path -Content $autonboardPS1Content -Encoding UTF8

# Criar o script autonboard.bat
$autonboardBATContent = @"
runas /noprofile /user:$userName "powershell.exe -noexit -command $autonboardPS1Path"
"@

Write-File -Path $autonboardBATPath -Content $autonboardBATContent -Encoding UTF8

# Reiniciar o computador
Write-Host "Reiniciando o computador..."
Restart-Computer -Force
