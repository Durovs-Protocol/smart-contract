import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log, saveLog, timer } from '../utils/helpers';
import { Manager } from '../wrappers/V0.Manager';
import { NewManager } from '../wrappers/V0.NewManager';
import { NewPositionKeeper } from '../wrappers/V0.NewPositionKeeper';
import { PositionKeeper } from '../wrappers/V0.PositionKeeper';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager', undefined, '0'))));
    const newManager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('manager', undefined, '1'))));
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
                    newManager: newManager.address,
                    id: BigInt(i),
                },
            );
            // удали newManager

            await timer(`Position${i} migration process`, i, newManager.getLastPositionId);

            const newPositionKeeperAddress = await newManager.getPositionKeeper(BigInt(i))
            const newPositionKeeper = provider.open(await NewPositionKeeper.fromAddress(newPositionKeeperAddress));

            await provider.waitForDeploy(newPositionKeeper.address, 30);

            const userAddressFromUpdatedContract = await newPositionKeeper.getUser()
            const updatedPositionAddress = await newPositionKeeper.getPosition()

            await saveLog(`migration_${i}`, `Migration complete: \n user from old position: ${userAddress};\noldPosition: ${positionAddress};
                \nuser from new position: ${userAddressFromUpdatedContract}; \nnewPosition: ${updatedPositionAddress}`)
        } catch (error) {
            await saveLog(`migration_${i}`, `Migration complete with errors:\nUser address: ${userAddress}; \nPosition: ${positionAddress}; \n Error: ${error}`)
        }
    }
}
