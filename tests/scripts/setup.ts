import { Address, Dictionary, toNano } from '@ton/core'
import { SandboxContract, TreasuryContract } from '@ton/sandbox'
import '@ton/test-utils'
import { assetsv1, couponRate, newManager, unixMaxExecutionTime } from '../../utils/data'
import { Asset } from '../../wrappers/Manager'
import { Coupon } from '../../wrappers/V1Coupon'
import { V1Manager } from '../../wrappers/V1Manager'
import { V1ReservePool } from '../../wrappers/V1Pool'
import { Stable } from '../../wrappers/V1Stable'




export default async function setup(props: {
    deployer: SandboxContract<TreasuryContract>;
    manager: SandboxContract<V1Manager>;
    pool: SandboxContract<V1ReservePool>;
    stable: SandboxContract<Stable>;
    coupon: SandboxContract<Coupon>;
}) {
    const localAssets = assetsv1;


    /* ==set deps== */
    async function setDeps(contract: any, name: string) {
        await contract.send(
            props.deployer.getSender(),
            { value: toNano(0.3) },
            {
                $$type: 'SetDeps',
                manager: props.manager.address,
                profitPool: props.pool.address,
                reservePool: props.pool.address,
                stable: props.stable.address,
                coupon: props.stable.address,
            },
        );
    }
    await setDeps(props.manager, 'manager');
    await setDeps(props.pool, 'reservePool');
    await setDeps(props.stable, 'stableContract');
    await setDeps(props.coupon, 'coupon');

    /* ==set settings== */


    await props.manager.send(
        props.deployer.getSender(),
        { value: toNano(0.3) },
        {
            $$type: 'SetSettings',
            minDelay: 0n,
            newManager: newManager,
            maxExecutionTime: unixMaxExecutionTime,
            couponRate: toNano(couponRate),
        },
    );

    /* ==set assets== */
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


    async function setAssets(contract: any, name: string) {
        await contract.send(
            props.deployer.getSender(),
            { value: toNano(0.3) },
            {
                $$type: 'SetAssets',
                assets: assetsData,
            },
        );
    }

    async function setBalance(contract: any, name: string) {
        await contract.send(
            props.deployer.getSender(),
            { value: toNano(0.3) },
            {
                $$type: 'SetBalances',
                balances: balancesData,
            },
        );
    }

    await setAssets(props.manager, 'manager');
    await setAssets(props.pool, 'reservePool');
    await setBalance(props.manager, 'manager');
    await setBalance(props.pool, 'reservePool');
    await setBalance(props.coupon, 'coupon');
    await setBalance(props.stable, 'stable');


    /* ==set rates== */
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

    await props.manager.send(
        props.deployer.getSender(),
        { value: toNano(0.3) },
        {
            $$type: 'SetRates',
            rates: rates,
        },
    );
}
