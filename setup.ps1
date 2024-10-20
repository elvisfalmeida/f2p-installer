# URL do executável gerado pelo PyInstaller
$exeUrl = "https://setup.f2p.io/Instalador_de_Programas.exe"

# Caminho onde o executável será salvo temporariamente
$tempPath = "$env:TEMP\Instalador_de_Programas.exe"

# Baixar o executável
Invoke-WebRequest -Uri $exeUrl -OutFile $tempPath

# Executar o instalador
Start-Process -FilePath $tempPath -NoNewWindow
