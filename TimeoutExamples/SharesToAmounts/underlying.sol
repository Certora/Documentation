// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import {ERC20} from "./ERC20.sol";

contract underlying is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
        ) ERC20(_name, _symbol) {}
}