# Сборка и деплой

> Создать папку `deploy` если ее нет

> Далее работа с core смарт-контрактами 

1. `yarn build` (Запустит build всех контрактов: usdTon, manager, pool, deps, runes, runes-owner)

2. `yarn deploy` (Деплой контрактов + установка зависимостей между контрактами)
    - `yarn deploy-pool`
    - `yarn deploy-manager`
    - `yarn deploy-usdton`
    - `yarn deploy-runecoin-owner`
    - `yarn deploy-runecoin`
    - Проверить выполнение: в папке вида `deploy/{contract_name}.address` должны лежать все адреса контрактов

3. `yarn setup`
    - `yarn set-deps`: имея адреса контрактов: usdTon, manager, poolContract, runeCoin
    - `yarn set-settings` (Настройка параметров пула)
    - `yarn update-price` (Установка цены тона)

> Далее работа с Runa Coin

1. `yarn deploy-runes-owner`
2. 

# Получение информации

1. `yarn rune-info` - получает данные о состоянии хранилища владельца
2. 

# User flow

> `yarn get-info` (Получение информации о позиции пользователя) - использовать после сброки, деплоя и запуска yarn add-supply

1. `yarn add-supply` (Внесение обеспечения (Для проверки баланса использовать скрипт `yarn get-info`(в случае ошибки Exit code: -256 )))
    - collateral: 2, debt:0
2. `yarn mint` (Перечесление usdTon пользователю)
3. `yarn get-runes` (Получение runecoins пользователем)
4. `yarn burn` (Возврат стейблкоина пользователем)
5. `yarn withdrawal-supply` (Возврат обеспечения пользователю)

### Путь обращения пользователя: **user => pool => manager => user_position(вычисления) => jetton master/pool(исполнение)**

# Runecoin

1. `yarn deploy-runes-owner` (Деплой контракта-владельца runecoins)
2. `yarn send-runes-to-owner` (Деплой runecoin и минт 1000000 токенов на баланс владельца)
3. `yarn get-runes` (Получение runecoins пользователем)

### Дополнительный RPC

https://ton.access.orbs.network/4410c0ff5Bd3F8B62C092Ab4D238bEE463E64410/1/testnet/toncenter-api-v2/jsonRPC
