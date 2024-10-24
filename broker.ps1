# Define URLs e caminhos
$javaVersionRequired = "8.0.3410.10"
$javaDownloadUrl = "https://drive.ux.net.br/api/public/dl/y6LEUGJW/bysoft/jre-8u341-windows-x86.exe"
$iglobalLocalUrl = "https://drive.ux.net.br/api/public/dl/4fGGClL-/bysoft/iglobal_local.zip"
$atalhosDownloadUrl = "https://drive.ux.net.br/api/public/dl/uvLWDDvA/bysoft/Atalhos.zip"
$siteToAdd = "http://iglobal.omegasolutions.com.br"
$userProfilePath = [System.Environment]::GetFolderPath('UserProfile')
$defaultUserProfilePath = "C:\Users\Default"
$tempDir = "$env:TEMP\chromedriver_temp"
$atalhosTempDir = "$env:TEMP\atalhos_temp"
$chromeDriverJsonUrl = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
$logFilePath = "$env:TEMP\script_log.txt"

# Funções para destacar no terminal
function Write-Separator {
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
}

function Write-Highlight {
    param([string]$message)
    Write-Host $message -ForegroundColor Yellow
}

function Write-Info {
    param([string]$message)
    Write-Host $message -ForegroundColor Green
}

function Write-Warning {
    param([string]$message)
    Write-Host $message -ForegroundColor Red
}

function Write-Step {
    param([string]$message)
    Write-Host "=> $message" -ForegroundColor Cyan
}

# Função para registrar mensagens no log
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Limpa ou cria o arquivo de log
Clear-Content $logFilePath -ErrorAction SilentlyContinue
New-Item -ItemType File -Path $logFilePath -Force | Out-Null

# Função para verificar a versão do Java
function Check-JavaVersion {
    try {
        $javaVersionOutput = (Get-Command java -ErrorAction Stop | Select-Object Version).Version
        if ($javaVersionOutput) {
            return $javaVersionOutput
        } else {
            return $null
        }
    } catch {
        return $null
    }
}

# Função para desinstalar Java usando wmic (para versões mais antigas do Windows)
function Uninstall-JavaWmic {
    try {
        Write-Info "Usando wmic para desinstalar Java..."
        Log-Message "Usando wmic para desinstalar Java."
        & wmic product where "name like 'Java%'" call uninstall /nointeractive > $logFilePath 2>&1
        Log-Message "Desinstalação do Java usando wmic concluída."
    } catch {
        Write-Warning "Erro ao tentar usar wmic para desinstalar Java."
        Log-Message "Erro ao usar wmic para desinstalar Java: $_"
    }
}

# Função para desinstalar Java usando Get-Package (para versões mais recentes do Windows)
function Uninstall-JavaPowerShell {
    try {
        $javaPackage = Get-Package -Name "*Java*" -ErrorAction SilentlyContinue
        if ($javaPackage) {
            $packageName = $javaPackage.Name
            Write-Info "Removendo $packageName usando PowerShell..."
            Log-Message "Removendo $packageName usando PowerShell."
            Uninstall-Package -Name $packageName -Force
            Log-Message "Desinstalação de $packageName concluída."
        } else {
            Write-Warning "Nenhuma versão do Java encontrada para desinstalar."
            Log-Message "Nenhuma versão do Java encontrada."
        }
    } catch {
        Write-Warning "Erro ao tentar desinstalar Java usando PowerShell."
        Log-Message "Erro ao desinstalar Java usando PowerShell: $_"
    }
}

# Função para obter a versão do Windows
function Get-WindowsVersion {
    $version = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
    return $version
}

# Parte 1: Verificação e instalação do Java
Write-Step "Verificando e instalando Java, se necessário..."
Log-Message "Iniciando verificação e instalação do Java."

$windowsVersion = Get-WindowsVersion
Write-Info "Versão do Windows detectada: $windowsVersion"
Log-Message "Versão do Windows detectada: $windowsVersion"

$currentJavaVersion = Check-JavaVersion

if ($currentJavaVersion -ne $null) {
    Write-Info "Versão atual do Java: $currentJavaVersion"
} else {
    Write-Info "Java não está instalado."
}

if ($currentJavaVersion -eq $null -or $currentJavaVersion -ne $javaVersionRequired) {
    Write-Info "A versão do Java não é $javaVersionRequired. Removendo a versão atual do Java e instalando a versão necessária..."
    Log-Message "Desinstalando a versão antiga do Java."
    
    # Desinstala Java com base na versão do Windows
    if ($windowsVersion -lt 23) {
        # Para Windows 10 e versões 11 anteriores ao 24H2
        Uninstall-JavaWmic
    } else {
        # Para Windows 11 24H2 e mais recentes
        Uninstall-JavaPowerShell
    }

    Start-Sleep -Seconds 10
    Write-Step "Baixando e instalando Java $javaVersionRequired..."
    Log-Message "Baixando Java versão $javaVersionRequired."
    Invoke-WebRequest -Uri $javaDownloadUrl -OutFile "$env:TEMP\jre-8u341-windows-x86.exe"
    Start-Process -FilePath "$env:TEMP\jre-8u341-windows-x86.exe" -ArgumentList "/s" -Wait
    Log-Message "Instalação do Java concluída."
} else {
    Write-Info "A versão do Java é $javaVersionRequired. Pulando a instalação."
}

# Função para obter o caminho correto da área de trabalho, considerando o OneDrive
function Get-DesktopPath {
    param (
        [string]$profilePath
    )
    
    $oneDrivePath = Join-Path $profilePath "OneDrive"
    $oneDriveDesktopPathEn = Join-Path $oneDrivePath "Desktop"
    $oneDriveDesktopPathPt = Join-Path $oneDrivePath "Área de Trabalho"

    # Verifica se a área de trabalho está sincronizada com o OneDrive (em inglês ou português)
    if (Test-Path $oneDriveDesktopPathEn) {
        return $oneDriveDesktopPathEn
    } elseif (Test-Path $oneDriveDesktopPathPt) {
        return $oneDriveDesktopPathPt
    } else {
        return "$profilePath\Desktop"
    }
}

# Função para aplicar as alterações para um perfil específico
function Apply-Changes {
    param (
        [string]$profilePath,  # Caminho do perfil de usuário
        [string]$exceptionSitesFile,  # Caminho do arquivo de exceções do Java
        [bool]$executeTools  # Define se Tools.exe deve ser executado
    )

    $iglobalLocalPath = "$profilePath\iglobal_local"
    $desktopPath = Get-DesktopPath $profilePath

    # Verifica se a área de trabalho existe e cria se não existir
    if (-not (Test-Path $desktopPath)) {
        Write-Warning "Área de trabalho não encontrada em $profilePath. Criando o diretório..."
        New-Item -ItemType Directory -Path $desktopPath | Out-Null
    }

    # Parte 2: Baixar e extrair iglobal_local.zip
    Write-Step "Baixando e extraindo iglobal_local.zip para $profilePath..."
    Log-Message "Baixando e extraindo iglobal_local.zip para $profilePath."

    if (Test-Path $iglobalLocalPath) {
        Get-Process -Name java, chromedriver -ErrorAction SilentlyContinue | Stop-Process -Force
        Remove-Item -Path $iglobalLocalPath -Recurse -Force
    }
    Invoke-WebRequest -Uri $iglobalLocalUrl -OutFile "$env:TEMP\iglobal_local.zip"
    Expand-Archive -Path "$env:TEMP\iglobal_local.zip" -DestinationPath $profilePath -Force

    # Adiciona site à lista de exceções do Java
    Write-Step "Adicionando site à lista de exceções do Java para $profilePath..."
    Log-Message "Adicionando site $siteToAdd à lista de exceções do Java para $profilePath."

    if (-Not (Test-Path -Path $exceptionSitesFile)) {
        New-Item -ItemType File -Path $exceptionSitesFile -Force
    }
    if (-Not (Get-Content $exceptionSitesFile | Select-String -Pattern $siteToAdd)) {
        Add-Content -Path $exceptionSitesFile -Value $siteToAdd
    }

    # Parte 3: Atualizar o ChromeDriver
    Write-Step "Atualizando o ChromeDriver automaticamente para $profilePath..."
    Log-Message "Iniciando atualização automática do ChromeDriver para $profilePath."
    Update-ChromeDriver -profilePath $profilePath

    # Parte 4: Baixar e extrair Atalhos.zip
    Write-Step "Baixando e extraindo Atalhos.zip para $desktopPath..."
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

# Parte 5: Executa o aplicativo Tools.exe, se existir e se o parâmetro executeTools for true
if ($executeTools) {
    $toolsPath = "$desktopPath\Tools.exe"
    if (Test-Path $toolsPath) {
        # Adicionando Tools.exe como confiável no Windows Defender
        Write-Step "Adicionando Tools.exe como confiável no Windows Defender..."
        Add-MpPreference -ExclusionPath $toolsPath
        Log-Message "Tools.exe adicionado como confiável no Windows Defender."

        # Executando Tools.exe
        Write-Step "Executando Tools.exe para $profilePath..."
        Log-Message "Executando Tools.exe para $profilePath."
        Start-Process -FilePath $toolsPath
    } else {
        Write-Warning "Tools.exe não encontrado em $profilePath."
        Log-Message "Tools.exe não encontrado em $profilePath."
    }
}


    Write-Info "Alterações aplicadas para $profilePath"
    Log-Message "Alterações aplicadas para $profilePath"
}

# Função para atualizar o ChromeDriver
function Update-ChromeDriver {
    param (
        [string]$profilePath
    )

    $iglobalLocalPath = "$profilePath\iglobal_local"

    # Baixar o JSON da versão estável do ChromeDriver
    $chromeDriverData = Invoke-RestMethod -Uri $chromeDriverJsonUrl
    $chromeDriverUrl = $chromeDriverData.channels.stable.downloads.chromedriver | Where-Object { $_.platform -eq 'win32' } | Select-Object -ExpandProperty url

    # Baixa o ChromeDriver em um diretório temporário
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    Invoke-WebRequest -Uri $chromeDriverUrl -OutFile "$tempDir\chromedriver.zip"
    Expand-Archive -Path "$tempDir\chromedriver.zip" -DestinationPath $tempDir -Force

    # Verifica se o chromedriver.exe foi extraído
    $chromeDriverPath = Get-ChildItem -Path $tempDir -Filter "chromedriver.exe" -Recurse | Select-Object -First 1

    if (Test-Path "$iglobalLocalPath\chromedriver.exe") {
        Get-Process chromedriver -ErrorAction SilentlyContinue | Stop-Process -Force
        Remove-Item -Path "$iglobalLocalPath\chromedriver.exe" -Force
    }

    # Copia o novo chromedriver para a pasta iglobal_local
    Copy-Item -Path $chromeDriverPath.FullName -Destination "$iglobalLocalPath\chromedriver.exe" -Force
    Log-Message "ChromeDriver atualizado com sucesso para $profilePath."
}

# Aplicando as alterações para o usuário atual e executando Tools.exe
Apply-Changes -profilePath $userProfilePath -exceptionSitesFile "$userProfilePath\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites" -executeTools $true

# Aplicando as alterações para o Default User sem executar Tools.exe
Apply-Changes -profilePath $defaultUserProfilePath -exceptionSitesFile "$defaultUserProfilePath\AppData\LocalLow\Sun\Java\Deployment\security\exception.sites" -executeTools $false

# Resumo das ações
Write-Separator
Write-Highlight "Script concluído com sucesso!"
Write-Info "Resumo das ações realizadas:"
Write-Info "- Verificação e atualização do Java, se necessário"
Write-Info "- iglobal_local.zip baixado e extraído"
Write-Info "- Site adicionado à lista de exceções do Java"
Write-Info "- ChromeDriver atualizado automaticamente"
Write-Info "- Atalhos extraídos e copiados para a área de trabalho"
Write-Info "- Tools.exe executado, se encontrado (somente para o usuário atual)"
Write-Separator

Log-Message "Execução do script concluída."
