<#
.SYNOPSIS
    Выполняет запросы к API Binance для получения текущих цен криптовалютных пар.

.DESCRIPTION
    Эта функция выполняет запросы к API Binance для получения текущей цены криптовалютной пары (например: BTCUSDT или ETHUSDT) на основе указанного типа рынка (spot или futures).
    Поддерживает прокси-серверы и подробное логирование для отслеживания ошибок и успешных операций.

.PARAMETER Ticker
    Тикер торговой пары (например: BTCUSDT, ETHUSDT).

.PARAMETER MarketType
    Тип рынка, который необходимо запросить:
    - spot (спот) для обычных торгов.
    - futures (фьючерсы) для торговли фьючерсами.

.PARAMETER Proxy
    Адрес прокси-сервера, если требуется для выполнения запроса (формат: http://proxy:port).

.PARAMETER ProxyCredential
    Учетные данные для аутентификации на прокси.

.EXAMPLE
    Invoke-BinanceRequest -Ticker "BTCUSDT" -MarketType "spot"
    Запросить спотовую цену для BTCUSDT.

.EXAMPLE
    Invoke-BinanceRequest -Ticker "ETHUSDT" -MarketType "futures"
    Запросить цену для ETHUSDT на рынке фьючерсов.

.NOTES
    Версия: 2.4.0
    Дата обновления: 2023-10-25
    Требует: PowerShell 7.0+
#>

function Invoke-BinanceRequest {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Ticker,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("spot", "futures")]
        [string]$MarketType,

        [string]$Proxy,
        [pscredential]$ProxyCredential
    )

    begin {
        Write-Verbose "[$(Get-Date)] Начало запроса для $Ticker"
    }

    process {
        try {
            # 1. Подтверждение операции перед выполнением запроса
            if (-not $PSCmdlet.ShouldProcess("Binance API", "Запрос для $Ticker")) {
                return @{ Status = "Cancelled"; Message = "Операция отменена" }
            }

            # 2. Формирование URL для запроса в зависимости от типа рынка (spot или futures)
            $url = switch ($MarketType) {
                "spot"    { "https://api.binance.com/api/v3/ticker/price?symbol=$Ticker" }
                "futures" { "https://fapi.binance.com/fapi/v1/ticker/price?symbol=$Ticker" }
            }
            Write-Verbose "Сформирован URL: $url"

            # 3. Настройка прокси (если требуется)
            $proxyParams = if ($Proxy) {
                Write-Verbose "Использование прокси: $Proxy"
                @{ Proxy = $Proxy; ProxyCredential = $ProxyCredential }
            } else { @{} }

            # 4. Выполнение запроса
            $response = Invoke-RestMethod -Uri $url @proxyParams -ErrorAction Stop

            # 5. Проверка ответа на наличие ошибки "Invalid symbol"
            if ($response.msg -match "Invalid symbol") {
                Write-Error "Символ $Ticker не найден."
                return @{ Status = "Error"; Message = "Тикер не найден" }
            }

            # 6. Проверка наличия цены в ответе
            if (-not $response.price) {
                Write-Error "Цена для $Ticker не найдена."
                return @{ Status = "Error"; Message = "Тикер не найден" }
            }

            # 7. Парсинг цены из ответа
            $price = [double]::Parse(
                $response.price,
                [System.Globalization.CultureInfo]::InvariantCulture
            )

            Write-Verbose "Успешно получена цена: $price"
            return @{ Status = "Success"; Price = $price }
        }
        catch {
            Write-Error "Критическая ошибка: $_"
            return @{ 
                Status = "Error"
                Message = "Тикер не найден"
                Ticker = $Ticker
                Timestamp = (Get-Date).ToString("o")
            }
        }
        finally {
            Write-Verbose "[$(Get-Date)] Завершение запроса для $Ticker"
        }
    }
}
