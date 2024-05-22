import { toNano } from '@ton/core';
import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import '@ton/test-utils';
import { Pool } from '../wrappers/Pool';
import { SToken } from '../wrappers/SToken';
import { Treasury } from '../wrappers/Treasury';


describe('TestFlow', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let pool: SandboxContract<Pool>;
    let sToken: SandboxContract<SToken>;
    let treasury: SandboxContract<Treasury>;


    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        //разворачиваем контракт sToken и treasury
        let max_supply = toNano("1000"); 
        sToken = blockchain.openContract(await SToken.fromInit(deployer.address, max_supply ));
        treasury = blockchain.openContract(await Treasury.fromInit(deployer.address));
        const treasuryResult = await treasury.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        expect(treasuryResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: treasury.address,
            deploy: true,
            success: true,
        });
        //передаем адреса в pool
        pool = blockchain.openContract(await Pool.fromInit(sToken.address, treasury.address));
        const deployResult = await pool.send(
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
            to: pool.address,
            deploy: true,
            success: true,
        });
    });

    // описание текущего пути пользователя
});
