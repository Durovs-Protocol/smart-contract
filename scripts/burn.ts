import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { burnAmount } from '../utils/data';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();

    log('03 | Пользователь возвращает usdTon | Burn amount: ' + burnAmount);

    const getDebtBalance = async function () {
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
        const userPositionState = await userPosition.getPositionState();
        return userPositionState.debt;
    };

    let usdTonBalance = await getDebtBalance();
    //комиссия за операцию
    const fee: number = (burnAmount * 0.01 >= 10 ? burnAmount * 0.01 : 10) / 7.5;

    await manager.send(
        user,
        { value: toNano(1 + fee) },
        {
            $$type: 'BurnUsdTONUserMessage',
            user: user.address as Address,
            amount: toNano(8.8),
            fee: toNano(fee),
        },
    );

    await timer(
        'User stable balance',
        'Погашение задолжности',
        usdTonBalance - toNano(burnAmount),
        getDebtBalance,
        true,
    );
}
