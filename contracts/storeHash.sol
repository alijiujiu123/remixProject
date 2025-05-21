// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract HashContract {
    // The stored hash is kept as bytes (as it might contain non-ASCII characters)
    string public storedHash;
    
    function store(string memory _hash) external {
        require(bytes(_hash).length > 0, "You must provide a valid input");
        
        // Store the provided hash
        storedHash = _hash;
    }
}