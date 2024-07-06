import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log, numberFormat } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';
import { Pool } from '../wrappers/Pool';
import { UsdTonMaster } from '../wrappers/UsdTon';

export async function run(provider: NetworkProvider) {
    log('System setting information');

    const runecoinOwner = provider.open(
        await RuneCoinOwner.fromAddress(Address.parse(await loadAddress('runecoin_owner'))),
    );

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    /**
     * Runacoin Owner account depencies
     */
    const usersRuneWalletFromOwnerContract = await runecoinOwner.getRuneInfo(provider.sender().address!);
    const runesAddress = await runecoinOwner.getAddress();
    const totalAmount = await runecoinOwner.getTotalAmount();
    log('Runecoin Owner : ' + usersRuneWalletFromOwnerContract +
        '\nRunecoinAddress: ' + runesAddress+
        '\nBalance        : ' + numberFormat(fromNano(totalAmount)));

    /**
     * Manager account depencies
     */
    const usersRuneWalletFromManagerContract = await manager.getRuneInfo(provider.sender().address!);
    const runesAddressFromManager = await manager.getDeps();
    log('RuneWalletManager      : ' + usersRuneWalletFromManagerContract +
        '\nRunesAddressFromManager: ' + runesAddressFromManager.runecoinAddress);


    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const pool = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));
    
    log('Manager address: ' + manager.address.toString() +
      '\nPool address   : ' + pool.address.toString() +
      '\nusdTon address : ' + usdTon.address.toString());
}
