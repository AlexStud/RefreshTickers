@{
    # --- Основные метаданные ---
    ModuleVersion        = '3.1.8'                  # Версия модуля (Major.Minor.Patch)
    GUID                 = 'd3a9b5e1-7c4a-4d88-9f6a-8e7c1f3a2b5c'  # Уникальный идентификатор модуля (GUID)
    Author               = 'AlexStud'               # Автор модуля
    CompanyName          = 'AlexStud''s Company'    # Название компании
    Copyright            = '(c) 2025'               # Права на модуль
    Description          = 'Automated crypto tickers updater with task scheduling'  # Описание модуля

    # --- Системные требования ---
    PowerShellVersion    = '7.0'                    # Минимальная версия PowerShell
    RequiredModules      = @(                       # Зависимые модули
        'ImportExcel',                              # Модуль для работы с Excel
        'ScheduledTasks'                            # Модуль для управления задачами Windows Task Scheduler
    )

    # --- Экспортируемые компоненты ---
    FunctionsToExport    = @(
        'Update-Tickers', 
        'Register-TickersUpdateTask'
        )                                           # Экспортируемые функции
    CmdletsToExport      = @()                      # Не используются
    VariablesToExport    = @()                      # Не используются
    AliasesToExport      = @()                      # Не используются

    # --- Дополнительные метаданные (рекомендуемые) ---
    RootModule            = 'RefreshTickers.psm1'    # Указываем основной модуль
    #ProjectUri           = 'https://github.com/AlexStud/RefreshTickers'  # Ссылка на репозиторий
    #LicenseUri           = 'https://opensource.org/licenses/MIT'         # Ссылка на лицензию
    #Tags                 = @('Crypto', 'Excel', 'Automation')            # Теги для поиска
    #IconUri              = 'https://example.com/icon.png'                # Иконка модуля
}