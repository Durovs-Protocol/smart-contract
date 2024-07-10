import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log, timer } from '../utils/helpers';
import { addSupplyAmount } from '../utils/test_data';
import { Manager } from '../wrappers/Manager';

import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    // const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    // const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    // const runecoin = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    // Получаем переменную текущей позиции обеспечения
    const userCollateral = async function () {
        // TODO Если использовать метод fromInit адреса контрактов отличаются, почему?
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));

        const state = await userPosition.getPositionState();
        return state.collateral;
    };

    log('01 | Пользователь вносит обеспечение, создается/обновляется контракт пользовательской позиции');

    const collateralAmount = toNano(addSupplyAmount);
    const currentPositionId = await manager.getLastPositionId();

    // Отправляем в пулл средства через метод смарт-контракта менеджера: DepositCollateralUserMessage
    // тут передан оптимальный газ
    // await manager.send(
    //     user,
    //     { value: collateralAmount + toNano(0.1) },
    //     {
    //         $$type: 'DepositCollateralUserMessage',
    //         user: user.address as Address,
    //         amount: collateralAmount,
    //     },
    // );

    console.log(`currentPositionId | ${currentPositionId}`);
    if (currentPositionId <= 0) {
        await timer(`Position Id`, 'Внесение обеспечения', currentPositionId + 1n, manager.getLastPositionId);
    } else {
        // эта проверка теперпь не будет работать тк supply будет показыватьчя с учетом остатков газа на контракте
        // const userBalanceBefore = await userCollateral();
        // console.log(`Supply Balance before | ${numberFormat(fromNano(userBalanceBefore.toString()))}`);
        // const userBalanceAfter = userBalanceBefore + collateralAmount;
        // await timer(`User balance`, 'Внесение обеспечения', userBalanceAfter, userCollateral);
    }
}
