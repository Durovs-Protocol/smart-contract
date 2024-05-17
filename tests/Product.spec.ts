import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { Product } from '../wrappers/Product';

describe('Product', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let product: SandboxContract<Product>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        product = blockchain.openContract(await Product.fromInit(0n));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await product.send(
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
            to: product.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and product are ready to use
    });
});
