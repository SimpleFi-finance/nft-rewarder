#!/usr/bin/env bash

source .env

echo Verify Simplefi NFT rewarder contract

CONTRACT_TO_VERIFY="0x1b09461084b567df0ddf65967d2e5bf3b3699b19"
forge verify-contract --chain-id 137 --constructor-args $(cast abi-encode "constructor(address)" $WHITELISTER) --compiler-version v0.8.12+commit.f00d7308 $CONTRACT_TO_VERIFY ./src/NFTRewarder.sol:NFTRewarder $POLYSCAN_API_KEY

echo Done!

