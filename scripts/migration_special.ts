import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log, saveLog, timer } from '../utils/helpers';
import { Manager } from '../wrappers/V0.Manager';
import { NewManager } from '../wrappers/V0.NewManager';
import { NewPositionKeeper } from '../wrappers/V0.NewPositionKeeper';
import { PositionKeeper } from '../wrappers/V0.PositionKeeper';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const newManager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('new_manager'))));


    log('Миграция конркетной up');

    const specialId: number = 1;

    const logName: string = `migration_${specialId}_attempt_${2}`;



        const positionKeeperAddress = await manager.getPositionKeeper(BigInt(specialId))
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
                    id: BigInt(specialId)
                },
            );
            await timer(`Position${specialId} migration process`, specialId, newManager.getLastPositionId);

            const newPositionKeeperAddress = await newManager.getPositionKeeper(BigInt(specialId))
            const newPositionKeeper = provider.open(await NewPositionKeeper.fromAddress(newPositionKeeperAddress));
            const userAddressFromUpdatedContract = await newPositionKeeper.getUser()
            const updatedPositionAddress = await newPositionKeeper.getPosition()

            await saveLog(logName, `Migration complete: \n user from old position: ${userAddress};\noldPosition: ${positionAddress};
                \nuser from new position: ${userAddressFromUpdatedContract}; \nnewPosition: ${updatedPositionAddress}`)
        } catch (error) {
            await saveLog(logName, `Migration complete with errors:\nUser address: ${userAddress}; \nPosition: ${positionAddress}; \n Error: ${error}`)
        }

}
