# Instalador de Impressora

Script PowerShell para instalação automática de impressoras de rede (HP, Xerox e outros), a partir de driver local `.inf`.

Útil para ambientes aonde não é possível fazer a instalação de driver automatizada via GPO ou não possui Servidor de Impressão.



---

## Estrutura de pastas

```
📁 IMP-SETOR - MARCA MODELO\
   ├── instalar-impressora.bat      ← executar este
   ├── instalar-impressora.ps1      ← script principal
   └── 📁 driver\
          ├── hpcu355u.inf          ← arquivo .inf do driver
          └── (demais arquivos do driver)
```

---

## Como usar

1. Copie a pasta do driver para dentro da pasta da impressora
2. Edite as 5 variáveis no topo do `instalar-impressora.ps1`
3. Execute o `instalar-impressora.bat` como Administrador

---

## Variáveis de configuração

| Variável | Descrição | Exemplo |
|---|---|---|
| `$PrinterName` | Nome que aparecerá no Painel de Controle | `"IMP-CONTABILIDADE"` |
| `$PrinterIP` | Endereço IP da impressora na rede | `"xxx.xxx.x.xxx"` |
| `$DriverName` | Nome exato do driver conforme o `.inf` | `"HP Universal Printing PCL 6"` |
| `$DriverInfNome` | Nome do arquivo `.inf` do driver de impressão | `"hpcu355u.inf"` |
| `$PortaTipo` | Tipo de porta: `"LPR"` ou `"TCP"` | `"LPR"` |

> **Dica:** Para descobrir o `$DriverName` correto, abra o arquivo `.inf` em um editor de texto e procure pela seção `[Model.NTamd64]`. Os nomes entre aspas são os drivers disponíveis.

---

## Tipo de porta

| Valor | Protocolo | Porta | Indicado para |
|---|---|---|---|
| `"LPR"` | LPR/LPD | 515 | HP |
| `"TCP"` | RAW / TCP/IP | 9100 | Xerox |

---



## O que o script faz

1. Localiza o arquivo `.inf` na pasta pelo nome definido em `$DriverInfNome`
2. Instala o driver no repositório do Windows via `pnputil`
3. Registra o driver na fila de impressão buscando o `.inf` publicado no `DriverStore`
4. Verifica se o driver foi registrado corretamente
5. Cria a porta (LPR 515 ou TCP 9100) se ainda não existir
6. Adiciona a impressora no Windows com o nome definido em `$PrinterName`

---

## Requisitos

- Windows 10 / 11 ou Windows Server 2016+
- PowerShell 5.1 ou superior
- Executar como **Administrador**
- Driver (pasta com `.inf` e arquivos auxiliares) presente na pasta do script