import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { UserStablecoinWallet } from '../wrappers/StablecoinWallet';

describe('StablecoinWallet', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let stablecoinWallet: SandboxContract<UserStablecoinWallet>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        // stablecoinWallet = blockchain.openContract(await UserStablecoinWallet.fromInit());

        deployer = await blockchain.treasury('deployer');

        // const deployResult = await stablecoinWallet.send(
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
        //     to: stablecoinWallet.address,
        //     deploy: true,
        //     success: true,
        // });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and stablecoinWallet are ready to use
    });
});
