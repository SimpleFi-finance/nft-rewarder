// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";

contract NFTRewarder is ERC1155, Ownable, Pausable {
    // track how many reward tokens user is eligible to mint per collection id
    mapping(address => mapping(uint256 => uint256)) public minters;

    // track how many reward tokens user has claimed per tokenId
    mapping(address => mapping(uint256 => uint256)) public claimed;

    // tokenId to uri mapping
    mapping(uint256 => string) public uris;

    // account responsible for whitelisting
    address public whitelister;

    //// Events
    event Claimed(address indexed user, uint256 indexed id, uint256 amount);
    event Whitelisted(address indexed user, uint256 indexed id, uint256 amount);
    event RemovedFromWhitelist(address indexed user, uint256 indexed id);

    constructor(address _whitelister) ERC1155("") {
        whitelister = _whitelister;
    }

    // Setter for metadata uri per tokenId
    function setUri(uint256 _tokenId, string memory _uri) external onlyOwner {
        uris[_tokenId] = _uri;
    }

    // Getter for metadata uri per tokenId
    function uri(uint256 tokenId) public view override returns (string memory) {
        return uris[tokenId];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // overriden to add pausability check
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

    //// User functions

    // Claim the token for msg.sender
    function claim(uint256 tokenId, uint256 amount) external {
        require(
            claimableTokens(msg.sender, tokenId) >= amount,
            "NFTRewarder: No claimable tokens"
        );

        // Mark it claimed and send the token(s)
        claimed[msg.sender][tokenId] += amount;
        _mint(msg.sender, tokenId, amount, "");

        emit Claimed(msg.sender, tokenId, amount);
    }

    // Return number of tokens in `tokenId` collection user can claim
    function claimableTokens(address user, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return minters[user][tokenId] - claimed[user][tokenId];
    }

    //// Owner functions

    // Add account to the whitelist
    function whitelistAccount(
        address account,
        uint256 tokenId,
        uint256 amount
    ) public onlyWhitelister {
        require(
            account != address(0),
            "NFTRewarder: Can't whitelist zero address"
        );
        require(
            amount > 0,
            "NFTRewarder: Whitelisted amount must be greater than zero"
        );
        minters[account][tokenId] += amount;

        emit Whitelisted(account, tokenId, amount);
    }

    // Add multiple accounts to the whitelist
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

    // Remove account from minters (and from `claimed`)
    function removeAccountFromWhitelist(address account, uint256 tokenId)
        external
        onlyWhitelister
    {
        require(account != address(0), "Can't de-whitelist zero address");

        minters[account][tokenId] = 0;
        claimed[account][tokenId] = 0;

        emit RemovedFromWhitelist(account, tokenId);
    }

    function setWhitelister(address _whitelister) public onlyOwner {
        whitelister = _whitelister;
    }

    modifier onlyWhitelister() {
        require(
            _msgSender() == whitelister,
            "Only whitelister account can manage minters list"
        );
        _;
    }
}
