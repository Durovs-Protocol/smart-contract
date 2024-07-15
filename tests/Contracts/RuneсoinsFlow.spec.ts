import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../../utils/helpers';
import { Runecoin } from '../../wrappers/Runecoin';

import { RunecoinWallet } from '../../wrappers/RunecoinWallet';
import { jettonParams } from '../../utils/data';

describe('RunaCoinOwner', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;

    let runecoinsWallet: SandboxContract<RunecoinWallet>;
    let runecoin: SandboxContract<Runecoin>;

    let totalAmount: bigint;
    let userAmount: bigint;

    beforeAll(async () => {
        const jettonParams = {
            name: 'runa',
            symbol: 'RN',
            description: 'runa',
            image: '',
        };
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        runecoin = blockchain.openContract(
            await Runecoin.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
        );

        runecoinsWallet = blockchain.openContract(
            await RunecoinWallet.fromInit(runecoin.address, deployer.getSender().address),
        );

        // expect(deployOwner.transactions).toHaveTransaction({
        //     from: deployer.address,
        //     to: ,
        //     deploy: true,
        //     success: true,
        // });

        totalAmount = toNano(100);
        userAmount = toNano(50);
    });

    it('runecoin goes to user', async () => {});
});
