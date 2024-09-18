import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { couponJettonParams, setupGas } from '../utils/data';
import { buildOnchainMetadata, saveAddress } from '../utils/helpers';
import { Coupon } from '../wrappers/V1Coupon';

export async function run(provider: NetworkProvider) {
    const owner = provider.sender().address as Address;
    const coupon = provider.open(await Coupon.fromInit(owner, buildOnchainMetadata(couponJettonParams)));

    await coupon.send(
        provider.sender(),
        {
            value: toNano(setupGas),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(coupon.address, 30);
    await saveAddress('coupon', coupon.address, undefined, '1');
    console.log('=============================================================================');
    console.log('Coupon deployed successfully');
    console.log('=============================================================================');
    // run methods on `stable`
}
