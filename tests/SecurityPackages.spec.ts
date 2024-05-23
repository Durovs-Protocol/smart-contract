import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { SecurityPackages } from '../wrappers/SecurityPackages';
import '@ton/test-utils';

describe('SecurityPackages', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let securityPackages: SandboxContract<SecurityPackages>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        securityPackages = blockchain.openContract(await SecurityPackages.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await securityPackages.send(
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
            to: securityPackages.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and securityPackages are ready to use
    });
});
