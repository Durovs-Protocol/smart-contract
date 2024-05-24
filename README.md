# Wallet Insurance

## Project structure

-   `contracts` - source code of all the smart contracts of the project and their dependencies.
-   `wrappers` - wrapper classes (implementing `Contract` from ton-core) for the contracts, including any [de]serialization primitives and compilation functions.
-   `tests` - tests for the contracts.
-   `scripts` - scripts used by the project, mainly the deployment scripts.

## How to use

### Build

`npx blueprint build` or `yarn build`

### Test

`npx blueprint test` or `yarn test`

### Deploy or run another script

`npx blueprint run` or `yarn run`

### Add a new contract

`npx blueprint create ContractName` or `yarn blueprint create ContractName`


## Контракты

- `01mint` - `EQAejN_aP5HZ6cplzI5nhjPH9rze0SdztPR-yonzyBfgZCfk`
- `02deployTreasury` & `03sendTon` & `05info` - `EQB93h6ym6QThQkAQwjtQFV776Xnc59BEYeoqZx_xQPcw2-f`
- `05info` - взаимодействие
- `07deployPool` - `EQCNm8SNX_wBt5LdqNQfDFxuFd1dLBnch2tpRw8SpIB6lWrd`
