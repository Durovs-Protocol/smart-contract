import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, toNano } from '@ton/core';
import { assets, gas } from '../utils/data';
import { loadAddress, saveAddress } from '../utils/helpers';
import { V1Manager } from '../wrappers/V1Manager';

export async function run(provider: NetworkProvider) {

    const newManager =provider.open(V1Manager.fromAddress(Address.parse(await loadAddress('manager'))))
    const balancesData: Dictionary<Address, bigint> = Dictionary.empty();

    assets.forEach((asset: { name: any; pool_wallet: string; master: string; }) => {
        balancesData.set(Address.parse(asset.master), 0n)
    })

    await newManager.send(
        provider.sender(),
        {
            value: toNano(gas),
        },
        {
            $$type: 'BuildPosition',
            user: provider.sender().address!!,
            balances: balancesData,
            supplyTimestamps: Dictionary.empty(),
            updatedTimestamps: null,
            withdrawState: Dictionary.empty(),
            lastWithdrawalRequest: 0n,
        },
    );

    const userPosition = await newManager.getUserPositionAddress(provider.sender().address!!)

    await provider.waitForDeploy(userPosition, 30);
    await saveAddress('userPosition', newManager.address);
    console.log('=============================================================================');
    console.log('New Up deployed successfully');
    console.log('=============================================================================');

    // run methods on `manager`
}
