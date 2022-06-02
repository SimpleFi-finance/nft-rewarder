import React, { Component } from "react";
import { Card, Image } from "semantic-ui-react";

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
                            <a>
                                You can claim: {nft.amountClaimable} <br />
                                Total: {nft.amountClaimable}
                            </a>
                        </Card.Content>
                    </Card>
                );
            });
    }
}

export default ClaimedRewards;