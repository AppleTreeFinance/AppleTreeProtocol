// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.8.0;
import "../modules/whiteListAddress.sol";
import "../modules/ReentrancyGuard.sol";
import "../modules/proxyOperator.sol";
import "../modules/safeTransfer.sol";
import "../modules/Halt.sol";
/**
 * @title systemCoin mine pool, which manager contract is systemCoin.
 * @dev A smart-contract which distribute some mine coins by systemCoin balance.
 *
 */
abstract contract MinePoolData is Halt,proxyOperator,safeTransfer,ReentrancyGuard {
    
    // The eligible adress list
    address[] internal whiteList;
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;
    uint256 constant rayDecimals = 1e27;
    // miner's balance
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerBalances;
    // miner's origins, specially used for mine distribution
    // map mineCoin => user => balance
    mapping(address=>mapping(address=>uint256)) internal minerOrigins;
    
    // mine coins total worth, specially used for mine distribution
    mapping(address=>uint256) internal mineNetworth;
    // total distributed mine coin amount
    mapping(address=>uint256) internal totalMinedCoin;
    // latest time to settlement
    mapping(address=>uint256) internal latestSettleTime;
    //distributed mine amount
    mapping(address=>uint256) internal mineAmount;
    //distributed time interval
    mapping(address=>uint256) internal mineInterval;

    mapping(address=>uint256) internal distributeBalance;
    uint256 internal _totalsupply;

    event SetMineCoinInfo(address indexed from,address indexed mineCoin,uint256 _mineAmount,uint256 _mineInterval);
    event TranserMiner(address indexed from, address indexed to);
    event ChangeUserbalance(address indexed Account,int256 amount);
    event RedeemMineCoin(address indexed from, address indexed mineCoin, uint256 value);    
}