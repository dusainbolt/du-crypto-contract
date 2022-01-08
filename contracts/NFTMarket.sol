// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NFTMarket is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice;

    constructor(uint256 _listingPrice) {
        listingPrice = _listingPrice;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private marketItemById;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Set the listing price of the contract */
    function setListingPrice(uint256 _listingPrice) external onlyOwner {
        listingPrice = _listingPrice;
    }

    /* Places an item for sale on the marketplace */
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        marketItemById[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(_msgSender()),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(_msgSender(), address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            _msgSender(),
            address(0),
            price,
            false
        );
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = marketItemById[itemId].price;
        uint256 tokenId = marketItemById[itemId].tokenId;
        address payable seller = marketItemById[itemId].seller;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        require(seller != _msgSender(), "You're creator of the NFT");

        marketItemById[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), _msgSender(), tokenId);
        marketItemById[itemId].owner = payable(_msgSender());
        marketItemById[itemId].sold = true;
        _itemsSold.increment();
        payable(owner()).transfer(listingPrice);
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            MarketItem storage currentItem = marketItemById[i + 1];
            if (currentItem.owner == address(0)) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (marketItemById[i + 1].owner == _msgSender()) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            MarketItem memory currentItem = marketItemById[i + 1];
            if (currentItem.owner == _msgSender()) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has created */
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (marketItemById[i + 1].seller == _msgSender()) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            MarketItem memory currentItem = marketItemById[i + 1];
            if (currentItem.seller == _msgSender()) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
