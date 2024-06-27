import { NetworkProvider } from '@ton/blueprint';
import { Address, fromNano } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { Pool } from '../wrappers/Pool';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { UsdTonMaster } from '../wrappers/UsdTon';
import { UserPosition } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    console.log('| User info:');
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const lastPositionId = await manager.getLastPositionId();
    const positionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);
    const stablecoin = provider.open(await UsdTonMaster.fromAddress(Address.parse(await loadAddress('stablecoin'))));
    const user = provider.sender().address as Address;

    const poolContract = provider.open(await Pool.fromAddress(Address.parse(await loadAddress('pool_contract'))));

    const positionAddressContract = provider.open(
        await PositionAddressContract.fromAddress(positionAddressContractAddress),
    );
    let userPossitionAddress = await positionAddressContract.getPositionAddress();

    const userPositionContract = provider.open(await UserPosition.fromAddress(userPossitionAddress));

    const state = await userPositionContract.getPositionState();

    console.log('----TON supply:', fromNano(state.collateral).toString());
    console.log('----usdTON borrow:', fromNano(state.debt).toString());

    // const managerDeps = await manager.getDeps();
    // console.log('managerDeps', managerDeps);

    // const stablecoinDeps = await stablecoin.getDeps();
    // console.log('stablecoinDeps', stablecoinDeps);

    // const poolContractDeps = await poolContract.getDeps();
    // console.log('poolContractDeps', poolContractDeps);
}
