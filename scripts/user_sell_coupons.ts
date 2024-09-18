import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { couponRate } from '../utils/data';
import { log, timer } from '../utils/helpers';
import { CouponWallet } from '../wrappers/V1CouponWallet';

export async function run(provider: NetworkProvider) {

    const user = provider.sender();
    const {v1manager, coupon } = await contracts(provider, user.address!!);

    const userWalletAddress = await coupon.getGetWalletAddress(user.address as Address);
    const userWallet = provider.open(await CouponWallet.fromAddress(userWalletAddress));
    const couponAmount = 0.5 * couponRate;

    const balanceBeforeExchange = Number(await userWallet.getGetBalance())

    log(`Buy coupons for ${couponAmount.toString()} stables` );

    await v1manager.send(
        user,
        { value: toNano(1) },
        {
            $$type: 'SellCoupons',
            amount: toNano(couponAmount),
        },
    );



    await timer(`User coupon balance`, balanceBeforeExchange - couponAmount, userWallet.getGetBalance);

}

