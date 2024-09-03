import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { mintAmount } from '../utils/data';
import { loadAddress, log } from '../utils/helpers';
import { NewManager } from '../wrappers/V0.NewManager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();


    log('03 | Пользователь возвращает usdTon | Burn amount: ' + mintAmount);

    // const getDebtBalance = async function () {
    //TODO переделать после изменения логики добавления задолженности

    //     const userPositionState = await userPosition.getPositionState();
    //     return userPositionState.debt;
    // };

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'BurnDurovUSDMessage',
            amount: toNano(mintAmount),
            fee: toNano(0),
        },
    );

}
