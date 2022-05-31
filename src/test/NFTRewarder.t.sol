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
        assertTrue(keccak256(abi.encode(_uri)) == keccak256(abi.encode(uriToken0)));
    }

    function testOnlyOwnerCanSetUri() public {
        // try to set uri by random user 0x1437
        string memory uriToken0 = "https://token-cdn-domain/0.json";
        vm.prank(address(0x1437));
        vm.expectRevert("Ownable: caller is not the owner");
        rewarder.setUri(0, uriToken0);
    }

    function testCannotSetUriTwice() public {
        string memory uriToken0 = "https://first/0.json";
        string memory newUriToken0 = "https://second/0.json";

        rewarder.setUri(0, uriToken0);
        vm.expectRevert("NFTRewarder: URI already set!");
        rewarder.setUri(0, newUriToken0);
    }

    function testWhitelistingSingleAccount() public {
        address account = address(this);
        uint256 tokenId = 0;
        rewarder.setUri(tokenId, "ipfs://xy");

        assertEq(rewarder.claimableTokens(account, tokenId), 0);

        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 1);

        assertEq(rewarder.claimableTokens(account, tokenId), 1);
    }

    function testCannotWhitelistWithoutRole() public {
        vm.expectRevert("NFTRewarder: Only whitelister account can manage minters list");
        rewarder.whitelistAccount(address(this), 0, 1);
    }

    function testCannotWhitelistForNonexistingToken(uint256 tokenId) public {
        // can't whitelist account before URI is set
        vm.expectRevert("NFTRewarder: URI has to be set before whitelisting accounts");
        vm.prank(whitelister);
        rewarder.whitelistAccount(address(this), tokenId, 1);

        // should work after setting URI
        rewarder.setUri(tokenId, "ipfs://xy");
        vm.prank(whitelister);
        rewarder.whitelistAccount(address(this), tokenId, 1);
    }

    function testBatchWhitelisting() public {
        address alice = address(0xa);
        address bob = address(0xb);
        uint256 tokenId = 0;
        rewarder.setUri(tokenId, "ipfs://xy");

        address[] memory accounts = new address[](2);
        accounts[0] = alice;
        accounts[1] = bob;

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = tokenId;

        uint256[] memory amounts = new uint256[](2);
        tokenIds[0] = 2;
        tokenIds[1] = 1;

        vm.prank(whitelister);
        rewarder.batchWhitelistAccounts(accounts, tokenIds, amounts);

        assertEq(rewarder.claimableTokens(alice, tokenId), 2);
        assertEq(rewarder.claimableTokens(bob, tokenId), 1);
    }

    function testRemovingFromWhitelist() public {
        address account = address(this);
        uint256 tokenId = 7;
        rewarder.setUri(tokenId, "ipfs://xy");

        // whitelist account
        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 3);
        assertEq(rewarder.claimableTokens(account, tokenId), 3);

        // remove from whitelist
        vm.prank(whitelister);
        rewarder.removeAccountFromWhitelist(account, tokenId);

        // check it's 0 claimable tokens now
        assertEq(rewarder.claimableTokens(account, tokenId), 0);
    }

    function testSingleClaim() public {
        address account = address(0x1337);
        uint256 tokenId = 0;
        rewarder.setUri(tokenId, "ipfs://xy");

        assertEq(rewarder.balanceOf(account, tokenId), 0);

        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 1);

        // spoof sender to be `account`
        vm.prank(account);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(account, tokenId), 1);
    }

    function testCannotClaimIfNotWhitelisted() public {
        address account = address(0x1337);
        uint256 tokenId = 0;

        // check reward claim reverts
        vm.expectRevert("NFTRewarder: No claimable tokens");
        vm.prank(account);
        rewarder.claim(tokenId, 1);
    }

    function testMultipleClaimsBySameUser() public {
        address account = address(0x1337);
        uint256 tokenId = 0;
        rewarder.setUri(tokenId, "ipfs://xy");

        assertEq(rewarder.balanceOf(account, tokenId), 0);

        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 2);

        vm.prank(account);
        rewarder.claim(tokenId, 1);

        vm.prank(account);
        rewarder.claim(tokenId, 1);

        assertEq(rewarder.balanceOf(account, tokenId), 2);
    }

    function testCannotClaimMoreThanWhitelistedAmount() public {
        address account = address(0x1337);
        uint256 tokenId = 10;
        rewarder.setUri(tokenId, "ipfs://xy");

        // whitelist 2 tokens for user
        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 2);

        // claim 2 times
        vm.startPrank(account);
        rewarder.claim(tokenId, 1);
        rewarder.claim(tokenId, 1);

        // 3rd claim should fail
        vm.expectRevert("NFTRewarder: No claimable tokens");
        rewarder.claim(tokenId, 1);
    }

    function testMultipleClaimOfSameTokenId() public {
        address addrA = address(0x1337A);
        address addrB = address(0x1337B);
        uint256 tokenId = 0;
        rewarder.setUri(tokenId, "ipfs://xy");

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
        rewarder.setUri(tokenId, "ipfs://xy");

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

    function testMintAfterUnpausing() public {
        address account = address(0x1337);
        uint256 tokenId = 0;
        rewarder.setUri(tokenId, "ipfs://xy");

        // whitelist
        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 1);

        // pause the contract
        rewarder.pause();

        // check reward claim reverts
        vm.expectRevert("Pausable: paused");
        vm.prank(account);
        rewarder.claim(tokenId, 1);

        // unpause the contract
        rewarder.unpause();

        // claim should work now
        vm.prank(account);
        rewarder.claim(tokenId, 1);
        assertEq(rewarder.balanceOf(account, tokenId), 1);
    }

    function testChangingWhitelister() public {
        address account = address(0x1337);
        uint256 tokenId = 0;
        rewarder.setUri(tokenId, "ipfs://xy");

        // initial whitelister can whitelist
        vm.prank(whitelister);
        rewarder.whitelistAccount(account, tokenId, 1);

        address oldWhitelister = whitelister;
        address newWhitelister = address(0x1338);

        // set new whitelister
        rewarder.setWhitelister(newWhitelister);

        // old whitelister cannot whitelist
        vm.prank(oldWhitelister);
        vm.expectRevert("NFTRewarder: Only whitelister account can manage minters list");
        rewarder.whitelistAccount(account, tokenId, 1);

        // but new whitelister can whitelist
        vm.prank(newWhitelister);
        rewarder.whitelistAccount(account, tokenId, 1);
    }
}
