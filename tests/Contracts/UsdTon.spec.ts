import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../../utils/helpers';
import { UsdTonMaster } from '../../wrappers/v1/UsdTon';

describe('UsdToncoin', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let usdTon: SandboxContract<UsdTonMaster>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        const jettonParams = {
            name: 'yt0.2',
            symbol: 'yt0.2',
            description: 'v0.2',
            image: '',
        };
        deployer = await blockchain.treasury('deployer');

        usdTon = blockchain.openContract(
            await UsdTonMaster.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
        );

        const deployResult = await usdTon.send(
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
            to: usdTon.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and usdTon are ready to use
    });
});
