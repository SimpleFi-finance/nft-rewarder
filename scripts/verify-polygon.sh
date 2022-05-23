#!/usr/bin/env bash

source .env

echo Verify Simplefi NFT rewarder contract

forge verify-contract --chain-id 137 --constructor-args $(cast abi-encode "constructor(address)" $WHITELISTER) --compiler-version v0.8.12+commit.f00d7308 0xad9527406dDe96f1e92e3Cc699CCD24ace786bd5 ./src/NFTRewarder.sol:NFTRewarder $POLYSCAN_API_KEY

echo Done!

