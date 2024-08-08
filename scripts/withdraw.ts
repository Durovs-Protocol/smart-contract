import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { gas, withdrawAmount } from '../utils/data';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();
    const withdraw = toNano(withdrawAmount);
    log('03 | Пользователь возвращает залог' + withdrawAmount);

    const getCollateralBalance = async function () {
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
        const userPositionState = await userPosition.getPositionState();
        return userPositionState.collateral;
    };

    let tonBalance = await getCollateralBalance();

    console.log('withdrawAmount: ', withdrawAmount);

    await manager.send(
        user,
        { value: toNano(gas) },
        {
            $$type: 'WithdrawMessage',
            amount: withdraw,
        },
    );

    await timer('User stable balance', 'Погашение задолжности', tonBalance - withdraw, getCollateralBalance, true);
}
