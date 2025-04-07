
<#
.SYNOPSIS
Создает задачу в планировщике для автоматического обновления котировок.

.DESCRIPTION
Эта функция регистрирует задачу в планировщике Windows, которая будет запускать функцию Update-Tickers для автоматического обновления котировок криптовалют. Задача будет запускаться по заданному расписанию, а параметры можно настроить, чтобы задать время начала, дни недели и интервал обновлений.

.PARAMETER TaskName
Имя задачи в планировщике. По умолчанию используется имя "CryptoPricesUpdate".

.PARAMETER FilePath
Путь к файлу Excel, в который будут записываться котировки. По умолчанию используется "CryptoPrices.xlsx" на рабочем столе пользователя.

.PARAMETER StartTime
Время первого запуска задачи. По умолчанию это текущее время плюс 5 минут, чтобы дать время на настройку задачи.

.PARAMETER DaysOfWeek
Дни недели, в которые задача будет выполняться. Возможные значения:
- "Weekdays" — только рабочие дни (понедельник — пятница).
- "Weekend" — только выходные (суббота и воскресенье).
- "All" — все дни недели (понедельник — воскресенье).
По умолчанию используется "Weekdays".

.PARAMETER IntervalHours
Интервал между запусками задачи в часах. По умолчанию установлен на 1 час.

.EXAMPLE
Register-TickersUpdateTask
# Использует путь по умолчанию и создает задачу для обновления котировок в рабочие дни с интервалом 1 час.

.EXAMPLE
Register-TickersUpdateTask -FilePath "D:\data.xlsx" -DaysOfWeek All
# Создает задачу для обновления котировок каждый день с интервалом 1 час, используя указанный путь к файлу Excel.

.NOTES
Для работы этой функции необходимы права администратора на компьютере.
#>

function Register-TickersUpdateTask {
    [CmdletBinding()]
    param(
        # Имя задачи в планировщике
        [string]$TaskName = "CryptoPricesUpdate",

        # Путь к Excel-файлу
        [string]$FilePath = $(Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath "CryptoPrices.xlsx"),

        # Время первого запуска задачи
        [DateTime]$StartTime = (Get-Date).AddMinutes(5),

        # Дни недели для выполнения задачи
        [ValidateSet("Weekdays", "Weekend", "All")]
        [string]$DaysOfWeek = "Weekdays",

        # Интервал между запусками задачи в часах
        [ValidateRange(1, 24)]
        [int]$IntervalHours = 1
    )

    # Проверка, если скрипт выполняется с правами администратора
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        throw "Требуются права администратора"
    }

    # Автоматическое создание файла Excel, если он не существует
    if (-not (Test-Path $FilePath)) {
        try {
            # Если файл не существует, создаем его
            $null = New-Item -Path $FilePath -ItemType File -Force
            Write-Host "Файл по умолчанию создан: $FilePath" -ForegroundColor Cyan
        }
        catch {
            # Если произошла ошибка при создании файла, выводим сообщение
            throw "Ошибка создания файла: $_"
        }
    }

    # Конфигурация дней недели для выполнения задачи
    $days = switch ($DaysOfWeek) {
        "Weekdays"  { @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday") }   # Рабочие дни
        "Weekend"   { @("Saturday", "Sunday") }                                       # Выходные дни
        "All"       { @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday") }  # Все дни
    }

    # Создание триггера для задачи (запуск по расписанию)
    $trigger = New-ScheduledTaskTrigger -Daily `
        -DaysOfWeek $days `            # Указываем дни недели
        -At $StartTime `               # Указываем время первого запуска
        -RepetitionInterval (New-TimeSpan -Hours $IntervalHours)  # Указываем интервал между запусками задачи

    # Конфигурация действия, которое будет выполняться при запуске задачи
    $action = New-ScheduledTaskAction `
        -Execute 'powershell.exe' `   # Запуск PowerShell
        -Argument "-NoProfile -WindowStyle Hidden -Command 'Import-Module RefreshTickers -ErrorAction Stop; Update-Tickers -FilePath ""$FilePath"" -Verbose'"  # Команда для выполнения функции Update-Tickers с указанным путем к файлу Excel и параметром Verbose для подробного вывода

    # Настройки задачи
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `   # Разрешаем запуск задачи, если устройство работает на батарее
        -DontStopIfGoingOnBatteries `  # Не останавливать задачу при переходе на батарею
        -StartWhenAvailable          # Запускать задачу, когда компьютер снова станет доступен, если задача не может быть выполнена в нужное время

    # Регистрация задачи в планировщике
    Register-ScheduledTask `
        -TaskName $TaskName `          # Имя задачи
        -Action $action `              # Действие для выполнения
        -Trigger $trigger `            # Триггер для расписания
        -Settings $settings `          # Настройки задачи
        -Description "Автоматическое обновление криптокотировок" `  # Описание задачи
        -Force                          # Принудительно регистрировать задачу, если она уже существует

    # Уведомление о создании задачи
    Write-Host "Задача `"$TaskName`" успешно создана!" -ForegroundColor Green
    Write-Host "Путь к файлу: $FilePath" -ForegroundColor Yellow
}
