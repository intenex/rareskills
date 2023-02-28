// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

/**
 * @title Bitmap Merkle Tree ERC-721
 * @author Ben Yu
 * @notice This contract handles public and presale minting of ERC-721 tokens
 */
contract BitmapMerkleTreeERC721 is
    ERC721,
    ERC2981,
    RevokableDefaultOperatorFilterer,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private supplyCounter;

    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    uint96 public constant ROYALTY_FEE = 250;
    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256[4] bitmapArr = [MAX_INT, MAX_INT, MAX_INT, MAX_INT];

    string public baseTokenURI =
        "ipfs://bafybeih5lgrstt7kredzhpcvmft2qefue5pl3ykrdktadw5w62zd7cbkja/";
    bytes32 public merkleRootMapping;
    bytes32 public merkleRootBitmap;
    mapping(address => bool) public presaleMinted;

    /**
     * @notice Construct a Curious Addys instance
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _setDefaultRoyalty(msg.sender, ROYALTY_FEE);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Override the default base URI function to provide a real base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Returns the total supply of tokens
     */
    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    /**
     * @notice Set the merkle root for the mapping allow list mint
     * @param _merkleRoot New merkle root to set
     */
    function setMerkleRootMapping(bytes32 _merkleRoot) external onlyOwner {
        merkleRootMapping = _merkleRoot;
    }

    /**
     * @notice Set the merkle root for the bitmap allow list mint
     * @param _merkleRoot New merkle root to set
     */
    function setMerkleRootBitmap(bytes32 _merkleRoot) external onlyOwner {
        merkleRootBitmap = _merkleRoot;
    }

    /**
     * @notice Allows for public minting of tokens
     * @param _mintNumber Number of tokens to mint
     */
    function publicMint(uint256 _mintNumber) external payable virtual {
        require(msg.value == PRICE * _mintNumber, "INVALID_PRICE");
        require((totalSupply() + _mintNumber) <= MAX_SUPPLY, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < _mintNumber; i++) {
            supplyCounter.increment();
            _safeMint(msg.sender, supplyCounter.current());
        }
    }

    /**
     * @notice Verify that an address is eligible for presale minting using a mapping
     * @param _address Address to verify
     * @param _merkleProof Merkle proof for the address
     */
    function verifyMappingMerkleProof(
        address _address,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, merkleRootMapping, leaf);
    }

    /**
     * @notice Verify that an address is eligible for presale minting using a bitmap
     * @param _address Address to verify
     * @param _merkleProof Merkle proof for the address
     */
    function verifyBitmapMerkleProof(
        address _address,
        uint256 _bitmapNumber,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_bitmapNumber, _address));
        return MerkleProof.verify(_merkleProof, merkleRootBitmap, leaf);
    }

    /**
     * @notice Allows for presale minting of tokens for allowlisted addresses using a mapping
     * @param _merkleProof Merkle proof for the address
     */
    function presaleMintMapping(
        bytes32[] calldata _merkleProof
    ) external payable {
        require((totalSupply() + 1) <= MAX_SUPPLY, "MINT_TOO_LARGE");
        require(msg.value == PRICE, "INVALID_PRICE");
        require(presaleMinted[msg.sender] == false, "ALREADY_MINTED");
        require(
            verifyMappingMerkleProof(msg.sender, _merkleProof),
            "INVALID_MERKLE_PROOF"
        );

        presaleMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    /**
     * @notice Allows for presale minting of tokens for allowlisted addresses uising a bitmap
     * @param _bitmapNumber Bitmap number to verify corresponding to the msg.sender address
     * @param _merkleProof Merkle proof for the address
     */
    function presaleMintBitmap(
        uint256 _bitmapNumber,
        bytes32[] calldata _merkleProof
    ) external payable {
        require((totalSupply() + 1) <= MAX_SUPPLY, "MINT_TOO_LARGE");
        require(msg.value == PRICE, "INVALID_PRICE");
        require(
            verifyBitmapMerkleProof(msg.sender, _bitmapNumber, _merkleProof),
            "INVALID_MERKLE_PROOF"
        );
        require(_bitmapNumber < MAX_SUPPLY, "BITMAP_NUMBER_TOO_LARGE");
        uint256 bitmapArrIdx;
        uint256 offsetWithinLocalBitmap;

        // Unchecked is safe here because we know that _bitmapNumber is less than MAX_SUPPLY
        unchecked {
            // Find the correct index in the bitmap array
            bitmapArrIdx = _bitmapNumber / 256;
            // Find the correct bit inside the specific 32 byte bitmap
            offsetWithinLocalBitmap = _bitmapNumber % 256;
        }

        uint256 localBitmap = bitmapArr[bitmapArrIdx];
        // Retrieve the specific bit we want by shifting right to remove all bits to the right
        // and then bitmasking with bitwise AND w/ a single 1 bit value to remove all bits to the left
        uint256 storedBit = (localBitmap >> offsetWithinLocalBitmap) &
            uint256(1);
        // Ensure that the bit is set to 1 and not 0 which would mean that the address has already minted
        require(storedBit == 1, "ALREADY_MINTED");
        // Set the bit to 0 to indicate that the address has already minted
        // We do this by first negating the bit with bitwise NOT (~) and then ANDing with the existing bitmap
        // This will set the bit to 0 and leave all other bits unchanged
        localBitmap = localBitmap & ~(uint256(1) << offsetWithinLocalBitmap);

        _safeMint(msg.sender, 1);
    }

    /**
     * @notice Allow contract owner to withdraw funds
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
