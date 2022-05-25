// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";

/**
 * @title SimpleFiNFTRewarder
 * @dev Purpose of SimpleFi NFT Rewarder is to reward SimpleFi app users. Users can earn rewards in different ways, ie.
 * by being a beta tester of the platform, or by DeFi achievements - having the best farming ROI in the previous month,
 * or having all the base tokens invested in  DeFi protocols.
 *
 * Contract is implemented as ERC1155. Every tokenId represents one reward and can have mulitple owners. When user gets
 * eligible for reward, contract owner will whitelist him/her and user can then claim the reward.
 */
contract NFTRewarder is ERC1155, Ownable, Pausable {
    event Claimed(address indexed user, uint256 indexed tokenId, uint256 amount);
    event Whitelisted(address indexed user, uint256 indexed tokenId, uint256 amount);
    event RemovedFromWhitelist(address indexed user, uint256 indexed tokenId);
    event UriSet(uint256 indexed tokenId, string uri);

    mapping(address => mapping(uint256 => uint256)) public minters;
    mapping(address => mapping(uint256 => uint256)) public claimed;
    mapping(uint256 => string) private uris;
    address public whitelister;

    /**
     * @dev Constructor sets the whitelister account. It can be modified later by owner.
     */
    constructor(address _whitelister) ERC1155("") {
        whitelister = _whitelister;
    }

    /**
     * @dev Setter for metadata uri per tokenId.
     *
     * Emits a {UriSet} event.
     *
     * Requirements:
     *
     * - only owner can set uri
     * - uri can be set only once
     */
    function setUri(uint256 tokenId, string memory tokenUri) external onlyOwner {
        require(bytes(uris[tokenId]).length == 0, "NFTRewarder: URI already set!");
        uris[tokenId] = tokenUri;
        emit UriSet(tokenId, tokenUri);
    }

    /**
     * @dev Getter for metadata uri per tokenId.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return uris[tokenId];
    }

    /**
     * @dev Claim the token for the sender if eligible.
     *
     * Emits a {Claimed} event.
     *
     * Requirements:
     *
     * - user needs to have enough claimable tokens
     */
    function claim(uint256 tokenId, uint256 amount) external {
        require(claimableTokens(_msgSender(), tokenId) >= amount, "NFTRewarder: No claimable tokens");

        claimed[_msgSender()][tokenId] += amount;
        _mint(_msgSender(), tokenId, amount, "");

        emit Claimed(_msgSender(), tokenId, amount);
    }

    /**
     * @dev Return number of tokens user can claim for this tokenId.
     */
    function claimableTokens(address user, uint256 tokenId) public view returns (uint256) {
        return minters[user][tokenId] - claimed[user][tokenId];
    }

    /**
     * @dev Make account eligible for claiming token of tokenId collection.
     *
     * Emits a {Whitelisted} event.
     *
     * Requirements:
     *
     * - only whitelister can whitelist account
     * - account can't be zero address
     * - amount of claimable tokens has to be greater than zero
     */
    function whitelistAccount(
        address account,
        uint256 tokenId,
        uint256 amount
    ) public onlyWhitelister {
        require(account != address(0), "NFTRewarder: Can't whitelist zero address");
        require(amount > 0, "NFTRewarder: Whitelisted amount must be greater than zero");

        minters[account][tokenId] += amount;
        emit Whitelisted(account, tokenId, amount);
    }

    /**
     * @dev Add multiple accounts to the whitelist.
     */
    function batchWhitelistAccounts(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyWhitelister {
        uint256 arrayLength = accounts.length;

        for (uint256 i = 0; i < arrayLength; i++) {
            whitelistAccount(accounts[i], amounts[i], tokenIds[i]);
        }
    }

    /**
     * @dev Remove account's eligibility for the unclaimed tokens.
     *
     * Emits a {RemovedFromWhitelist} event.
     *
     * Requirements:
     *
     * - only whitelister can remove account from whitelist
     * - account can't be zero address
     */
    function removeAccountFromWhitelist(address account, uint256 tokenId) public onlyWhitelister {
        require(account != address(0), "NFTRewarder: Can't de-whitelist zero address");

        uint256 alreadyClaimed = claimed[account][tokenId];
        minters[account][tokenId] = alreadyClaimed;

        emit RemovedFromWhitelist(account, tokenId);
    }

    /**
     * @dev Remove eligibility for the unclaimed tokens for multiple accounts.
     */
    function batchRemoveFromWhitelist(address[] calldata accounts, uint256[] calldata tokenIds)
        external
        onlyWhitelister
    {
        uint256 arrayLength = accounts.length;

        for (uint256 i = 0; i < arrayLength; i++) {
            removeAccountFromWhitelist(accounts[i], tokenIds[i]);
        }
    }

    /**
     * @dev Set new whitelister account.
     *
     * Requirements:
     *
     * - only owner can set whitelister
     */
    function setWhitelister(address _whitelister) public onlyOwner {
        whitelister = _whitelister;
    }

    /**
     * @dev Pause the contract - tokens can't be claimed or transferred.
     *
     * Requirements:
     *
     * - only owner can pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract - tokens can again be claimed and transferred.
     *
     * Requirements:
     *
     * - only owner can unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Overriden to add pausability check.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Modifier checks sender is whitelister account
     */
    modifier onlyWhitelister() {
        require(_msgSender() == whitelister, "Only whitelister account can manage minters list");
        _;
    }
}
