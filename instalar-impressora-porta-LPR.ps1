#Requires -RunAsAdministrator

# ===============================
# CONFIGURAÇÕES DA IMPRESSORA
# ===============================

$PrinterName   = "IMP-COMPRAS"
$PrinterIP     = "192.168.3.86"
$DriverName    = "HP LaserJet Pro MFP 4101 4102 4103 4104 PCL 6 (V3)"
$DriverInfNome = "hplo0374_x64.inf"

# Tipo de porta: "TCP" para porta padrão 9100, "LPR" para porta LPR 515
$PortaTipo  = "LPR"
$LPRQueue   = "auto"

# ===============================
# (NÃO EDITAR ABAIXO)
# ===============================

$PortName = $PrinterIP

Write-Host "==============================="
Write-Host "INSTALADOR DE IMPRESSORA"
Write-Host "==============================="
Write-Host ""
Write-Host "Diretorio do script:"
Write-Host $PSScriptRoot
Write-Host ""

# ===============================
# PROCURAR DRIVER .INF
# ===============================

Write-Host "Procurando driver INF ($DriverInfNome)..."

$DriverInf = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter $DriverInfNome -ErrorAction SilentlyContinue | Select-Object -First 1

if (!$DriverInf) {
    Write-Host ""
    Write-Host "ERRO: Arquivo $DriverInfNome nao encontrado na pasta!"
    pause
    exit
}

Write-Host ""
Write-Host "Driver encontrado:"
Write-Host $DriverInf.FullName
Write-Host ""

# ===============================
# INSTALAR DRIVER VIA PNPUTIL
# ===============================

Write-Host "Instalando driver via pnputil..."

$pnpOutput = & pnputil /add-driver "$($DriverInf.FullName)" /install 2>&1
Write-Host ($pnpOutput -join "`n")

# Capturar o nome publicado (ex: oem40.inf)
$oemInf = ($pnpOutput | Select-String "Nome Publicado|Published Name" | Select-Object -First 1) -replace '.*:\s*', '' -replace '\s', ''

Start-Sleep 3

# ===============================
# REGISTRAR DRIVER NA FILA DE IMPRESSAO
# ===============================

Write-Host ""
Write-Host "Registrando driver na fila de impressao..."

# Monta o caminho do .inf publicado no sistema
$infPublicado = if ($oemInf) { "$env:SystemRoot\System32\DriverStore\FileRepository\$($oemInf -replace '\.inf','')_amd64\$DriverInfNome" } else { $null }

# Tenta com o caminho publicado primeiro, depois com o original
$registrado = $false

if ($infPublicado -and (Test-Path $infPublicado)) {
    Write-Host "Usando inf publicado: $infPublicado"
    try {
        Add-PrinterDriver -Name $DriverName -InfPath $infPublicado -ErrorAction Stop
        $registrado = $true
        Write-Host "Driver registrado com sucesso."
    } catch {
        Write-Host "Aviso: $_"
    }
}

if (!$registrado) {
    # Busca direto no DriverStore pelo nome do arquivo
    $infNoStore = Get-ChildItem "$env:SystemRoot\System32\DriverStore\FileRepository" -Recurse -Filter $DriverInfNome -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($infNoStore) {
        Write-Host "Usando inf do DriverStore: $($infNoStore.FullName)"
        try {
            Add-PrinterDriver -Name $DriverName -InfPath $infNoStore.FullName -ErrorAction Stop
            $registrado = $true
            Write-Host "Driver registrado com sucesso."
        } catch {
            Write-Host "Aviso: $_"
        }
    }
}

Start-Sleep 2

# ===============================
# VERIFICAR SE DRIVER FOI REGISTRADO
# ===============================

Write-Host ""
Write-Host "Verificando driver registrado no Windows..."

$DriverInstalado = (Get-PrinterDriver | Where-Object { $_.Name -eq $DriverName } | Select-Object -First 1).Name

if (!$DriverInstalado) {
    Write-Host "ERRO: Driver nao foi registrado no Windows."
    Write-Host ""
    Write-Host "Drivers disponiveis:"
    Get-PrinterDriver | Select-Object -ExpandProperty Name
    pause
    exit
}

Write-Host "Driver OK: $DriverInstalado"
Write-Host ""

# ===============================
# CRIAR PORTA
# ===============================

if ($PortaTipo -eq "LPR") {

    Write-Host "Criando porta LPR (porta 515)..."

    $portScriptPT = "$env:SystemRoot\System32\Printing_Admin_Scripts\pt-BR\prnport.vbs"
    $portScriptEN = "$env:SystemRoot\System32\Printing_Admin_Scripts\en-US\prnport.vbs"

    if (Test-Path $portScriptPT) { $portScript = $portScriptPT }
    else                         { $portScript = $portScriptEN }

    cscript $portScript -a -r $PortName -h $PrinterIP -o lpr -q $LPRQueue

} else {

    Write-Host "Criando porta TCP/IP (porta 9100)..."

    if (!(Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
        Write-Host "Porta criada: $PortName"
    } else {
        Write-Host "Porta ja existe: $PortName"
    }
}

Write-Host ""

# ===============================
# CRIAR IMPRESSORA
# ===============================

Write-Host "Criando impressora..."

if (!(Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue)) {
    Add-Printer `
        -Name       $PrinterName `
        -DriverName $DriverName `
        -PortName   $PortName
} else {
    Write-Host "Impressora ja existe: $PrinterName"
}

Write-Host ""
Write-Host "==============================="
Write-Host "IMPRESSORA INSTALADA COM SUCESSO"
Write-Host "Nome:   $PrinterName"
Write-Host "IP:     $PrinterIP"
Write-Host "Porta:  $PortaTipo"
Write-Host "Driver: $DriverName"
Write-Host "==============================="

pause