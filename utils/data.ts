/**
 * Общие настройки
 */
export const gasFee: number = 0.2; // Стоимость газа
export const tonPrice: number = 7.5;
export const liquidationRatio: number = 1.15;
export const stabilityFeeRate: number = 0.05;
export const liquidationFee: number = 0.05;
export const minHealthRate: number = 2;

/**
 * Supply
 */
export const addSupplyAmount: number = 1;
export const addSupplyGas: number = 0.15;

/**
 * Mint
 */
export const mintAmount: number = 3;
export const mintGas: number = 0.05;

/**
 * Burn
 */
export const burnAmount: number = 2.5;
export const burnGas: number = 0.12;

/**
 * Withdraw
 */
export const withdrawAmount: number = 1;
export const withdrawGas: number = 0.15;

/**
 * Liquidation
 */
export const liquidationGas: number = 0.3;


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
