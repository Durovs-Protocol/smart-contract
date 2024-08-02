/**
 * Общие настройки
 */
export const tonPrice: number = 6.5;
export const gas: number = 1;
export const setupGas: number = 0.03;
export const liquidationRatio: number = 1;
export const reservePool: number = 1.5;
export const reserveMin: number = 5; // $
export const burnMin: number = 1; // $
export const serviceFeePercent: number = 0.1;
export const serviceFee: number = 2; // $

/**
 * Supply
 */
export const addSupplyAmount: number = 1;
/**
 * Mint
 */
export const mintAmount: number = tonPrice; // Минт, отправка на кошелек, обновление UserPosition
/**
 * Burn
 */
export const burnAmount: number = tonPrice;
/**
 * Withdraw
 */
export const withdrawAmount: number = 1;
/**
 * Liquidation
 */
export const liquidationTonPrice: number = 6; // mintAmount*liquidationRatio - {немного тк в supply попадает TON на хранение}
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
    name: `ton-usd-${Date.now()}`,
    symbol: 'TUSD',
    description: 'Algorithmic Stable coin (USD) on TON',
    image: 'https://ipfs.io/ipfs/QmPSGcz4TyDo3qShEymZRQRavKKRRbiLPHYs9GUgbtwEwx',
};

/**
 * Для теста
 */
export const testJettonParams = {
    name: `ton-usd-${Date.now()}`,
    symbol: 'TUSD',
    description: 'Algorithmic Stable coin (USD) on TON',
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
