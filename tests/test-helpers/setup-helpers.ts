import { Address, Dictionary, fromNano, toNano } from '@ton/core'
import { SandboxContract } from '@ton/sandbox'
import '@ton/test-utils'
import { assetsv1, couponRate, newManager, unixMaxExecutionTime } from '../../utils/data'
import { Coupon } from '../../wrappers/V1Coupon'
import { Asset, V1Manager } from '../../wrappers/V1Manager'
import { V1ReservePool } from '../../wrappers/V1Pool'
import { Stable } from '../../wrappers/V1Stable'


const localAssets = assetsv1;

export const addressByIndex = (index: number) => Address.parse(localAssets[index]?.master);

export async function checkDeps(props: {
    manager: SandboxContract<V1Manager>;
    pool: SandboxContract<V1ReservePool>;
    stable: SandboxContract<Stable>;
    coupon: SandboxContract<Coupon>;
}) {
    
    async function checkDeps(contract: any, name: string) {
        const deps = await contract.getDeps();
        expect(deps.manager.toString()).toEqual(props.manager.address.toString());
        expect(deps.reservePool.toString()).toEqual(props.pool.address.toString());
        expect(deps.stable.toString()).toEqual(props.stable.address.toString());
    }

    await checkDeps(props.manager, 'manager');
    await checkDeps(props.pool, 'reservePool');
    await checkDeps(props.stable, 'stableContract');
    await checkDeps(props.coupon, 'coupon');
}

export async function checkAssets(props: {
    manager: SandboxContract<V1Manager>;
    pool: SandboxContract<V1ReservePool>;
    stable: SandboxContract<Stable>;
    coupon: SandboxContract<Coupon>;
}) {
    const assetsData: Dictionary<Address, Asset> = Dictionary.empty();
    const balancesData: Dictionary<Address, bigint> = Dictionary.empty();

    localAssets.forEach((asset: { name: any; pool_wallet: string; master: string }) => {
        const assetTemplate: Asset = {
            $$type: 'Asset',
            name: asset.name,
            poolWallet: Address.parse(asset.pool_wallet!!),
            master: Address.parse(asset.master),
        };
        assetsData.set(Address.parse(asset.master), assetTemplate);
        balancesData.set(Address.parse(asset.master), 0n);
    });


    async function checkAssets(contract: any, name: string) {
        const assets = await contract.getAssets();
        expect(JSON.stringify(assets.get(addressByIndex(0)))).toEqual(
            JSON.stringify(assetsData.get(addressByIndex(0))),
        );
        expect(JSON.stringify(assets.get(addressByIndex(1)))).toEqual(
            JSON.stringify(assetsData.get(addressByIndex(1))),
        );
    }

    async function checkBalance(contract: any, name: string) {
        const balances = await contract.getBalances();
        const keysJson = JSON.stringify({
            keys: Array.from(balances._map.keys()),
        });
        expect(keysJson).toContain(balancesData.keys()[0].toString());
    }
    await checkAssets(props.manager, 'manager');
    await checkAssets(props.pool, 'reservePool');
    await checkBalance(props.manager, 'manager');
    await checkBalance(props.pool, 'reservePool');
    await checkBalance(props.coupon, 'coupon');
    await checkBalance(props.stable, 'stable');
}

export async function checkSettings(props: {
    manager: SandboxContract<V1Manager>;
}) {
    const managerSettings = await props.manager.getSettings()
    // expect(managerSettings.minDelay).toEqual(unixDelay);
    expect(managerSettings.newManager.toString()).toMatch(newManager.toString());
    expect(managerSettings.maxExecutionTime).toEqual(unixMaxExecutionTime);
    expect(fromNano(managerSettings.couponRate)).toEqual(couponRate);
}

export async function checkRates(props: {
    manager: SandboxContract<V1Manager>;
    pool: SandboxContract<V1ReservePool>;
    stable: SandboxContract<Stable>;
    coupon: SandboxContract<Coupon>;
}) {
    const rates: Dictionary<Address, bigint> = Dictionary.empty();
    interface RatesData {
        [index: string]: bigint;
    }
    const ratesData: RatesData = {
        stTON: toNano(5.74),
        hTON: toNano(5.36),
        tsTON: toNano(5.73),
        NOT: toNano(1.4),
        DOGS: toNano(1.5),
        TON: toNano(5.5),
    };

    assetsv1.forEach((asset: { name: any; pool_wallet: string; master: string }) => {
        rates.set(Address.parse(asset.master), ratesData[asset.name]);
    });
    const managersRates = await props.manager.getRates();
    expect(managersRates.get(addressByIndex(0))).toEqual(rates.get(addressByIndex(0)));
    expect(managersRates.get(addressByIndex(1))).toEqual(rates.get(addressByIndex(1)));
    expect(managersRates.get(addressByIndex(2))).toEqual(rates.get(addressByIndex(2)));
    expect(managersRates.get(addressByIndex(3))).toEqual(rates.get(addressByIndex(3)));
}