pragma solidity ^0.4.24;

import './StandardToken.sol';

contract DFINoken is StandardToken {

    string public name = 'Consensus Blockchain';
    string public symbol = 'DFIN';
    uint8 public decimals = 4;
    uint public INITIAL_SUPPLY = 300000000 * (10 ** uint(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}