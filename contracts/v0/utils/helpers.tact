fun createOffchainContent(pram: String): Cell {
    let s: StringBuilder = beginStringFromBuilder(beginCell().storeBool(true).storeUint(0, 32));
    s.append(pram);
    return s.toCell();
}