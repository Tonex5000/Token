// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address public minter; // Declare the minter variable

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event StageIncreased(uint256 indexed newStage);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() external view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "Ownable: new minter is the zero address");
        minter = newMinter;
    }
}
