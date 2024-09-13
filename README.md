# Описание проекта

Документация:

1. [Примеры](/docs/examples.md)
2. [Контроль цены](/docs/price_control.md)
3. [Описание текущего функционала](/docs/contracts.md)
4. [Подробнее](/docs/ux.md)

### Step 1: Деплой

> Проверить выполнение: в папке вида `deploy/v/{contract_name}.address` должны лежать все адреса контрактов

1. `yarn v0-build` (Запустит build обеих версий:  manager/reserve)
2. `yarn v0-deploy` (Деплой контрактов версии 0)
    - `yarn v0-deploy-manager`
    - `yarn v0-deploy-reserve`

3. `yarn v1-build`
4. `yarn v1-deploy` (Деплой версии 1)
    - `yarn deploy-new-pool`
    - `yarn deploy-new-manager`
    - `yarn deploy-runausd`


### Step 2: Настройка(env: v=0/v=1)

- `yarn set-deps`: имея адреса контрактов: stable, manager, poolContract
- `yarn set-settings` передача настроек пула в менеджер
- `yarn set-assets` Установка кошельков пула и шаблона балансов (проверить в коде выполнение всех 4-х этапов )


### Step 3: Получение информации (env: v=0/v=1)
> `yarn info-system` (Получение информации о системе) -
> `yarn info-user` (Получение информации о позиции пользователя) - если миграции не было - о старой, если была - о новой. 

### Step 4: User flow (env: v=0/v=1)
  - для проверки jetton используем assets[0], для проверки ton - assets[3], индекс хранится в переменных assetIndex 
1. `yarn v0-supply` Внесение обеспечения активов на TON
2. `yarn v0-supply-ton` Внесение обеспечения TON
3. `yarn v0-withdraw` Возврат обеспечения пользователю

### Step 4: Миграция (env: v=0)
> в env меняем версию на 1, запускаем команды из пункта 4(Сборка и деплой), для запуска миграции меняем версию на 0
 - `yarn migration` Запуск миграции менеджера
 - `yarn migration-pool` Запуск миграции пула (для каждой валюты нужно отдельно запустить скрипты с соответствующим      migrationIndex)
 - `delete-manager` (опционально) После успешной миграции удаляем старый контракт менеджера

### Этап 1

1. `Manager` - точка входа для добавления обеспечения TON (конвертации в wTON), чеканки USDTON и погашения займа
2. `Pool` - расчетный счет с TON полученых в качестве обеспечения
3. Оракул для получения данных
4. Расчет health rate на балансах и авто ликвидация обеспечения
5. Базовая настройка Stability (service) fee, которая в том числе тратиться на поддержание курса USDTON (в моменты когда он становится отрицательным)
6. Механизм аварийного глобального [расчета](/docs/price_control.md#глобальный-расчет)

### Этап 2

7. Запуск торговых пары USDTON/TON, USDTON/jUSDT, USDTON/jUSDC, USDTON/jDAI на DEX от TON

### Этап 3

8. Параметр чувствительности - переключает систему с механизма целевой цены на механизм обратной связи целевого курса (Target Rate Feedback Mechanism, TRFM)
9. Работа [TRFM](/docs/price_control.md#2-этап-переключение-с-целевой-цены-на-механизм-обратной-связи-целевого-курса---trfm): запрос курса TON(через оракул) и изменение Stability (service) fee (изменяется ассиметрично изменению курса)

## Разработка

Целевые настройки:

-   Health rate ликвидации: 1.5
-   Health rate для эмиссии: >=2 (необходимый health rate для создания)
-   Stability Fee: 1% (за использование USDTON)

Команды:

-   `yarn build` - сборка смарт-контракта
-   `yarn test` - запуск теста для смарт-контракта
-   `yarn run` - запуск выполнения скрипта для взаимодействия со смарт-контрактом
-   `yarn blueprint create ContractName` - создание зависимостей при создании смарт-контракта

## Прочее

-   `contracts` - source code of all the smart contracts of the project and their dependencies.
-   `wrappers` - wrapper classes (implementing `Contract` from ton-core) for the contracts, including any [de]serialization primitives and compilation functions.
-   `tests` - tests for the contracts.
-   `scripts` - scripts used by the project, mainly the deployment scripts.
