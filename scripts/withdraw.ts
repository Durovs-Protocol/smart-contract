import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { assets } from '../utils/data';
import { getBalanceValue, loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/V0.Manager';
import { UserPosition } from '../wrappers/V0.UserPosition';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const userPositionAddress = await manager.getUserPositionAddress(user.address!!);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));

    const withdrawAmount = 1;
    log('03 | Пользователь возвращает залог ' + withdrawAmount);
    
    //3 ton 0 jetton
    const assetIndex = 3

    let oldBalance = 0n
    try {
        oldBalance =  await (await getBalanceValue(userPosition, assetIndex))()
    } catch(e) {}
    let balanceAfterWithdraw = oldBalance - toNano(withdrawAmount)

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'WithdrawMessage',
            amount: toNano(withdrawAmount),
            master: Address.parse(assets[assetIndex].master)
        },
    );
    await timer(`'Погашение задолжности: баланс ${withdrawAmount} ${assets[assetIndex].name} `, balanceAfterWithdraw, getBalanceValue(userPosition, assetIndex));

}


