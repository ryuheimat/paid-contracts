pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/payment/escrow/Escrow.sol";

contract EscrowManager {
    mapping(bytes32 => Escrow) escrows;
    constructor() 
    public {

    } 

    function withdraw() public returns (bool) {
        return true;
    }

    function deposit() public view returns(bool) {
        return true;
    }

    function has() public returns (bool) {
        return true;
    }
}