import React from "react";
import { Container, Button, Image, Header, Card } from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import HeaderComp from "./Header";
import { ethers } from "ethers";
import axios from "axios";
import ClaimedRewards from "./ClaimedRewards";
import ClaimableRewards from "./ClaimableRewards";





import { NoWalletDetected } from "./NoWalletDetected";
import { ConnectWallet } from "./ConnectWallet";
import { TransactionErrorMessage } from "./TransactionErrorMessage";
import { WaitingForTransactionMessage } from "./WaitingForTransactionMessage";
const request = require("request");

const ERROR_CODE_TX_REJECTED_BY_USER = 4001;
const SUBGRAPH_ENDPOINT = 'https://api.thegraph.com/subgraphs/name/gvladika/nft-rewarder';

export class Dapp extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      account: "",
      claimedNFTs: [],
      claimableNFTs: [],

      // hasClaimed: false,
      // isWhitelisted: false,
      // merkleProof: "",
      // imageUrl: "",
      // imageName: "",

      // txBeingSent: undefined,
      // transactionError: undefined,
      // networkError: undefined,
    };
  }

  async componentDidMount() {
    await this.loadEthers();
    await this.loadData();
  }

  render() {
    if (this.state.account === "") {
      return <NoWalletDetected />;
    }

    // connect wallet
    if (!this.state.account) {
      return (
        <ConnectWallet
          connectWallet={() => this._connectWallet()}
          networkError={this.state.networkError}
          dismiss={() => this._dismissNetworkError()}
        />
      );
    }

    // If everything is loaded, we render the application.
    return (
      <Container>
        <HeaderComp account={this.state.account} />

        {/* {this.state.hasClaimed && (
          <Container textAlign="center">
            <Header as="h1">Congrats, you're a SimpleFi OG!</Header>
            <br />
            <Header as="h3">{this.state.imageName}</Header>
            <Image size="medium" centered src={this.state.imageUrl} />
          </Container>
        )}
        {this.state.txBeingSent && <WaitingForTransactionMessage txHash={this.state.txBeingSent} />}
        {this.state.transactionError && (
          <TransactionErrorMessage
            message={this._getRpcErrorMessage(this.state.transactionError)}
            dismiss={() => this._dismissTransactionError()}
          />
        )} */}

        <Header as='h3' block textAlign='center'  >
          Congrats, you are eligible to claim NFT reward!
        </Header>

        {(this.state.claimableNFTs.length > 0) && (
          <ClaimableRewards
            nfts={this.state.claimableNFTs}
            signer={this._provider.getSigner(0)}
          ></ClaimableRewards>
        )
        }

        <Header as='h3' block textAlign='center'  >
          My rewards
        </Header>

        {(this.state.claimedNFTs.length > 0) && (
          <ClaimedRewards
            nfts={this.state.claimedNFTs}
          ></ClaimedRewards>
        )
        }

      </Container>
    );
  }


  /**
   *
   * @returns Load web3 provider
   */
  async loadEthers() {
    this._provider = new ethers.providers.Web3Provider(window.ethereum);

    window.ethereum.on("accountsChanged", async (accounts) => {
      this._resetState();
      this.setState({ account: accounts[0] });
      console.log("accountsChanged => " + accounts[0]);
      await this.loadData();
    });
  }

  async loadData() {
    const [account] = await window.ethereum.enable();
    this.setState({ account });

    await this.loadClaimedNFTs();
    await this.loadClaimableNFTs();
  }

  /**
   * Show NFT rewards user has so far claimed 
   */
  async loadClaimedNFTs() {
    try {
      const query = `
      {
        accountBalances(where: {user: "${this.state.account}", amountOwned_gt: 0}) {
          id
          reward {
            id
            name
            description
            image
            supply
            tokenAddress
            tokenId
          }
          amountOwned
        }
      }
      `;

      const subgraphResponse = await axios.post(SUBGRAPH_ENDPOINT, { query: query });
      const accountBalances = subgraphResponse.data.data.accountBalances;

      var claimedNFTs = []
      accountBalances.forEach(accBal =>
        claimedNFTs.push({
          id: accBal.id,
          amountOwned: accBal.amountOwned,
          rewardName: accBal.reward.name,
          rewardDescription: accBal.reward.description,
          rewardImage: this.ipfsToHttpUrl(accBal.reward.image),
          rewardSupply: accBal.reward.supply,
          rewardTokenAddress: accBal.reward.tokenAddress,
          rewardTokenId: accBal.reward.tokenId
        }));
      this.setState({ claimedNFTs: claimedNFTs });
    } catch (error) {
      console.error(error);
    }
  }

  async loadClaimableNFTs() {
    try {
      const query = `
      {
        accountBalances(where: {user: "${this.state.account}", amountClaimable_gt: 0}) {
          id
          user {
            id
          }
          reward {
            id
            name
            description
            image
            supply
            tokenAddress
            tokenId
          }
          amountClaimable
        }
      }
      `;

      const subgraphResponse = await axios.post(SUBGRAPH_ENDPOINT, { query: query });
      const accountBalances = subgraphResponse.data.data.accountBalances;

      var claimableNFTs = []
      accountBalances.forEach(accBal =>
        claimableNFTs.push({
          id: accBal.id,
          amountClaimable: accBal.amountClaimable,
          rewardName: accBal.reward.name,
          rewardDescription: accBal.reward.description,
          rewardImage: this.ipfsToHttpUrl(accBal.reward.image),
          rewardSupply: accBal.reward.supply,
          rewardTokenAddress: accBal.reward.tokenAddress,
          rewardTokenId: accBal.reward.tokenId
        }));
      this.setState({ claimableNFTs: claimableNFTs });
    } catch (error) {
      console.error(error);
    }
  }



  ipfsToHttpUrl(ipfsUrl) {
    let prefix = "https://ipfs.io/ipfs/";
    // remove 'ipfs://'
    let ipfsHash = ipfsUrl.slice(7);
    return prefix + ipfsHash;
  }

  _resetState() {
    this.state = {
      account: "",
      claimedNFTs: [],
      hasClaimableTokens: false

      // hasClaimed: false,
      // isWhitelisted: false,
      // merkleProof: "",
      // imageUrl: "",
      // imageName: "",

      // txBeingSent: undefined,
      // transactionError: undefined,
      // networkError: undefined,
    };
  }

  _dismissTransactionError() {
    this.setState({ transactionError: undefined });
  }

  _dismissNetworkError() {
    this.setState({ networkError: undefined });
  }

  _getRpcErrorMessage(error) {
    if (error.data) {
      return error.data.message;
    }

    return error.message;
  }

  async _connectWallet() {
    const [account] = await window.ethereum.enable();
    this.setState({ account });
    this.loadData();
  }
}