// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@ds/test.sol";
import "../NFTRewarder.sol";

contract NFTRewarderTest is DSTest {
    NFTRewarder public rewarder;
    string public metadataUri = "https://token-cdn-domain/{id}.json";

    function setUp() public {
        rewarder = new NFTRewarder(metadataUri);
    }

    function testUriIsSet() public {
        string memory _uri = rewarder.uri(0);
        assertTrue(
            keccak256(abi.encode(_uri)) == keccak256(abi.encode(metadataUri))
        );
    }

    function testOwnershipAfterMint() public {
        address account = address(0x1337);
        uint256 tokenId = 0;

        assertEq(rewarder.balanceOf(account, tokenId), 0);
        rewarder.mintTo(account, tokenId);
        assertEq(rewarder.balanceOf(account, tokenId), 1);
    }
}
