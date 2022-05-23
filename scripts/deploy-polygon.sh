#!/usr/bin/env bash

source .env

echo Deploying Simplefi NFT rewarder to Polygon
forge build --contracts ./src/
forge create ./src/NFTRewarder.sol:NFTRewarder --use 0.8.12 --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY --gas-price $ETH_GAS_PRICE --priority-fee $ETH_GAS_PRIORITY_FEE --constructor-args 0xDAD7513A41877B23C627f0427dd3237F35Cb8F7d 
echo Done!

