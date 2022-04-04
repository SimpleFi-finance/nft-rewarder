// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@ds/test.sol";
import "../NFTRewarder.sol";
import "@openzeppelin/token/ERC1155/IERC1155Receiver.sol";

interface CheatCodes {
    function prank(address) external;
}

contract NFTRewarderTest is DSTest {
    CheatCodes public cheats = CheatCodes(HEVM_ADDRESS);

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

    function testWhitelistingSingleAccount() public {
        address account = address(this);
        uint256 tokenId = 0;

        assertEq(rewarder.claimableTokens(account, tokenId), 0);
        rewarder.whitelistAccount(account, tokenId, 1);
        assertEq(rewarder.claimableTokens(account, tokenId), 1);
    }

    function testSingleMint() public {
        address account = address(0x1337);
        uint256 tokenId = 0;

        assertEq(rewarder.balanceOf(account, tokenId), 0);
        rewarder.whitelistAccount(account, tokenId, 1);

        // spoof sender to be `account`
        cheats.prank(account);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(account, tokenId), 1);
    }

    function testMulitpleMintsBySameUser() public {
        address account = address(0x1337);
        uint256 tokenId = 0;

        assertEq(rewarder.balanceOf(account, tokenId), 0);
        rewarder.whitelistAccount(account, tokenId, 2);

        cheats.prank(account);
        rewarder.claim(tokenId, 1);

        cheats.prank(account);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(account, tokenId), 2);
    }

    function testMultipleMintsOfSameTokenId() public {
        address addrA = address(0x1337A);
        address addrB = address(0x1337B);
        uint256 tokenId = 0;

        assertEq(rewarder.balanceOf(addrA, tokenId), 0);
        assertEq(rewarder.balanceOf(addrB, tokenId), 0);

        rewarder.whitelistAccount(addrA, tokenId, 1);
        rewarder.whitelistAccount(addrB, tokenId, 1);

        cheats.prank(addrA);
        rewarder.claim(tokenId, 1);

        cheats.prank(addrB);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(addrA, tokenId), 1);
        assertEq(rewarder.balanceOf(addrB, tokenId), 1);
    }
}
