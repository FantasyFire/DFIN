pragma solidity ^0.4.24;

import './StandardToken.sol';
import './Ownable.sol';

contract DFINToken is StandardToken, Ownable {

    string public name = 'Consensus Blockchain';
    string public symbol = 'DEFI';
    uint8 public decimals = 4;
    // 总量3个亿
    uint public INITIAL_SUPPLY = 300000000 * (10 ** uint(decimals));
    
    
    // 池子
    uint[] public fundsPool;
    address[] public whiteList;

    // 创建时间
    uint public createTime = 0;
    
    //回收池子DFIN事件
    event WithdrawDFIN(uint8 indexed _poolIndex, uint256 _value);
    
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
        // 检索_receiver是否在白名单
        bool inWhiteList = false;
        for (uint i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == _receiver) {
                inWhiteList = true;
                break;
            }
        }
        require(inWhiteList, "_receiver不在白名单");
        
        // 池子剩余DFIN数
        uint remain = fundsPool[_poolIndex];
        // 认为30天为1个月，这里计算出自合约发布起，过去了多少个月
        uint months = (now - createTime) / 30 days + 1;
        // 计算仍冻结的DFIN
        uint locked = 0;
        
        // 计算出可以分配的DFIN量
        if (_poolIndex == 0) { // 分5年释放，即60个月
            locked = (60 >= months ? 60 - months : 0) * (INITIAL_SUPPLY * 15 / 100 / 60);
            remain = remain >= locked ? remain - locked : 0;
        } else if (_poolIndex == 1) { // 分10年释放，即120个月
            locked = (120 >= months ? 120 - months : 0) * (INITIAL_SUPPLY * 35 / 100 / 120);
            remain = remain >= locked ? remain - locked : 0;
        } else if (_poolIndex == 2) { // 1年内锁定，1年后可以释放
            remain = months >= 12 ? remain : 0;
        } else { // 不应该走入这个分支
            remain = 0;
        }
        
        // 有足够DFIN分配时进行分配
        require(remain >= _value, "池子剩余DFIN不足分配");
        fundsPool[_poolIndex] -= _value;
        totalSupply_ += _value;
        balances[_receiver] = balances[_receiver].add(_value);
        emit Transfer(0x0, _receiver, _value);
        return true;
    }
    
    // 合约创建者可销毁池子里的DFIN
    function withdrawDFIN(
        uint256 _value,
        uint8 _poolIndex
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_value > 0, "不允许回收0DFIN，没有意义");
        require(_poolIndex >= 0 && _poolIndex < 3, "只能回收前3个池子");
        require(fundsPool[_poolIndex] >= _value, "池子内DFIN已不足回收量");
        fundsPool[_poolIndex] -= _value;
        emit WithdrawDFIN(_poolIndex, _value);
        return true;
    }
}