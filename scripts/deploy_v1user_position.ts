import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { assets, gas } from '../utils/data';
import { saveAddress } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const {v1manager } = await contracts(provider, user.address!!);

    const balancesData: Dictionary<Address, bigint> = Dictionary.empty();

    assets.forEach((asset: { name: any; pool_wallet: string; master: string; }) => {
        balancesData.set(Address.parse(asset.master), 0n)
    })

    await v1manager.send(
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

    const userPosition = await v1manager.getUserPositionAddress(provider.sender().address!!)

    await provider.waitForDeploy(userPosition, 30);
    await saveAddress('userPosition', v1manager.address);
    console.log('=============================================================================');
    console.log('New Up deployed successfully');
    console.log('=============================================================================');

    // run methods on `manager`
}
