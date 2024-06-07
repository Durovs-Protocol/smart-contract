import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { PoolContract } from '../wrappers/Pool';

describe('PoolContract', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let poolContract: SandboxContract<PoolContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        poolContract = blockchain.openContract(await PoolContract.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await poolContract.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: poolContract.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and poolContract are ready to use
    });
});
