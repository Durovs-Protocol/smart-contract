import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/runecoins/runecoins_owner.tact',
    options: {
        debug: true,
    },
};
