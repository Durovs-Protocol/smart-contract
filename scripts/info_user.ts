import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/v0.Manager';
import { NewManager } from '../wrappers/v0.NewManager';
import { NewUp } from '../wrappers/v0.NewUp';
import { UserPosition } from '../wrappers/v0.UserPosition';
import { UsdTonMaster } from '../wrappers/v1/UsdTon';
import { UsdTonWallet } from '../wrappers/v1/UsdTonWallet';


export async function run(provider: NetworkProvider) {
    log('User Position info');

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const newManager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('new_manager'))));

    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const user = provider.sender().address as Address;

    /**
     * User position
     */
    const userPositionAddress = await manager.getUserPositionAddress(user);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
    const isActive = await userPosition.getStatus();
    let state = null;
    if (!isActive) {
        console.log('User position migrated', '\n\n');
        const newUserPositionAddress = await newManager.getUserPositionAddress(user);
        const newUserPosition = provider.open(await NewUp.fromAddress(newUserPositionAddress));
        console.log('new user Position address:  ', newUserPosition.address.toString() + '\n\n');
        state = await newUserPosition.getPositionState();
    } else {
        state = await userPosition.getPositionState();
        console.log('User Position address:  ', userPosition.address.toString() + '\n\n');
    }

    let tonPrice = await manager.getTonPrice();

    console.log('Ton price:        ', fromNano(tonPrice).toString());
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

    log('Finished');
}
function toNano(mintAmount: any) {
    throw new Error('Function not implemented.');
}
