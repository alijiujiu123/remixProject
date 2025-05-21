// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Reference {
    // 数组
    // 静态状态变量
    uint[100] private ageArr;
    // 动态状态变量：可自动扩容，类似java中Stack的概念，但是可以对指定pos值进行修改
    uint[] private scoreArr;

    // 静态数组
    // 根据索引获取数组值
    function getAgeByPos(uint pos) external view returns (uint){
        require(pos < ageArr.length, "out of index");
        return ageArr[pos];
    }

    // 根据下标写入数组
    function setAgeVal(uint age, uint pos) external returns (uint) {
        // require(age > 0, "age must be positive");
        require(pos < ageArr.length, "out of index");
        uint old = ageArr[pos];
        ageArr[pos] = age;
        return old;
    }

    // 动态数组
    // 获取数组长度
    function getScoreArrLength() external view returns (uint) {
        return scoreArr.length;
    }
    // 在数组后添加分数
    function addLast(uint score) external returns (uint) {
        scoreArr.push(score);
        return scoreArr.length;
    }
    // 获取全部分数: 这里会自动转换，storage -> memory
    function getScoreArr() external view returns (uint[] memory) {
        return scoreArr;
    }
    // 获取指定位置元素
    function getScoreByPos(uint pos) external view returns (uint) {
        require(pos < scoreArr.length, "out of index");
        return scoreArr[pos];
    }
    // 设置指定pos的值: 
    function setScoreByPos(uint score, uint pos) external returns (uint) {
        require(pos < scoreArr.length, "out of index");
        uint old = scoreArr[pos];
        scoreArr[pos] = score;
        return old;
    }
    // 移除动态数组的最后一个元素
    function removeLastScore() external returns (uint) {
        require(scoreArr.length > 0, "stack is empty");
        uint lastVal = scoreArr[scoreArr.length-1];
        scoreArr.pop();
        return lastVal;
    }
    // 清空数组
    function clearScoreArr() external returns (string memory) {
        // uint[] storage emptyArr = new uint[]();
        delete scoreArr;
        return "success";
    }

    // 结构体定义
    struct Student {
        uint id;
        uint score;
    }
    // 声明结构体对象引用
    Student student;
    // 结构体对象引用赋值
    function setId(uint id) external {
        student.id = id;
    }
    function setScore(uint score) external {
        student.score = score;
    }
    // 构造函数赋值
    function setIdAndScore(uint id, uint score) external {
        student = Student(id, score);
    }
    // 构造体具名参数赋值
    function setStudent(uint id, uint score) external {
        student = Student({id: id, score: score});
    }
    // 获取结构体对象
    function getStudent() external view returns (Student memory) {
        return student;
    }

    // 映射
    mapping(uint => string) public  id2NameMapping;
    // 映射key数组
    uint[] private idArr;
    struct Person {
        uint id;
        string name;
    }
    // put
    function putIdNameMapping(uint256 id, string calldata name) external returns (string memory) {
        string memory oldStr = id2NameMapping[id];
        id2NameMapping[id] = name;
        if(strEquals(oldStr, "")){
            idArr.push(id);
        }
        return oldStr;
    }
    // 查询map所有键值对
    function getId2NameMapping() external view returns (Person[] memory) {
        uint len = idArr.length;
        Person[] memory result = new Person[](len);
        uint counter;
        for(uint i=0; i<len; i++) {
            uint id = idArr[i];
            result[i] = Person(id, id2NameMapping[id]);
            if(id != 0) {
                counter++;
                result[i] = Person(id, id2NameMapping[id]);
            }
        }
        // 去除空Person
        Person[] memory resultWithoutDelete = new Person[](counter);
        uint cursor;
        for(uint i=0;i<result.length;i++) {
            if(result[i].id !=0){
                resultWithoutDelete[cursor++] = result[i];
            }
        }
        return resultWithoutDelete;
    }

    function strEquals(string memory str1, string memory str2) private pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
    // 删除具体key
    function deleteKey(uint id) external returns (string memory) {
        uint index;
        for(uint i=0;i < idArr.length; i++){
            if(id == idArr[i]) {
                index = i;
            }
        }
        string memory oldStr = id2NameMapping[id];
        delete idArr[index];
        delete id2NameMapping[id];
        return oldStr;
    }

    // 常数
    // 常量：只能在状态变量声明时初始化赋值
    uint public constant currencyMaximum = 100;
    string public constant currencySymbol = "shuai";
    bytes public constant myHash = abi.encode(keccak256("abc"));
//     uint public constant currentBlockNum = block.number;
//    uint[3] public constant myIdArr = [uint(1), 2, 3];
    // 不可变量, 如发行时间（合约的部署时间）,不可修饰非值类型
    uint public immutable issueData = block.timestamp;
    address public immutable deployer;
//    uint[3] public immutable myIdArr1 = [uint(1), 2, 3];
    constructor() {
        // 合约部署时确定
//        issueData = block.timestamp;
        deployer = block.coinbase;
    }
}