// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Verify {
    // Using Openzeppelin ECDSA cryptography library
    function getMessageHash(
        address _candidate,
        uint256 _maxAmount,
        uint256 _minAmount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_candidate, _maxAmount, _minAmount));
    }

    function getClaimMessageHash(address _candidate, uint256 _amount)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_candidate, _amount));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }

    function getSingerAdderss(bytes32 _messageHash, bytes memory _singature)
        public
        pure
        returns (address singer)
    {
        return ECDSA.recover(_messageHash, _singature);
    }

    function verify(
        address _singer,
        address _candidate,
        uint256 _maxAmount,
        uint256 _minAmount,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _candidate,
            _maxAmount,
            _minAmount
        );
        bytes32 ethSignMessagehash = getEthSignedMessageHash(messageHash);
        return getSingerAdderss(ethSignMessagehash, signature) == _singer;
    }

    function verifyClaimToken(
        address _singer,
        address _candidate,
        uint256 _amount,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getClaimMessageHash(_candidate, _amount);
        bytes32 ethSignMessagehash = getEthSignedMessageHash(messageHash);
        return getSingerAdderss(ethSignMessagehash, signature) == _singer;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
