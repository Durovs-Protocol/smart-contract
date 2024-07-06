import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress, log } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    log('User position info');

    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));

    const user = provider.sender().address as Address;
    const userPositionAddress = await manager.getUserPositionAddress(user);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
    const state = await userPosition.getPositionState();


    console.log('Supply         in TON:',   fromNano(state.collateral).toString());
    console.log('Borrow         usdTON:',   fromNano(state.debt).toString());
    console.log('User Position address:',   userPosition.address.toString());

    log('Wallet dependencies');

    // const managerDeps = await manager.getDeps();
    // console.log('managerDeps', managerDeps);

    // const usdTonDeps = await usdTon.getDeps();
    // console.log('usdTonDeps', usdTonDeps);

    // const poolContractDeps = await pool.getDeps();
    // console.log('poolContractDeps', poolContractDeps);

    // console.log('=============================================================================\n\n');
}
