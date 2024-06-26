import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    // Получаем переменную текущей позиции обеспечения
    const userCollateral = async function () {
        const lastPositionId = await manager.getLastPositionId();
        const positionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);
        const positionAddressContract = provider.open(
            await PositionAddressContract.fromAddress(positionAddressContractAddress),
        );

        provider.waitForDeploy(positionAddressContract.address, 30);

        let userPossitionAddress = await positionAddressContract.getPositionAddress();
        const userPositionContract = provider.open(await UserPosition.fromAddress(userPossitionAddress));

        const state = await userPositionContract.getPositionState();
        return state.collateral;
    };

    console.log('=============================================================================');
    console.log('01 | Пользователь вносит обеспечение, создается контракт пользовательской позиции');
    console.log('=============================================================================');

    const collateralAmount = toNano(0.5);
    const currentPositionId = await manager.getLastPositionId();

    // Отправляем в пулл средства через метод смарт-контракта пула: DepositCollateralUserMessage
    await poolContract.send(
        user,
        { value: collateralAmount + toNano(0.5) },
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
