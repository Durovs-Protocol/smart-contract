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
7. liquidation 🟡 куда-то делись 0.05 USDT

## Add Supply: 1 TON

User: - 2 TON

-   Reserve pool: 1.004 TON
-   GAS + ton for storage: 0.0693424 TON

User: + 0.9306576

--------------------info:
Max for mint: 3.833333333
Max for burn: 0
Max for withdraw: 1
Ton price: 5.75

Supply in TON: 1
Borrow by UP: 0
Borrow by wallet: no data

## Mint: 3.8 usdTON, ton price 5.75

User: - 1 TON

-   USDT master 6.8 TUSD (max supply)
-   User wallet 3.7917 TUSD // TODO почему не отображается в обозревателе jetton и тип контракта? (видно только через запрос к контракту)
-   Pool wallet 0.0383 TUSD // TODO почему не отображается в обозревателе jetton и тип контракта? (видно только через запрос к контракту)
-   GAS: 0.1235144 TON

User: + 0.8764856 TON

--------------------info:
Max for mint: 3.833333333 // TODO учесть в расчете долг
Max for burn: 3.7917
Max for withdraw: 0.516470184
Ton price: 5.75

Supply in TON: 1
Borrow by UP: 3.7917
Borrow by wallet: 3.7917

## Burn: 4.2867 usdTON fee1 fee

User: -2 TON (1 комиссия за сжигание, остальное на газ)

-   Reserve Pool: + 0.930048672 TON / -1.921 TON (возврат и излишки тона на газ)
-   Profit Pool: +1.33 TON
-   USDT master 0.068 TUSD (max supply) то что осталось в пуле, пользовательские монеты сожгли
-   User wallet 0 TUSD
-   GAS: 0.009 TON

User: + 0

## Ликвидация

ton price: 6
supply: 1.002
borrow: 6.732

liquidator: -1 TON

-   User Position: nonexist
-   Reserve pool 0.023941769 отсюда отправили в "dex"
-   USDTON master 0.983235988 TON тут приняли и наминтили монет для сжигания
-   USDTON master 0.92 TUSD (max supply) расчет:
    было: 0.068 + 6.732 | 6.8
    6.8 - 0.92 | 5.88 столько сожгли в процессе ликвидации

    accountBalance: = self.collateral - (self.MinTonsForStorage + self.GasConsumption) | 1.002 - 0.02 | 0.982
    liquidationDebt: = liquidati6onAmount - ((accountBalance \* msg.tonPrice) / 1000000000) | 6.732 - (0.982 \* 6) | 0.84
    6.732 - 0.84 | 5.892, на 5.892 должно было хватить баланса при такой цене тона и за вычетом расходов на газ (тут газ платит пользователь получается из залоговых средств)

*   куда-то делись 0.012 USDT, видимо это не ошибка, а расчет внутри в up, добавила функцию проверки up после
    ликвидации, при следующей проверке можно будет точно узнать параметры ликвидации

-   GAS: 0.08157035

pool: + 0.91842965 (излишек газа который заплатил ликвидатор)

## Итого:

Нужно поправить скрипты с таймером, остальное работает
Нужно разобраться куда делись 0.05 USDT
