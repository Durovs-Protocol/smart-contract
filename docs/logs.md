# Кошельки:

-   Старый: UQBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRiWqh (purity addict pact west bicycle clutch captain emotion fluid oval ethics evolve monitor draft arctic apart gas payment field invest face pen ordinary miracle)

-   `Root Wallet` (9.429 TON):
    -   0QBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRidEr
    -   UQBBl-nmyXbVBrm5cVEcYWc1lXL2clCek9WW3XRo-nYRiWqh

> Заметки и вопросы по коду смотреть через поиск по файлам по ключевому слову TODO

# Логи:

Статусы: ✅, 🟡, 🔴

> Сейчас все проверяется только с одним кошельком

1. ✅ => build
2. ✅ => deploy (pool, manager, usdTON, runecoin)
3. ✅ => setup
4. add-supply: ✅
5. mint: ✅
6. burn: ✅
7. liquidation 🟡 ошибка в том что списание не проходит с пула, остатки оплаты газа возвращаются пользователю 

## Add Supply: 1 TON

User: - 2TON

-   User Position: 0.0011884 TON
-   Manager: 0.008312073 TON
-   Reserve pool: 1.004 TON
-   GAS + ton for storage: 0.0627684 TON

User: + 0.9372316TON

## Mint: 9.3 usdTON

User: - 1 TON

-   User Position: 0.006203756 // тут увеличилось число из-за того что остаток средств переданных на оповещение остался на позиции
-   User wallet 6.732 TUSD
-   Pool 0.068 TUSD
-   GAS: 0.120632 TON

User: + 0.879368 TON

## Burn: 9.207 usdTON

User: -2.333 TON (1.333 комиссия за сжигание 10$, остальное на газ)

-   Pool: + 0.930049304 TON / -1.921 TON (0.990950696 возврат, остальное излишки тона на газ)
-   Profit Pool: +1.33 TON
-   GAS: 0.009049304 TON

User: + 1.909 TON (0.990950696 возврат, остальное излишки тона)

## Ликвидация на цене 6

liquidator: -1 TON

-   User Position: nonexist
-   USDTON master 0.92 TUSD (сожгли 5.88) тут все верно, расчет:

    accountBalance: = self.collateral - (self.MinTonsForStorage + self.GasConsumption) | 1 - 0.02 | 0.98
    liquidationDebt: = liquidati6onAmount - ((accountBalance _ msg.tonPrice) / 1000000000) | 6.8 - (0.98 _ 6) | 0.92
    6.8 - 0.92 | 5.88, мы выкупили и сожгли 5.88, на столько хватило баланса при такой цене тона и за вычетом расходов на газ (тут газ платит пользователь получается из залоговых средств)

-   GAS: 0.093281995

user: + 0.906718005 (излишек газа)

## Итого:

