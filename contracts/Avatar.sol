// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Pokemon.sol";
import "./Potion.sol";

contract MyToken is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {}

    function _baseURI() internal pure override returns (string memory) {
        return "revise-url/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
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


contract PLAYGROUND is MyToken {
    struct avatarInfo{
        uint256 currLoc;
        uint256 battlesWon;
        uint256 potionsBal;
        uint256[] pokemons;
    }

    event PokemonAdded(uint256 indexed AvatarId, uint256 indexed PokemonId);
    event PotionsAdded(uint256 indexed PotionsAdded );
    event PotionsBurned(uint256 indexed PotionsBurned );
    event BattleWon(uint256 indexed avatarId, bool indexed PlayerWon);

    mapping(uint256 => avatarInfo) public avatars;

    Pokemon POKEMON;
    Potion POTION;

    uint housePokemonBal;

    constructor(Pokemon _pokemon,Potion _potion){
        POKEMON = _pokemon;
        POTION = _potion;
        POKEMON.safeMint(address(this)); 
        POKEMON.safeMint(address(this)); 
        housePokemonBal += 2;

    }

    function addPokemon() internal {
        uint256 tokenId = POKEMON.safeMint(address(this)); 
        uint256 avatarId = tokenOfOwnerByIndex(msg.sender,0);
        avatars[avatarId].pokemons.push(tokenId);
        emit PokemonAdded(avatarId, tokenId);
    }

    // gets pokemon/potion based on chainink random number
    function collectPokemon() internal{
        // TODO : query random
        avatarInfo storage avatar = avatars[tokenOfOwnerByIndex(msg.sender,0)];
        uint randomNo = uint256(keccak256(abi.encodePacked(block.timestamp))) ;
        if (randomNo % 10 == 0 ) {
            randomNo = randomNo / 10 ;
            if (randomNo % 2 == 0){
                // gets potion
                avatar.potionsBal += 1 ;
                POTION.mint(address(this),1);
                emit PotionsAdded(1);
            }else {
                // gets pokemon
                addPokemon();
            }
        }
        // potions gets stealed
        if (randomNo % 97 == 0 ) {
            // remove potion
            avatar.potionsBal -= 2 ;
            POTION.burn(address(this),2);
            emit PotionsBurned(2);
        }
    }

    function move(uint256 destLoc) public{
        //  destLoc should be in surrounding
        avatarInfo storage avatar = avatars[tokenOfOwnerByIndex(msg.sender,0)];
        if (!((destLoc == avatar.currLoc + 1) || (destLoc == avatar.currLoc - 1) || (destLoc == avatar.currLoc + 10) || (destLoc == avatar.currLoc - 10) || (destLoc == avatar.currLoc + 11) || (destLoc == avatar.currLoc - 11) || (destLoc == avatar.currLoc + 9) || (destLoc == avatar.currLoc - 9))){
            // jump - 2 potions
            avatar.potionsBal -= 2 ;
            POTION.burn(address(this),2);
            emit PotionsBurned(2);
        }
        collectPokemon();
    }

    enum OnSale{
        POTION,
        RANDOMON
    }

    function shop(OnSale item) public{
        avatarInfo storage avatar = avatars[tokenOfOwnerByIndex(msg.sender,0)];
        if(item == OnSale.POTION){
            avatar.potionsBal += 1 ; 
            POTION.mint(address(this), 1);
        }else{
            addPokemon();
        }
    }

    function battle(uint challengerPokemonIndex) public{

        uint randomHouseIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % housePokemonBal ;

        Pokemon.pokemonDetails memory housePokemon = POKEMON.getPokemonDetails(POKEMON.tokenOfOwnerByIndex(address(this),randomHouseIndex));

        uint256 avatarId = tokenOfOwnerByIndex(msg.sender,0);
        Pokemon.pokemonDetails memory challengerPokemon = POKEMON.getPokemonDetails(avatars[avatarId].pokemons[challengerPokemonIndex]);

        uint housePokemonScore = housePokemon.attack + housePokemon.defense + housePokemon.mana + housePokemon.speed + housePokemon.strength;
        uint challengerPokemonScore = challengerPokemon.attack + challengerPokemon.defense + challengerPokemon.mana + challengerPokemon.speed + challengerPokemon.strength;

        bool playerWon = false;
        if (challengerPokemonScore > housePokemonScore ){
            avatars[avatarId].battlesWon += 1 ;
            playerWon = true;
        }
        emit BattleWon(avatarId, playerWon);
    }

    function advanceTo() public {

    }

}
