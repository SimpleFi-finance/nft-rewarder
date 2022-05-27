#!/usr/bin/env bash

source .env

echo Deploying Simplefi NFT rewarder to Polygon
forge build --force --contracts ./src/
forge create ./src/NFTRewarder.sol:NFTRewarder --use 0.8.12 --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY --gas-price $POLYGON_GAS_PRICE --priority-fee $POLYGON_GAS_PRIORITY_FEE --constructor-args $WHITELISTER
echo Done!