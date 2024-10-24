# Define URLs e caminhos
$javaVersionRequired = "8.0.3410.10"
$javaDownloadUrl = "https://drive.ux.net.br/api/public/dl/y6LEUGJW/bysoft/jre-8u341-windows-x86.exe"
$iglobalLocalUrl = "https://drive.ux.net.br/api/public/dl/4fGGClL-/bysoft/iglobal_local.zip"
$atalhosDownloadUrl = "https://drive.ux.net.br/api/public/dl/uvLWDDvA/bysoft/Atalhos.zip"
$siteToAdd = "http://iglobal.omegasolutions.com.br"
$userProfilePath = [System.Environment]::GetFolderPath('UserProfile')
$defaultUserProfilePath = "C:\Users\Default"
$exceptionSitesFileUser = "$userProfilePath\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"
$exceptionSitesFileDefault = "$defaultUserProfilePath\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites"
$tempDir = "$env:TEMP\chromedriver_temp"
$atalhosTempDir = "$env:TEMP\atalhos_temp"
$chromeDriverJsonUrl = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
$logFilePath = "$env:TEMP\script_log.txt"

# Função para registrar mensagens no log
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Função para aplicar alterações ao perfil
function Apply-Changes {
    param (
        [string]$profilePath,  # Caminho do perfil de usuário
        [string]$exceptionSitesFile  # Caminho do arquivo de exceções Java
    )

    $iglobalLocalPath = "$profilePath\iglobal_local"
    $desktopPath = Get-DesktopPath $profilePath

    # Baixa e extrai iglobal_local.zip
    Write-Host "Baixando e extraindo iglobal_local.zip para $profilePath..."
    Log-Message "Baixando e extraindo iglobal_local.zip para $profilePath."

    if (Test-Path $iglobalLocalPath) {
        Get-Process -Name java, chromedriver -ErrorAction SilentlyContinue | Stop-Process -Force
        Remove-Item -Path $iglobalLocalPath -Recurse -Force
    }
    Invoke-WebRequest -Uri $iglobalLocalUrl -OutFile "$env:TEMP\iglobal_local.zip"
    Expand-Archive -Path "$env:TEMP\iglobal_local.zip" -DestinationPath $profilePath -Force

    # Adiciona site à lista de exceções do Java
    Write-Host "Adicionando site à lista de exceções do Java para $profilePath..."
    Log-Message "Adicionando site $siteToAdd à lista de exceções do Java para $profilePath."

    if (-Not (Test-Path -Path $exceptionSitesFile)) {
        New-Item -ItemType File -Path $exceptionSitesFile -Force
    }
    if (-Not (Get-Content $exceptionSitesFile | Select-String -Pattern $siteToAdd)) {
        Add-Content -Path $exceptionSitesFile -Value $siteToAdd
    }

    # Baixa e extrai Atalhos.zip
    Write-Host "Baixando e extraindo Atalhos.zip para $desktopPath..."
    Log-Message "Baixando e extraindo Atalhos.zip para $desktopPath."

    if (Test-Path $atalhosTempDir) {
        Remove-Item -Path $atalhosTempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $atalhosTempDir | Out-Null
    Invoke-WebRequest -Uri $atalhosDownloadUrl -OutFile "$atalhosTempDir\Atalhos.zip"
    Expand-Archive -Path "$atalhosTempDir\Atalhos.zip" -DestinationPath $atalhosTempDir -Force

    # Copia os arquivos .exe extraídos para a área de trabalho
    $exeFiles = Get-ChildItem -Path $atalhosTempDir -Filter "*.exe" -Recurse
    foreach ($file in $exeFiles) {
        Copy-Item -Path $file.FullName -Destination "$desktopPath\$($file.Name)" -Force
    }

    Write-Host "Alterações aplicadas para $profilePath"
    Log-Message "Alterações aplicadas para $profilePath"
}

# Função para obter o caminho correto da área de trabalho
function Get-DesktopPath {
    param (
        [string]$profilePath
    )
    $oneDrivePath = Join-Path $profilePath "OneDrive"
    $oneDriveDesktopPath = Join-Path $oneDrivePath "Desktop"

    if (Test-Path $oneDriveDesktopPath) {
        return $oneDriveDesktopPath
    } else {
        return "$profilePath\Desktop"
    }
}

# Aplica alterações ao usuário atual
Apply-Changes -profilePath $userProfilePath -exceptionSitesFile $exceptionSitesFileUser

# Aplica alterações ao usuário padrão (Default User)
Apply-Changes -profilePath $defaultUserProfilePath -exceptionSitesFile $exceptionSitesFileDefault

Write-Host "Execução do script concluída."
Log-Message "Execução do script concluída."
