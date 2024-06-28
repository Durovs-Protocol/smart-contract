import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    console.log('| User info:');
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const usdTon = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('usdTon'))));
    const pool = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool'))));

    const user = provider.sender().address as Address;
    const userPositionAddress = await manager.getUserPositionAddress(user);
    const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
    const state = await userPosition.getPositionState();

    console.log('----TON supply:', fromNano(state.collateral).toString());
    console.log('----usdTON borrow:', fromNano(state.debt).toString());

    const managerDeps = await manager.getDeps();
    console.log('managerDeps', managerDeps);

    const usdTonDeps = await usdTon.getDeps();
    console.log('usdTonDeps', usdTonDeps);

    const poolContractDeps = await pool.getDeps();
    console.log('poolContractDeps', poolContractDeps);
}
