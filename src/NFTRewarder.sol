// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/token/ERC1155/ERC1155.sol";

contract NFTRewarder is ERC1155 {
    constructor(string memory _uri) ERC1155(_uri) {}

    function mintTo(address to, uint256 tokenId) external {
        _mint(to, tokenId, 1, "");
    }
}
