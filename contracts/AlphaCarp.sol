// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AlphaCarp is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    using SafeMath for uint256;
    using Strings for uint256;

    bool public isRevealed = false;
    uint256 public mintPrice = 0.05 ether;
    string public hiddenMetadataUri;
    string public baseURI;
    uint256 public constant MAX_PURCHASE_AT_A_TIME = 10;
    uint256 public constant MAX_CARPES = 5000;

    bool public isSaleActive = true;

    /**
    -------------------------------------------------------------------------------
    ------------------------------ Modifier ---------------------------------------
    -------------------------------------------------------------------------------
     */

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            totalSupply().add(_mintAmount) <= MAX_CARPES,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _numberOfTokens) {
        require(
            mintPrice.mul(_numberOfTokens) <= msg.value,
            "Ether sent is not enough"
        );
        _;
    }

    modifier mintAmountCompliance(uint256 _numberOfTokens) {
        require(
            _numberOfTokens <= MAX_PURCHASE_AT_A_TIME,
            "Can mint only 10 tokens at a time"
        );
        _;
    }

    modifier onlySaleIsActive() {
        require(isSaleActive, "Sale must be active to mint Carp");
        _;
    }

    constructor() ERC721("Alpha Carp Test", "KOTEST") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (isRevealed == false) {
            return hiddenMetadataUri;
        }

        string memory base = baseURI;
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, _tokenId.toString()))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setIsRevealed(bool _isRevealed) public onlyOwner {
        isRevealed = _isRevealed;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory _baseURI) internal virtual {
        baseURI = _baseURI;
    }

    /**
     * Reserve some Alpha Carp
     */
    function reserveCarpes() public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintCarp(uint256 _numberOfTokens)
        public
        payable
        onlySaleIsActive
        mintCompliance(_numberOfTokens)
        mintPriceCompliance(_numberOfTokens)
        mintAmountCompliance(_numberOfTokens)
    {
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_CARPES) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}
