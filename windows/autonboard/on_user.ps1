###########################
# Declaração de variáveis #
###########################

# Recebe variáveis obrigatórias

Param (
    [Parameter (Mandatory = $true)]
    [string] $JumpCloudConnectKey
)

# $documentsFolder = $env:USERPROFILE + "\Meus Documentos"
# $downloadsFolder = $env:USERPROFILE + "\Downloads"
# $imagesFolder = $env:USERPROFILE + "\Minhas Imagens"


# Baixar softwares
Function DownloadInstallers() {
    (New-Object System.Net.WebClient).DownloadFile("${googleDriveURL}", "${googleDrivePath}")
    Write-Host "Google Drive baixado."
    (New-Object System.Net.WebClient).DownloadFile("${preyURL}", "${preyPath}")
    Write-Host "Prey baixado."
    (New-Object System.Net.WebClient).DownloadFile("${slackURL}", "${slackPath}")
    Write-Host "Slack baixado."
}

# Instalar softwares
Function InstallSoftwares() {
    # Slack
    Start-Process -FilePath $slackPath -ArgumentList /INSTALLDIR= ${env:ProgramFiles(x86)}"Slack" /HIDECONSOLE -PassThru -NoNewWindow
    Write-Host "Instalação do Slack concluída."

    # Prey
    Start-Process -FilePath $preyPath -PassThru -NoNewWindow
    Write-Host "Instalação do Prey concluída."
}

Function InstallGoogleDrive() {
    Start-Process -FilePath $googleDrivePath -PassThru -NoNewWindow -Wait
}

Function InstallJumpCloud() {
    ### Instalação do JumpCloud ### 
    Write-Host "Deseja instalar o JumpCloud?"
    $response = Read-Host "Lembrando que a máquina deve estar devidamente configurada. [S][N]" 
    if ($response.ToUpper() -eq "S") {

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
            }
            else {
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
    }
    else {
        Write-Host "JumpCloud não foi instalado."
    }
}

######################
# Início da execução #
######################

# Remover OneDrive
Write-Host "Removendo OneDrive..."
winget uninstall Microsoft.OneDrive -Wait
Write-Host "Remoção concluída."

# Download / Instalação dos Softwares
Write-Host "Baixando softwares..."
DownloadInstallers -Wait

Write-Host "Instalando softwares..."
InstallSoftwares
InstallJumpCloud

<#
Write-Host "Continue apenas se:"
Write-Host "O nome da máquina foi alterado para o mesmo nome do usuário;"
Write-Host "O Google Drive estiver logado na conta do usuário."
Write-Host " "
Write-Host "Nome do usuário: $env:USERNAME"
Write-Host "Nome atual da máquina: $env:COMPUTERNAME"
Write-Host " "

$response = Read-Host "Podemos prosseguir? [Sim][Nao]"

if ($response.ToUpper() -eq "SIM") {

    Write-Host "Alterando local das pastas do usuário para o Google Drive"

    # Altera Local das pastas do usuário
    $newDocumentsLocation = "G:\Meu Drive\$documentsFolder"
    $newDownloadsLocation = "G:\Meu Drive\$downloadsFolder"
    $newImagesLocation = "G:\Meu Drive\$imagesFolder"
    
    Set-ItemProperty -Path $documentsFolder -Name TargetPath -Value $newDocumentsLocation
    Set-ItemProperty -Path $downloadsFolder -Name TargetPath -Value $newDownloadsLocation
    Set-ItemProperty -Path $imagesFolder -Name TargetPath -Value $newImagesLocation

    Write-Host "Alterações efetuadas com sucesso!"
}
else {
    Write-Host "Locais das pastas do usuário não foram alteradas"
    Write-Host "Faça o processo manualmente após logar a conta do usuário ao Google Drive"
}

#>

# Apagar arquivos temporários
Write-Host "Apagando arquivos temporários..."

# Remove-Item -Path "C:\Windows\Temp" -Recurse -Force
# Remove-Item C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Startup\autonboard.bat