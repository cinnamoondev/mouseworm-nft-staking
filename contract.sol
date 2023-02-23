// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./contracts/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract AutistNFTs is ERC721Enumerable, Ownable, DefaultOperatorFilterer, AccessControl {
    using Strings for uint256;

    string _baseTokenURI = ""; // base URI (used by NFT market places)
    uint256 private _price = 0.0001 ether; // price of NFT
    bool public _paused = true; // if true, minting is paused (update it via pause function
    uint256 public _maxNFTAmount = 1; // maximum amount of NFTs per wallet
    uint256 public _maxSupply = 100; //maximum supply of NFTs
    bool public _isRevealed = true;
    IERC20 private _mouseworm; // mouseworm token contract
    uint256 public _minAmount = 100 * 1e6; // minimum MouseWorm amount require to mint NFT


    // withdraw addresses
    address marketingAddress = 0xD4a79d62DdBc39b33297498c43e4Cc4F468CDb7F;

    // canWithdraw modifier checks if NFT contract has ETH
    modifier canWithdraw() {
        require(address(this).balance > 0 ether);
        _;
    }

    //
    struct MarketingAddresses {
        address payable addr;
        uint256 percent;
    }

    MarketingAddresses[] marketingAddresses;

    constructor() ERC721("MouseWorms", "MouseWorms") {
        marketingAddresses.push(
            MarketingAddresses(payable(address(marketingAddress)), 100)
        );

        for(uint i = 0; i < 10; i++){
            _safeMint(marketingAddress, i);
        }

        _mouseworm = IERC20(0xE670F2e597e8454e6B17195511780093c335E987);
    }

    /**
     * @dev Public function to mint NFTs.
     * @param num uint256 number of NFTs user wants to mint
     * payable function means you need to send ETH when calling function. ETH amount should be num * price
     */

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply(); //get current supply - e.g. total number of minted NFTs

        require(!_paused, "Minting paused"); //check if minting is pause.
        require(
            num <= _maxNFTAmount,
            "You can mint a maximum of 1 NFT at the time"
        ); // check if desired number exceeds max NFT amount
        require(
            ERC721.balanceOf(msg.sender) + num <= _maxNFTAmount,
            "Exceeds maximum NFTs per wallet"
        ); // check if current NFT balance and desired amount exceeds max NFT amount
        require(
            _mouseworm.balanceOf(_msgSender()) >= _minAmount,
            "MouseWorm balance too low");
        require(supply + num <= _maxSupply, "Exceeds maximum NFT supply"); // check if current supply exceeds max supply
        require(msg.value >= _price * num, "Ether sent is not correct"); // check if user sent enough ETH to mint NFTs

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i); // mint num NFTs
        }
    }

    /**
     * @dev Public view to check users NFTs.
     * @param _owner address - address of user
     * returns the array of NFT IDs
     */
    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
     * @dev Public function to change price of NFT.
     * @param _newPrice uint256 - new price (use wei, e.g - 0.1 ETH = 100000000000000000)
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    /**
     * @dev Public view returns base URI. Used for fetching the metadata of each NFT
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Public function to change baseURI.
     * @param baseURI string - new baseURI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Public view returns current price per NFT
     */
    function getPrice() public view returns (uint256) {
        return _price;
    }

    /**
    * @dev Public function to change minimum amount of THE tokens required to mint an NFT.
     * @param _newMinAmount uint256
     */
    function setMinAmount(uint256 _newMinAmount) public onlyOwner {
        _minAmount = _newMinAmount;
    }

    /**
     * @dev Public view returns the minimum amount of THE tokens required to mint an NFT.
     */
    function getMinAmount() public view returns (uint256) {
        return _minAmount;
    }


    /**
     * @dev Public function to pause/unpause minting.
     * @param val bool - new status. true if pause, false if unpaused
     */
    function pause(bool val) public onlyOwner {
        _paused = val;
    }
    /**
     * @dev Public function to reveal collection.
     */
    function reveal() public onlyOwner {
        require(!_isRevealed, "Collection already revealed");
        _isRevealed = true;
    }


    // Withdraw ETH from NFT contract
    function withdraw() external payable onlyOwner canWithdraw {
        uint256 nbalance = address(this).balance;
        for (uint256 i = 0; i < marketingAddresses.length; i++) {
            MarketingAddresses storage m = marketingAddresses[i];
            (bool success, ) = payable(m.addr).call{value: (nbalance * m.percent) / 100} ("");
            require(success, "Failed to withdraw");
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override (ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}