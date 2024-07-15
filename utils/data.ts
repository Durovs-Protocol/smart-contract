/**
 * Общие настройки
 */
export const gasFee: number = 0.05; // Стоимость газа
export const tonPrice: number = 7.5;

export const liquidationRatio: number = 1.15;
export const stabilityFeeRate: number = 0.05;
export const liquidationFee: number = 0.05;
export const minHealthRate: number = 2;

/**
 * Supply
 */
export const addSupplyAmount: number = 1;
export const addSupplyGas: number = 0.1; // Создание/обновление UserPosition

/**
 * Mint
 */
export const mintAmount: number = 3; // Минт, отправка на кошелек, обновление UserPosition
export const mintGas: number = 0.1;

/**
 * Burn
 */
export const burnAmount: number = 2.5;
export const burnGas: number = 0.1;  // Сжигание, отправка с кошелека runacoins, обновление UserPosition

/**
 * Withdraw
 */
export const withdrawAmount: number = 1;
export const withdrawGas: number = 0.15;

/**
 * Liquidation
 */
export const liquidationGas: number = 0.3;
export const liquidationTonPrice: number = 3.4; // mintAmount*liquidationRatio - {немного тк в supply попадает TON на хранение}

/**
 * Runacoin
 */
export const testnetMintAmount: number = 100;
export const jettonParams = {
    name: `rune-${Date.now()}`,
    symbol: 'R',
    description: '-',
    image: 'https://ipfs.io/ipfs/QmfGfEGQav42ZW14W2D5oNtvWUC7Nwj759hjHAZvFiRhaX',
};
export const runecoinParams = {
    name: 'rune',
    symbol: 'rune',
    description: 'rune',
    image: '',
};
