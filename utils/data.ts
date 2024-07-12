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
export const jettonParams = {
    name: `rune-${Date.now()}`,
    symbol: 'R',
    description: '-',
    image: 'https://ipfs.io/ipfs/QmfGfEGQav42ZW14W2D5oNtvWUC7Nwj759hjHAZvFiRhaX',
};
