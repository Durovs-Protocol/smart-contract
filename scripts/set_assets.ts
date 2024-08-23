import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, toNano } from '@ton/core';
import { assets, setupGas } from '../utils/data';
import { getBalanceValue, loadAddress, log, timer } from '../utils/helpers';
import { Asset, Manager } from '../wrappers/V0.Manager';
// import { UsdTonMaster } from '../wrappers/v1/UsdTon';
//переделать инит каким-то образом
import { ReservePool } from '../wrappers/V0.ReservePool';

export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));

    const assetsData: Dictionary<Address, Asset> = Dictionary.empty();
    const balancesData: Dictionary<Address, bigint> = Dictionary.empty();
    assets.forEach((asset) => {
        const assetTemplate: Asset = {
            $$type: 'Asset',
            name: asset.name,
            poolWallet: Address.parse(asset.pool_wallet),
            op_code: 0n
          }
        assetsData.set(Address.parse(asset.master), assetTemplate);
        balancesData.set(Address.parse(asset.master), 0n)
    })

    async function setAssets(contract: any, name: string) {
        log('Set assets in ' + name.toUpperCase());

            await contract.send(
                provider.sender(),
                { value: toNano(setupGas) },
                {
                    $$type: 'SetAssets',
                    assets: assetsData,
                },
            );
        // await assetTimer(contract, name)
    } 

    async function setBalance(contract: any, name: string) {
        log('Set balances template in ' + name.toUpperCase());
            await contract.send(
                provider.sender(),
                { value: toNano(setupGas) },
                {
                    $$type: 'SetBalances',
                    balances: balancesData,
                },
            );
            await balancesTimer(contract, name)
    }

    await setAssets(manager, 'manager');
    await setAssets(reservePool, 'reservePool');
    await setBalance(manager, 'manager');
    await setBalance(reservePool, 'reservePool');
}

const getAssetName = function (contract: any, index: number) {
    return async function () {
        const allAssets = await contract.getAssets();
         return (allAssets.get(Address.parse(assets[index].master)))?.name
    };
};



async function assetTimer(contract: any, name: string) {
    for (let i = 0; i < assets.length; i++) {
        const currentName = assets[i].name
        await timer(`Set assets in ${name}`, currentName, getAssetName(contract, i));
    }
}
async function balancesTimer(contract: any, name: string) {
    for (let i = 0; i < assets.length; i++) {
        await timer(`Set balance in ${name}`, 0n, getBalanceValue(contract, i));
    }
}

