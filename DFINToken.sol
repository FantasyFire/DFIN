pragma solidity ^0.4.24;

import './StandardToken.sol';
import './Ownable.sol';

contract DFINToken is StandardToken, Ownable {

    string public name = 'Consensus Blockchain';
    string public symbol = 'DEFI';
    uint8 public decimals = 8;
    // 总量3个亿
    uint public INITIAL_SUPPLY = 300000000 * (10 ** uint(decimals));
    
    // 往后10年每个月的天数数组，用于计算释放时间
    uint[] public releaseDays;
    
    // 池子
    uint[] public fundsPool;
    // 白名单
    address[] public whiteList;

    // 创建时间
    uint public createTime = 0;
    
    // 回收池子DFIN事件
    event WithdrawDFIN(uint256 _value);
    
    constructor() public {
        // 10%流通
        totalSupply_ = INITIAL_SUPPLY / 10;
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, totalSupply_);
        
        // 依序初始化池子
        // 15%团队及顾问（分5年释放完成）
        fundsPool.push(INITIAL_SUPPLY * 15 / 100);
        // 35%生态发展（分10年释放完成）
        fundsPool.push(INITIAL_SUPPLY * 35 / 100);
        // 40%先暂时锁定，未来升级成主网，则该部分代币销毁。一年后可以释放
        fundsPool.push(INITIAL_SUPPLY * 40 / 100);
        
        // 初始化白名单
        whiteList.push(0xBE269dfB42f49b393651CD51f3a2Ca4352C847B7);
        
        // 记录创建时间
        createTime = now;

        // 初始化释放时间数组（第n个元素代表自createTime起，过了多少天认为是过了n+1个月）
        releaseDays = [30,61,92,122,153,183,214,245,273,304,334,365,395,426,457,487,518,548,579,610,638,669,699,730,760,791,822,852,883,913,944,975,1003,1034,1064,1095,1125,1156,1187,1217,1248,1278,1309,1340,1369,1400,1430,1461,1491,1522,1553,1583,1614,1644,1675,1706,1734,1765,1795,1826,1856,1887,1918,1948,1979,2009,2040,2071,2099,2130,2160,2191,2221,2252,2283,2313,2344,2374,2405,2436,2464,2495,2525,2556,2586,2617,2648,2678,2709,2739,2770,2801,2830,2861,2891,2922,2952,2983,3014,3044,3075,3105,3136,3167,3195,3226,3256,3287,3317,3348,3379,3409,3440,3470,3501,3532,3560,3591,3621,3652];
    }
    
    // 从池子里分配DFIN，只有合约创建者可以执行
    function allocateDFIN(
        address _receiver,
        uint256 _value,
        uint8 _poolIndex
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_value > 0, "不允许分配0DFIN，没有意义");
        require(_poolIndex >= 0 && _poolIndex < 3, "只能分配前3个池子");
        // 自动补零
        _value = _value * (10 ** uint(decimals));
        // 检索_receiver是否在白名单
        bool inWhiteList = false;
        for (uint i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == _receiver) {
                inWhiteList = true;
                break;
            }
        }
        require(inWhiteList, "_receiver不在白名单");
        
        // 计算自合约发布起，过去了多少天
        // uint d = (now - createTime) / 1 days;
        uint d = (now - createTime) / 4 seconds;
        // 从释放时间数组找出对应的第几个月
        uint months = 0;
        while (months < 120) {
            if (d < releaseDays[months]) {
                break;
            } else {
                months++;
            }
        }
        months = months + 1;

        // 池子剩余DFIN数量
        uint remain = fundsPool[_poolIndex];
        // 计算仍冻结的DFIN
        uint locked = 0;
        // 该时间节点能分配的DFIN数量
        uint allocatableDFIN = 0;
        // 计算出可以分配的DFIN数量
        if (_poolIndex == 0) { // 分5年释放，即60个月
            locked = (60 >= months ? 60 - months : 0) * (INITIAL_SUPPLY * 15 / 100 / 60);
            allocatableDFIN = remain >= locked ? remain - locked : 0;
        } else if (_poolIndex == 1) { // 分10年释放，即120个月
            locked = (120 >= months ? 120 - months : 0) * (INITIAL_SUPPLY * 35 / 100 / 120);
            allocatableDFIN = remain >= locked ? remain - locked : 0;
        } else if (_poolIndex == 2) { // 1年内锁定，1年后可以释放
            allocatableDFIN = months >= 12 ? remain : 0;
        } else { // 不应该走入这个分支
            allocatableDFIN = 0;
        }
        
        // 有足够DFIN分配时进行分配
        require(allocatableDFIN >= _value, "该时间节点能分配的DFIN数量不足分配");
        fundsPool[_poolIndex] = fundsPool[_poolIndex] - _value;
        totalSupply_ = totalSupply_ + _value;
        balances[_receiver] = balances[_receiver].add(_value);
        emit Transfer(0x0, _receiver, _value);
        return true;
    }
    
    // 合约创建者可销毁池子里的DFIN
    function withdrawDFIN(
        uint256 _value
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_value > 0, "不允许回收0DFIN，没有意义");
        // 自动补零
        _value = _value * (10 ** uint(decimals));
        require(fundsPool[2] >= _value, "池子内DFIN已不足回收量");
        fundsPool[2] = fundsPool[2] - _value;
        emit WithdrawDFIN(_value);
        return true;
    }
}