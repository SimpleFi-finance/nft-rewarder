# <h1 align="center"> NFT rewarder system </h1>

Smart contract

-   ERC1155
    -   Mapping from token ID to account balances:  
        `mapping(uint256 => mapping(address => uint256)) private _balances;`
-   whitelisting integrated into contract
    -   data structure which holds mapping between NFT <-> eligible user
    -   can be updated in batches, to minimize gas cost
-   compatibility with Opensea
-   extensive testing - hardhat tests or Foundry
-   chain?

Reward eligibility

-   plug-in scripts checking the subgraphs (or some other data source) for specific criteria
    -   script can be a cron-job
-   script's output should be account or list of accounts, stored to file/DB
-   result (account eligible for reward) should be checked manually
    -   do the numbers make sense?
    -   is account EOA or contract?
-   add NFT metadata and jpeg to IPFS and pin it (Pinata)
-   send TX to smart contract, making user whitelisted to mint his NFT

UI

-   create jpegs and metadata
-   integrate minting functionality into UI
    -   alert to make user aware of NFT eligibility
    -   minting button
-   display my reward NFTs
-   display page for all the rewarded NFTs - leaderboard, statistics, etc.
