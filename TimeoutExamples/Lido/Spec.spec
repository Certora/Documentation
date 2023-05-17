methods {
    function obtainDepositData(uint256) external returns (bytes, bytes) envfree;
}

rule sanity(uint256 depositCount) {
    require depositCount > 0;
    obtainDepositData(depositCount);
    assert false;
}