# Сборка и деплой

1. `yarn build-all` (Запустит build всех контрактов)
2. `yarn deploy-and-set` (Деплой контрактов + установка зависимостей)
   `yarn deploy-pool`
   `yarn deploy-manager`
   `yarn deploy-stablecoin`
   `yarn set-deps`
3. `yarn set-settings` (Настройка параметров пула)
4. `yarn set-price` (Установка цены тона)

# User flow

1. `yarn deposit-collateral` (Внесение залога (Для проверки баланса использовать скрипт info))
2. `yarn withdraw-stablecoin` (Перечесление stablecoin пользователю)
3. `yarn repay-stablecoin` (Возврат стейблкоина пользователем)
4. `yarn withdraw-collateral` (Возврат залога пользователю)

`yarn get-info` (Получение информации о позиции пользователя)

### Путь обращения пользователя: **user => pool => manager => user_position(вычисления) => jetton master/pool(исполнение)**

### Дополнительный RPC

https://ton.access.orbs.network/4410c0ff5Bd3F8B62C092Ab4D238bEE463E64410/1/testnet/toncenter-api-v2/jsonRPC
