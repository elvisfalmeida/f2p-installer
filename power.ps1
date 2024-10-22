# URL do arquivo de plano de energia hospedado
$urlPlano = "https://drive.ux.net.br/api/public/dl/djrCYkyh/omega/power_js.pow"
# Caminho onde o arquivo será salvo localmente
$caminhoPlano = "C:\power_js.pow"

# Baixar o arquivo de plano de energia
Invoke-WebRequest -Uri $urlPlano -OutFile $caminhoPlano

# Verifica se o arquivo do plano de energia foi baixado
if (Test-Path $caminhoPlano) {
    # Importa o plano de energia
    powercfg -import $caminhoPlano

    # Define o plano de energia importado como o plano ativo
    $novoPlanoGUID = (powercfg -list | Select-String -Pattern "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c").Line.Split()[3]
    powercfg -setactive $novoPlanoGUID

    Write-Host "Plano de energia aplicado com sucesso!"
} else {
    Write-Host "Falha ao baixar o arquivo do plano de energia!"
}
