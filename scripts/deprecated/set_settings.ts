import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { gasFee, liquidationFee, liquidationRatio, minHealthRate, stabilityFeeRate } from '../utils/data';
import { loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    let getliquidRatio = async function () {
        const settings = await manager.getPoolSettings();
        const liquidationRatio = settings.liquidationRatio;
        return liquidationRatio;
    };

    await manager.send(
        provider.sender(),
        { value: toNano(gasFee) },
        {
            $$type: 'SetPoolSettings',
            liquidationRatio: toNano(liquidationRatio),
            stabilityFeeRate: toNano(stabilityFeeRate),
            liquidationFee: toNano(liquidationFee),
            minHealthRate: toNano(minHealthRate),
        },
    );

    await timer(`liquid ratio`, 'Настройка пула', toNano(liquidationRatio), getliquidRatio);
}
