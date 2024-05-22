import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import fs from 'fs';
import { Pool } from '../build/Pool/tact_Pool';
import { Treasury } from '../build/Treasury/tact_Treasury';

export async function run(provider: NetworkProvider) {
    const deployer = provider.sender().address as Address;
    let rawdata = fs.readFileSync('JettonAddress.json');
    const jettonAddress = Address.parse(JSON.parse(rawdata.toString()));
    const treasury = provider.open(await Treasury.fromInit(jettonAddress, deployer));
    const pool = provider.open(await Pool.fromInit(jettonAddress, treasury.address));

    await pool.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(pool.address);
    console.log('----------------pool deployed--------------------------')
}
