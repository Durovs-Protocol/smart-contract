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

    const userCollateral = async function () {
        const lastPositionId = await manager.getLastPositionId();
        const positionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);
        const positionAddressContract = provider.open(
            await PositionAddressContract.fromAddress(positionAddressContractAddress),
        );
        let userPossitionAddress = await positionAddressContract.getPositionAddress();
        const userPositionContract = provider.open(await UserPosition.fromAddress(userPossitionAddress));
        const state = await userPositionContract.getPositionState();
        return state.collateral;
    };

    console.log(
        '01 | Пользователь вносит залог, создается контракт пользовательской позиции--------------------------------',
    );

    const collateralAmount = toNano(1);
    const currentPositionId = await manager.getLastPositionId();

    await poolContract.send(
        user,
        { value: collateralAmount + toNano(0.3) },
        {
            $$type: 'DepositCollateralUserMessage',
            user: user.address as Address,
            amount: collateralAmount,
        },
    );
    console.log('currentPositionId:', currentPositionId);

    if (currentPositionId <= 0) {
        await timer(`Id последней зарегистрированной позиции:`, currentPositionId, manager.getLastPositionId);
        const userBalanceBefore = await userCollateral();
        await timer(`Баланс залога пользователя`, userBalanceBefore, userCollateral);
    } else {
        const userBalanceBefore = await userCollateral();
        await timer(`Баланс залога пользователя`, userBalanceBefore, userCollateral);
    }
}
