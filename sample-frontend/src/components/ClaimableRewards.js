import React, { Component } from "react";
import { Card, Image, Button } from "semantic-ui-react";
import NFTRewarder from "../abis/NFTRewarder.json";
import { ethers } from "ethers";

class ClaimedRewards extends Component {
    render() {
        return (
            <Card.Group>
                {this.renderCards()}
            </Card.Group>
        );
    }

    renderCards() {
        return Object.keys(this.props.nfts)
            .map((nftId) => {
                let nft = this.props.nfts[nftId];
                return (
                    <Card>
                        <Image src={nft.rewardImage} wrapped ui={false} />
                        <Card.Content>
                            <Card.Header>{nft.rewardName}</Card.Header>
                            <Card.Description>
                                {nft.rewardDescription}
                            </Card.Description>
                        </Card.Content>
                        <Card.Content extra>
                            <div>

                                <a>
                                    Claimable: {nft.amountClaimable} <br />
                                    Total supply: {nft.rewardSupply}
                                </a>

                                <Button floated='right' primary onClick={(e) => this.onClickClaim(e, nft.rewardTokenAddress, nft.rewardTokenId, nft.amountClaimable)}>
                                    Claim
                                </Button>
                            </div>

                        </Card.Content>
                    </Card>
                );
            });
    }

    onClickClaim = async (event, tokenAddress, tokenId, amountClaimable) => {
        console.log("Click click", tokenAddress, tokenId);


        const erc1155 = new ethers.Contract(
            tokenAddress,
            NFTRewarder.abi,
            this.props.signer
        );

        const tx = await erc1155.claim(tokenId, 1);
        const receipt = await tx.wait();

        if (receipt.status === 0) {
            console.log("Transaction failed");
        } else {
            console.log("Transaction successful");
        }

        // try {
        //     this._dismissTransactionError();

        //     // send the transaction
        //     const tx = await this._distributor.claim(this.state.merkleProof);
        //     this.setState({ txBeingSent: tx.hash });
        //     const receipt = await tx.wait();

        //     // The receipt, contains a status flag, which is 0 to indicate an error.
        //     if (receipt.status === 0) {
        //         throw new Error("Transaction failed");
        //     } else {
        //         // TX successful
        //         await this.loadData();
        //     }
        // } catch (error) {
        //     if (error.code === ERROR_CODE_TX_REJECTED_BY_USER) {
        //         return;
        //     } else {
        //         // store error for display
        //         console.error(error);
        //         this.setState({ transactionError: error });
        //     }
        // } finally {
        //     this.setState({ txBeingSent: undefined });
        // }
    };
}

export default ClaimedRewards;