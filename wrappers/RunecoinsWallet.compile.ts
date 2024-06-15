import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/runecoins/runecoins_wallet.tact',
    options: {
        debug: true,
    },
};
