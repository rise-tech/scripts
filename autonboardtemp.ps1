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