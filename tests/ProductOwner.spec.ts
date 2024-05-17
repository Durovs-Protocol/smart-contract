import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { ProductOwner } from '../wrappers/ProductOwner';
import '@ton/test-utils';

describe('ProductOwner', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let productOwner: SandboxContract<ProductOwner>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        productOwner = blockchain.openContract(await ProductOwner.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await productOwner.send(
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
            to: productOwner.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and productOwner are ready to use
    });
});
