import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {

    const user = provider.sender();

    const balance = user.send(
        user,
        { value: toNano(2) },
        {
            $$type: 'DepositCollateralUserMessage',
            user: user.address as Address,
            amount: collateralAmount,
        },
    );
    log(balance);
}
