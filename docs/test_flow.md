# Сборка и деплой

> Создать папку `deploy` если ее нет

1. `yarn build-all` (Запустит build всех контрактов: stablecoin, manager, pool, deps, runes, runes-owner)
2. `yarn deploy-and-set` (Деплой контрактов + установка зависимостей между контрактами)

    - `yarn deploy-pool`
    - `yarn deploy-manager`
    - `yarn deploy-stablecoin`
    - `yarn deploy-runecoin-owner`
    - `yarn deploy-runecoin`
    - `yarn set-deps`

3. `yarn set-settings` (Настройка параметров пула)
4. `yarn set-price` (Установка цены тона - по факту метод updatePrice)

# User flow

1. `yarn deposit-collateral` (Внесение обеспечения (Для проверки баланса использовать скрипт info(в случае ошибки Exit code: -256 )))
    - collateral: 2, debt:0
2. `yarn get-runes` (Получение runecoins пользователем)
3. `yarn mint-stablecoin` (Перечесление stablecoin пользователю)
4. `yarn repay-stablecoin` (Возврат стейблкоина пользователем)
5. `yarn withdraw-collateral` (Возврат обеспечения пользователю)

`yarn get-info` (Получение информации о позиции пользователя)

### Путь обращения пользователя: **user => pool => manager => user_position(вычисления) => jetton master/pool(исполнение)**

# Runecoins

1. `yarn deploy-runes-owner` (Деплой контракта-владельца runecoins)
2. `yarn send-runes-to-owner` (Деплой runecoin и минт 1000000 токенов на баланс владельца)
3. `yarn get-runes` (Получение runecoins пользователем)

### Дополнительный RPC

https://ton.access.orbs.network/4410c0ff5Bd3F8B62C092Ab4D238bEE463E64410/1/testnet/toncenter-api-v2/jsonRPC
