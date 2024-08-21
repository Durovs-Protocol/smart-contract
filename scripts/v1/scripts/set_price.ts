import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { setupGas, tonPrice } from '../../../utils/data';
import { loadAddress, timer } from '../../../utils/helpers';
import { Manager } from '../../../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    let getCurrentTonPrice = async function () {
        return await manager.getTonPrice();
    };

    const newTonPrice = toNano(tonPrice);

    await manager.send(
        provider.sender(),
        { value: toNano(setupGas) },
        {
            $$type: 'UpdateTonPriceMsg',
            price: newTonPrice,
        },
    );
    await timer('Настройка стоимости ton', newTonPrice, getCurrentTonPrice, true);
}
