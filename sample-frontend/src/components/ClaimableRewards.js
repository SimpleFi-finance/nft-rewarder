import React, { Component } from "react";
import { Card, Image, Button } from "semantic-ui-react";
import NFTRewarder from "../abis/NFTRewarder.json";
import { ethers } from "ethers";

class ClaimedRewards extends Component {
    render() {
        return (
            <Card.Group centered>
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
        const erc1155 = new ethers.Contract(
            tokenAddress,
            NFTRewarder.abi,
            this.props.signer
        );

        const tx = await erc1155.claim(tokenId, amountClaimable);
        const receipt = await tx.wait();

        if (receipt.status === 0) {
            console.log("Transaction failed");
        } else {
            console.log("Transaction successful");
        }
    };
}

export default ClaimedRewards;