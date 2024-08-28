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
3. `yarn v1-deploy` (Деплой версии 1)
    - `yarn deploy-new-pool`
    - `yarn deploy-new-manager`
    - `yarn deploy-runausd`


### Step 2: Настройка(env: v=0/v=1)
0. Указать в utils/data.ts - адрес pool_wallet (перевести токены на кошелек reserve pool)
    - [Пример](https://testnet.tonviewer.com/transaction/c4723b1d790819ba21ced0d489065d3a7b4564b4c90235bd7100fb58a9dc9f46)
    - Указать кошелек `C`
1. `yarn v0-set-deps`: проверить в коде выполнение всех 2-х этапов настроек
2. `yarn v0-set-settings` передача настроек пула в менеджер
3. пополнение пула для активации jetton wallet каждой из монет
      тк монеты у нас тестовые и у них одинаковый интерфейс достаточно сделать это с одной монетой, это монета под индексом 0 из массива assets. Со своего адреса нужно через тонкипер перевести на адрес пула 1 монету st, скопировать кошелек-получатель из ветки транзакции и вставить в объект assets[0] в поле poolWallet, затем адрес кошелька отправителя вставить в переменную jettonUserWallet, после этих настроек можно запускать следующий скрипт:
4. `yarn v0-set-assets`: проверить в коде выполнение всех 4-х этапов настроек
5. Указать ST_JETTON_WALLET адрес `B` из транзакции в 0. этапе


### Step 3: Получение информации (env: v=0/v=1)
> `yarn v0-info-system` (Получение информации о системе) -
> `yarn v0-info-user` (Получение информации о позиции пользователя) - если миграции не было - о старой, если была - о новой. 

### Step 4: User flow (env: v=0/v=1)
  - для проверки jetton используем assets[0], для проверки ton - assets[3], индекс хранится в переменных assetIndex 
1. `yarn v0-supply` Внесение обеспечения активов на TON
2. `yarn v0-supply-ton` Внесение обеспечения TON
3. `yarn v0-withdraw` Возврат обеспечения пользователю

### Step 4: Миграция (env: v=0)
> в env меняем версию на 1, запускаем команды из пункта 4(Сборка и деплой), для запуска миграции меняем версию на 0
 - `yarn v0-migration` Запуск миграции менеджера
 - `yarn v0-migration-pool` Запуск миграции пула (для каждой валюты нужно отдельно запустить скрипты с соответствующим      migrationIndex)
 - `v0-delete-manager` (опционально) После успешной миграции удаляем старый контракт менеджера

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
