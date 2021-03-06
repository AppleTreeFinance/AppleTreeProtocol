pragma solidity ^0.5.16;
import './StardardToken.sol';

contract TreeToken is StandardToken20{
    using SafeMath for uint;

    string private name_;
    string private symbol_;
    uint8  private decimals_;

    //total tokens supply
    uint256 constant public MAX_TOTAL_TOKEN_AMOUNT = 100000000 ether;
    uint256 constant public MAX_RESERVE_AMOUNT = 10000000 ether;     //10% for reserve
    uint256 constant public MAX_BUSINESS_EXPANDING = 5000000 ether;  //5% for business expanding

    modifier maxWanTokenAmountNotReached (uint amount){
    	  assert(totalSupply().add(amount).add(MAX_RESERVE_AMOUNT).add(MAX_BUSINESS_EXPANDING) <= MAX_TOTAL_TOKEN_AMOUNT);
    	  _;
    }

    constructor(string memory tokenName,
                string memory tokenSymbol,
                uint256 tokenDecimal,
                address initHolder,
                address reserveHolder,
                address businessHolder)
        public
    {
        name_ = tokenName;
        symbol_ = tokenSymbol;
        decimals_ = uint8(tokenDecimal);

        _mint(reserveHolder,MAX_RESERVE_AMOUNT);
        _mint(businessHolder,MAX_BUSINESS_EXPANDING);
        _mint(initHolder,MAX_TOTAL_TOKEN_AMOUNT.sub(MAX_RESERVE_AMOUNT).sub(MAX_BUSINESS_EXPANDING));
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return name_;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return decimals_;
    }

}