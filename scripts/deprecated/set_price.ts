import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { gasFee, liquidationTonPrice, tonPrice } from '../utils/data';
import { Manager } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const newTonPrice = toNano(tonPrice);
    // const newTonPrice = toNano(liquidationTonPrice);
    
    let getCurrentTonPrice = async function () {
        return await manager.getTonPrice();
    };

    await manager.send(
        provider.sender(),
        { value: toNano(gasFee) },
        {
            $$type: 'UpdateTonPriceMsg',
            price: newTonPrice,
        },
    );
    await timer(`ton price`, 'Настройка стоимости ton', newTonPrice, getCurrentTonPrice, true);
}
