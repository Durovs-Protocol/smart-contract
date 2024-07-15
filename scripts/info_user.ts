import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    log('User info');

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));

    const user = provider.sender().address as Address;
    const userPositionAddress = await manager.getUserPositionAddress(user);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
    const state = await userPosition.getPositionState();

    const userUsdTonWalletAddress = await usdTon.getGetWalletAddress(user);

    console.log('UserUsdTonWalletAddress: ' + userUsdTonWalletAddress);
    console.log('User Position address:  ', userPosition.address.toString() + '\n\n');
    const userUsdTonWallet = provider.open(await UsdTonWallet.fromAddress(userUsdTonWalletAddress));

    console.log('Supply in TON:    ', fromNano(state.collateral).toString());
    console.log('Borrow by UP:     ', fromNano(state.debt).toString());
    try {
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
function toNano(mintNormal: any) {
    throw new Error('Function not implemented.');
}
