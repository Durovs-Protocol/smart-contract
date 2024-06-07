import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, timer } from '../utils/helpers';
import { Pool } from '../wrappers/Pool';

export async function run(provider: NetworkProvider) {
    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    const getliquidRatio = async function () {
        const settings = await poolContract.getPoolSettings();
        return settings.liquidationRatio;
    };

    await poolContract.send(
        provider.sender(),
        { value: toNano('0.3') },
        {
            $$type: 'PoolSettingsMsg',
            liquidationRatio: toNano('1.2'),
            stabilityFeeRate: 1000000000625n,
            liquidatorIncentiveBps: toNano(1.05),
        },
    );

    const liquidRatio = await getliquidRatio();

    await timer(`liquid ratio`, 'Настройка пула', liquidRatio, getliquidRatio);
}
