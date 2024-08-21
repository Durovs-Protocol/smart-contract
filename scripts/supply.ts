
import { NetworkProvider } from '@ton/blueprint';
import { Address, beginCell, internal, toNano } from '@ton/core';
import { mnemonicToPrivateKey } from "@ton/crypto";
import { WalletContractV4 } from '@ton/ton/dist/wallets/WalletContractV4';
import { assets } from '../utils/data';
import { getBalanceValue, loadAddress, timer } from '../utils/helpers';
import { Manager } from '../wrappers/v0.Manager';
import { UserPosition } from '../wrappers/v0.UserPosition';

export async function run(provider: NetworkProvider) {
  const user = provider.sender();

  const manager = provider.open(await Manager.fromAddress(Address.parse(await loadAddress('manager'))));
  const userPositionAddress = await manager.getUserPositionAddress(user.address!!);
  const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));
  
const reservePool =Address.parse(await loadAddress('reservePool'));

const supplyAmount = 1
const assetIndex = 0

const jettonUserWallet = Address.parse('kQDrMl3jny6a7NkicAt-o868ZjHXKE4HoZl57op2zkx3XEh-')

let assetBuilder = beginCell()
assetBuilder.storeAddress(Address.parse(assets[assetIndex].master)); // мастер контракт жетона 
assetBuilder.storeInt(2n, 64).endCell(); // код олперации, в случае supply это 1 

    const client = provider.api()
    const body = beginCell()
    .storeUint(0xf8a7ea5, 32) // jetton transfer op code
    .storeUint(0, 64) // query_id:uint64
    .storeCoins(toNano(supplyAmount)) // amount:(VarUInteger 16) -  Jetton amount for transfer (decimals = 6 - jUSDT, 9 - default)
    .storeAddress(reservePool) // destination:MsgAddress
    .storeAddress(user.address) // response_destination:MsgAddress
    .storeUint(0, 1) // custom_payload:(Maybe ^Cell)
    .storeCoins(700000000) // forward_ton_amount:(VarUInteger 16)
    .storeMaybeRef(assetBuilder)// forward_payload:(Either Cell ^Cell)
    .endCell();

let keyPair = await mnemonicToPrivateKey("addict ozone kit involve tip person rocket wood curious attack celery question this gentle toast resource laundry brisk gaze brand caught half buzz bonus".split(" "));

// Create wallet contract
let workchain = 0; // Usually you need a workchain 0
let wallet = WalletContractV4.create({ workchain, publicKey: keyPair.publicKey });
let contract = client.open(wallet);
let seqno: number = await contract.getSeqno();

let oldBalance = 0n
let positionId = await manager.getLastPositionId()

if (positionId != 0n) {
    oldBalance =  await (await getBalanceValue(userPosition, assetIndex))()
}

let balanceAfterSupply = oldBalance + toNano(supplyAmount)


await contract.sendTransfer({
  seqno,
  secretKey: keyPair.secretKey,
  messages: [internal({
    value: '1',
    to: jettonUserWallet,
    body: body,
  })]
});

if (positionId == 0n) {
  await timer(`Supply ${supplyAmount} ${assets[assetIndex].name} `, 1n, manager.getLastPositionId);
} else {
  
  await timer(`Supply ${supplyAmount} ${assets[assetIndex].name} `, balanceAfterSupply, getBalanceValue(userPosition, assetIndex));
}

}


