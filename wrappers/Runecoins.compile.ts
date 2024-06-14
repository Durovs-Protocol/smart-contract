import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/runecoins/runecoin.tact',
    options: {
        debug: true,
    },
};
