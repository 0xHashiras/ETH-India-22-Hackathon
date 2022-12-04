// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MultimonPolygonDeployedLatest.sol";
import "./PotionPolygonDeployedLatest.sol";

contract OZ_Token is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    constructor() ERC721("MyToken", "MTK") {
        baseURI = "revise-url/";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri ;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) external {
        require(balanceOf(to)==0,"User can mint only one NFT Avatar");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
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
}


contract ARENA is OZ_Token {
    struct avatarInfo{
        uint256 currLoc;
        uint256 battlesWon;
        uint256 potionsBal;
        uint256[] multimons;
    }

    event MultimonAdded(uint256 indexed AvatarId, uint256 indexed MultimonId);
    event PotionsAdded(uint256 indexed AvatarId, uint256 indexed PotionsAdded );
    event PotionsBurned(uint256 indexed AvatarId, uint256 indexed PotionsBurned );
    event BattleWon(uint256 indexed AvatarId, bool indexed PlayerWon);

    mapping(uint256 => avatarInfo) public avatars;

    Multimon MULTIMON;
    Potion POTION;

    uint houseMultimonBal;

    constructor(Multimon _multimon,Potion _potion){
        MULTIMON = _multimon;
        POTION = _potion;
    }


    function initialSetup() external onlyOwner{
        MULTIMON.safeMint(address(this)); 
        MULTIMON.safeMint(address(this)); 
        houseMultimonBal += 2;
    }

    function addMultimon() internal {
        uint256 tokenId = MULTIMON.safeMint(address(this)); 
        uint256 avatarId = tokenOfOwnerByIndex(msg.sender,0);
        avatars[avatarId].multimons.push(tokenId);
        emit MultimonAdded(avatarId, tokenId);
    }

    // gets multimon/potion based on chainink random number
    function collectMultimon() internal{
        
        uint256 avatarId = tokenOfOwnerByIndex(msg.sender,0);
        avatarInfo storage avatar = avatars[avatarId];
        uint randomNo = uint256(keccak256(abi.encodePacked(block.timestamp))) ;
        if (randomNo % 10 == 0 ) {
            randomNo = randomNo / 10 ;
            if (randomNo % 2 == 0){
                // gets potion
                avatar.potionsBal += 1 ;
                POTION.mint(address(this),1);
                emit PotionsAdded(avatarId, 1);
            }else {
                // gets multimon
                addMultimon();
            }
        }
        // potions gets stealed
        if (randomNo % 97 == 0 ) {
            // remove potion
            avatar.potionsBal -= 2 ;
            POTION.burn(address(this),2);
            emit PotionsBurned(avatarId, 2);
        }
    }

    function move(uint256 destLoc) public{
        uint256 avatarId = tokenOfOwnerByIndex(msg.sender,0);
        //  destLoc should be in surrounding
        avatarInfo storage avatar = avatars[avatarId];
        require(destLoc != avatar.currLoc);
        if ((destLoc == avatar.currLoc + 1) || (destLoc == avatar.currLoc - 1) || (destLoc == avatar.currLoc + 10) || (destLoc == avatar.currLoc - 10) || (destLoc == avatar.currLoc + 11) || (destLoc == avatar.currLoc - 11) || (destLoc == avatar.currLoc + 9) || (destLoc == avatar.currLoc - 9)){
            // jump:  2 potions
            collectMultimon();
        }else{

            avatar.potionsBal -= 2 ;
            POTION.burn(address(this),2);
            emit PotionsBurned(avatarId, 2);
        }
        avatar.currLoc = destLoc;
    }

    enum OnSale{
        POTION,
        RANDOMON
    }

    function shop(OnSale item) public{
        uint256 avatarId = tokenOfOwnerByIndex(msg.sender,0);
        avatarInfo storage avatar = avatars[avatarId];
        if(item == OnSale.POTION){
            avatar.potionsBal += 1 ; 
            POTION.mint(address(this), 1);
            emit PotionsAdded(avatarId, 1);
        }else{
            addMultimon();
        }
    }

    function battle(uint challengerMultimonIndex) public{

        uint randomHouseIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % houseMultimonBal ;

        Multimon.multimonDetails memory houseMultimon = MULTIMON.getMultimonDetails(MULTIMON.tokenOfOwnerByIndex(address(this),randomHouseIndex));

        uint256 avatarId = tokenOfOwnerByIndex(msg.sender,0);
        Multimon.multimonDetails memory challengerMultimon = MULTIMON.getMultimonDetails(avatars[avatarId].multimons[challengerMultimonIndex]);

        uint houseMultimonScore = houseMultimon.attack + houseMultimon.defense + houseMultimon.mana + houseMultimon.speed + houseMultimon.strength;
        uint challengerMultimonScore = challengerMultimon.attack + challengerMultimon.defense + challengerMultimon.mana + challengerMultimon.speed + challengerMultimon.strength;

        bool playerWon = false;
        if (challengerMultimonScore > houseMultimonScore ){
            avatars[avatarId].battlesWon += 1 ;
            playerWon = true;
        }
        emit BattleWon(avatarId, playerWon);
    }

    uint32 constant R_GOERLI_DOMAIN_ID = 5;
    address R_GOERLI_TARGET;
    address constant S_POLYGON_TESTNET_OUTBOX = 0xe17c37212d785760E8331D4A4395B17b34Ba8cDF;

    function set_R_GOERLI_TARGET(address _target) public onlyOwner{
        R_GOERLI_TARGET = _target;
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function advanceTo() public {
        avatarInfo storage avatar = avatars[tokenOfOwnerByIndex(msg.sender,0)];
        require(avatar.battlesWon > 3,"Min 3 Battle Wins");

        bytes memory params = abi.encode(avatar);

        IOutbox(S_POLYGON_TESTNET_OUTBOX).dispatch(
            R_GOERLI_DOMAIN_ID,
            addressToBytes32(R_GOERLI_TARGET),
            params
        );

        // TODO : burn
        




    }  

}

interface IOutbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (uint256);
}
