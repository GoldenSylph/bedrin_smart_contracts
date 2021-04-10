#!/bin/bash

source ./scripts/utils/generate_truffle_config.sh

# generate_truffle_config "0.6.6" ".\/node_modules\/@uniswap\/v2-periphery\/contracts"
# truffle compile

# copy uniswap artifacts
if [[ ! -d ./build/contracts ]]; then
  echo Building directory is not exists! Creating one...
  mkdir -p ./build/contracts
fi
# cp ./node_modules/@uniswap/v2-core/build/UniswapV2Pair.json ./build/contracts
# cp ./node_modules/@uniswap/v2-core/build/UniswapV2Factory.json ./build/contracts
# cp ./node_modules/@uniswap/v2-periphery/build/WETH9.json ./build/contracts
# cp ./node_modules/@uniswap/v2-periphery/build/TransferHelper.json ./build/contracts
cp ./node_modules/@uniswap/v2-periphery/build/IUniswapV2Router02.json ./build/contracts
