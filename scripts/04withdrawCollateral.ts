import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/PoolContract';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { UserPositionContract } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    const user = provider.sender();

    const lastPositionId = await manager.getLastPositionId();
    const positionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);
    const positionAddressContract = provider.open(
        await PositionAddressContract.fromAddress(positionAddressContractAddress),
    );

    const userPossitionAddress = await positionAddressContract.getPositionAddress();
    const userPositionContract = provider.open(await UserPositionContract.fromAddress(userPossitionAddress));

    console.log('04 | Возврат залога--------------------------------');

    const collateralToWithdraw = toNano('1');

    const userCollateral = async function () {
        const state = await userPositionContract.getPositionState();
        return state.collateral;
    };
    const collateralBeforeWithdraw = await userCollateral();

    await poolContract.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawCollateralUserMessage',
            user: user.address as Address,
            amount: collateralToWithdraw,
        },
    );

    await timer('Баланс пользователя при возврате залога', collateralBeforeWithdraw, userCollateral);
}
