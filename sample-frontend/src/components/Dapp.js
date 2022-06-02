import React from "react";
import { Container, Button, Image, Header, Card } from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import HeaderComp from "./Header";
import { ethers } from "ethers";
import axios from "axios";



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
    await this.loadNFTs();
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
        <Container textAlign="center">
          <Button
            size="huge"
            primary
            onClick={this.onClickClaim}
          >
            Claim your NFT!
          </Button>
          <br />
          <br />
        </Container>

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

        {(this.state.claimedNFTs.length > 0) && (
          <Card>
            <Image src={this.ipfsToHttpUrl(this.state.claimedNFTs[0].rewardImage)} wrapped ui={false} />
            <Card.Content>
              <Card.Header>{this.state.claimedNFTs[0].rewardName}</Card.Header>
              <Card.Description>
                {this.state.claimedNFTs[0].rewardDescription}
              </Card.Description>
            </Card.Content>
            <Card.Content extra>
              <a>
                You own: {this.state.claimedNFTs[0].amountOwned} <br />
                Total: {this.state.claimedNFTs[0].amountOwned}
              </a>
            </Card.Content>
          </Card>
        )
        }

      </Container>
    );
  }

  onClickClaim = async () => {
    // await this._claim();
  };

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

  /**
   * Show NFT rewards user has so far claimed 
   */
  async loadNFTs() {
    const [account] = await window.ethereum.enable();
    this.setState({ account });

    try {
      const query = `
      {
        accountBalances(where: {user: "${this.state.account}"}) {
          id
          reward {
            id
            name
            description
            image
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
          rewardImage: accBal.reward.image
        }));
      this.setState({ claimedNFTs: claimedNFTs });
    } catch (error) {
      console.error(error);
    }
  }

  /**
   * Load state data by calling contracts or from JSON file containing Merkle tree info.
   */
  async loadData() {
    // const isWhitelisted = merkleInfo.claims[this.state.account] !== undefined;
    // this.setState({ isWhitelisted });

    // if (isWhitelisted) {
    //   const merkleProof = merkleInfo.claims[this.state.account].proof;
    //   this.setState({ merkleProof });
    // }

    // const hasClaimed = await this._distributor.hasClaimed(this.state.account);
    // this.setState({ hasClaimed });

    // if (this.state.hasClaimed) {
    //   // user can have exactly 1 token so use index 0
    //   const usersTokenId = await this._erc721Enumberable.tokenOfOwnerByIndex(this.state.account, 0);
    //   const ipfsUrl = await this._erc721Enumberable.tokenURI(usersTokenId);
    //   const metadataHttpUrl = this.ipfsToHttpUrl(ipfsUrl);

    //   // fetch metadata and extract image url
    //   request(metadataHttpUrl, { json: true }, (error, res, body) => {
    //     if (error) {
    //       return console.log(error);
    //     }

    //     if (!error && res.statusCode === 200) {
    //       this.setState({ imageUrl: this.ipfsToHttpUrl(body.image) });
    //       this.setState({ imageName: body.name });
    //     }
    //   });
    // }
  }

  /**
   * Send the TX to Merkle distributor to claim NFT. Handle any error which may occur
   * @returns
   */
  async _claim() {
    try {
      this._dismissTransactionError();

      // send the transaction
      const tx = await this._distributor.claim(this.state.merkleProof);
      this.setState({ txBeingSent: tx.hash });
      const receipt = await tx.wait();

      // The receipt, contains a status flag, which is 0 to indicate an error.
      if (receipt.status === 0) {
        throw new Error("Transaction failed");
      } else {
        // TX successful
        await this.loadData();
      }
    } catch (error) {
      if (error.code === ERROR_CODE_TX_REJECTED_BY_USER) {
        return;
      } else {
        // store error for display
        console.error(error);
        this.setState({ transactionError: error });
      }
    } finally {
      this.setState({ txBeingSent: undefined });
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