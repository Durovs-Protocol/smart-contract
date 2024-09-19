import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { couponRate } from '../utils/data';
import { log, saveAddress, timer } from '../utils/helpers';
import { CouponWallet } from '../wrappers/V1CouponWallet';

export async function run(provider: NetworkProvider) {

    const user = provider.sender();
    const {v1manager, coupon } = await contracts(provider, user.address!!);

    const userWalletAddress = await coupon.getGetWalletAddress(user.address as Address);

    const stableAmount = 0.9;
    const checkAmount = stableAmount * couponRate / 1000000000


    log(`Buy coupons for ${stableAmount.toString()} stables` );

    await v1manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'BuyCouponsMessage',
            amount: toNano(stableAmount),
        },
    );

    const userWallet = provider.open(await CouponWallet.fromAddress(userWalletAddress));
    await provider.waitForDeploy(userWalletAddress, 30);
    await saveAddress('user_coupon_wallet', userWallet.address);
    await timer(`User coupon balance`, checkAmount, userWallet.getGetBalance);

}
