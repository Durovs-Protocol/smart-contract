import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../../utils/helpers';
import { Stable } from '../../wrappers/V1Stable';

describe('DurovUsdcoin', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let stable: SandboxContract<Stable>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        const jettonParams = {
            name: 'yt0.2',
            symbol: 'yt0.2',
            description: 'v0.2',
            image: '',
        };
        deployer = await blockchain.treasury('deployer');

        stable = blockchain.openContract(
            await Stable.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
        );

        const deployResult = await stable.send(
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
            to: stable.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and stable are ready to use
    });
});
