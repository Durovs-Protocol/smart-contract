# Сборка и деплой

> Создать папку `deploy` если ее нет

1. `yarn build-all` (Запустит build всех контрактов: stablecoin, manager, pool, deps, runes, runes-owner)
2. `yarn deploy-and-set` (Деплой контрактов + установка зависимостей между контрактами)
    - `yarn deploy-pool`
    - `yarn deploy-manager`
    - `yarn deploy-stablecoin`
    - `yarn set-deps`
3. `yarn set-settings` (Настройка параметров пула)
4. `yarn set-price` (Установка цены тона - по факту метод updatePrice)

# User flow

1. `yarn deposit-collateral` (Внесение обеспечения (Для проверки баланса использовать скрипт info))
    - collateral: 2, debt:0
2. `yarn mint-stablecoin` (Перечесление stablecoin пользователю)
3. `yarn repay-stablecoin` (Возврат стейблкоина пользователем)
4. `yarn withdraw-collateral` (Возврат обеспечения пользователю)

`yarn get-info` (Получение информации о позиции пользователя)

### Путь обращения пользователя: **user => pool => manager => user_position(вычисления) => jetton master/pool(исполнение)**

# Runecoins

1. `yarn deploy-runes-owner` (Деплой контракта-владельца runacoins)
2. `yarn send-runes-to-owner` (Деплой runacoin и минт 1000000 токенов на баланс владельца)
3. `yarn get-runes` (Получение runacoins пользователем)

### Дополнительный RPC

https://ton.access.orbs.network/4410c0ff5Bd3F8B62C092Ab4D238bEE463E64410/1/testnet/toncenter-api-v2/jsonRPC
