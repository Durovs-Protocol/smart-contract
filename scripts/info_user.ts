import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    log('User Position info');

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const user = provider.sender().address as Address;

    /**
     * User position
     */
    const userPositionAddress = await manager.getUserPositionAddress(user);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
    const state = await userPosition.getPositionState();
    console.log('User Position address:  ', userPosition.address.toString() + '\n\n');

    let tonPrice = await manager.getTonPrice();
    // let healthRate = tonPrice * state.collateral/state.debt;
    // TODO исправить при / на 0

    console.log('Ton price:        ', fromNano(tonPrice).toString());
    // console.log('Health Rate:      ', fromNano(healthRate).toString());
    console.log('\nSupply in TON:    ', fromNano(state.collateral).toString());
    console.log('Borrow by UP:     ', fromNano(state.debt).toString());

    try {
        const userUsdTonWalletAddress = await usdTon.getGetWalletAddress(user);
        const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdTonWalletAddress));

        const userUsdTonBalance = await userUsdTonWallet.getGetBalance();
        console.log('Borrow by wallet: ', fromNano(userUsdTonBalance).toString());
    } catch (e) {
        console.log('Borrow by wallet: no data');
    }

    /**
     * Также выводить тут баланс с userUsdTonWalletAddress
     */

    // let usdTonBalance = await userUsdTon.getGetBalance()

    // console.log(userUsdTonWalletAddress);

    log('Finished');

    // const managerDeps = await manager.getDeps();
    // console.log('managerDeps', managerDeps);

    // const usdTonDeps = await usdTon.getDeps();
    // console.log('usdTonDeps', usdTonDeps);

    // const poolContractDeps = await pool.getDeps();
    // console.log('poolContractDeps', poolContractDeps);

    // console.log('=============================================================================\n\n');
}
function toNano(mintAmount: any) {
    throw new Error('Function not implemented.');
}
