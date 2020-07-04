pragma solidity ^0.4.24;

import './StandardToken.sol';
import './Ownable.sol';

contract DFINToken is StandardToken, Ownable {

    string public name = 'DEFINANCE';
    string public symbol = 'DFIN';
    uint8 public decimals = 6;
    // A_total_of_300_million
    uint public INITIAL_SUPPLY = 300000000 * (10 ** uint(decimals));
    

    //Array for release days. 
    //The following 10 years, tokens will be release on a monthly basis based on the days recorded
    uint[] public releaseDays;
    
    // 10%初始发行地址
    address public initialAddress = 0xBE269dfB42f49b393651CD51f3a2Ca4352C847B7;
    // Fundpool
    uint[] public fundsPool;
    
    // White List
    address[] public whiteList;

    // Creation_time
    uint public createTime = 0;
    
    //DFIN_fundpool_retrieving_event
    event WithdrawDFIN(uint256 _value);

    // 
    event Burn(address _from, uint256 _value)
    
    constructor() public {
        // 总发行数3亿
        totalSupply_ = INITIAL_SUPPLY;
        // 10%_supply
        balances[initialAddress] = INITIAL_SUPPLY / 10;
        emit Transfer(0x0, initialAddress, INITIAL_SUPPLY / 10);
        
        // Initial_fundpool_usage
        // 15%_team_and_consultant(distributed_across_five_years)
        fundsPool.push(INITIAL_SUPPLY * 15 / 100);
        // 35%_ecosystem_development(distributed_across_ten_years)
        fundsPool.push(INITIAL_SUPPLY * 35 / 100);
        // 40%_temporarily_be_used_for_upgrading_of_the_mainnet_with_the_burning_of_the_original_tokens(completed_in_one_year)
        fundsPool.push(INITIAL_SUPPLY * 40 / 100);
        
        // Initial_whitelist
        whiteList.push(0xBE269dfB42f49b393651CD51f3a2Ca4352C847B7);
        
        // Recorded_creation_time
        createTime = now;

      
        // initialize the release time array (the nth element represents how much has passed since createTime Day is considered to be an array of days per month for the next 10 years after n+1 months, used to calculate the release time)
        releaseDays = [30,61,92,122,153,183,214,245,273,304,334,365,395,426,457,487,518,548,579,610,638,669,699,730,760,791,822,852,883,913,944,975,1003,1034,1064,1095,1125,1156,1187,1217,1248,1278,1309,1340,1369,1400,1430,1461,1491,1522,1553,1583,1614,1644,1675,1706,1734,1765,1795,1826,1856,1887,1918,1948,1979,2009,2040,2071,2099,2130,2160,2191,2221,2252,2283,2313,2344,2374,2405,2436,2464,2495,2525,2556,2586,2617,2648,2678,2709,2739,2770,2801,2830,2861,2891,2922,2952,2983,3014,3044,3075,3105,3136,3167,3195,3226,3256,3287,3317,3348,3379,3409,3440,3470,3501,3532,3560,3591,3621,3652];
    }
    
   // Only_the_contract_creator_has_the_right_to_allocate_DFIN_from_fundpool
    function allocateDFIN(
        address _receiver,
        uint256 _value,
        uint8 _poolIndex
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_value > 0, "Allocating 0 DFIN is not allowed.");
        require(_poolIndex >= 0 && _poolIndex < 3, "Pool index 0,1,2 is valid.");
        // Automatic zero padding
        _value = _value * (10 ** uint(decimals));
        // Search_whether_the_receiver_is_in_the_whitelist
        bool inWhiteList = false;
        for (uint i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == _receiver) {
                inWhiteList = true;
                break;
            }
        }
        require(inWhiteList, "The receiver is not in the whitelist");
        
      
        //calculate_the_number_of_months_after_the_contract_announced
        // uint d = (now - createTime) / 1 days;
        uint d = (now - createTime) / 4 seconds;
        //calculated the month from the release time array,
        uint months = 0;
        while (months < 120) {
            if (d < releaseDays[months]) {
                break;
            } else {
                months++;
            }
        }
        months = months + 1;

       // Leftover_DFIN_amount_in_fundpool
        uint remain = fundsPool[_poolIndex];
       // Calculate_the_locked_DFIN_amount
        uint locked = 0;
        // amount of DFINs  can be allocated at this time
        uint allocatableDFIN = 0;
        // Calculate_the_allocated_DFIN_amount
        if (_poolIndex == 0) { //  // split_into_five_years,_60_months
            locked = (60 >= months ? 60 - months : 0) * (INITIAL_SUPPLY * 15 / 100 / 60);
            allocatableDFIN = remain >= locked ? remain - locked : 0;
        } else if (_poolIndex == 1) { //  split_into_ten_years,_120_months
            locked = (120 >= months ? 120 - months : 0) * (INITIAL_SUPPLY * 35 / 100 / 120);
            allocatableDFIN = remain >= locked ? remain - locked : 0;
        } else if (_poolIndex == 2) { // Lock_for_one_year_and_available_after_one_year
            allocatableDFIN = months >= 12 ? remain : 0;
        } else { // should not go to here
            allocatableDFIN = 0;
        }
        
       // Allocate_DFINs_when_there_are_sufficient_DFINs_in_the_fundpool
        require(allocatableDFIN >= _value, "Not enough DFINs to distribute in the fundpool");
        fundsPool[_poolIndex] = fundsPool[_poolIndex] - _value;
        balances[_receiver] = balances[_receiver].add(_value);
        emit Transfer(0x0, _receiver, _value);
        return true;
    }
    
    // The_contract_creator_has_the_right_to_destroy_DFIN_in_the_fundpool
    function withdrawDFIN(
        uint256 _value
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_value > 0, "Retrieving 0 DFIN is not allowed. No meaning.");
        // Automatic zero padding
        _value = _value * (10 ** uint(decimals));
        require(fundsPool[2] >= _value, "The amount of DFIN in the fundpool is insufficient to retrieve.");
        fundsPool[2] = fundsPool[2] - _value;
        emit WithdrawDFIN(_value);
        return true;
    }

    // 自行销毁DFIN
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);                 // Check if the sender has enough
        balances[msg.sender] = balances[msg.sender] - _value;    // Subtract from the sender
        totalSupply_ = totalSupply_ - _value;                    // Updates totalSupply_
        emit Burn(msg.sender, _value);
        return true;
    }

    // 代理销毁DFIN
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                                       // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);                            // Check allowance
        balances[_from] = balances[_from] - _value;                               // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;         // Subtract from the sender's allowance
        totalSupply_ = totalSupply_ - _value;                                     // Update totalSupply_
        emit Burn(_from, _value);
        return true;
    }
}