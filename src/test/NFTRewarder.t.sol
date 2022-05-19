// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "../NFTRewarder.sol";
import "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import "openzeppelin/utils/Strings.sol";

contract NFTRewarderTest is Test {
    // main contract being tested
    NFTRewarder public rewarder;
    address public whitelister = address(0x1337abc);
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        rewarder = new NFTRewarder(whitelister);
    }

    function testUriIsEmptyByDefault() public {
        string memory _uri = rewarder.uri(0);
        assertTrue((bytes(_uri)).length == 0);
    }

    function testUriIsSet() public {
        string memory _uri = rewarder.uri(0);
        assertTrue((bytes(_uri)).length == 0);

        // set uri
        string memory uriToken0 = "https://token-cdn-domain/0.json";
        rewarder.setUri(0, uriToken0);

        // check new uri is set
        _uri = rewarder.uri(0);
        assertTrue(
            keccak256(abi.encode(_uri)) == keccak256(abi.encode(uriToken0))
        );
    }

    function testWhitelistingSingleAccount() public {
        address account = address(this);
        uint256 tokenId = 0;

        assertEq(rewarder.claimableTokens(account, tokenId), 0);

        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 1);

        assertEq(rewarder.claimableTokens(account, tokenId), 1);
    }

    function testCannotWhitelistWithoutRole() public {
        vm.expectRevert("Only whitelister account can manage minters list");
        rewarder.whitelistAccount(address(this), 0, 1);
    }

    function testSingleMint() public {
        address account = address(0x1337);
        uint256 tokenId = 0;

        assertEq(rewarder.balanceOf(account, tokenId), 0);

        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 1);

        // spoof sender to be `account`
        vm.prank(account);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(account, tokenId), 1);
    }

    function testMulitpleMintsBySameUser() public {
        address account = address(0x1337);
        uint256 tokenId = 0;

        assertEq(rewarder.balanceOf(account, tokenId), 0);

        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 2);

        vm.prank(account);
        rewarder.claim(tokenId, 1);

        vm.prank(account);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(account, tokenId), 2);
    }

    function testMultipleMintsOfSameTokenId() public {
        address addrA = address(0x1337A);
        address addrB = address(0x1337B);
        uint256 tokenId = 0;

        assertEq(rewarder.balanceOf(addrA, tokenId), 0);
        assertEq(rewarder.balanceOf(addrB, tokenId), 0);

        vm.prank(whitelister);
        rewarder.whitelistAccount(addrA, tokenId, 1);
        vm.prank(whitelister);
        rewarder.whitelistAccount(addrB, tokenId, 1);

        vm.prank(addrA);
        rewarder.claim(tokenId, 1);

        vm.prank(addrB);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(addrA, tokenId), 1);
        assertEq(rewarder.balanceOf(addrB, tokenId), 1);
    }

    function testCannotMintWhenPaused() public {
        address account = address(0x1337);
        uint256 tokenId = 0;

        // whitelist
        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 1);

        // pause the contract
        rewarder.pause();

        // check reward claim reverts
        vm.expectRevert("Pausable: paused");
        vm.prank(account);
        rewarder.claim(tokenId, 1);
    }
}
