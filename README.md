# Описание проекта

Внешние документы:

1. [Примеры](/docs/examples.md)
2. [Контроль цены](/docs/price_control.md)
3. [Воспроизведение текущего функционала](/docs/test_flow.md)
4. [Описание текущего функционала](/docs/contracts.md)

## Дорожная карта

### Этап 1

1. `Manager` - точка входа для добавления залога TON (конвертации в wTON), чеканки USDTON и погашения займа
2. `Pool` - расчетный счет с TON полученых в качестве залога
3. Оракул для получения данных
4. Расчет health rate на балансах и авто ликвидация залога
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
