import { NetworkProvider } from '@ton/blueprint';
import { Address, Dictionary, fromNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Asset, Manager } from '../wrappers/v0.Manager';

import { assets } from '../utils/data';
import { ReservePool } from '../wrappers/v0.ReservePool';
// import { UsdTonMaster } from '../wrappers/v1/UsdTon';

/**
 *
 * @param provider
 */
export async function run(provider: NetworkProvider) {
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const reservePool = provider.open(await ReservePool.fromAddress(Address.parse(await loadAddress('reservePool'))));

    await showPoolWallets(manager, 'manager')
    await showPoolWallets(reservePool, 'reservePool')

    await showDeps(manager, 'manager')
    await showDeps(reservePool, 'reservePool')

    let settings = await manager.getSettings();

    log(
        'System setting information'.toUpperCase() +
        'Reserve pool           :' +
            fromNano(settings.reserveRatio) +
            ' %' +
            '\nReserve min      :' +
            fromNano(settings.reserveMin) +
            ' (ton)' +
            '\nService fee      :' +
            fromNano(settings.serviceFeePercent) +
            ' %' +
            '\nService fee min  :' +
            fromNano(settings.serviceFee) +
            ' $' +
            '\nBurn min         :' +
            fromNano(settings.burnMin) +
            ' (ton)',
    );

    // console.log(await reservePool.getOp())
    // console.log(await reservePool.getMaster())
    // console.log(await reservePool.getPayload())



    async function showPoolWallets(contract: any, name: string) {
        const allAssets: Dictionary<Address, Asset> = await contract.getAssets();
        const stakedTON = allAssets.get(Address.parse(assets[0].master))?.poolWallet.toString()
        const hipoStakedTON = allAssets.get(Address.parse(assets[1].master))?.poolWallet.toString()
        const tonstakers = allAssets.get(Address.parse(assets[2].master))?.poolWallet.toString()
        const toncoin = allAssets.get(Address.parse(assets[3].master))?.poolWallet.toString()
        log(
            `Assets in ${name}`.toUpperCase() +
            'Staked TON pool wallet :    ' +
                stakedTON ?? '' +
                '\nHipo Staked TON pool wallet: ' +
                hipoStakedTON ?? '' +
                '\nTon Stakers pool wallet:       ' +
                tonstakers ?? '' +
                '\nToncoin pool wallet:   ' +
                toncoin ?? ''
        );
    }
    async function showDeps(contract: any, name: string) {
        const deps = await contract.getDeps();

        log(
            `deps in ${name}`.toUpperCase() +
            'manager :    ' +
                deps.manager.toString() +
                '\nreservePool: ' +
                deps.reservePool.toString() +
                '\nprofitPool:       ' +
                deps.profitPool.toString() +
                '\nusdton:   ' +
                deps.usdton.toString()
        );
    }

}
