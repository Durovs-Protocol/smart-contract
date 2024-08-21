import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/v1/manager.tact',
    options: {
        debug: true,
    },
};
