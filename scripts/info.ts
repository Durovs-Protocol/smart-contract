import { NetworkProvider } from '@ton/blueprint';
import { Address } from '@ton/core';
import { loadAddress } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { PositionAddressContract } from '../wrappers/PositionAddress';
import { UserPositionContract } from '../wrappers/UserPosition';

export async function run(provider: NetworkProvider) {
    console.log('| User info:');
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const lastPositionId = await manager.getLastPositionId();
    const positionAddressContractAddress = await manager.getUserPositionAddressById(lastPositionId);

    const positionAddressContract = provider.open(
        await PositionAddressContract.fromAddress(positionAddressContractAddress),
    );
    let userPossitionAddress = await positionAddressContract.getPositionAddress();

    const userPositionContract = provider.open(await UserPositionContract.fromAddress(userPossitionAddress));
    const state = await userPositionContract.getPositionState();

    console.log('----collateral:', state.collateral);
    console.log('----debt:', state.debt);
}
