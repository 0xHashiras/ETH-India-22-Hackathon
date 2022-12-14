// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Multimon is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address public operator;

    constructor() ERC721("MULTIMON", "MON") { }

    function updateOperator(address _operator) external onlyOwner{
        operator = _operator ;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier onlyOperator() {
        require(operator == _msgSender(), "caller is not the operator");
        _;
    }

    function safeMint(address to),uint256 tokenId public onlyOperator returns (uint256){
        // uint256 tokenId = _tokenIdCounter.current();
        // _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    struct multimonDetails{
        uint256 attack;
        uint256 defense;
        uint256 mana;
        uint256 speed;
        uint256 strength;
    }
    mapping (uint256 => multimonDetails) multimons;

    function getMultimonDetails(uint256 tokenId) public view returns (multimonDetails memory ){
        return multimons[tokenId];
    }
    
}