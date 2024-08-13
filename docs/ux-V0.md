
# Сборка и деплой
> Создать папку `deploy/v0` если ее нет

> Далее работа с core смарт-контрактами

1. `yarn V0-build` (Запустит build:  manager, newManager, reserve)

2. `yarn V0-deploy` (Деплой контрактов + установка зависимостей между контрактами)

    - `yarn V0-deploy-reserve`
    - `yarn V0-deploy-manager`
    - `yarn V0-deploy-new-manager`

    - Проверить выполнение: в папке вида `deploy/v0/{contract_name}.address` должны лежать все адреса контрактов

    - newManager деплоится исключительно для проверки миграции, он и контракт new up упрощены по функционалу и не будут использоваться

4. `yarn V0-setup`
    - `yarn V0-set-deps`: имея адреса контрактов: usdTon, manager, poolContract, runeCoin
    - `yarn V0-set-settings` (Настройка параметров пула)
    - `yarn V0-set-price` (Установка цены тона)

# Получение информации


> `yarn info_system` (Получение информации о системе) -
> `yarn info_user` (Получение информации о позиции пользователя) - если миграции не было - о старой, если была - о новой. 

# User flow
1. `yarn V0-supply` (Внесение обеспечения)
2. `yarn V0-withdraw` (Возврат обеспечения пользователю)
2. `yarn V0-migration` (Запуск миграции от владельца контракта  менеджер)


### Путь обращения пользователя: **user => manager => user_position(вычисления) 
