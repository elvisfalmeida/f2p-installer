# URL do arquivo de plano de energia hospedado
$urlPlano = "https://drive.ux.net.br/api/public/dl/djrCYkyh/omega/power_js.pow"
# Caminho onde o arquivo será salvo localmente
$caminhoPlano = "C:\power_js.pow"

# Nome desejado para o novo plano de energia
$planoNome = "Power JS"

# Baixar o arquivo de plano de energia
Invoke-WebRequest -Uri $urlPlano -OutFile $caminhoPlano

# Verifica se o arquivo de plano de energia foi baixado com sucesso
if (Test-Path $caminhoPlano) {
    # Importar o plano de energia e capturar o GUID do plano importado
    Try {
        $output = powercfg -import $caminhoPlano
        Write-Host "Plano de energia importado com sucesso!"

        # Capturar o GUID do plano importado a partir do resultado
        $novoPlanoGUID = $output -match 'GUID: ([\w-]+)' | Out-Null
        $novoPlanoGUID = $Matches[1]

        # Verificar se o GUID foi extraído corretamente
        If ($novoPlanoGUID) {
            # Renomear o plano de energia para "Power JS"
            powercfg -changename $novoPlanoGUID $planoNome
            Write-Host "Plano de energia renomeado para: $planoNome"

            # Aplicar o novo plano de energia
            powercfg -setactive $novoPlanoGUID
            Write-Host "Plano de energia aplicado com sucesso! GUID: $novoPlanoGUID"
        } Else {
            Write-Host "Erro ao extrair o GUID do plano de energia." -ForegroundColor Red
        }
    } Catch {
        Write-Host "Erro ao importar o plano de energia: $_" -ForegroundColor Red
    }
} Else {
    Write-Host "Falha ao baixar o arquivo do plano de energia!" -ForegroundColor Red
}
