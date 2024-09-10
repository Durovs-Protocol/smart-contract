!Уделить внимание `// TODOs`!

# Архитектура
В целях сохранения области видимости
- `manager.tact` содержит Manager, PositionKeeper
- `up_pool.tact` содержит UserPosition, ReservePool

# UX

## Supply

1. `ReservePool('TokenNotification')`:
    - Проверки 
        - op кода (TON, указанные для поддержки jettonCode, проверка на существование кода)
        - сумма средств
    - сразу принимаем жетоны на баланс, а дальше через notification в скрипты
2. `Manager('SupplyMessage')`
    - Создаем `UserPosition('Init')` если нет
    - `UserPosition('Supply')`

## Withdraw

1. 

# Комментарии по контрактам

## ReservePool:

- Имплементация от Deployable, OwnableTransferable
- Данные: 
    - MinTonForStorage = ton("0.011"), GasConsumption = ton("0.01")
    - deps, owner, balances, assets, version

## Manager:
    - 

## UP Pool

1. ✅ Init:
    - Данные: balances: map<Address, Int>, user, manager, withdrawState
    - Отправка AddPositionId в Manager->PositionKeeper

2. Supply:
    - Проверка на isActive - для отмененых позиций после миграции
    - Проверка на то что вызов только от Manager


## ✅ PositionKeeper

1. Init: id, position(адрес userPosition), manager, user
2. SetAddress
3. InformationRequest: доступ только для manager