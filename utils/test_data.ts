export const tonPrice: number = 7.5;
export const gasFee: number = 0.2; // Стоимость газа
export const liquidationRatio: number = 1.15;
export const stabilityFeeRate: number = 0.05;
export const liquidationFee: number = 0.05;
export const minHealthRate: number = 2;

/**
 * UX
 */
export const addSupplyAmount: number = 1;

export const mintNormal: number = 3;
export const mintMax: number = 3.5;
export const burn: number = mintNormal - 0.5;

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
