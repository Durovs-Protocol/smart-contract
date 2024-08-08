import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { burnAmount, gas, serviceFee, serviceFeePercent } from '../utils/data';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();
    const burn = toNano(burnAmount);
    log('03 | Пользователь возвращает usdTon | Burn amount: ' + burn);

    const getDebtBalance = async function () {
        const userPositionAddress = await manager.getUserPositionAddress(user.address as Address);
        const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
        const userPositionState = await userPosition.getPositionState();
        return userPositionState.debt;
    };

    let usdTonBalance = await getDebtBalance();
    //комиссия за операцию
    const fee: number = burnAmount * serviceFeePercent >= serviceFee ? burnAmount * serviceFeePercent : serviceFee;

    console.log('BurnAmount: ', burnAmount);
    console.log('Fee: ', fee);

    await manager.send(
        user,
        { value: toNano(gas + fee) },
        {
            $$type: 'BurnUsdTonMessage',
            amount: burn,
            fee: toNano(fee),
        },
    );

    await timer('User stable balance', 'Погашение задолжности', usdTonBalance - burn, getDebtBalance, true);
}
