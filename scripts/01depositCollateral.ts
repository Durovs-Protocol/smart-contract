import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { Runecoin } from '../wrappers/Runecoin';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    const runecoin = provider.open(await Runecoin.fromAddress(Address.parse(await loadAddress('runecoin'))));

    // Получаем переменную текущей позиции обеспечения
    const userCollateral = async function () {
        // TODO Если использовать метод fromInit адреса контрактов отличаются, почему?
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));

        const state = await userPosition.getPositionState();
        return state.collateral;
    };

    console.log('=============================================================================');
    console.log('01 | Пользователь вносит обеспечение, создается контракт пользовательской позиции');
    console.log('=============================================================================');

    const collateralAmount = toNano(0.5);
    const currentPositionId = await manager.getLastPositionId();

    // Отправляем в пулл средства через метод смарт-контракта менеджера: DepositCollateralUserMessage
    await manager.send(
        user,
        { value: collateralAmount + toNano(2) },
        {
            $$type: 'DepositCollateralUserMessage',
            user: user.address as Address,
            amount: collateralAmount,
        },
    );

    console.log(`currentPositionId | ${currentPositionId}`);
    if (currentPositionId <= 0) {
        await timer(`Position Id`, 'Внесение обеспечения', currentPositionId + 1n, manager.getLastPositionId);
    }

    const userBalanceBefore = await userCollateral();
    console.log(`userBalanceBefore | ${userBalanceBefore}`);

    const userBalanceAfter = userBalanceBefore + collateralAmount;
    await timer(`User balance`, 'Внесение обеспечения', userBalanceAfter, userCollateral);
}
