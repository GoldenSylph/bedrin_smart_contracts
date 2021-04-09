#!/bin/bash
export CONFIG_NAME="./truffle-config.js"
source ./scripts/utils/generate_truffle_config.sh

generate_truffle_config "0.8.3" ".\/contracts"

if [ -z $1 ]; then
  echo "Nothing to verify..."
  # truffle run verify MultiSignature --network rinkeby
  # truffle run verify AllowList --network rinkeby
  # truffle run verify BondToken --network rinkeby
  # truffle run verify SecurityAssetToken --network rinkeby
  # truffle run verify DDP --network rinkeby
  # truffle run verify EURxb --network rinkeby
  # truffle run verify Router --network rinkeby
  # truffle run verify StakingManager --network rinkeby
else
  if [ -z $2 ]; then
    truffle run verify $1 --network rinkeby
  else
    if [[ $1 = "all" ]]; then
      echo "Nothing to verify all..."
      # truffle run verify MultiSignature --network $2
      # truffle run verify AllowList --network $2
      # truffle run verify BondToken --network $2
      # truffle run verify SecurityAssetToken --network $2
      # truffle run verify DDP --network $2
      # truffle run verify EURxb --network $2
      # truffle run verify Router --network $2
      # truffle run verify StakingManager --network $2
    else
      truffle run verify $1 --network $2
    fi
  fi
fi

# remove config file
rm -f $CONFIG_NAME
