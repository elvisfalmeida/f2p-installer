# Define URLs e caminhos
$iglobalLocalPath = "$env:USERPROFILE\iglobal_local"
$tempDir = "$env:TEMP\chromedriver_temp"
$chromeDriverJsonUrl = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
$logFilePath = "$env:TEMP\chromedriver_update_log.txt"

# Configura a politica de execucao
Set-ExecutionPolicy Unrestricted -Force

# Limpa ou cria o arquivo de log
Clear-Content $logFilePath -ErrorAction SilentlyContinue
New-Item -ItemType File -Path $logFilePath -Force | Out-Null

# Função para registrar mensagens no log
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Baixar e atualizar o ChromeDriver
Write-Host "Iniciando o processo de atualizacao do ChromeDriver..."
Log-Message "Iniciando atualizacao do ChromeDriver."

# Baixar o JSON da versão estável do ChromeDriver
$chromeDriverData = Invoke-RestMethod -Uri $chromeDriverJsonUrl
$chromeDriverUrl = $chromeDriverData.channels.stable.downloads.chromedriver | Where-Object { $_.platform -eq 'win32' } | Select-Object -ExpandProperty url

# Baixar o ChromeDriver em um diretório temporário
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null
Invoke-WebRequest -Uri $chromeDriverUrl -OutFile "$tempDir\chromedriver.zip"
Expand-Archive -Path "$tempDir\chromedriver.zip" -DestinationPath $tempDir -Force

# Verifica se o chromedriver.exe foi extraído
$chromeDriverPath = Get-ChildItem -Path $tempDir -Filter "chromedriver.exe" -Recurse | Select-Object -First 1

if (-Not $chromeDriverPath) {
    Write-Host "Falha ao baixar o ChromeDriver."
    Log-Message "Erro: Falha ao baixar o ChromeDriver."
    Exit 1
}

# Checa se o ChromeDriver está em uso e o encerra
if (Test-Path "$iglobalLocalPath\chromedriver.exe") {
    Get-Process chromedriver -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 5
    Remove-Item -Path "$iglobalLocalPath\chromedriver.exe" -Force
    Log-Message "Processos do ChromeDriver finalizados e arquivo removido."
}

# Copia o novo chromedriver para a pasta iglobal_local
Copy-Item -Path $chromeDriverPath.FullName -Destination "$iglobalLocalPath\chromedriver.exe" -Force
Log-Message "ChromeDriver atualizado com sucesso para a versao mais recente."

Write-Host "Atualizacaodo ChromeDriver concluida."
Log-Message "Atualizacaodo ChromeDriver concluida."
