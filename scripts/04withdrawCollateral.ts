import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { UserPosition } from '../wrappers/UserPosition';

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
    const userPositionContract = provider.open(await UserPosition.fromAddress(userPossitionAddress));

    console.log('=============================================================================');
    console.log('04 | Возврат обеспечения');
    console.log('=============================================================================');

    const collateralToWithdraw = toNano(1);

    const userCollateral = async function () {
        const state = await userPositionContract.getPositionState();
        return state.collateral;
    };
    const collateralBeforeWithdraw = await userCollateral();

    await poolContract.send(
        user,
        { value: toNano(0.3) },
        {
            $$type: 'WithdrawCollateralUserMessage',
            user: user.address as Address,
            amount: collateralToWithdraw,
        },
    );

    await timer('User balance', 'Возврат обеспечения', collateralBeforeWithdraw - collateralToWithdraw, userCollateral);
}
