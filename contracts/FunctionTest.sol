// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract FunctionTest {
    uint256 private  counter = 0;
    uint256[] private numArray = [1,2,3];
    // 1.函数可见性
    // public
    function setCounter(uint256 num) public returns (bool) {
        require(num > 0, "num must be positive number");
        counter = num;
        return true;
    }
    // internal 内部以及继承可见
    function addNum(uint256 num1, uint256 num2) internal pure returns (uint256) {
        return num1+num2;
    }
    // private 仅内部可见
    function counterIncreaseBy(uint256 num) private returns (uint256) {
        require(num > 0, "num must be positive number");
        counter += num;
        return counter;
    }
    function counterIncrease() public returns (uint256) {
        return counterIncreaseBy(1);
    }
    // external
    function counterIncreaseTwo() external returns (uint256) {
        return counterIncreaseBy(2);
    }
    // 2.函数功能修饰符
    // pure
    function concatStr(string calldata firstStr, string memory secondStr) public pure returns (string memory) {
        return string.concat(firstStr, secondStr);
    }
    // view
    function getCounter() external view returns (uint256) {
        return counter;
    }
    // payable
    function giveMeMoney() external payable returns (uint256) {
        uint256 val = msg.value;
        require(val > 0, "can not give me nothing");
        return val;
    }
    // 获取合约余额
    function showBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // 浅拷贝
    function setNumByIndex(uint256 num, uint256 pos) public view returns (uint256) {
        uint256 arrLen = numArray.length;
        require(pos < arrLen, "out of index");
        uint256[] memory copyArray = numArray;
        copyArray[pos] = num;
        return numArray[pos];
    }
    // 深拷贝
    function setNumByIndexDeep(uint256 num, uint256 pos) public returns (uint256) {
        uint256 arrLen = numArray.length;
        require(pos < arrLen, "out of index");
        uint256[] storage copyArray = numArray;
        copyArray[pos] = num;
        return numArray[pos];
    }
    // 获取numArray指定位置的值
    function getNumByIndex(uint256 pos) public view returns (uint256) {
        uint256 arrLen = numArray.length;
        require(pos < arrLen, "out of index");
        return numArray[pos];
    }
    // 时间单位
    function timeUintTest() external pure {
        assert(1 seconds == 1);
        assert(1 minutes == 60 seconds);
        assert(1 hours == 60 minutes);
        assert(1 days == 24 hours);
        assert(1 weeks == 7 days);
    }
    // 以太单位
    function ethUnitTest() external payable {
        assert(1 wei == 1);
        assert(1 gwei == 1e9);
        assert(1 ether == 1e18);
        assert(1 ether == 1e9 gwei);
    }
    function ethUnitErrorTest() external payable {
        assert(1 ether == 1e9 wei);
    }

    // 插入排序
    function insertSort(int[] memory numArr) external pure returns (int[] memory) {
        //2 3 5 7 9 1 4 6 8
        uint len = numArr.length;
        for(uint i=1; i<len; ++i) {
            bool flag = false;
            // 需要插入的值
            int key = numArr[i];
            uint j = i-1;
            // 向前寻找插入位置
            while (j>=0 && numArr[j]>key) {
                numArr[j+1] = numArr[j];
                // 特殊处理j不能为负数的问题
                if (j>0){
                    j--;
                }else {
                    // j==0,就不减了
                    flag = true;
                    break;
                }
                
            }
            // 将找到的位置，插入key值
            if (flag) {
                numArr[0] = key;
            }else {
                numArr[j+1] = key;
            }
            
        }
        return numArr;
    }

    function insertSort1(int[] memory numArr) external pure returns (int[] memory) {
        //1 3 5 7 9 2 4 6 8
        uint len = numArr.length;
        for(uint i=1; i<len; ++i) {
            // 需要插入的值
            int key = numArr[i];
            uint j = i;
            // 向前寻找插入位置
            while (j>=1 && numArr[j-1]>key) {
                numArr[j] = numArr[j-1];
                // 特殊处理j不能为负数的问题
                j--;
            }
            // 将找到的位置，插入key值
            numArr[j] = key;
            
        }
        return numArr;
    }

    // overload
    function saySomething() external pure returns (string memory) {
        return "nothing";
    }
    function saySomrthing(string calldata str) external pure returns (string memory) {
        return string.concat("hello ", str);
    }
}