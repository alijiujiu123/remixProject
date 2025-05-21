// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
event Log(string message);
// 动物
contract Animal {
    // 不希望子类继承
    function breath() public {
        emit Log("every animal can breath");
    }
    // 叫声，希望继承
    function sounds() public virtual {
        emit Log("wo~wo~");
    }
}
// 人类(普通继承)
contract Person is Animal {
    function sounds() public virtual override {
        emit Log("language");
    }
}
// 父亲（多重继承）
// 继承多个父类，必须按照顺序，从高到低依次声明，否则报错:TypeError: Linearization of inheritance graph impossible
contract Father is Animal,Person {
    // 1. sounds在Animal和Person都有实现，所有必须要重写
    // 否则报错：TypeError: Derived contract must override function "sounds". Two or more base classes define function with same name and parameter types.
    // 2. 重写时必须加上所有父合约的名字
    function sounds() public virtual override(Person,Animal) {
        emit Log("i am father");
    }
    // todo 修饰器定义:参数必须是2的倍数
    modifier paramRule(uint param) virtual {
        require(param%2==0, "param must be Multiples of 2");
        _;
    }
    // 修饰器测试方法
    function sendNum(uint param) public virtual paramRule(param) {
        emit Log("Father call sendNum success");
    }
}
// 母亲（多重继承）
contract Mother is Animal, Person {
    uint public age;
    // todo 构造函数继承
    constructor(uint num) {
        age = num;
    }
    function sounds() public virtual override(Animal, Person) {
        emit Log("i am Mother");
    }
}
// 学生（钻石继承，菱形继承）
contract Student is Father, Mother {
    constructor(uint num) Mother(num*2) {
        emit Log("Student constructor init");
    }
    function sounds() public override(Father, Mother) {
        emit Log("i am studeng and son");
        // 调用父合约函数
        // 1.钻石继承，super关键字会调用继承链上所有的函数
        emit Log("call super.sounds()");
        super.sounds();
    }
    // 修饰器修饰方法: 这里用的是父类对2整除的规则（复用父类的修饰器）
    function sendNum(uint param) public override paramRule(param) {
        emit Log("Studeng call sendNum");
    }
}
// 学徒
contract Apprentice is Animal,Person,Father {
    function sounds() public override(Animal, Person,Father) {
        emit Log("i am a apprentice and son");
        // 父合约名直接调用：只调用一次
        emit Log("call Father.sounds");
        Father.sounds();
    }
    // 修饰器继承: 参数必须是4的倍数
    modifier paramRule(uint param) override {
        require(param%4==0, "param must be Multiples of 4");
        _;
    }
    // 这里用的自己重新实现的对4整除的规则
    function sendNum(uint param) public override paramRule(param) {
        emit Log("Apprentice call sendNum success");
    }
}