import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { loadAddress } from '../utils/helpers';
import { tonPrice } from '../utils/data';
import { Address, toNano } from '@ton/core';
import '@ton/test-utils';

import { Manager } from '../wrappers/Manager';

describe('Main', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>; // Пользователь

    let manager: SandboxContract<Manager>;

    beforeAll(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        manager = blockchain.openContract(await Manager.fromInit(Address.parse(await loadAddress('manager'))));
    });

    it('Check update price function', async () => {
        const manager = blockchain.openContract(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
        const launchResult = await manager.send(
            deployer.getSender(),
            { value: toNano('0.1') },
            {
                $$type: 'UpdateTonPriceMsg',
                price: toNano(tonPrice),
            },
        );
        expect(launchResult.transactions).toHaveTransaction({
            // from: manager.address, ???
            to: deployer.address,
            success: true,
        })
    });
});
