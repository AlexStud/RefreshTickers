<#
.SYNOPSIS
Выполняет запросы к API Bybit для получения рыночных данных.

.DESCRIPTION
Функция выполняет запросы к API Bybit для получения актуальных котировок для:
- Спотового рынка (spot)
- Линейных фьючерсов (linear)
- Инверсных фьючерсов (inverse)

Особенности:
- Поддержка прокси-серверов с аутентификацией.
- Логирование всех действий с уровнем Verbose.
- Проверка структуры ответа API.
- Подтверждение действий перед выполнением.

.PARAMETER Ticker
Тикер торговой пары, например: BTCUSDT, ETHUSD.

.PARAMETER MarketType
Тип рынка:
- spot    (спотовый рынок)
- linear  (линейные фьючерсы)
- inverse (инверсные фьючерсы).

.PARAMETER Proxy
Адрес прокси-сервера (например: http://proxy:port).

.PARAMETER ProxyCredential
Учетные данные для прокси-сервера (логин/пароль).

.EXAMPLE
Invoke-BybitRequest -Ticker "BTCUSDT" -MarketType "spot"
Запрос для получения котировки для BTC/USDT на спотовом рынке.

.EXAMPLE
Invoke-BybitRequest -Ticker "ETHUSD" -MarketType "inverse" -Verbose
Запрос для получения котировки для ETH/USDT на инверсных фьючерсах с подробным логированием.

.NOTES
Версия: 2.4.1
Дата обновления: 2023-11-05
Требует: PowerShell 7.0+, модуль ScheduledTasks
#>

function Invoke-BybitRequest {
    [CmdletBinding(SupportsShouldProcess = $true, 
                   ConfirmImpact = 'Medium',
                   DefaultParameterSetName = 'Default')]

    [System.ComponentModel.Description("v2.4.1 | Bybit API V5 Integration")]
    param(
        # Тикер торговой пары
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Ticker,

        # Тип рынка
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("spot", "linear", "inverse")]
        [string]$MarketType,

        # Параметры прокси
        [string]$Proxy,
        [pscredential]$ProxyCredential
    )

    begin {
        # Инициализация: выполняется один раз при начале работы функции
        # Логирование начала выполнения функции и параметры, переданные в запрос
        Write-Verbose "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Инициализация запроса для тикера $Ticker на рынке $MarketType."

        # Проверяем, был ли задан прокси-сервер
        if (-not [string]::IsNullOrEmpty($Proxy)) {
            Write-Verbose "Использование прокси: $Proxy"
        } else {
            Write-Verbose "Прокси не используется."
        }
    }

    process {
        try {
            # Проверка на согласие пользователя с выполнением операции
            # Эта проверка используется для предотвращения непреднамеренных действий
            if (-not $PSCmdlet.ShouldProcess("Bybit $MarketType API", "Запрос котировок для $Ticker")) {
                Write-Warning "Операция отменена пользователем"
                return @{ Status = "Cancelled"; Message = "Запрос отменен пользователем." }
            }

            # Формируем URL для запроса к API
            # URL строится динамически в зависимости от типа рынка и тикера
            $url = "https://api.bybit.com/v5/market/tickers?category=$MarketType&symbol=$Ticker"
            Write-Verbose "Сформирован URL запроса: $url"

            # Настройка параметров прокси
            # Если прокси-сервер указан, то передаем его в запрос
            $proxyParams = @{}
            if (-not [string]::IsNullOrEmpty($Proxy)) {
                Write-Verbose "Настройка прокси для запроса."
                $proxyParams = @{
                    Proxy           = $Proxy
                    ProxyCredential = $ProxyCredential
                }
            }

            # Выполнение запроса к API Bybit
            Write-Verbose "Отправка запроса к API Bybit..."
            $response = Invoke-RestMethod -Uri $url @proxyParams -ErrorAction Stop

            # Проверка ответа от API
            # Если retCode в ответе не равен 0, значит произошла ошибка
            if ($response.retCode -ne 0) {
                # Проверка значения поля retMsg с использованием регулярного выражения для проверки "Ок" или других значений
                if ($response.retMsg -notmatch "Ок") {
                    Write-Error "Тикер не найден: $($response.retMsg)"
                    return @{
                        Status  = "Error"
                        Message = "Тикер не найден"
                        Timestamp = (Get-Date).ToString("o")
                    }
                }
                throw "API Error: $($response.retMsg) [Code: $($response.retCode)]"
            }

            # Проверка структуры ответа
            # Убедимся, что в ответе есть ожидаемые данные (lastPrice)
            if (-not $response.result.list[0].lastPrice) {
                throw "Некорректная структура ответа: отсутствует поле lastPrice"
            }

            # Парсим цену из ответа, преобразуя строку в число с плавающей запятой
            $price = [double]::Parse(
                $response.result.list[0].lastPrice,
                [System.Globalization.CultureInfo]::InvariantCulture
            )

            # Логируем успешное получение данных
            Write-Verbose "Успешно получена цена: $price"
            return @{ Status = "Success"; Price = $price }

        } catch {
            # Обработка ошибок запроса
            # Логируем ошибку, если произошла ошибка в процессе запроса
            Write-Error "Ошибка при обработке запроса для тикера ${$Ticker}: $_"
            return @{ 
                Status    = "Error"
                Message   = $_.Exception.Message
                Timestamp = (Get-Date).ToString("o")
            }
        } finally {
            # Завершаем выполнение функции
            Write-Verbose "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Завершение обработки запроса для тикера $Ticker."
        }
    }

    end {
        # Финализация работы функции
        Write-Verbose "Завершение работы функции."
    }
}
