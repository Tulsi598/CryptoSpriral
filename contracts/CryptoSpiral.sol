Mapping from address to token balance
    mapping(address => uint256) private balances;

    Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    Returns balance of given account
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    Approve spender to spend tokens on owner's behalf
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address");

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    Transfer tokens from one address to another using allowance mechanism
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    Owner can burn tokens from an account
    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Burn from zero address");
        uint256 burnAmount = amount * 10**decimals;
        require(balances[account] >= burnAmount, "Burn amount exceeds balance");

        balances[account] -= burnAmount;
        totalSupply -= burnAmount;

        emit Transfer(account, address(0), burnAmount);
    }

    End
End
// 
// 
End
// 
