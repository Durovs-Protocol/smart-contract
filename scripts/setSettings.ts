import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    let getliquidRatio = async function () {
        const settings = await poolContract.getPoolSettings();
        const liquidationRatio = settings.liquidationRatio;
        return liquidationRatio;
    };

    const newLiquidationRatio = toNano(2);
    const newLiquidatorIncentiveBps = toNano(1.6);

    await poolContract.send(
        provider.sender(),
        { value: toNano('0.3') },
        {
            $$type: 'PoolSettingsMsg',
            liquidationRatio: newLiquidationRatio,
            stabilityFeeRate: toNano('0.02'),
            liquidatorIncentiveBps: newLiquidatorIncentiveBps,
        },
    );

    await timer(`liquid ratio`, 'Настройка пула', newLiquidationRatio, getliquidRatio);
}
