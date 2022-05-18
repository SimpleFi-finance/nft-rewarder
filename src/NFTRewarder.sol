// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/token/ERC1155/ERC1155.sol";
import "@openzeppelin/access/AccessControl.sol";

contract NFTRewarder is ERC1155, AccessControl {
    // track how many reward tokens user is eligible to mint per collection id
    mapping(address => mapping(uint256 => uint256)) public minters;

    // track how many reward tokens user has claimed per tokenId
    mapping(address => mapping(uint256 => uint256)) public claimed;

    // tokenId to uri mapping
    mapping(uint256 => string) public uris;

    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    //// Events
    event Claimed(address indexed user, uint256 indexed id, uint256 amount);
    event Whitelisted(address indexed user, uint256 indexed id, uint256 amount);
    event RemovedFromWhitelist(address indexed user, uint256 indexed id);

    constructor(address whitelister) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITELISTER_ROLE, whitelister);
    }

    // Setter for metadata uri per tokenId
    function setUri(uint256 _tokenId, string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uris[_tokenId] = _uri;
    }

    // Getter for metadata uri per tokenId
    function uri(uint256 tokenId) public view override returns (string memory) {
        return uris[tokenId];
    }

    //// User functions

    // Claim the token for msg.sender
    function claim(uint256 tokenId, uint256 amount) external {
        require(
            claimableTokens(msg.sender, tokenId) >= amount,
            "Whitelister: No claimable tokens"
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
    ) external onlyRole(WHITELISTER_ROLE) {
        require(account != address(0), "Can't whitelist zero address");
        require(amount > 0, "Whitelisted amount must be greater than zero");
        minters[account][tokenId] += amount;

        emit Whitelisted(account, tokenId, amount);
    }

    // Add multiple accounts to the whitelist
    function batchWhitelistAccounts(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyRole(WHITELISTER_ROLE) {
        uint256 arrayLength = accounts.length;

        address account;
        uint256 amount;
        uint256 tokenId;

        for (uint256 i = 0; i < arrayLength; i++) {
            account = accounts[i];
            amount = amounts[i];
            tokenId = tokenIds[i];

            require(account != address(0), "Can't whitelist zero address");
            require(amount > 0, "Whitelisted amount must be greater than zero");

            minters[account][tokenId] += amount;

            emit Whitelisted(account, tokenId, amount);
        }
    }

    // Remove account from minters (and from `claimed`)
    function removeAccountFromWhitelist(address account, uint256 tokenId)
        external
        onlyRole(WHITELISTER_ROLE)
    {
        require(account != address(0), "Can't de-whitelist zero address");

        minters[account][tokenId] = 0;
        claimed[account][tokenId] = 0;

        emit RemovedFromWhitelist(account, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
