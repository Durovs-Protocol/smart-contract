import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/V0/new_manager.tact',
    options: {
        debug: true,
    },
};
