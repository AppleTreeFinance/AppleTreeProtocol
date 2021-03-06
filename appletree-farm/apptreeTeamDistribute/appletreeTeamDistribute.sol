pragma solidity ^0.5.16;
import "../modules/SafeMath.sol";
import "../modules/IERC20.sol";
import "../modules/proxyOwner.sol";
import "./appletreeTeamDistributeStorage.sol";

/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract TeamDistribute is appletreeTeamDistributeStorage,proxyOwner {

    using SafeMath for uint256;
    modifier inited (){
    	  require(rewardToken !=address(0));
    	  _;
    }

    constructor(address _multiSignature,address origin0,address origin1,
                address _rewardToken)
        proxyOwner(_multiSignature,origin0,origin1)
        public
    {
        rewardToken = _rewardToken;
    }

    function setRewardToken(address _rewardToken)  public onlyOrigin {
		rewardToken = _rewardToken;
    } 
	
    /**
     * @dev getting back the left mine token
     * @param reciever the reciever for getting back mine token
     */
    function getbackLeftReward(address reciever)  public onlyOrigin {
        uint256 bal =  IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).transfer(reciever,bal);
    }  

    function setMultiUsersInfo( address[] memory users,
                                uint256[] memory ratio)
        public
        inited
        OwnerOrOrigin
    {
        require(users.length==ratio.length);
        for(uint256 i=0;i<users.length;i++){
            require(users[i]!=address(0),"user address is 0");
            require(ratio[i]>0,"ratio should be bigger than 0");

            require(allUserIdx[users[i]]==0,"the user exist already");
			userCount++;
            allUserIdx[users[i]] = userCount;
            allUserInfo[userCount] = userInfo(users[i],ratio[i],0,0,false);
           
            RATIO_DENOM += ratio[i];
        }

    }

    function ressetUserRatio(address user,uint256 ratio)
        public
        inited
        onlyOrigin
    {
        uint256 idx = allUserIdx[user];
        RATIO_DENOM -= allUserInfo[idx].ratio;
        RATIO_DENOM += ratio;
        allUserInfo[idx].ratio = ratio;
    }

    function setUserStatus(address user,bool status)
        public
        inited
        onlyOrigin
    {
        require(user != address(0));
        uint256 idx = allUserIdx[msg.sender];
        allUserInfo[idx].disable = status;
    }

    function claimableBalanceOf(address user) public view returns (uint256) {
        uint256 idx = allUserIdx[user];
        return allUserInfo[idx].pendingAmount;
    }

    function claimReward() public inited notHalted {
        uint256 idx = allUserIdx[msg.sender];
        //idx begin from 1
		require(idx != 0,"no this account");
      
        uint256 amount = allUserInfo[idx].pendingAmount;
        require(amount>0,"pending amount need to be bigger than 0");

        allUserInfo[idx].pendingAmount = 0;

        //transfer back to user
        uint256 balbefore = IERC20(rewardToken).balanceOf(msg.sender);
        IERC20(rewardToken).transfer(msg.sender,amount);
        uint256 balafter = IERC20(rewardToken).balanceOf(msg.sender);
        require((balafter.sub(balbefore))==amount,"error transfer melt,balance check failed");
    }

    function inputTeamReward(uint256 _amount)
        public
        inited
    {
        if(_amount==0) {
            return;
        }

        IERC20(rewardToken).transferFrom(msg.sender,address(this),_amount);
        if(RATIO_DENOM>0) {
            for(uint256 i=1;i<userCount+1;i++){
                userInfo storage info = allUserInfo[i];
                if(info.disable) {
                    continue;
                }
                uint256 useramount = _amount.mul(info.ratio).div(RATIO_DENOM);
                info.pendingAmount = info.pendingAmount.add(useramount);
                info.wholeAmount = info.wholeAmount.add(useramount);
            }
        }
    }
    
}
