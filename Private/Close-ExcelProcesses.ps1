<#
.SYNOPSIS
Безопасно закрывает процессы Excel, связанные с целевым файлом.

.DESCRIPTION
Эта функция ищет все запущенные экземпляры Excel, которые работают с указанным файлом, и принудительно завершает их для предотвращения блокировки файла. Это может быть полезно, если Excel не закрывается корректно, или если файл не может быть изменён, потому что он занят процессами Excel.

.PARAMETER TargetFilePath
Полный путь к целевой Excel-книге. Это обязательный параметр, указывающий на файл Excel, процессы которого должны быть закрыты.

.EXAMPLE
Close-ExcelProcesses -TargetFilePath "C:\Users\Username\Desktop\CryptoPrices.xlsx"
# Этот пример закроет все процессы Excel, работающие с файлом "CryptoPrices.xlsx" на рабочем столе пользователя.
#>

function Close-ExcelProcesses {
    param(
        # Обязательный параметр: полный путь к целевому файлу Excel
        [Parameter(Mandatory)]
        [string]$TargetFilePath
    )

    # Получаем все процессы с именем "EXCEL"
    # -Name "EXCEL" ищет процессы Excel
    # -ErrorAction SilentlyContinue подавляет ошибки, если процесс не найден
    Get-Process -Name "EXCEL" -ErrorAction SilentlyContinue | 

        # Фильтруем только те процессы, которые связаны с целевым файлом
        # $_.MainWindowTitle - возвращает название окна, связанного с процессом Excel
        # [regex]::Escape используется для безопасного экранирования имени файла, чтобы избежать ошибок в регулярных выражениях
        Where-Object { 
            $_.MainWindowTitle -match [regex]::Escape((Split-Path $TargetFilePath -Leaf)) 
        } |

        # Принудительно завершает эти процессы
        # Stop-Process -Force завершает процесс без запроса подтверждения
        # -ErrorAction SilentlyContinue подавляет любые ошибки, если процесс не может быть завершён
        Stop-Process -Force -ErrorAction SilentlyContinue

    # Задержка на 1 секунду, чтобы дать системе время завершить процессы
    Start-Sleep -Seconds 1

    # Выводим сообщение в лог, что процессы Excel для целевого файла были закрыты
    Write-Verbose "Процессы Excel для файла $TargetFilePath закрыты"
}
