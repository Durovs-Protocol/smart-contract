import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { DurovUsdWallet } from '../../wrappers/V1StableWallet';

describe('DurovUsdcoinWallet', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let stableWallet: SandboxContract<DurovUsdWallet>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        // stableWallet = blockchain.openContract(await DurovUsdWallet.fromInit());

        deployer = await blockchain.treasury('deployer');

        // const deployResult = await stableWallet.send(
        //     deployer.getSender(),
        //     {
        //         value: toNano('0.05'),
        //     },
        //     {
        //         $$type: 'Deploy',
        //         queryId: 0n,
        //     },
        // );

        // expect(deployResult.transactions).toHaveTransaction({
        //     from: deployer.address,
        //     to: stableWallet.address,
        //     deploy: true,
        //     success: true,
        // });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and stableWallet are ready to use
    });
});
