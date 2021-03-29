/* eslint no-unused-vars: 0 */
/* eslint eqeqeq: 0 */

const { strategyTestSuite } = require("./eurxb_strategy_test.js");
const InstitutionalEURxbStrategy = artifacts.require("InstitutionalEURxbStrategy");
contract('InstitutionalEURxbStrategy', strategyTestSuite(InstitutionalEURxbStrategy));
