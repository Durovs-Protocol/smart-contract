import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));

    console.log('=============================================================================');
    console.log('04 | Возврат обеспечения');
    console.log('=============================================================================');

    const collateralToWithdraw = toNano(0.5);

    const userCollateral = async function () {
        const state = await userPosition.getPositionState();
        return state.collateral;
    };
    const collateralBeforeWithdraw = await userCollateral();

    await manager.send(
        user,
        { value: toNano(0.05) },
        {
            $$type: 'WithdrawCollateralUserMessage',
            user: user.address as Address,
            amount: collateralToWithdraw,
        },
    );

    await timer('User balance', 'Возврат обеспечения', collateralBeforeWithdraw - collateralToWithdraw, userCollateral);
}
