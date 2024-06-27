import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { buildOnchainMetadata } from '../utils/helpers';
import { Runecoin } from '../wrappers/Runecoin';
import { RuneCoinOwner } from '../wrappers/RunecoinOwner';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

describe('RunaCoinOwner', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let runecoinOwner: SandboxContract<RuneCoinOwner>;
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
        runecoinOwner = blockchain.openContract(await RuneCoinOwner.fromInit(deployer.getSender().address));
        runecoin = blockchain.openContract(
            await Runecoin.fromInit(runecoinOwner.address, buildOnchainMetadata(jettonParams)),
        );

        runecoinsWallet = blockchain.openContract(
            await RunecoinWallet.fromInit(runecoin.address, deployer.getSender().address),
        );

        const deployOwner = await runecoinOwner.send(
            deployer.getSender(),
            {
                value: toNano('1'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployOwner.transactions).toHaveTransaction({
            from: deployer.address,
            to: runecoinOwner.address,
            deploy: true,
            success: true,
        });

        totalAmount = toNano(100);
        userAmount = toNano(50);
    });

    it('runecoins goes to owner', async () => {
        const balanceBefore = await runecoinOwner.getTotalAmount();

        const jettonParams = {
            name: 'runa',
            symbol: 'RN',
            description: 'runa',
            image: '',
        };
        await runecoinOwner.send(
            deployer.getSender(),
            {
                value: toNano(1),
            },
            {
                $$type: 'SetBalance',
                amount: totalAmount,
                content: buildOnchainMetadata(jettonParams),
            },
        );
        const balanceAfter = await runecoinOwner.getTotalAmount();
        // expect(balanceAfter).toBeGreaterThan(balanceBefore);
        expect(balanceAfter).toEqual(balanceBefore + totalAmount);
    });

    it('runecoin goes to user', async () => {
        const balanceBefore = await runecoinOwner.getTotalAmount();

        await runecoinOwner.send(
            deployer.getSender(),
            { value: toNano(1) },
            {
                $$type: 'GetRunecoin',
                amount: userAmount,
                user: deployer.getSender().address,
            },
        );
        const balanceAfter = await runecoinOwner.getTotalAmount();
        expect(balanceAfter).toEqual(balanceBefore - userAmount);
    });
});
