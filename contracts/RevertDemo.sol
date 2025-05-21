// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RevertDemo {
    error CustomError(address user, uint256 value);
    // arr
    uint[] public arr = [1];
    /// @notice 原始函数，根据模式抛出不同的异常
    function willRevert(uint8 mode) public view returns (uint256) {
        if (mode == 1) {
            revert("String revert");
        } else if (mode == 2) {
            revert CustomError(msg.sender, 42);
        } else if (mode == 3) {
            return arr[10]; // panic: out-of-bounds
        } else {
            revert("Default revert");
        }
    }

    /// @notice 捕获 willRevert() 的异常并使用 revert(reason) 转发
    function revertNormal(uint8 mode) public view {
        try this.willRevert(mode) {
            // do nothing
        } catch (bytes memory reason) {
            revert(string(reason)); // 自动解析成 string
        }
    }

    /// @notice 捕获 willRevert() 的异常并使用 assembly revert() 原样转发
    function revertAssembly(uint8 mode) public view {
        try this.willRevert(mode) {
            // do nothing
        } catch (bytes memory reason) {
            assembly {
                revert(add(reason, 32), mload(reason))
            }
        }
    }
}