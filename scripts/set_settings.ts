import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import {
    burnMin,
    liquidationRatio,
    reserveMin,
    reservePool,
    serviceFee,
    serviceFeePercent,
    setupGas,
} from '../utils/data';
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
        { value: toNano(setupGas) },
        {
            $$type: 'SetSettings',
            reservePool: toNano(reservePool), // 100/80
            reserveMin: toNano(reserveMin), // $
            burnMin: toNano(burnMin), // $
            serviceFeePercent: toNano(serviceFeePercent),
            serviceFee: toNano(serviceFee), // $
            liquidationRatio: toNano(liquidationRatio),
        },
    );

    await timer(`reserve pool`, 'Настройка пула', toNano(1.25), getliquidRatio);
}
