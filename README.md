# Durov Protocol

#### Описание функционала контрактов

`Manager` - Отвечает за создание позиции, хранение и передачу настроек, миграцию пользователей.

`UserPosition` - Контракт для расчетов и хранения информации о конкретной позции пользователя. Инициализируется с входными данными:  
- адрес пользователя;  
- адрес manager;  
- адрес reservePool;  
- Balances. 

`PositionKeeper` - Cохраняет id, userPosition и адрес пользователя при создании новой позиции. Инициализируется с id и адресом текущего manager, необходим для миграции.  
`ReservePool` - Контракт на котором хранятся средства переведенные в качетсве залога. 

Build & Deploy
   - Указать в .env = v0
   
> Проверять выполнение: в папке `deploy/v/{contract_name}.address` должны лежать все адреса контрактов
- `yarn v{0/1}-build` - запустить оба в обязательном порядке
  - yarn v0-build
  - yarn v1-build

- `yarn v{0/1}-deploy` 
    - `yarn v0-deploy-manager`
    - `yarn v0-deploy-reserve`
    
    - `yarn v1-deploy-pool`
    - `yarn v1-deploy-manager`
    - `yarn v1-deploy-stable`

    
> Если версия 1 запускается отдельно от процесса миграции впервые для пользователя запустить скрипт:
- `yarn v1-deploy-up` 

> Запуска обеих версий:
- `yarn build` & `yarn deploy`

> В процессе деплоя проверить выполнение функции createAssetsList, результатом должен стать сформированный JSON в папке utils (assets_v{0/1})


Настройка (env: v={0/1})
   - 
> Проверять выполнение всех этапов через **https://{testnet.}tonviewer.com**

**Передача зависимостей в контракты:**
- `yarn set-deps`

**Передача настроек пула в менеджер:**
- `yarn set-settings`
  - **minDelay** - задержка вывода в секундах.
  - **newManager** - адрес нового контракта менеджера (для миграции), до      миграции передавать нулевой.
  - **maxExecutionTime** - максимальное время выполнения операции вывода в секундах, после этого времени информация о предыдущем выводе будет удалена, необходимо для того чтобы после ошибки повторный вывод был возможен.

 **Передача структур assets/blances:**
- `yarn set-assets`

  >Скрипт формирует и передает в контракты **ReservePool** и **Manager** структуры assets/balances. Данные для формирования расчитываются на этапе деплоя **ReservePool** с помощью функции **createAssetsList**. До запуска скрипта проверить результат ее выполнения в utils/assets_v{0/1}.
  
  - **asset** - содержит в себе адреса мастер-контракта, кошелька пула и тикер валюты.
  - **balances** - шаблон для записи балансов вида { masterAddress: amount }, будет передан при первой инициализации **UserPosition** из контракта **Manager**
  
> **Cкрипты версии 1:**

- `yarn set-rates`
  - Установка курса.
   

User flow (env: v={0/1})
   - 
- `yarn supply`
   - Внесение обеспечения активов (кроме TON), в скрипте необходимо указать индекс валюты assets[1-3]

- `yarn supply-ton` 
   - Внесение обеспечения TON, в скрипте необходимо указать индекс валюты assets[0]

- `yarn withdraw`
   - Возврат обеспечения пользователю

> **Cкрипты версии 1:**

- `yarn mint`
   - Выдача кредита в durovUSD
   
- `yarn burn`
   - Погашение задолженности


Получение информации (env: v=0/v=1)
   - 
Получение информации о системе:
- `yarn info-system` 
   - Настройки менеджера;
   - Адреса кошельков пула в контрактах **Manager**/**ReservePool**;
   - Зависимости в контрактах;

Получение информации о позиции пользователя:
- `yarn info-user`
   - Версия контракта;
   - Total collateral in USD (Для проверки первой версии, показывает сумму залога в %);

Миграция (env: v=0)

Подготовка: 
  - `yarn set-settings`

Запуск миграции для up 
 - `yarn migration`
   - Запуск миграции всех up в цикле, результат миграции будет в логе logs/migration/migration_{v}.txt. 
   - Для повторной миграции одной из позиций в случае ошибки запустить `yarn migration-solo` указав id позиции.
   
 Запуск миграции пула
 - `yarn migration-pool`
   - для каждой валюты нужно отдельно запустить скрипты с соответствующим migrationIndex указав сумму монет для миграции. - При миграции TON сумму указывать не нужно.


Доп. информация о разработке
-
###### Целевые настройки:

-   Min Delay: 86400
-   New Manager: UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ
-   Max Execution Time: 86400

###### Прочее:

-   `contracts` - Исходный код контрактов. 
-   `wrappers` - Обертки для скомпилированных контрактов и настройки компиляции к каждому из них.
-   `tests` - Тесты.
-   `scripts` - Скрипты для деплоя и запуска функций. 

###### Описание структуры скриптов:
  - deploy_: деплой контрактов
  - admin_: скрипты со стороны админа
  - set_: настройка контрактов 
  - user_: скрипты со стороны пользователя
  - info_: запрос информации о системе и отдельном пользователе

###### Поиск ошибок: 
В случае проверки через обозреватель кастомный код/текст ошибки искать в папке build, общепринятие коды можно найти в документациях ton/tact.

Этапы запуска Durov Protocol
-
### Этап 1
1. Прием и вывод залоговых средств, чеканка и сжигание durovUSD;
2. Расчет health rate на балансах и авто ликвидация обеспечения;
2. Базовая настройка Stability (service) fee, которая в том числе тратиться на поддержание курса durovUSD (в моменты когда он становится отрицательным);
5. Механизм аварийного глобального [расчета](/docs/price_control.md#глобальный-расчет);

### Этап 2
6. Запуск торговых пары durovUSD/TON, durovUSD/hTON, durovUSD/tsTON, durovUSD/NOT, durovUSD/DOGS, durovUSD/stTON на DEX

### Этап 3
7. Параметр чувствительности - переключает систему с механизма целевой цены на механизм обратной связи целевого курса (Target Rate Feedback Mechanism, TRFM)
8. Работа [TRFM](/docs/price_control.md#2-этап-переключение-с-целевой-цены-на-механизм-обратной-связи-целевого-курса---trfm): запрос курса TON(через оракул) и изменение Stability (service) fee (изменяется ассиметрично изменению курса)
