import { Sha256 } from '@aws-crypto/sha256-js';
import { Address, Cell, Dictionary, beginCell, toNano } from '@ton/core';
import fs from 'fs';

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

export async function timer(message: string, action: string, newVal: any, checkFunction: Function) {
    let currentVal = await checkFunction();
    console.log(`Started | ${message} | newVal: ${newVal}, currentVal: ${currentVal}`);
    console.log('=============================================================================');

    let attempt = 1;

    if (newVal == currentVal) {
        console.log(`Finished | The same value was received | ${newVal} | ${currentVal}`);
        console.log('=============================================================================');
        return;
    }

    while (newVal != currentVal) {
        console.log(`${action} (attempts: ${attempt}) | newVal: ${newVal} | currentVal: ${currentVal}`);
        await delay(3000);
        currentVal = await checkFunction();
        attempt++;
    }

    console.log(`Finished | ${message}:${currentVal}`);
    console.log('=============================================================================');
}

function delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function getFilename(name: string, nameSuffix?: string) {
    return `deploy/${name}${nameSuffix ? `_${nameSuffix}` : ''}.address`;
}

export async function saveAddress(name: string, address: Address, nameSuffix?: string) {
    const filename = getFilename(name, nameSuffix);
    await fs.promises.writeFile(filename, address.toString());

    console.log(`Address '${address.toString()}' saved to file ${filename}.`);
}

export async function loadAddress(name: string, nameSuffix?: string) {
    return await fs.promises.readFile(getFilename(name, nameSuffix), 'utf8');
}
