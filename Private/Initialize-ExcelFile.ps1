<#
.SYNOPSIS
    Инициализирует Excel-файл и рабочий лист.

.DESCRIPTION
    Функция проверяет наличие Excel-файла по указанному пути.
    Если файл отсутствует — создаёт его. Если файл доступен только для чтения — генерирует ошибку.
    После этого открывает файл как ExcelPackage и создаёт лист, если он не существует.
    Возвращает объект ExcelPackage для дальнейшего использования (например, записи данных в Excel).

.PARAMETER Path
    Полный путь к Excel-файлу. Если файл отсутствует — он будет создан.

.PARAMETER Sheet
    Имя рабочего листа, который должен быть создан, если он отсутствует в книге.

.EXAMPLE
    $excel = Initialize-ExcelFile -Path "C:\Data\Tickers.xlsx" -Sheet "BTC"
    # Открывает или создаёт файл и лист BTC, возвращает объект ExcelPackage

.NOTES
    Требует установленного модуля ImportExcel.
    Версия: 1.0
    Автор: ChatGPT
#>

function Initialize-ExcelFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Sheet
    )

    begin {
        Write-Verbose "Начало выполнения функции Initialize-ExcelFile"
        Write-Verbose "Параметр Path: $Path"
        Write-Verbose "Параметр Sheet: $Sheet"
    }

    process {
        try {
            # Проверка: существует ли файл
            if (Test-Path -Path $Path) {
                Write-Verbose "Файл найден по пути: $Path"

                # Проверка: не доступен ли файл только для чтения
                if ((Get-Item -Path $Path).IsReadOnly) {
                    throw "Файл '$Path' доступен только для чтения. Изменения невозможны."
                }
            }
            else {
                Write-Verbose "Файл не найден. Создание нового файла: $Path"

                # Создание пустого файла
                New-Item -Path $Path -ItemType File -Force | Out-Null

                # Задержка, чтобы ОС успела инициализировать файл (особенно важно для Excel)
                Start-Sleep -Seconds 1
            }

            # Открытие Excel-пакета. Если файл существует — он будет открыт, иначе создан.
            Write-Verbose "Открытие Excel-файла"
            $excel = Open-ExcelPackage -Path $Path -Create

            # Проверка: существует ли нужный лист
            if (-not $excel.Workbook.Worksheets[$Sheet]) {
                Write-Verbose "Лист '$Sheet' не найден. Создание нового листа."
                Add-Worksheet -ExcelPackage $excel -WorksheetName $Sheet | Out-Null
            }
            else {
                Write-Verbose "Лист '$Sheet' уже существует"
            }

            # Возврат объекта ExcelPackage
            return $excel
        }
        catch {
            Write-Error "Ошибка при инициализации Excel-файла: $($_.Exception.Message)"
            throw
        }
    }

    end {
        Write-Verbose "Завершение выполнения функции Initialize-ExcelFile"
    }
}
