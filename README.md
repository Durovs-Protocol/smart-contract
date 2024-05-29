# Описание проекта

## Описание архитектуры

### Смарт-контракты для обеспечения функционала

Функционал:
- Предоставление TON в обмен на wTON - в качестве залогового обязательства
    - Точка входа: `Pool`
    - TON добавляется в `Treasury`
    - `Pool` выдает wTON

- Создание (mint) `usdTON`
    - Точка входа: `Pool`
    - {данные о расчете целевой цены}
    - {данные о стандарте залога wTON} - сейчас 180% (health rate: 1.8)
    - Выпуск usdTON

- Погашение (burn) usdTON
    - Точка входа: `Pool`

- Возврат обсеспечения
    - Точка входа: `Pool`


Ценообразование:

- Предоставление ликвидности: при леквидации высоко-рисковых обязательств покупается залог (wTON) и сразу же продается

## How to use

-   `contracts` - source code of all the smart contracts of the project and their dependencies.
-   `wrappers` - wrapper classes (implementing `Contract` from ton-core) for the contracts, including any [de]serialization primitives and compilation functions.
-   `tests` - tests for the contracts.
-   `scripts` - scripts used by the project, mainly the deployment scripts.

### Build

`npx blueprint build` or `yarn build`

### Test

`npx blueprint test` or `yarn test`

### Deploy or run another script

`npx blueprint run` or `yarn run`

### Add a new contract

`npx blueprint create ContractName` or `yarn blueprint create ContractName`