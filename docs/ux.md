# Сборка и деплой

> Создать папку `deploy` если ее нет

> Далее работа с core смарт-контрактами

1. `yarn build` (Запустит build всех контрактов: usdTon, manager, pool, deps, runes, runes-owner)

2. `yarn deploy` (Деплой контрактов + установка зависимостей между контрактами)
3. `yarn deploy-runes` (Деплой контрактов связанных с runes)

    - `yarn deploy-pool`
    - `yarn deploy-manager`
    - `yarn deploy-usdton`

    - `deploy-runes`
    - Проверить выполнение: в папке вида `deploy/{contract_name}.address` должны лежать все адреса контрактов

4. `yarn setup`
    - `yarn set-deps`: имея адреса контрактов: usdTon, manager, poolContract, runeCoin
    - `yarn set-settings` (Настройка параметров пула)
    - `yarn set-price` (Установка цены тона)

# Получение информации

> `yarn rune-info` - получить кошелек rune
> `yarn get-info` (Получение информации о позиции пользователя) - использовать после сброки, деплоя и запуска yarn add-supply

# User flow

1. `yarn get-runes` (Получение runecoins пользователем, через info скрипт берем новый адрес кошелька (убедиться что он новый!!))
2. `yarn add-supply` (Внесение обеспечения (Для проверки баланса использовать скрипт `yarn get-info`(в случае ошибки Exit code: -256 )))
    - collateral: 2, debt:0
3. `yarn mint` (Перечесление usdTon пользователю)
4. `yarn burn` (Возврат стейблкоина пользователем)
5. `yarn withdrawal-supply` (Возврат обеспечения пользователю)

### Путь обращения пользователя: **user => pool => manager => user_position(вычисления) => jetton master/pool(исполнение)**

# Runecoin

1. `yarn deploy-runes-owner` (Деплой контракта-владельца runecoins)
2. `yarn send-runes-to-owner` (Деплой runecoin и минт 1000000 токенов на баланс владельца)
3. `yarn get-runes` (Получение runecoins пользователем)

# Ликвидация

> Мы заложили 1 TON, если lr 1.15, а TON стоит 7.5, то позиция будет считаться здоровой до ~6 USDTON, чтобы провалить проверку обновляем цену TON до 5 (utils/test_data/tonPrice) и запускаем yarn update-price

1. `yarn add-supply` Внесение обеспечения
    - collateral: 1, debt:0
2. `yarn mint` Перечесление usdTon пользователю
    - debt:5
3. `yarn update-price` Обновить цену
4. `yarn liquidation` Запуск ликвидации

### RPC

https://testnet.toncenter.com/api/v2/jsonRPC
https://ton.access.orbs.network/4410c0ff5Bd3F8B62C092Ab4D238bEE463E64410/1/testnet/toncenter-api-v2/jsonRPC

### Тестирование

1. `yarn run-script withdraw_pool` Вывод средств с пула после прохождения цикла на кошелек тестировщика
