// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol"; // Import the Ownable contract

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BEP20Token is IBEP20, Ownable {
    string public constant name = "BITSLAB";
    string public constant symbol = "BLAB";
    uint8 public constant decimals = 18; // Adjust decimals as needed

    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18; // Total supply: 1 billion tokens
    uint256 public constant PUBLIC_PRESALES_ALLOCATION = 200000000 * 10**18; // 20% of total supply
    uint256 public constant PRIVATE_SALE_ALLOCATION = 125000000 * 10**18; // 12.5% of total supply
    uint256 public constant LIQUIDITY_ALLOCATION = 75000000 * 10**18; // 7.5% of total supply
    uint256 public constant AIRDROP_REWARDS_ALLOCATION = 50000000 * 10**18; // 5% of total supply
    uint256 public constant STAKING_POOL_ALLOCATION = 165000000 * 10**18; // 16.5% of total supply
    uint256 public constant ADVISORY_ALLOCATION = 30000000 * 10**18; // 3% of total supply
    uint256 public constant TEAM_ALLOCATION = 80000000 * 10**18; // 8% of total supply
    uint256 public constant ECOSYSTEM_ALLOCATION = 90000000 * 10**18; // 9% of total supply
    uint256 public constant EXCHANGE_RESERVES_ALLOCATION = 140000000 * 10**18; // 14% of total supply
    uint256 public constant DEV_MARKETING_ALLOCATION = 45000000 * 10**18; // 4.5% of total supply

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _totalSupply = TOTAL_SUPPLY;

        // Distribute initial token allocations
        _balances[msg.sender] = TOTAL_SUPPLY;
        minter = msg.sender;
        //_balances[address(this)] += PRIVATE_SALE_ALLOCATION; // Example: Assign to private sale allocation
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }


    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount <= _balances[sender], "BEP20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        return true;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "BEP20: caller is not the minter");
        _;
    }

    function setMinter(address newMinter) public onlyOwner override {
    require(newMinter != address(0), "BEP20: new minter is the zero address");
    minter = newMinter;
    }
}

