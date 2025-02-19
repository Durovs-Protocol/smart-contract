import { NetworkProvider } from '@ton/blueprint'
import { Address, Dictionary, toNano } from '@ton/core'
import contracts from '../utils/contracts'
import { assets, assetsv1, setupGas } from '../utils/data'
import { contractVersion, getBalanceValue, log, timer } from '../utils/helpers'
import { Asset } from '../wrappers/Manager'

export async function run(provider: NetworkProvider) {
    const user = provider.sender().address as Address;
	const {
		reservePool,
		manager,
	    } = await contracts(provider, user)

    const assetsData: Dictionary<Address, Asset> = Dictionary.empty();
    const balancesData: Dictionary<Address, bigint> = Dictionary.empty();

    const localAssets = process.env.v == '0' ? assets : assetsv1


    localAssets.forEach((asset: { name: any; pool_wallet: string; master: string; }) => {
        const assetTemplate: Asset = {
            $$type: 'Asset',
            name: asset.name,
            master: Address.parse(asset.master),
            poolWallet: Address.parse(asset.pool_wallet!!),
          }
        assetsData.set(Address.parse(asset.master), assetTemplate);
        balancesData.set(Address.parse(asset.master), 0n)
    })


    
    async function setAssets(contract: any, name: string) {
        log('\nSet assets in ' + name.toUpperCase() +
        `\n ${await contractVersion(contract, name)}`);

            await contract.send(
                provider.sender(),
                { value: toNano(setupGas) },
                {
                    $$type: 'SetAssets',
                    assets: assetsData,
                },
            );
        await assetTimer(contract, name)
    } 

    async function setBalance(contract: any, name: string) {
        log('\nSet balances template in ' + name.toUpperCase() +
        `\n ${await contractVersion(contract, name)}`);

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
