# Recebe variáveis obrigatórias

Param (
    [Parameter (Mandatory = $true)]
    [string] $userName
)

Param (
    [Parameter (Mandatory = $true)]
    [string] $slackPath
)

Param (
    [Parameter (Mandatory = $true)]
    [string] $preyPath
)

Param (
    [Parameter (Mandatory = $true)]
    [string] $googleDrivePath
)

Param (
    [Parameter (Mandatory = $true)]
    [string] $JumpCloudConnectKey
)

# Baixar e instalar softwares
Write-Host "Instalando softwares 5/5..."

# Slack
Start-Process -FilePath $slackPath -ArgumentList "/INSTALLDIR=\"C:\Program Files (x86)\Slack\" /HIDECONSOLE" -PassThru -NoNewWindow

# Prey
Start-Process -FilePath $preyPath -PassThru -NoNewWindow

# Drive
Write-Host "### Iniciando instalação do Google Drive ###"
Write-Host "### Necessário logar o usuário no Google Drive após a instalação! ###"
Write-Host "### Esta ação irá alterar o local das pastas do usuário para o disco G: ###"

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
    Write-Host "Locais das pastas do usuário não foram alteradas"
    Write-Host "Faça o processo manualmente após logar a conta do usuário ao Google Drive"
}

### Instalação do JumpCloud ### 
Write-Host "Deseja instalar o JumpCloud?"
$response = Read-Host "Lembrando que a máquina deve estar devidamente configurada. [S][N]" 
if ($response -eq "S") {

#--- Modify Below This Line At Your Own Risk ------------------------------

# JumpCloud Agent Installation Variables
$AGENT_PATH = Join-Path ${env:ProgramFiles} "JumpCloud"
$AGENT_BINARY_NAME = "jumpcloud-agent.exe"
$AGENT_INSTALLER_URL = "https://cdn02.jumpcloud.com/production/jcagent-msi-signed.msi"
$AGENT_INSTALLER_PATH = "C:\windows\Temp\jcagent-msi-signed.msi"
# JumpCloud Agent Installation Functions
Function InstallAgent() {
    msiexec /i $AGENT_INSTALLER_PATH /quiet JCINSTALLERARGUMENTS=`"-k $JumpCloudConnectKey /VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /L*V "C:\Windows\Temp\jcUpdate.log"`"
}
Function DownloadAgentInstaller() {
    (New-Object System.Net.WebClient).DownloadFile("${AGENT_INSTALLER_URL}", "${AGENT_INSTALLER_PATH}")
}
Function DownloadAndInstallAgent() {
    If (Test-Path -Path "$($AGENT_PATH)\$($AGENT_BINARY_NAME)") {
        Write-Output 'JumpCloud Agent Already Installed'
    } else {
        Write-Output 'Downloading JCAgent Installer'
        # Download Installer
        DownloadAgentInstaller
        Write-Output 'JumpCloud Agent Download Complete'
        Write-Output 'Running JCAgent Installer'
        # Run Installer
        InstallAgent

        # Check if agent is running as a service
        # Do a loop for 5 minutes to check if the agent is running as a service
        # The agent pulls cef files during install which may take longer then previously.
        for ($i = 0; $i -lt 300; $i++) {
            Start-Sleep -Seconds 1
            #Output the errors encountered
            $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
            if ($AgentService.Status -eq 'Running') {
                Write-Output 'JumpCloud Agent Succesfully Installed'
                exit
            }
        }
        Write-Output 'JumpCloud Agent Failed to Install'
    }
}

#Flush DNS Cache Before Install

ipconfig /FlushDNS

# JumpCloud Agent Installation Logic

DownloadAndInstallAgent
} else {
    Write-Host "JumpCloud não foi instalado."
}
# Apagar arquivos temporários
Write-Host "Apagando arquivos temporários..."

# Remove-Item -Path "C:\Windows\Temp" -Recurse -Force
# Remove-Item C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Startup\autonboard.bat