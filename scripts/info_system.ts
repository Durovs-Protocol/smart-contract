import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
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
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const profitPool = provider.open(await ProfitPool.fromAddress(Address.parse(await loadAddress('profitPool'))));
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));

    log(
        'Manager:        ' +
            manager.address.toString() +
            '\nprofit pool:  ' +
            profitPool.address.toString() +
            '\nreserve pool: ' +
            reservePool.address.toString() +
            '\nusdTon:       ' +
            usdTon.address.toString(),
    );

    let settings = await manager.getSettings();
    let tonPrice = await manager.getTonPrice();

    log(
        'Reserve pool:    ' +
            fromNano(settings.reserveRatio) +
            ' %' +
            '\nReserve min: ' +
            fromNano(settings.reserveMin) +
            ' (ton)' +
            '\nService fee:       ' +
            fromNano(settings.serviceFeePercent) +
            ' %' +
            '\nService fee min:   ' +
            fromNano(settings.serviceFee) +
            ' $' +
            '\nTon price:         ' +
            fromNano(tonPrice) +
            ' $' +
            '\nBurn min:    ' +
            fromNano(settings.burnMin) +
            ' (ton)',
    );
}
