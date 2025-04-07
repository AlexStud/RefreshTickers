<#
.SYNOPSIS
    Выполняет запросы к API биржи MEXC для получения текущих цен криптовалютных инструментов.

.DESCRIPTION
    Эта функция отправляет запросы к API биржи MEXC для получения текущей цены криптовалютных инструментов на основе указанного тикера и типа рынка (spot или futures).
    Функция поддерживает настройку прокси-сервера, а также подробное логирование каждого шага выполнения через Write-Verbose.
    Все ошибки обрабатываются с выводом подробной информации об исключениях.

.PARAMETER Ticker
    Тикер торговой пары, например: BTCUSDT, ETHUSDT.

.PARAMETER MarketType
    Тип рынка, который нужно запросить:
    - "spot" — для обычной спотовой торговли.
    - "futures" — для фьючерсных контрактов.

.PARAMETER Proxy
    Адрес прокси-сервера, если он используется (формат: http://proxy-server:port).

.PARAMETER ProxyCredential
    Учетные данные для аутентификации на прокси-сервере.

.EXAMPLE
    Invoke-MexcRequest -Ticker "BTCUSDT" -MarketType "spot"
    Выполнит запрос для получения спотовой цены пары BTC/USDT.

.EXAMPLE
    Invoke-MexcRequest -Ticker "ETHUSDT" -MarketType "futures" -Verbose
    Получит цену для фьючерсной пары ETH/USDT с подробным логированием.

.NOTES
    Версия: 2.3.0
    Дата обновления: 2023-10-20
    Требует: PowerShell 7.0+
#>

function Invoke-MexcRequest {
    [CmdletBinding(SupportsShouldProcess = $true)]
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
        # Инициализация: выводим в лог, что процесс начинается
        Write-Verbose "[$(Get-Date)] Инициализация запроса для тикера '$Ticker' на рынке '$MarketType'."
    }

    process {
        try {
            # 1. Проверка разрешения на выполнение операции
            if (-not $PSCmdlet.ShouldProcess("MEXC API", "Запрос для $Ticker")) {
                Write-Verbose "Операция для тикера $Ticker отменена пользователем."
                return @{ Status = "Cancelled"; Message = "Операция отменена пользователем" }
            }

            # 2. Формирование URL для API в зависимости от типа рынка
            $url = switch ($MarketType) {
                "spot"    { "https://api.mexc.com/api/v3/ticker/price?symbol=$Ticker" }
                "futures" { "https://contract.mexc.com/api/v1/contract/ticker?symbol=$Ticker" }
            }
            Write-Verbose "Сформирован URL для запроса: $url"
            
            # 3. Настройка прокси (если задано)
            $proxyParams = if ($Proxy) {
                Write-Verbose "Использование прокси-сервера: $Proxy"
                @{ Proxy = $Proxy; ProxyCredential = $ProxyCredential }
            } else { 
                Write-Verbose "Прокси не используется."
                @{} 
            }

            # 4. Выполнение запроса к API с помощью Invoke-RestMethod
            Write-Verbose "Отправка запроса к API..."
            $response = Invoke-RestMethod -Uri $url @proxyParams -ErrorAction Stop

            # 5. Обработка ошибки, если в поле msg есть сообщение о недопустимых символах
            if ($response.msg -match "Illegal characters found in parameter 'symbol'") {
                Write-Error "Тикер '$Ticker' не найден (недопустимые символы в параметре)."
                return @{ Status = "Error"; Message = "Тикер '$Ticker' не найден" }
            }

            # 6. Обработка ответа в зависимости от типа рынка
            $price = if ($MarketType -eq "spot") { 
                $response.price 
            } else { 
                $response.data.lastPrice 
            }

            # 7. Проверка наличия цены в ответе
            if (-not $price) {
                throw "Цена для '$Ticker' не найдена в ответе API."
            }

            # 8. Парсинг строки с ценой в число с плавающей точкой
            $parsedPrice = [double]::Parse(
                $price,
                [Globalization.CultureInfo]::InvariantCulture
            )

            Write-Verbose "Успешно получена цена для тикера '$Ticker': $parsedPrice"
            return @{ Status = "Success"; Price = $parsedPrice }
        }
        catch {
            # 9. Логирование ошибок
            Write-Error "Произошла ошибка при обработке запроса для тикера '$Ticker': $_"
            return @{ 
                Status = "Error"
                Message = $_.Exception.Message
                Ticker = $Ticker
                Timestamp = (Get-Date).ToString("o")
            }
        }
        finally {
            # 10. Финализация: выводим в лог завершение работы функции
            Write-Verbose "[$(Get-Date)] Завершение обработки запроса для тикера '$Ticker'."
        }
    }

    end {
        # Этот блок может быть использован для финализации работы, если необходимо (например, закрытие соединений)
        Write-Verbose "Запрос завершен."
    }
}
