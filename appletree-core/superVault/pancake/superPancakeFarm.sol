// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.8.0;

import "./superPancakeBase.sol";
import "./IMasterChefPancake.sol";
import "../../uniswap/IUniswapV2Pair.sol";
// superToken is the coolest vault in town. You come in with some token, and leave with more! The longer you stay, the more token you get.
//
// This contract handles swapping to and from superToken.
contract superPancakeFarm is superPancakeBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IMasterChefPancake public constant masterChefPancake = IMasterChefPancake(0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652);
    uint256 public poolId;
    address public constant cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // Define the qiToken token contract
    constructor(address multiSignature,address origin0,address origin1,address _stakeToken,address _dsOracle,address payable _FeePool,uint256 _poolId)
            superPancakeBase(multiSignature,origin0,origin1,_stakeToken,_dsOracle,_FeePool) {
        poolId = _poolId;
        IERC20(_stakeToken).safeApprove(address(masterChefPancake), uint(-1));
        _setReward(0,0,false,cake,1e17);
    }
    function stakeBalance()public view returns (uint256){
        (uint amount,) = masterChefPancake.userInfo(poolId,address(this));
        return amount;
    }
    // Enter the bar. Pay some stakeTokens. Earn some shares.
    // Locks stakeToken and mints superToken
    function enter(uint256 _amount) external nonReentrant {
        // Gets the amount of stakeToken locked in the contract
        uint256 totalstakeToken = stakeBalance();
        // Gets the amount of superToken in existence
        uint256 totalShares = totalSupply();
        // If no superToken exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalstakeToken == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of superToken the stakeToken is worth. The ratio will change overtime, as superToken is burned/minted and stakeToken deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalstakeToken);
            _mint(msg.sender, what);
        }
        // Lock the stakeToken in the contract
        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
        masterChefPancake.deposit(poolId,_amount);
    }
    // Leave the bar. Claim back your stakeTokens.
    // Unlocks the staked + gained stakeToken and burns superToken
    function leave(uint256 _share) external nonReentrant {
        // Gets the amount of superToken in existence
        uint256 totalShares = totalSupply();
        uint256 totalstakeToken = stakeBalance();
        // Calculates the amount of stakeToken the superToken is worth
        uint256 what = _share.mul(totalstakeToken).div(totalShares);
        _burn(msg.sender, _share);
        _withdraw(what);
        stakeToken.safeTransfer(msg.sender, what);
    }
    function _withdraw(uint256 _amount)internal {
        masterChefPancake.withdraw(poolId,_amount);
    }
    function swapPancake(address token0,address token1,uint256 balance)internal{
        if(token0 == token1){
            return;
        }
        uint256 minOut = getSwapMinAmountOut(token0,token1,balance);
        address[] memory path = getSwapRouterPathInfo(token0,token1);
        if (token0 == address(0)){
            IPancakeRouter01(cakeRouter).swapExactETHForTokens{value : balance}(minOut,path,address(this),block.timestamp+30);
        }else{
            if (token1 == address(0)){
                IPancakeRouter01(cakeRouter).swapExactTokensForETH(balance,minOut,path,address(this),block.timestamp+30);
            }else{
                IPancakeRouter01(cakeRouter).swapExactTokensForTokens(balance,minOut,path,address(this),block.timestamp+30);
            }
        }
    }
}