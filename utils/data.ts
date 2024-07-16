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
export const burnGas: number = 0.1; // Сжигание, отправка с кошелека runacoins, обновление UserPosition

/**
 * Withdraw
 */
export const withdrawAmount: number = 1;
export const withdrawGas: number = 0.15;

/**
 * Liquidation
 */
export const liquidationGas: number = 0.05;
export const liquidationTonPrice: number = 3.4; // mintAmount*liquidationRatio - {немного тк в supply попадает TON на хранение}

/**
 * Runacoin
 */
export const testnetMintAmount: number = 100;
export const jettonParams = {
    name: 'Runa_test_1', //`rune-${Date.now()}`,
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

export const usdTONJettonParams = {
    name: `yt-${Date.now()}`,
    symbol: 'YT',
    description: '-',
    image: 'https://ipfs.io/ipfs/QmPSGcz4TyDo3qShEymZRQRavKKRRbiLPHYs9GUgbtwEwx',
};

/**
 * Для теста
 */

export const testJettonParams = {
    name: 'yt',
    symbol: 'yt',
    description: 'yt',
    image: '',
};
export const testRunecoinParams = runecoinParams;
export const holders = [
    { name: 'supply', percent: 40 },
    { name: 'foundersTeam', percent: 16 },
    { name: 'foundation', percent: 9 },
    { name: 'dao', percent: 5 },
    { name: 'private', percent: 5 },
    { name: 'preSeed', percent: 6 },
    { name: 'seed', percent: 7 },
    { name: 'airdrop', percent: 5 },
    { name: 'advisors', percent: 4 },
    { name: 'publicSales', percent: 2 },
    { name: 'marketMaking', percent: 1 },
];
