import { Sha256 } from '@aws-crypto/sha256-js';
import { NetworkProvider } from '@ton/blueprint';
import { Address, Cell, Dictionary, beginCell, toNano } from '@ton/core';
import { JettonMaster } from '@ton/ton';
import fs from 'fs';
import { assets } from './data';

const ONCHAIN_CONTENT_PREFIX = 0x00;
const SNAKE_PREFIX = 0x00;
const CELL_MAX_SIZE_BYTES = Math.floor((1023 - 8) / 8);

const sha256 = (str: string) => {
    const sha = new Sha256();
    sha.update(str);
    return Buffer.from(sha.digestSync());
};

const toKey = (key: string) => {
    return BigInt(`0x${sha256(key).toString('hex')}`);
};

export function buildOnchainMetadata(data: { name: string; description: string; image: string }): Cell {
    let dict = Dictionary.empty(Dictionary.Keys.BigUint(256), Dictionary.Values.Cell());

    // Store the on-chain metadata in the dictionary
    Object.entries(data).forEach(([key, value]) => {
        dict.set(toKey(key), makeSnakeCell(Buffer.from(value, 'utf8')));
    });

    return beginCell().storeInt(ONCHAIN_CONTENT_PREFIX, 8).storeDict(dict).endCell();
}

export function makeSnakeCell(data: Buffer) {
    // Create a cell that package the data
    let chunks = bufferToChunks(data, CELL_MAX_SIZE_BYTES);

    const b = chunks.reduceRight((curCell, chunk, index) => {
        if (index === 0) {
            curCell.storeInt(SNAKE_PREFIX, 8);
        }
        curCell.storeBuffer(chunk);
        if (index > 0) {
            const cell = curCell.endCell();
            return beginCell().storeRef(cell);
        } else {
            return curCell;
        }
    }, beginCell());
    return b.endCell();
}

function bufferToChunks(buff: Buffer, chunkSize: number) {
    let chunks: Buffer[] = [];
    while (buff.byteLength > 0) {
        chunks.push(buff.slice(0, chunkSize));
        buff = buff.slice(chunkSize);
    }
    return chunks;
}

const jettonParams = {
    name: 'Supply token',
    description: '-',
    symbol: 'YT',
    image: '-',
};

export const content = buildOnchainMetadata(jettonParams);

export const maxSupply = toNano(12345000);

export function cell(pram: string) {
    return beginCell().storeBit(1).storeUint(0, 32).storeStringTail(pram).endCell();
}

export async function timer(
    message: string,
    newVal: any,
    checkFunction: Function,
    showLogs: boolean = false,
    maxAttempts: number = 60,
) {
    let currentVal = await checkFunction();
    console.log('=============================================================================');
    let attempt = 1;
    if (newVal == currentVal) {
        console.log(`Finished | The same value was received | ${newVal} | ${currentVal}`);
        console.log('=============================================================================');
        return;
    }

    while (newVal != currentVal) {
        console.log(`${message}, currentVal: ${currentVal}, (attempts: ${attempt})`);

        await delay(3000);
        currentVal = await checkFunction();
        attempt++;
        if (maxAttempts < attempt) {
            log('Attemps limit');
            throw new Error('Max attempt exceeded');
        }
    }

    console.log(`Finished`);
    console.log('=============================================================================');
}

export function numberFormat(val: String) {
    return new Intl.NumberFormat().format(Number(val));
}

export function delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function getFilename(name: string, nameSuffix?: string, v = process.env.v) {
    var dir = `deploy/v${v}`;
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir);
    }
    return `deploy/v${v}/${name}${nameSuffix ? `_${nameSuffix}` : ''}.address`;
}

export async function saveAddress(name: string, address: Address, nameSuffix?: string, v?: string) {
    
    const filename = getFilename(name, nameSuffix, v );
    await fs.promises.writeFile(filename, address.toString());
    console.log(`Address '${address.toString()}' saved to file ${filename}.`);
}

export async function loadAddress(name: string, nameSuffix?: string, v?: string) {
    return await fs.promises.readFile(getFilename(name, nameSuffix, v), 'utf8');
}

export async function saveLog(name: string, log: any) {
    var dir = 'logs/migration';
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir);
    }
    const filename = `logs/migration/${name}.txt`;
    await fs.promises.writeFile(filename, log);
}

export function log(message: any) {
    console.log('\n\n=============================================================================');
    console.log(message);
    console.log('\n\n=============================================================================');
}

export const getBalanceValue = function (contract: any, index: number) {
    return async function () {
        const allBalances = await contract.getBalances();
        return allBalances.get(Address.parse(assets[index].master!!));
    };
};

export const contractVersion = async function (contract: any, name: string) {

    try {
    const version = await contract.getVersion()
    return `version of ${name}: ${version}`
    } catch(err) {
    return `contract not exist`
    }
};

export async function createAssetsList(owner: string, provider: NetworkProvider, version: string) {
    let assets = [
        {
            name: 'TON',
            master: process.env.TON_MINTER,
            pool_wallet: 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ', // адрес пула!!
        },
        {
            name: 'stTON', // Свой токен
            master: process.env.ST_JETTON_MINTER,
            pool_wallet: 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ',
        },
        {
            name: 'hTON',
            master: process.env.HT_JETTON_MINTER,
            pool_wallet: 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ',
        },
        {
            name: 'tsTON',
            master: process.env.TS_JETTON_MINTER,
            pool_wallet: 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ',
        },
        // {
        //     name: 'NOT',
        //     master: process.env.NOT_JETTON_MINTER,
        //     pool_wallet: 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ',
        // },
        // {
        //     name: 'DOGS',
        //     master: process.env.DOGS_JETTON_MINTER,
        //     pool_wallet: 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ',
        // }
    ];

    for (const asset of assets) {
        if (asset.master == 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ') {
            asset.pool_wallet = owner;
        } else {
            const masterInterface = JettonMaster.create(Address.parse(asset.master!!));
            const master = await provider.open(masterInterface);
            const jettonWalletAddress = await master.getWalletAddress(Address.parse(owner));
            asset.pool_wallet = jettonWalletAddress.toString();
        }
    }

    var dir = `utils`;
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir);
    }
    
    switch(version) {
        case 'v0':
            await fs.promises.writeFile(`${dir}/assets_v0.json`, JSON.stringify({ assets: assets }));
            break
        case 'v1':
            await fs.promises.writeFile(`${dir}/assets_v1.json`, JSON.stringify({ assets: assets }));
            break

    }
}
