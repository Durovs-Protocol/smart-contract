
import { NetworkProvider } from '@ton/blueprint';
import { Address, beginCell, internal, toNano } from '@ton/core';
import { mnemonicToPrivateKey } from "@ton/crypto";
import { WalletContractV4 } from '@ton/ton/dist/wallets/WalletContractV4';
import contracts from '../utils/contracts';
import { assets } from '../utils/data';
import { contractVersion, log, timer } from '../utils/helpers';


export async function run(provider: NetworkProvider) {
  const user = provider.sender();
    const {
      reservePool,
      manager,
    } = await contracts(provider, user.address!!)

    // const userPositionAddress = await managerContract.getUserPositionAddress(user.address!!);
    // const userPosition = provider.open(await UserPosition.fromAddress(userPositionAddress));

    const supplyAmount = 1
    const assetIndex = 0
    log('\nВнесение залога jetton:' + supplyAmount +
      `\n${await contractVersion(manager, 'manager')}`
    );
	// Адрес кошелька TON Assets
    const jettonUserWallet = Address.parse('kQDrMl3jny6a7NkicAt-o868ZjHXKE4HoZl57op2zkx3XEh-')

    let assetBuilder = beginCell()
		assetBuilder.storeAddress(Address.parse(assets[assetIndex].master)); // мастер контракт жетона 
		assetBuilder.storeInt(2n, 64).endCell(); // код олперации, в случае supply это 1 

		/**
		 * A: основной кошелек в принципе (WalletV4)
		 * A->B(подкошлек с самой монетой):
		 * B->C(reserve pool wallet): отправка в reserve Pool
		 * С->A: возврат газа
		 * C->D(reserve pool): сообщение о поступлении
		 * D->E(manager): SupplyMessage
		 * E->F(user position): Supply
		 * F->E(manager): Добавляем PositionId
		 * E->G(position keeper
		 * G->A: Возврат газа
		 */

		/**
		 * A: основной кошелек в принципе (WalletV4)
		 * A->B(подкошлек с самой монетой):
		 * B->C(reserve pool wallet): отправка в reserve Pool
		 * С->A: возврат газа
		 * C->D(reserve pool): сообщение о поступлении
		 * D->E(manager): SupplyMessage
		 * E->F(user position): Supply
		 * F->A: Возврат газа
		 */
	const client = provider.api()
	const body = beginCell()
        .storeUint(0xf8a7ea5, 32)
        .storeUint(0, 64)
        .storeCoins(toNano(supplyAmount)) // Сумма
        .storeAddress(reservePool.address) // Кто получит TON Assets
        .storeAddress(user.address) // Остаток газа
        .storeUint(0, 1)
        .storeCoins(700000000)
        .storeMaybeRef(assetBuilder)
        .endCell();

    let keyPair = await mnemonicToPrivateKey(process.env.WALLET_MNEMONIC!!.split(" "));

    // Create wallet contract
    let workchain = 0; // Usually you need a workchain 0
    let wallet = WalletContractV4.create({ workchain, publicKey: keyPair.publicKey }); // Просто кошелек
    let contract = client.open(wallet);
    let seqno: number = await contract.getSeqno();

    let oldBalance = 0n
    let positionId = await manager.getLastPositionId()

    // if (positionId != 0n) {
    //     oldBalance =  await (await getBalanceValue(userPosition, assetIndex))()
    // }

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

// if (positionId == 0n) {
  await timer(`Supply ${supplyAmount} ${assets[assetIndex].name} `, positionId + 1n, manager.getLastPositionId);
// } else {
  // await timer(`Supply ${supplyAmount} ${assets[assetIndex].name} `, balanceAfterSupply, getBalanceValue(userPosition, assetIndex));
// }
}


