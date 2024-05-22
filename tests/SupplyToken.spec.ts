import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { SupplyToken } from '../wrappers/SupplyToken';
import '@ton/test-utils';

describe('SupplyToken', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let supplyToken: SandboxContract<SupplyToken>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        supplyToken = blockchain.openContract(await SupplyToken.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await supplyToken.send(
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
            to: supplyToken.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and supplyToken are ready to use
    });
});
