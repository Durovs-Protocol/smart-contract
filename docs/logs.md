# Кошельки:

- Старый: UQBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRiWqh (purity addict pact west bicycle clutch captain emotion fluid oval ethics evolve monitor draft arctic apart gas payment field invest face pen ordinary miracle)

- `Root Wallet` (9.429 TON):
    - 0QBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRidEr
    - UQBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRiWqh

> Заметки и вопросы по коду смотреть через поиск по файлам по ключевому слову TODO


# Логи:
Статусы: ✅, 🟡, 🔴
> Сейчас все проверяется только с одним кошельком
1. build: ✅
2. deploy (pool, manager, usdTON, runecoin_owner, runecoin): ✅
3. setup: ✅
4. get-runes: 🔴
5. add-supply: ✅
6. mint: 🟡 - ошибка в metadata
7. burn: 🟡 - списывать TON с supply(работает) и обновлять его баланс, добавить проверку чтобы при сжигании 2.5 и балансе 0.5 не было ошибок
8. withdrawal-supply - (даем доступ к кошельку runacoin только для текущей userposition), убрать статистику о сумме залога - брать с баланса
9. liquidation (распоряжаемся только залогом - runacoin не трогаем), убрать usdTonsIssued посылать остатки газа в доход, иметация покупки на DEX - сами у себя

## Add Supply: 1 TON

User: 8.358 TON => - 1.071 TON
- User Position: 1.008 TON
- Manager: 0.00874797
- GAS: 0.13425203 TON

## Mint: 3 usdTON

User: 8.248 TON
- User Position: 1.08 TON (-0.003 TON)
- GAS: 0,103 TON

------------------------------------------------------------------------------------------------------------

## Burn: 2.5 usdTON

User: 8.173 TON
- User Position: 0.99035526 TON
- Pool: 0.012874266 TON (Доход) - 0,00964474 (должно уменьшиться)
- GAS: 0,075 TON

## Burn: 0.5 usdTON

User: 8.098 TON
- User Position: 0.99035526 TON
- Pool: 0.012874266 TON (Доход) - 0,00964474 (должно уменьшиться)
- GAS: 0,075 TON

------------------------------------------------------------------------------------------------------------

## Вывод залога: 1.014 TON

User: 3.206 TON,
- User Position: 0.137619317 TON
- Manager: 0.129519091 TON
- Pool: 0.013702625 TON
- GAS: 3.206 - 1 - 2.269 = -0,063 TON (Оплатил в счет возвратов ?)

## Итого:
- User Wallet: 3.831 => 3.206 (потерял 0.625)
    - Разбросал по кошелькам: 0.280841033
    - Оплата займа: ???
    - Оплата газа: минимум 0.344158967 (из расчета отсутствия комиссий за займ)
- User Position: 0.137619317
- Manager: 0.129519091
- Pool: 0.013702625


При создании User Position (передаем RunaCoinAddress - сохраняем в переменной контракта - для выплат)


Перед ликвидацией: 4.944
UP: 2.388