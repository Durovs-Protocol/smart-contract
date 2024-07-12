import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { Runecoin } from '../wrappers/Runecoin';
import '@ton/test-utils';
import { jettonParams } from '../utils/data';
import { buildOnchainMetadata } from '../utils/helpers';
import { Manager } from '../wrappers/Manager';
import { RunecoinWallet } from '../wrappers/RunecoinWallet';

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
            await Runecoin.fromInit(
                deployer.getSender().address, 
                buildOnchainMetadata(jettonParams)
            )
        );
        
        runecoinWallet = blockchain.openContract(
            await RunecoinWallet.fromAddress (
                await runecoin.getMyWallet()
            )
        );

        manager = blockchain.openContract(
            await Manager.fromInit(
                deployer.getSender().address
            )
        );

        let deployResult = await runecoin.send(
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
            to: runecoin.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // Проверка адреса до
        // Получение адреса после

        const addressCalculated = await runecoin.getUserRunaCoinAddress(deployer.getSender().address);

        console.log('Deployer address: ' + deployer.getSender().address)
        console.log('addressCalculated: ' + addressCalculated) // Расчитали в runecoin
        
        await runecoin.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'DexMessage',
                user: deployer.getSender().address, 
                amount: toNano('123'),
            }
        );

        await delay(10000);

        const balanceBefore = await runecoinWallet.getGetBalance()
        console.log('balanceBefore: '+ balanceBefore);

        const burnResult = await manager.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'BurnUsdTONUserMessage',
                user: deployer.getSender().address, 
                amount: toNano('1'),
            }
        );

        const balanceAfter = await runecoinWallet.getGetBalance()
        console.log('balanceAfter: '+ balanceAfter);

    });
});
function delay(arg0: number) {
    throw new Error('Function not implemented.');
}

