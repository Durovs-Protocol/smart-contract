import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { UserPosition } from '../wrappers/UserPosition';
import '@ton/test-utils';

describe('UserPosition', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let userPosition: SandboxContract<UserPosition>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        userPosition = blockchain.openContract(await UserPosition.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await userPosition.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: userPosition.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and userPosition are ready to use
    });
});
