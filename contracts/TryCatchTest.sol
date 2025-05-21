// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
contract TryCatchTest {
    event ContractCreateSuccess(address newContract);
    event ErrorEvent(string reason);
    event PanicEvent(uint errorCode);
    event OtherExceptionEvent(bytes data);
    event FunctionCallSuccess(uint result);
    ExternalFailContract private externalContract;
    
    // 合约创建异常捕获
    function createExternalFailContract(uint num) external returns (address) {
        try new ExternalFailContract(num) returns (ExternalFailContract _contract) {
            // contract create success
            emit ContractCreateSuccess(address(_contract));
            externalContract = _contract;
        }catch Error(string memory reason) {
            emit ErrorEvent(reason);
        }catch Panic(uint errorCode) {
            emit PanicEvent(errorCode);
        }catch (bytes memory lowLevelData) {
            emit OtherExceptionEvent(lowLevelData);
        }
        return address(externalContract);
    }
    // 外部函数调用异常捕获    
    function callMightFail(uint num) external returns(uint result) {
        try externalContract.mightFail(num) returns (uint _result) {
            // success
            emit FunctionCallSuccess(result);
            result = _result;
        }catch Error(string memory reason) {
            emit ErrorEvent(reason);
        }catch Panic(uint errorCode) {
            emit PanicEvent(errorCode);
        }catch {
            // (bytes memory lowLevelData), but not need the bytes dta
            emit OtherExceptionEvent("(bytes memory lowLevelData), but not need the bytes dta");
        }
        return result;
    }
}
contract ExternalFailContract {
    error ConstructFail(string reason);
    error FunctionFail(string reason);
    constructor(uint num) {
        // Error(string memory reason)
        require(num!=0, "num can not be zero");
        // Panic(uint errorCode): asset 0x01
        assert(num!=1);
        // (bytes memory lowLevelData)
        if (num == 3) {
            revert();
        }
        if (num == 4) {
            require(false);
        }
        if (num == 5) {
            revert ConstructFail("num can not be three");
        }
    }
    function mightFail(uint256 num) external pure returns(uint256) {
        // Error(string memory reason)
        if (num == 1) {
            revert("the num can not equals zero in mightFail function");
        }
        // when num == 0, Panic(uint errorCode): 0x12
        uint a = 10/num;
        // catch {}
        if (num == 3) {
            revert FunctionFail("mightFail param can not equals three");
        }
        return a;
    }
}
