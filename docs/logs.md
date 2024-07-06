# Логи:
1. build - ✅
2. deploy - ✅
3. setup - ✅
4. get-runes - 🔴 описание [по ссылке](../docs/backlog.md)
5. add-supply - ✅
6. mint - 🟡 не видно usdTON на балансе пользователя в TonViewer
7. burn - 🔴 зависает скрипт
8. liquidation - 


# Деплой
После деплоя контрактов: 5.967 TON (было 7.118 TON)
- `User Wallet`:
    - UQBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRiWqh
    - EQBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRiTdk
- `usdTON`:
    - EQD_5uNFHWjroPFmrw9w2YcNNPIEkY5w2Md-9FB0t5ZLjEhH
- `Manager`:
    - EQDi_mL_15pTjxBtR9jOa2d693ZOHzY8s9LMmBzJw_M7KAdr
- `Pool`:
    - EQAIZm8leBIUn4vWw_myDLBFKk6BZ4qw0AOpVElgeC2eaYLc
- `RunecoinOwner`:
    - EQCa7Rdqf1xEbplL9rTDuXjOqjACBlkfnFiWGA2gjfBCDiHC
- `Runecoin`:
    - EQAMgUf6nTQHeCpjrdA5MIu0v4w32bQnkSHEBwxKtGY26mop
- `User Position`:
    - EQCSQV0VSYwqsRz9tGZwgUkKOLLBpAZnYeoMOEq8Tc24HrRO

## Add Supply: 1 TON

User: 4.813 TON => - 1.154 TON
- User Position: 1.011 TON
- Manager: 0.00874797
- GAS: 0.13425203 TON

## Mint: 3 usdTON

User: 4.71 TON, usdTON не видно !!!
- User Position: 1.08 TON (-0.003 TON)
- Manager: 0.008746899 TON (-0.000001071 TON )
- GAS: 0,103 TON

## Burn: 0.01 usdTON

User: 2.269 TON, доп. токена больше нет.
- User Position: 0.137620349 TON
- Manager: 0.129521021 TON
- Pool: 1.014 TON
- GAS: 0,405 TON

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