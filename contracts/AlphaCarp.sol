// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MultiOwnable {
    address public manager; // address used to set owners
    address[] public owners;
    mapping(address => bool) public ownerByAddress;

    event SetOwners(address[] owners);

    modifier onlyOwner() {
        require(ownerByAddress[msg.sender] == true);
        _;
    }

    /**
     * @dev MultiOwnable constructor sets the manager
     */
    constructor(address _manager) {
        manager = _manager;
    }

    /**
     * @dev Function to set owners addresses
     */
    function setOwners(address[] memory _owners) public {
        require(msg.sender == manager);
        _setOwners(_owners);
    }

    function _setOwners(address[] memory _owners) internal {
        for (uint256 i = 0; i < owners.length; i++) {
            ownerByAddress[owners[i]] = false;
        }

        for (uint256 j = 0; j < _owners.length; j++) {
            ownerByAddress[_owners[j]] = true;
        }
        owners = _owners;
        emit SetOwners(_owners);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }
}

contract AlphaCarp is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    MultiOwnable
{
    using SafeMath for uint256;
    using Strings for uint256;

    bool public isRevealed = false;
    uint256 public mintPrice = 0.05 ether;
    string public hiddenMetadataUri;
    string public baseURI;
    uint256 public constant MAX_PURCHASE_AT_A_TIME = 10;
    uint256 public constant MAX_CARPES = 5000;

    bool public isSaleActive = false;

    bytes32 public whitelistMerkleRoot;
    uint256 public whiteListCost;

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

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    constructor(address _manager)
        ERC721("Alpha Carp Test", "KOTEST")
        MultiOwnable(_manager)
    {}

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

    function setIsSaleActive(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whiteListCost = _newCost;
    }

    function mintWhitelist(bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(whiteListCost, 1)
    {
        uint256 supply = totalSupply();
        require(supply + 1 <= MAX_CARPES, "max NFT limit exceeded");
        _safeMint(msg.sender, supply + 1);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }
}
