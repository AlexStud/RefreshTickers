<#
.SYNOPSIS
    Формирует параметры прокси-соединения для использования в веб-запросах.

.DESCRIPTION
    Эта функция проверяет, были ли переданы параметры прокси и учетные данные, 
    и возвращает хэш-таблицу с соответствующими параметрами, которые могут быть переданы 
    в команды, поддерживающие прокси, например Invoke-RestMethod.

    Это удобно, чтобы избежать дублирования кода и централизованно обрабатывать 
    прокси-настройки при работе в защищённых сетях или корпоративной среде.

.PARAMETER Proxy
    URL-адрес прокси-сервера в формате http://адрес:порт.
    Пример: http://proxy.local:8080

.PARAMETER ProxyCredential
    Учетные данные (логин и пароль) для аутентификации на прокси-сервере.
    Используется объект типа [pscredential].

.EXAMPLE
    Get-ProxySettings -Proxy "http://proxy.local:8080" -ProxyCredential (Get-Credential)

    Возвращает хэш-таблицу с параметрами Proxy и ProxyCredential.

.EXAMPLE
    $proxyParams = Get-ProxySettings -Proxy "http://10.10.10.1:3128"
    Invoke-RestMethod -Uri $url @proxyParams

    Используется прокси-сервер без аутентификации для запроса к API.

.NOTES
    Версия: 1.0
    Автор: ChatGPT
    Совместимость: PowerShell 5.1+, 7+
#>

function Get-ProxySettings {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Proxy,

        [Parameter(Position = 1)]
        [pscredential]$ProxyCredential
    )

    begin {
        Write-Verbose "Начало выполнения функции Get-ProxySettings"
        Write-Verbose "Проверка входных параметров Proxy и ProxyCredential"
    }

    process {
        # Создание пустой хэш-таблицы для хранения параметров
        $params = @{}

        # Проверка: если указан адрес прокси
        if ($Proxy) {
            Write-Verbose "Обнаружен параметр Proxy: $Proxy"
            $params.Proxy = $Proxy

            # Проверка: если указаны учетные данные для прокси
            if ($ProxyCredential) {
                Write-Verbose "Обнаружены учетные данные для прокси"
                $params.ProxyCredential = $ProxyCredential
            }
            else {
                Write-Verbose "Учетные данные для прокси не указаны"
            }
        }
        else {
            Write-Verbose "Параметр Proxy не указан — возвращается пустая хэш-таблица"
        }

        # Возврат сформированных параметров
        Write-Verbose "Возврат параметров прокси: $($params | Out-String)"
        return $params
    }

    end {
        Write-Verbose "Завершение выполнения функции Get-ProxySettings"
    }
}
