import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, toNano } from '@ton/core';
import { Manager } from '../../wrappers/Manager';
import { Runecoin } from '../../wrappers/Runecoin';
import '@ton/test-utils';

import { jettonParams } from '../../utils/data';
import { buildOnchainMetadata, saveAddress } from '../../utils/helpers';
import { RuneInfo } from '../../wrappers/RuneInfo';

describe('Runacoin', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;

    let manager: SandboxContract<Manager>;
    let runecoin: SandboxContract<Runecoin>;
    let runeInfo: SandboxContract<RuneInfo>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        manager = blockchain.openContract(await Manager.fromInit(deployer.getSender().address));
        runecoin = blockchain.openContract(
            await Runecoin.fromInit(deployer.getSender().address, buildOnchainMetadata(jettonParams)),
        );
        runeInfo = blockchain.openContract(await RuneInfo.fromInit(deployer.getSender().address as Address));

        let deployResult = await manager.send( deployer.getSender(),
            { value: toNano('0.05') },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: manager.address,
            deploy: true,
            success: true,
        });

        deployResult = await runecoin.send( deployer.getSender(),
            { value: toNano('0.05') },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: runecoin.address,
            deploy: true,
            success: true,
        });

    });

    it('should runacoin address findable', async () => {
        // Расчитать адрес кошелька до деплоя
        // Узнать адрес после деплоя


        // Покупка runacoin

        const amount = toNano(123);
        const user = deployer.getSender();

        await runecoin.send(
            user,
            { value: toNano(0.1) },
            {
                $$type: 'DexMessage',
                amount: amount,
                user: user.address as Address,
            },
        );
        
        // const runeWallet = await runeInfo.getMyAddress();
        // console.log('Rune wallet:', runeWallet.toString());
    });
});
