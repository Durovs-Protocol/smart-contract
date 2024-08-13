import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { loadAddress, log, timer } from '../utils/helpers';
import { Manager } from '../wrappers/V0.Manager';
import { NewManager } from '../wrappers/V0.NewManager';

export async function run(provider: NetworkProvider) {
    const user = provider.sender();
    const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
    const newManager = provider.open(await NewManager.fromAddress(Address.parse(await loadAddress('new_manager'))));

    log('Миграция up');

    const currentPositionId = await manager.getLastPositionId();
    let errors: Object[] = [];

    for (let i = 1; i < currentPositionId; i++) {
        try {
            await manager.send(
                user,
                { value: toNano(1) },
                {
                    $$type: 'Migration',
                    newManager: newManager.address,
                    id: i,
                },
            );
            await timer(`Position${i} migration process`, i, newManager.getLastPositionId);
        } catch (error) {
            errors.push({
                id: i,
                error: error,
            });
        }
    }

    log(errors.length === 0 ? 'migration complete' : `migration complete with errors: ${errors}`);
}
