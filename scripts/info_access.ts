import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log, numberFormat } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';
import { Pool } from '../wrappers/Pool';
import { UsdTonMaster } from '../wrappers/UsdTon';

/**
 * 
 * @param provider 
 */
export async function run(provider: NetworkProvider) {
    log('System setting information');

    const manager = provider.open(
        await Manager.fromAddress(Address.parse(await loadAddress('manager')))
    )
    const managerOwner = await manager.getOwner();

    const usdTon = provider.open(
        await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon')))
    )
    const usdTonOwner = await usdTon.getOwner();

    const pool = provider.open(
        await Pool.fromAddress(Address.parse(await loadAddress('pool')))
    )
    const poolOwner = await pool.getOwner();

    if(managerOwner.toString() == usdTonOwner.toString() &&  usdTonOwner.toString() == poolOwner.toString()){
        log('Owners of manager, usdTon and pool the same: ' + managerOwner)
    } else {
        log(
            "Owners is not the same" + 
            "\nmanagerOwner: " + managerOwner +
            "\nusdTonOwner:  " + usdTonOwner + 
            "\npoolOwner:    " + poolOwner
        );
    }
}
