import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { gasFee } from '../utils/data';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    let getliquidRatio = async function () {
        const settings = await manager.getSettings();
        const reservePool = settings.reservePool;
        return reservePool;
    };

    await manager.send(
        provider.sender(),
        { value: toNano(gasFee) },
        {
            $$type: 'SetSettings',
            reservePool: toNano(1.1), // 100/80
            reserveMin: toNano(10), // $
            burnMin: toNano(10), // $
            serviceFeePercent: toNano(0.1),
            serviceFee: toNano(10), // $
            liquidationRatio: toNano(0.9),
        },
    );

    await timer(`reserve pool`, 'Настройка пула', toNano(1.25), getliquidRatio);
}
