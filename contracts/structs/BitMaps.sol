// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// BitMaps Library
library BitMaps {
    // bitMap base struct: every element has one bit, value range: {0,1}
    struct BitMap {
        // data content
        mapping(uint256 bucket => uint256) _data;
    }
    /**
     * @dev Returns whether the bit at `data` is set.
     */
    function _get(BitMap storage bitmap, uint256 data) private view returns (bool) {
        (uint256 bucket, uint256 mask) = _calcBucketAndMask(data);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `data` to the boolean `value`.
     */
    function _setTo(BitMap storage bitmap, uint256 data, bool value) private {
        if (value) {
            _set(bitmap, data);
        } else {
            _unset(bitmap, data);
        }
    }

    /**
     * @dev Sets the bit at `data`.
     */
    function _set(BitMap storage bitmap, uint256 data) private {
        (uint256 bucket, uint256 mask) = _calcBucketAndMask(data);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `data`.
     */
    function _unset(BitMap storage bitmap, uint256 data) private {
        (uint256 bucket, uint256 mask) = _calcBucketAndMask(data);
        bitmap._data[bucket] &= ~mask;
    }

    // 计算指定数据的bucket & mask
    function _calcBucketAndMask(uint256 data) private pure returns (uint256 bucket, uint256 mask) {
        // 计算下标：index/256,一个value值，可以存储256个bit
        bucket = data >> 8;
        // 计算index在指定bucket中的哪个bit位：index的后8个bit位，是index%256（取余）,0xff: 1111 1111
        // 从低字节地址开始存储，类似于小端存储
        mask = 1 << (data & 0xff);
    }

    // uint256 BitMap
    struct Uint256BitMap {
        BitMap _inner;
    }

    /**
     * @dev Returns whether the bit at `data` is set.
     */
    function get(Uint256BitMap storage bitmap, uint256 data) internal view returns (bool) {
        return _get(bitmap._inner, data);
    }

    /**
     * @dev Sets the bit at `data` to the boolean `value`.
     */
    function setTo(Uint256BitMap storage bitmap, uint256 data, bool value) internal {
        _setTo(bitmap._inner, data, value);
    }

    /**
     * @dev Sets the bit at `data`.
     */
    function set(Uint256BitMap storage bitmap, uint256 data) internal {
        _set(bitmap._inner, data);
    }

    /**
     * @dev Unsets the bit at `data`.
     */
    function unset(Uint256BitMap storage bitmap, uint256 data) internal {
        _unset(bitmap._inner, data);
    }

    // Address BitMap
    struct AddressBitMap {
        BitMap _inner;
    }

    /**
     * @dev Returns whether the bit at `data` is set.
     */
    function get(AddressBitMap storage bitmap, address data) internal view returns (bool) {
        return _get(bitmap._inner, _addressToUint256(data));
    }

    /**
     * @dev Sets the bit at `data` to the boolean `value`.
     */
    function setTo(AddressBitMap storage bitmap, address data, bool value) internal {
        _setTo(bitmap._inner, _addressToUint256(data), value);
    }

    /**
     * @dev Sets the bit at `data`.
     */
    function set(AddressBitMap storage bitmap, address data) internal {
        _set(bitmap._inner, _addressToUint256(data));
    }

    /**
     * @dev Unsets the bit at `data`.
     */
    function unset(AddressBitMap storage bitmap, address data) internal {
        _unset(bitmap._inner, _addressToUint256(data));
    }

    function _addressToUint256(address data) private pure returns (uint256) {
        return uint256(uint160(data));
    }

    // bytes32 BitMap
    struct Bytes32BitMap {
        BitMap _inner;
    }

    /**
     * @dev Returns whether the bit at `data` is set.
     */
    function get(Bytes32BitMap storage bitmap, bytes32 data) internal view returns (bool) {
        return _get(bitmap._inner, _bytes32ToUint256(data));
    }

    /**
     * @dev Sets the bit at `data` to the boolean `value`.
     */
    function setTo(Bytes32BitMap storage bitmap, bytes32 data, bool value) internal {
        _setTo(bitmap._inner, _bytes32ToUint256(data), value);
    }

    /**
     * @dev Sets the bit at `data`.
     */
    function set(Bytes32BitMap storage bitmap, bytes32 data) internal {
        _set(bitmap._inner, _bytes32ToUint256(data));
    }

    /**
     * @dev Unsets the bit at `data`.
     */
    function unset(Bytes32BitMap storage bitmap, bytes32 data) internal {
        _unset(bitmap._inner, _bytes32ToUint256(data));
    }

    function _bytes32ToUint256(bytes32 data) private pure returns (uint256) {
        return uint256(data);
    }
}