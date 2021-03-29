const MockToken = artifacts.require('MockToken');

const usd = (n) => web3.utils.toWei(n, 'Mwei');
const ether = (n) => web3.utils.toWei(n, 'ether');

module.exports = function (deployer, network, accounts) {
  deployer.then(async () => {
    if (network === 'test' || network === 'soliditycoverage') {
      
    } else {
      console.error(`Unsupported network: ${network}`);
    }
  });
};
