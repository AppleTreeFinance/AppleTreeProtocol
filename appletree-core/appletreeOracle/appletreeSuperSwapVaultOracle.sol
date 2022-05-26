/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2020 defrost Protocol
 */
pragma solidity >=0.7.0 <0.8.0;
import "./chainLinkOracle.sol";
import "../uniswap/IUniswapV2Pair.sol";
import "../modules/SafeMath.sol";
import "../interface/ISuperToken.sol";
import "../interface/IStakeDao.sol";
contract AppleTreeSuperSwapVaultOracle is chainLinkOracle {
    using SafeMath for uint256;
    
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    constructor(address multiSignature,address origin0,address origin1)
    chainLinkOracle(multiSignature,origin0,origin1) {
        _setAssetsAggregator(WBNB,0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); //bnb
        _setAssetsAggregator(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82, 0xB6064eD41d4f67e353768aA239cA86f4F73665a1); //cake
        _setAssetsAggregator(0x55d398326f99059fF775485246999027B3197955,0xB97Ad0E74fa7d920791E90258A6E2085088b4320); //usdt
        _setAssetsAggregator(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d,0x51597f405303C4377E36123cBc172b13269EA163); //usdc
        _setAssetsAggregator(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,0xcBb98864Ef56E9042e7d2efef76141f15731B82f); //busd
    }

    function getPriceInfo(address token) public override view returns (bool,uint256){
        (bool bHave,uint256 price) = _getPrice(uint256(token));
        if(bHave){
            return (bHave,price);
        }
          
        (bool success,) = token.staticcall(abi.encodeWithSignature("stakeToken()"));
        if(success){
            return getSuperPrice(token);
        }
        (success,) = token.staticcall(abi.encodeWithSignature("getReserves()"));
        if(success){
            return getUniswapPairPrice(token);
        }
        return (false,0);
    }
    function getSuperPrice(address token) public view returns (bool,uint256){
        address underlying = ISuperToken(token).stakeToken();
        (bool bTol,uint256 price) = getInnerTokenPrice(underlying);
        uint256 totalSuply = IERC20(token).totalSupply();
        if(totalSuply == 0){
            return (bTol,price);
        }
        uint256 balance = ISuperToken(token).stakeBalance();
        //1 qiToken = balance(underlying)/totalSuply super
        return (bTol,price.mul(balance)/totalSuply);
    }
    function getInnerTokenPrice(address token) internal view returns (bool,uint256){
        (bool bHave,uint256 price) = _getPrice(uint256(token));
        if(bHave){
            return (bHave,price);
        }
           
        (bool success,) = token.staticcall(abi.encodeWithSignature("getReserves()"));
        if(success){
            return getUniswapPairPrice(token);
        }
        return (false,0);
    }
    
    
    function getUniswapPairPrice(address pair) public view returns (bool,uint256) {
        IUniswapV2Pair upair = IUniswapV2Pair(pair);
        (uint112 reserve0, uint112 reserve1,) = upair.getReserves();
        (bool have0,uint256 price0) = _getPrice(uint256(upair.token0()));
        (bool have1,uint256 price1) = _getPrice(uint256(upair.token1()));
        uint256 totalAssets = 0;
        if(have0 && have1){
            price0 *= reserve0;  
            price1 *= reserve1;
            uint256 tol = price1/10;  
            bool inTol = (price0 < price1+tol && price0 > price1-tol);
            totalAssets = price0+price1;
            uint256 total = upair.totalSupply();
            if (total == 0){
                return (false,0);
            }
            return (inTol,totalAssets/total);
        }else{
            return (false,0);
        }
    }
}