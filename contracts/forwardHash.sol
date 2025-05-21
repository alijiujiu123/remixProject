pragma solidity ^0.8.0;

contract HashContract {
    
    // Mapping of hashes stored on-chain -> their respective owners' addresses.
    mapping (string => address) public hashedOwners;
    
    // Stores arbitrary input as our "hash" with provided owner's information.
    function store(string memory _input, address _ownerAddress)
        external
        returns(bool success){
        
        require(bytes(_input).length > 0,"You must provide a valid hash.");
        require(isValidEOAOrContract(_ownerAddress), "_ownerAddress is not an EOA or Contract instance");
        
        // Store the provided hash under their ownership.
        hashedOwners[_input] = _ownerAddress;
    
    }
    
    function forwardHash(string memory _hashToForward, address payable _newOwnerAddress)
         external
          returns(bool success){
      require(isValidEOAOrContract(_newOwnerAddress),"New owner must be a valid EOA or Contract instance.");
      
       // Transfer ownership of passed hash to new recipient.
       hashedOwners[_hashToForward] = _newOwnerAddress;
    
        return true; 
   }
   function isValidEOAorcontract(address payable  addr) internal returns(bool success){
    return (addr != address(0));
    }
}