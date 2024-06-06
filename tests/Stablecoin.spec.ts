import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { Stablecoin } from '../wrappers/Stablecoin';
import '@ton/test-utils';

describe('Stablecoin', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let stablecoin: SandboxContract<Stablecoin>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        stablecoin = blockchain.openContract(await Stablecoin.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await stablecoin.send(
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
            to: stablecoin.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and stablecoin are ready to use
    });
});
