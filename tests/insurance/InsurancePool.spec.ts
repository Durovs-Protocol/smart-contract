import { Address, toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { InsurancePool } from '../../wrappers/insurance/InsurancePool';

describe('InsurancePool', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let insurancePool: SandboxContract<InsurancePool>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        insurancePool = blockchain.openContract(await InsurancePool.fromAddress(Address.parse('EQDMIjPdVwqre3TVNL_imU2eX281SfcmnQAXPU1KBkWDULl5')));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await insurancePool.send(
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
            to: insurancePool.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and insurancePool are ready to use
    });
});
