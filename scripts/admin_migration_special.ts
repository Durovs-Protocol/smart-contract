import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { gas } from '../utils/data';
import { loadAddress, log, saveLog, timer } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { PositionKeeper } from '../wrappers/PositionKeeper';
import { V1Manager } from '../wrappers/V1Manager';
import { V1PositionKeeper } from '../wrappers/V1PositionKeeper';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager', undefined, '0'))));
    const newManager = provider.open(await V1Manager.fromAddress(Address.parse(await loadAddress('manager', undefined, '1'))));

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
                { value: toNano(gas) },
                {
                    $$type: 'Migration',
                    id: BigInt(specialId)
                },
            );
            await timer(`Position${specialId} migration process`, specialId, newManager.getLastPositionId);

            const V1PositionKeeperAddress = await newManager.getPositionKeeper(BigInt(specialId))
            const v1PositionKeeper = provider.open(await V1PositionKeeper.fromAddress(V1PositionKeeperAddress));
            const userAddressFromUpdatedContract = await v1PositionKeeper.getUser()
            const updatedPositionAddress = await v1PositionKeeper.getPosition()

            await saveLog(logName, `Migration complete: \n user from old position: ${userAddress};\noldPosition: ${positionAddress};
                \nuser from new position: ${userAddressFromUpdatedContract}; \nnewPosition: ${updatedPositionAddress}`)
        } catch (error) {
            await saveLog(logName, `Migration complete with errors:\nUser address: ${userAddress}; \nPosition: ${positionAddress}; \n Error: ${error}`)
        }

}
