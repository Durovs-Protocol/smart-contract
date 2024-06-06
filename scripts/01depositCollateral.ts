import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/PoolContract';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { UserPositionContract } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    const user = provider.sender();

    console.log(
        '01 | Пользователь вносит залог, создается контракт пользовательской позиции--------------------------------',
    );

    const collateralAmount = toNano(1);
    const currentPositionId = await manager.getLastPositionId();

    await poolContract.send(
        user,
        { value: collateralAmount + toNano(0.5) },
        {
            $$type: 'DepositCollateralUserMessage',
            user: user.address as Address,
            amount: collateralAmount,
        },
    );

    //     await timer(`Id последней зарегистрированной позиции:`, currentPositionId, manager.getLastPositionId);

    console.log('01 | info:');
    const lastPositionId = await manager.getLastPositionId();
    const positionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);
    console.log('----адрес контракта хранящего адрес позиции пользователя:', positionAddressContractAddress);

    const positionAddressContract = provider.open(
        await PositionAddressContract.fromAddress(positionAddressContractAddress),
    );
    let userPossitionAddress = await positionAddressContract.getPositionAddress();
    console.log('----адрес контракта позиции пользователя:', userPossitionAddress);

    const userPositionContract = provider.open(await UserPositionContract.fromAddress(userPossitionAddress));
    const state = await userPositionContract.getPositionState();

    console.log('----Баланс пользователя:', state.collateral);
}
