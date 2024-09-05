import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log, saveLog, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { PositionKeeper } from '../wrappers/PositionKeeper';
import { V1Manager } from '../wrappers/V1Manager';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager', undefined, '0'))));
    const newManager = provider.open(await V1Manager.fromAddress(Address.parse(await loadAddress('manager', undefined, '1'))));
    log('Миграция up');

    const currentPositionId = await manager.getLastPositionId();

    for (let i = 1; i <= currentPositionId; i++) {
        const positionKeeperAddress = await manager.getPositionKeeper(BigInt(i))
        const positionKeeper = provider.open(await PositionKeeper.fromAddress(positionKeeperAddress));
        const userAddress = await positionKeeper.getUser()
        const positionAddress = await positionKeeper.getPosition()

        try {
            await manager.send(
                user,
                { value: toNano(1) },
                {
                    $$type: 'Migration',
                    id: BigInt(i),
                },
            );

            await timer(`Position${i} migration process`, i, newManager.getLastPositionId);

            const V1PositionKeeperAddress = await newManager.getPositionKeeper(BigInt(i))
            const V1PositionKeeper = provider.open(await V1PositionKeeper.fromAddress(V1PositionKeeperAddress));

            await provider.waitForDeploy(V1PositionKeeper.address, 30);

            const userAddressFromUpdatedContract = await V1PositionKeeper.getUser()
            const updatedPositionAddress = await V1PositionKeeper.getPosition()

            await saveLog(`migration_${i}`, `Migration complete: \n user from old position: ${userAddress};\noldPosition: ${positionAddress};
                \nuser from new position: ${userAddressFromUpdatedContract}; \nnewPosition: ${updatedPositionAddress}`)
        } catch (error) {
            await saveLog(`migration_${i}`, `Migration complete with errors:\nUser address: ${userAddress}; \nPosition: ${positionAddress}; \n Error: ${error}`)
        }
    }
}
