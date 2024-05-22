import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { ProductOwner } from '../../wrappers/insurance/ProductOwner';

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

    it('should create product', async () => {
        const createProduct = await productOwner.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            {
                $$type: 'CreateProduct',
                name: 'Product name',
                description: 'Description',
            }
        );
        expect(createProduct.transactions).toHaveTransaction({
            from: deployer.address,
            to: productOwner.address,
            success: true,
            outMessagesCount: 1
        });
    });
});
