import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { runaUSDCouponParams, setupGas } from '../../../utils/data';
import { buildOnchainMetadata, saveAddress } from '../../../utils/helpers';
import { RunaCoupon } from '../../../wrappers/RunaCoupon';

export async function run(provider: NetworkProvider) {
    const owner = provider.sender().address as Address;
    const coupon = provider.open(await RunaCoupon.fromInit(owner, buildOnchainMetadata(runaUSDCouponParams)));

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
    await saveAddress('runaUSDCoupon', coupon.address);
    console.log('=============================================================================');
    console.log('Usd on runaUSDCoupon deployed successfully');
    console.log('=============================================================================');
}
