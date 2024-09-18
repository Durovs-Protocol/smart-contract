import { NetworkProvider } from '@ton/blueprint';
import { toNano } from '@ton/core';
import contracts from '../utils/contracts';
import { setupGas } from '../utils/data';
import { log, timer } from '../utils/helpers';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const {v1manager, coupon } = await contracts(provider, user.address!!);



    const typeOfCOupons = false ? 'sell' : 'buy'
    // const typeOfCOupons = 'sell'
    const testCouponsValue = 10


    log(`Set ${testCouponsValue} coupons with type ${typeOfCOupons}`);

    await v1manager.send(
        user,
        { value: toNano(setupGas) },
        {
            $$type: 'ManageCoupons',
            type: typeOfCOupons,
            // amount: toNano(testCouponsValue)
            //but/sell 
        },
    );



    if (typeOfCOupons == 'buy') {
        await timer(`Manager coupons`, testCouponsValue, v1manager.getCouponsForBuy);
    } else if (typeOfCOupons == 'sell') {
        await timer(`Manager coupons`, testCouponsValue, v1manager.getCouponsForSell);
    }
}
