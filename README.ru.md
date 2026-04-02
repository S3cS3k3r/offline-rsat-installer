---

## `README.ru.md`

```md
# Offline RSAT Installer for Windows

[English version](README.md)

PowerShell-скрипт для офлайн-установки RSAT в Windows с помощью ISO с Language and Optional Features.

## Что делает этот скрипт

Скрипт:

- скачивает ISO с Language and Optional Features
- автоматически монтирует ISO
- находит корректный путь к пакетам
- устанавливает все отсутствующие компоненты RSAT офлайн
- не использует WSUS и Windows Update во время установки
- размонтирует ISO после завершения
- удаляет скачанный ISO-файл

## Зачем это нужно

Скрипт полезен, если:

- установка RSAT через WSUS не работает
- Windows Update ограничен корпоративными политиками
- нужно установить RSAT без интернета
- работа ведётся на VDI или на жёстко ограниченных корпоративных рабочих станциях

## Важно

Ссылку на ISO нужно выбирать в зависимости от версии/сборки Windows.

Перед запуском скрипта замени значение `$IsoUrl` на правильную ссылку на **Language and Optional Features ISO** для той версии Windows, на которой будет выполняться установка.
Прямые ссылки можно найти здесь: https://learn.microsoft.com/en-us/azure/virtual-desktop/windows-11-language-packs

## Как использовать

1. Открой PowerShell от имени администратора
2. Обнови ссылку на ISO внутри скрипта
3. Запусти скрипт

## Результат

Скрипт установит все отсутствующие компоненты RSAT, доступные через Windows Features on Demand.

После установки можно открыть Active Directory Users and Computers командой:

```powershell
dsa.msc
