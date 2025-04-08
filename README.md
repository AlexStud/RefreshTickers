# RefreshTickers

**RefreshTickers** — PowerShell-модуль для автоматического обновления криптовалютных котировок в Excel с использованием API популярных бирж (Bybit, Binance, MEXC). Подходит для всех, кто хочет автоматизировать отслеживание цен.

## 📦 Возможности

- Поддержка спотовых и фьючерсных рынков.
- API-интеграции с Bybit, Binance и MEXC.
- Вывод данных в Excel-файл.
- Поддержка прокси.
- Возможность запуска обновления по расписанию через Task Scheduler.

## 🗂 Структура проекта

```
RefreshTickers/
├── Public/
│   ├── Register-TickersUpdateTask.ps1
│   └── Update-Tickers.ps1
├── Private/
│   ├── Close-ExcelProcesses.ps1
│   ├── Get-CachedPrice.ps1
│   ├── Initialize-ExcelFile.ps1
│   ├── Invoke-BinanceRequest.ps1
│   ├── Invoke-BybitRequest.ps1
│   ├── Invoke-MexcRequest.ps1
│   └── ProxyHandler.ps1
├── RefreshTickers.psd1
├── RefreshTickers.psm1
└── README.md
```

## ⚙️ Установка

```powershell
# Клонировать репозиторий
git clone https://github.com/AlexStud/RefreshTickers.git

# Импортировать модуль
Import-Module "путь_до_модуля\RefreshTickers"
```

## 🚀 Примеры использования

```powershell
# Обновить котировки вручную
Update-Tickers

# Зарегистрировать задачу для автообновления
Register-TickersUpdateTask
```

## 💱 Поддерживаемые биржи

| Биржа   | Типы рынков   |
|---------|---------------|
| Bybit   | Spot, Futures |
| Binance | Spot, Futures |
| MEXC    | Spot, Futures |

## 🧾 Требования

- PowerShell 5.1 или выше
- Microsoft Excel
- Интернет-соединение

## 📄 Лицензия

Проект распространяется под лицензией **MIT**.

---

— **AlexStud**

## Примеры использования

### Обновление тикеров вручную

```powershell
Update-Tickers -MarketType spot -Exchange Binance
```

### Регистрация фоновой задачи для автоматического обновления тикеров

```powershell
Register-TickersUpdateTask -DailyTime "08:00" -MarketType futures -Exchange Bybit
```

Эти команды обеспечивают гибкость в обновлении данных: можно запустить разовое обновление вручную или настроить автоматическую ежедневную задачу.