import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/runecoin/runecoin_owner.tact',
    options: {
        debug: true,
    },
};
