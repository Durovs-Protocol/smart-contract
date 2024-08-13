import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { gasFee, testnetMintAmount, testRunecoinParams } from '../../utils/data';
import { buildOnchainMetadata } from '../../utils/helpers';
import { Runecoin } from '../../wrappers/Runecoin';
import { RunecoinWallet } from '../../wrappers/RunecoinWallet';
import { Manager } from '../../wrappers/v1/Manager';

describe('Runecoin', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let runecoin: SandboxContract<Runecoin>;
    let runecoinWallet: SandboxContract<RunecoinWallet>;
    let manager: SandboxContract<Manager>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        runecoin = blockchain.openContract(
            await Runecoin.fromInit(deployer.getSender().address, buildOnchainMetadata(testRunecoinParams)),
        );
        runecoinWallet = blockchain.openContract(
            await RunecoinWallet.fromInit(deployer.getSender().address, deployer.getSender().address),
        );

        let deployResult = await runecoin.send( deployer.getSender(),
            { value: toNano(gasFee) },
            { $$type: 'Deploy', queryId: 0n }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: runecoin.address,
            deploy: true,
            success: true,
        });
    });

    it('DEX: get test RUNA', async () => {

        // TODO: брать баланс до и после
        await runecoin.send(
            deployer.getSender(),
            { value: toNano(gasFee) },
            {
                $$type: 'DexMessage',
                user: deployer.getSender().address, 
                amount: toNano(testnetMintAmount),
            }
        );

        expect(testnetMintAmount).toEqual(100);

        // await delay(10000);

        // const burnResult = await manager.send(
        //     deployer.getSender(),
        //     {
        //         value: toNano(gasFee),
        //     },
        //     {
        //         $$type: 'BurnUsdTONUserMessage',
        //         user: deployer.getSender().address, 
        //         amount: toNano('1'),
        //     }
        // );
    });
});