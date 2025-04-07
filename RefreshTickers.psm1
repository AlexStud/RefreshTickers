<#
.SYNOPSIS
Этот скрипт загружает функции из папок "Public" и "Private" модуля и экспортирует только те функции, которые указаны в `.psd1`.

.DESCRIPTION
Скрипт выполняет следующие шаги:
1. Загружает все PowerShell-скрипты из папок "Public" и "Private" в текущий сеанс.
2. Экспортирует только те функции, которые указаны в файле `.psd1` через параметр `FunctionsToExport`.
3. В конце выводит список загруженных и экспортированных функций.

.PARAMETER None
Этот скрипт не имеет параметров.

.EXAMPLE
. .\ИмяСкрипта.ps1
Этот пример просто запускает скрипт, и он импортирует все функции.

.NOTES
Это необходимо для того, чтобы загрузить все нужные функции для работы с модулем.
#>

# Получаем путь к корню модуля
$moduleRoot = $PSScriptRoot

# Проверяем, существует ли корневой путь модуля
if (-not (Test-Path $moduleRoot)) {
    Write-Error "Корневой путь модуля не найден: $moduleRoot"
    return
}

# Создаем пути для папок Public и Private относительно корня модуля
$publicPath  = Join-Path $moduleRoot 'Public'
$privatePath = Join-Path $moduleRoot 'Private'

# Проверяем, существуют ли папки Public и Private
if (-not (Test-Path $publicPath)) {
    Write-Error "Папка Public не найдена: $publicPath"
    return
}

if (-not (Test-Path $privatePath)) {
    Write-Error "Папка Private не найдена: $privatePath"
    return
}

# Получаем все файлы .ps1 в папках Public и Private
$public  = @(Get-ChildItem -Path $publicPath -Filter '*.ps1' -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem -Path $privatePath -Filter '*.ps1' -ErrorAction SilentlyContinue)

# Перебираем все файлы из обеих папок (Public и Private)
foreach ($import in @($public + $private)) {
    try {
        # Проверяем, существует ли файл перед импортом
        if (-not (Test-Path $import.FullName)) {
            Write-Warning "Файл не существует: $($import.FullName)"
            continue
        }

        # Загружаем каждый скрипт в текущий сеанс PowerShell
        . $import.FullName  # Точка (.) используется для вызова скрипта в текущем сеансе
        Write-Host "Загружен скрипт: $($import.FullName)"  # Выводим сообщение о том, что скрипт был успешно загружен
    }
    catch {
        # Если возникает ошибка при импорте скрипта, выводим сообщение об ошибке
        Write-Error "Не удалось импортировать $($import.FullName): $_"
    }
}

# Получаем список функций, указанных в .psd1
$FunctionsToExport = @('Update-Tickers', 'Register-TickersUpdateTask')

# Экспортируем только те функции, которые указаны в .psd1
Export-ModuleMember -Function $FunctionsToExport

# Выводим список всех загруженных функций из Public
Write-Host "Экспортированы функции:"
$FunctionsToExport | ForEach-Object { Write-Host "- $_" }  # Выводим имена экспортированных функций
