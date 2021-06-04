pragma solidity ^ 0.6.10;
abstract contract Erc20Token{  
    uint256 public totalSupply;
    function balanceOf(address _owner) public view virtual returns (uint256 val);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256  _value);
}

contract TokenNBK is Erc20Token {
    using SafeMath for uint256;
    string public name = "NBK";
    string public symbol = "NBK";
    uint8 public decimals = 18;
    address private owner = 0x2B064a49F4F445CCDf99cc41737B7e599Fc03762;
    address private opAddr = 0x877Da52EA00122503eB83CC96af6ca9866d91A50;
    address private issuerAddr;
    event Burn(address indexed _from, uint256 _value);
    event Issue(address indexed issuerAddr, uint256 _value);
    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyop() {
        require(msg.sender == opAddr);
        _;
    }
    function set_issuer_addr(address addr) external onlyowner{
        issuerAddr = addr;
    }
    function set_op_addr(address addr) external onlyowner{
        opAddr = addr;
    }
    constructor(address issuerAddr) public {
        totalSupply = 25001 * 10 ** uint256(decimals);
        balance[issuerAddr] = totalSupply;
    }
  
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0x0));
        require(balance[msg.sender] >= _value && balance[_to] + _value > balance[_to]);
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0x0));
        require(balance[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balance[_from] = balance[_from].sub(_value);
        balance[_to] = balance[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 val) {  
        return balance[_owner];
    }
  
    function approve(address _spender, uint256 _value) public override returns (bool success) {   
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {  
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balance[msg.sender] >= _value);
        balance[msg.sender] -= _value;
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function issue(uint _value) public onlyop {
        require(issuerAddr != address(0x0));
        require(totalSupply + _value > totalSupply);
        require(balance[issuerAddr] + _value > balance[issuerAddr]);
        balance[issuerAddr] += _value;
        totalSupply += _value;
        emit Issue(issuerAddr, _value);
    }

    mapping (address => uint256) balance;  
    mapping (address => mapping (address => uint256)) allowed;  
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}