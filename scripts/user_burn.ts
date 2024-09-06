import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { mintAmount } from '../utils/data';
import { loadAddress, log } from '../utils/helpers';
import { V1Manager } from '../wrappers/V1Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await V1Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const user = provider.sender();


    log('03 | Пользователь возвращает stable | Burn amount: ' + mintAmount);

    // const getDebtBalance = async function () {
    //TODO переделать после изменения логики добавления задолженности

    //     const userPositionState = await userPosition.getPositionState();
    //     return userPositionState.debt;
    // };

    await manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'BurnStableMessage',
            amount: toNano(mintAmount),
            fee: toNano(0),
        },
    );

}
