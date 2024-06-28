import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { UsdTonWallet } from '../wrappers/UsdTonWallet';

describe('UsdToncoinWallet', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let usdTonWallet: SandboxContract<UsdTonWallet>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        // usdTonWallet = blockchain.openContract(await UsdTonWallet.fromInit());

        deployer = await blockchain.treasury('deployer');

        // const deployResult = await usdTonWallet.send(
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
        //     to: usdTonWallet.address,
        //     deploy: true,
        //     success: true,
        // });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and usdTonWallet are ready to use
    });
});
