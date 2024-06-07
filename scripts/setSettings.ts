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
            liquidationRatio: toNano('1'),
            stabilityFeeRate: 1000000000625n,
            liquidatorIncentiveBps: 10500n,
        },
    );

    const currentliquidRatio = await getliquidRatio();

    await timer(`liquidation ratio:`, currentliquidRatio, getliquidRatio);
}
