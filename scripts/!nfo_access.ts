import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { ProfitPool } from '../wrappers/ProfitPool';
import { ReservePool } from '../wrappers/ReservePool';
import { UsdTonMaster } from '../wrappers/UsdTon';

/**
 *
 * @param provider
 */
export async function run(provider: NetworkProvider) {
    log('System setting information');

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const managerOwner = await manager.getOwner();

    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const usdTonOwner = await usdTon.getOwner();

    const profitPool = provider.open(await ProfitPool.fromAddress(Address.parse(await loadAddress('profitPool'))));
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));
    const profitPoolOwner = await profitPool.getOwner();
    const reservePoolOwner = await reservePool.getOwner();

    if (
        managerOwner.toString() == usdTonOwner.toString() &&
        usdTonOwner.toString() == profitPoolOwner.toString() &&
        profitPoolOwner.toString() == reservePoolOwner.toString()
    ) {
        log('Owners of manager, usdTon and pools the same: ' + managerOwner);
    } else {
        log(
            'Owners is not the same' +
                '\nmanagerOwner: ' +
                managerOwner +
                '\nusdTonOwner:  ' +
                usdTonOwner +
                '\nprofitpool owner:    ' +
                profitPoolOwner +
                '\nreservepool owner:    ' +
                reservePoolOwner,
        );
    }
}
