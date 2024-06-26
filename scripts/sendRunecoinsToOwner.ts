import { NetworkProvider } from '@ton/blueprint';
import { Address, toNano } from '@ton/core';
import { buildOnchainMetadata, loadAddress, saveAddress, timer } from '../utils/helpers';
import { RuneCoinsOwner } from '../wrappers/RunecoinsOwner';

export async function run(provider: NetworkProvider) {
    const runecoinsOwner = provider.open(
        await RuneCoinsOwner.fromAddress(Address.parse(await loadAddress('runecoins_owner'))),
    );

    const jettonParams = {
        name: 'runa2',
        symbol: 'RN2',
        description: 'runa2',
        image: 'https://d391b93f5f62d9c15f67142e43841acc.ipfscdn.io/ipfs/bafybeighpd4rtwtnv3cumptlz4pmvi7z3iuo75mvyvdlthusdiuumfedbq/logo-dark.png',
    };

    const amount = toNano('1000000');

    await runecoinsOwner.send(
        provider.sender(),
        {
            value: toNano('0.8'),
        },
        {
            $$type: 'SetBalance',
            amount: amount,
            content: buildOnchainMetadata(jettonParams),
        },
    );

    const totalAmount = await runecoinsOwner.getTotalAmount();

    await timer(
        'owners balance',
        'Передача runecoins контракту-владельцу',
        totalAmount + amount,
        runecoinsOwner.getTotalAmount,
    );
    const getAddress = await runecoinsOwner.getAddress();
    await saveAddress('runecoin', getAddress);

    console.log('=============================================================================');
    console.log('Owner recieved runecoins');
    console.log('=============================================================================');
}
