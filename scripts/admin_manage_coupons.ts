import { NetworkProvider } from '@ton/blueprint'
import { toNano } from '@ton/core'
import contracts from '../utils/contracts'
import { setupGas, testCouponsValue } from '../utils/data'
import { log, timer } from '../utils/helpers'

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const {v1manager, coupon } = await contracts(provider, user.address!!);

    log(`Set coupons`);

    await v1manager.send(
        user,
        { value: toNano(setupGas) },
        {
            $$type: 'ManageCoupons',
            type: 'buy',
            amount: toNano(testCouponsValue)
        },
    );
    await timer(`Manager coupons`, toNano(testCouponsValue), v1manager.getCouponsForBuy);
    await v1manager.send(
        user,
        { value: toNano(setupGas) },
        {
            $$type: 'ManageCoupons',
            type: 'sell',
            amount: toNano(testCouponsValue)
        },
    );


    await timer(`Manager coupons`, toNano(testCouponsValue), v1manager.getCouponsForSell);

}
