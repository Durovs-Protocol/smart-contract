import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { UsdTonMaster } from '../wrappers/UsdTon';

/**
 *
 * @param provider
 */
export async function run(provider: NetworkProvider) {
    log('System setting information');

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    /**
     * Manager account depencies
     */
    const usersRuneWalletFromManagerContract = await manager.getRuneInfo(provider.sender().address!);
    const runesAddressFromManager = await manager.getDeps();
    log(
        'RuneWalletManager      : ' +
            usersRuneWalletFromManagerContract +
            '\nRunesAddressFromManager: ' +
            runesAddressFromManager.runecoinAddress,
    );

    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const pool = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    log(
        'Manager address: ' +
            manager.address.toString() +
            '\nPool address   : ' +
            pool.address.toString() +
            '\nusdTon address : ' +
            usdTon.address.toString(),
    );
}
