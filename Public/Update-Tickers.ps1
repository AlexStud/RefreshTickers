<#
.SYNOPSIS
Обновляет криптовалютные котировки из выбранной биржи в Excel-файле

.DESCRIPTION
Эта функция обновляет данные по криптовалютным тикерам, получая актуальные котировки из выбранной биржи и записывая их в указанный Excel-файл. Для этого используется API различных криптовалютных бирж, таких как Bybit, Binance и Mexc. Данные по каждому тикеру записываются в отдельный столбец с ценами.

Особенности:
- Поддержка различных бирж: Bybit, Binance, Mexc
- Поддержка нескольких типов рынков: spot (спотовая торговля), futures (фьючерсы)
- Кэширование котировок для ускорения последующих запросов
- Обработка ошибок и логирование
- Возможность проксирования запросов через внешний сервер

.PARAMETER FilePath
Путь к Excel-файлу, в который будут записаны обновленные котировки. По умолчанию используется файл "CryptoPrices.xlsx" на рабочем столе пользователя.

.PARAMETER Exchange
Выбор биржи, с которой будут получены котировки. Поддерживаемые значения:
- Bybit — для получения данных с биржи Bybit
- Binance — для получения данных с биржи Binance
- Mexc — для получения данных с биржи Mexc
По умолчанию используется биржа Bybit.

.PARAMETER SheetName
Название листа Excel, где будут записаны данные. По умолчанию используется лист "Prices".

.PARAMETER TickerColumn
Номер столбца в Excel, где будут храниться тикеры криптовалют (по умолчанию — 1).

.PARAMETER PriceColumn
Номер столбца в Excel, где будут храниться котировки (по умолчанию — 2).

.PARAMETER StartRow
Номер строки, с которой начнется обновление данных (по умолчанию — 2).

.PARAMETER MarketType
Тип рынка для запроса котировок. Доступные значения:
- spot — для спотовых котировок
- futures — для фьючерсных котировок
По умолчанию используется "spot".

.PARAMETER Proxy
Адрес прокси-сервера для выполнения запросов. Указывается в формате "http://proxy:port". Если прокси не нужен, параметр можно не указывать.

.PARAMETER ProxyCredential
Учетные данные для прокси-сервера (если требуется аутентификация). Этот параметр должен содержать объект типа PSCredential.

.PARAMETER CacheSeconds
Время жизни кэша для каждой котировки в секундах. По умолчанию — 30 секунд.

.PARAMETER Delay
Задержка между запросами в миллисекундах, чтобы избежать чрезмерной нагрузки на API. По умолчанию — 500 миллисекунд.

.EXAMPLE
Update-Tickers -Exchange Binance -Verbose
Получение котировок с биржи Binance и обновление данных в Excel с выводом подробной информации.

.NOTES
- Работает с PowerShell 7.0 и выше.
- Для работы с Excel требуется установленный модуль ImportExcel или аналогичные библиотеки.
- Использует прокси-серверы и учетные данные при необходимости.
#>

function Update-Tickers {
    [CmdletBinding()]
    param(
        # Путь к Excel-файлу, в который будут записаны котировки
        [string]$FilePath = $(Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath "CryptoPrices.xlsx"),
        
        # Название листа в Excel, по умолчанию "Prices"
        [string]$SheetName = "Prices",
        
        # Номер столбца для тикеров, по умолчанию 1
        [int]$TickerColumn = 1,
        
        # Номер столбца для цен, по умолчанию 2
        [int]$PriceColumn = 2,
        
        # Номер строки, с которой начинаются данные, по умолчанию 2
        [int]$StartRow = 2,
        
        # Биржа для получения котировок (Bybit, Binance, Mexc), по умолчанию Bybit
        [ValidateSet("Bybit", "Binance", "Mexc")]
        [string]$Exchange = "Bybit",
        
        # Тип рынка (spot или futures), по умолчанию futures
        [ValidateSet("spot", "futures")]
        [string]$MarketType = "futures",
        
        # Прокси-сервер (необязательный параметр)
        [string]$Proxy,
        
        # Учетные данные для прокси (если требуется)
        [pscredential]$ProxyCredential,
        
        # Время жизни кэша для тикера (по умолчанию 30 секунд)
        [int]$CacheSeconds = 30,
        
        # Задержка между запросами в миллисекундах (по умолчанию 500)
        [int]$Delay = 500
    )

    # Получаем корневой путь модуля, чтобы использовать его для загрузки вспомогательных скриптов
    $ModuleRoot = Split-Path -Parent $PSScriptRoot

    try {
        # Закрываем процессы Excel, если они были открыты
        . "$ModuleRoot\Private\Close-ExcelProcesses.ps1"
        Close-ExcelProcesses -TargetFilePath $FilePath

        # Инициализируем файл Excel для работы с ним
        . "$ModuleRoot\Private\Initialize-ExcelFile.ps1"
        $excel = Initialize-ExcelFile -Path $FilePath -Sheet $SheetName
        $worksheet = $excel.Workbook.Worksheets[$SheetName]

        $row = $StartRow
        while ($true) {
            # Получаем тикер из Excel
            $ticker = $worksheet.Cells[$row, $TickerColumn].Value

            # Если тикер пустой, выходим из цикла
            if ([string]::IsNullOrEmpty($ticker)) { break }

            # Если биржа Mexc и запрашивается фьючерс, преобразуем тикер: вставляем подчеркивание перед "USDT"
            if ($Exchange -eq "Mexc" -and $MarketType -eq "futures") {
                if ($ticker -notmatch '_USDT') {
                    $ticker = $ticker -replace 'USDT', '_USDT'
                }
            }

            try {
                # Проверяем кэш для тикера
                . "$ModuleRoot\Private\Get-CachedPrice.ps1"
                $cachedPrice = Get-CachedPrice -Ticker $ticker -Exchange $Exchange
                if ($cachedPrice) {
                    # Если данные есть в кэше, обновляем цену в Excel
                    $worksheet.Cells[$row, $PriceColumn].Value = $cachedPrice
                    Write-Verbose "[КЭШ] $ticker : $cachedPrice"
                    $row++
                    continue
                }

                # Преобразуем тип рынка в подходящий формат для каждой биржи
                $apiMarketType = switch ($Exchange) {
                    "Bybit" {
                        if ($MarketType -eq "futures") { "linear" } else { "spot" }
                    }
                    "Binance" {
                        if ($MarketType -eq "futures") { "futures" } else { "spot" }
                    }
                    "Mexc" {
                        if ($MarketType -eq "futures") { "futures" } else { "spot" }
                    }
                    default {
                        throw "Неизвестная биржа: $Exchange"
                    }
                }

                # Подготавливаем параметры для запроса к API
                $params = @{
                    Ticker          = $ticker
                    MarketType      = $apiMarketType
                    Proxy           = $Proxy
                    ProxyCredential = $ProxyCredential
                }

                # Выполняем запрос в зависимости от выбранной биржи
                switch ($Exchange) {
                    "Bybit" {
                        . "$ModuleRoot\Private\Invoke-BybitRequest.ps1"
                        $result = Invoke-BybitRequest @params
                    }
                    "Binance" {
                        . "$ModuleRoot\Private\Invoke-BinanceRequest.ps1"
                        $result = Invoke-BinanceRequest @params
                    }
                    "Mexc" {
                        . "$ModuleRoot\Private\Invoke-MexcRequest.ps1"
                        $result = Invoke-MexcRequest @params
                    }
                }

                # Обработка полученного результата
                if ($result.Status -eq "Success") {
                    # Если запрос успешный, записываем цену в Excel и обновляем кэш
                    $worksheet.Cells[$row, $PriceColumn].Value = $result.Price
                    Update-Cache -Ticker $ticker -Exchange $Exchange -Price $result.Price
                    Write-Host "[УСПЕХ] $ticker : $($result.Price)" -ForegroundColor Green
                } else {
                    # В случае ошибки записываем сообщение об ошибке в Excel
                    $worksheet.Cells[$row, $PriceColumn].Value = $result.Message
                    Write-Warning "[ОШИБКА] $ticker : $($result.Message)"
                }
            }
            catch {
                # Логируем ошибки выполнения
                $errorMsg = $_.Exception.Message
                $worksheet.Cells[$row, $PriceColumn].Value = "ОШИБКА: $errorMsg"
                Write-Error "[КРИТИЧЕСКО] $ticker : $errorMsg"
            }
            finally {
                # Переход к следующей строке и установка задержки перед следующим запросом
                $row++
                Start-Sleep -Milliseconds $Delay
            }
        }

        # Сохраняем файл Excel
        Close-ExcelPackage $excel
        Write-Host "Обновлено $($row - $StartRow) тикеров" -ForegroundColor Cyan
    }
    catch {
        # Логируем фатальные ошибки
        Write-Error "ФАТАЛЬНАЯ ОШИБКА: $_"
        if ($excel) { Close-ExcelPackage $excel -NoSave }
    }
}
