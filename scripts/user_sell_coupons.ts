import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { gas } from '../utils/data';
import { log, timer } from '../utils/helpers';
import { CouponWallet } from '../wrappers/V1CouponWallet';

export async function run(provider: NetworkProvider) {

    const user = provider.sender();
    const {v1manager, coupon } = await contracts(provider, user.address!!);

    const userWalletAddress = await coupon.getGetWalletAddress(user.address as Address);
    const userWallet = provider.open(await CouponWallet.fromAddress(userWalletAddress));
    const couponAmount = 1 ;

    const balanceBeforeExchange = await userWallet.getGetBalance()
    console.log(balanceBeforeExchange)
    console.log(balanceBeforeExchange - toNano(couponAmount))

    log(`Buy coupons for ${couponAmount.toString()} stables` );

    await v1manager.send(
        user,
        { value: toNano(gas) },
        {
            $$type: 'SellCoupons',
            amount: toNano(couponAmount),
        },
    );



    await timer(`User coupon balance`, balanceBeforeExchange - toNano(couponAmount), userWallet.getGetBalance);

}

