// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";

contract ERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approve(address indexed _from, address indexed _to, uint256 _value);
 
    mapping(address => uint256) private balances;
    mapping(address => mapping(address=>uint256)) private allowances;
    uint256 private totalSupply;

    string private name;
    string private symbol;
    uint8 private decimal;

    bool private _paused;

    address private owner;
    mapping(address => uint256) public nonces;
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
        balances[msg.sender] = 100 ether;
        totalSupply = 100 ether;
        owner = msg.sender;
        _paused = false;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public virtual returns (bool){
        require(!_paused);
        require(msg.sender != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        require(balances[msg.sender] >= _value, "You don't have enough balance.");
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool){
        require(!_paused);
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        require(balances[_from] >= _value, "You don't have enough balance.");
        
        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function pause() public{
        require(msg.sender == owner, "You are not owner");
        _paused = true;
    }

    function unpause() public{
        require(msg.sender == owner, "You are not owner");
        _paused = false;
    }

    function approve(address _to, uint256 _value) public virtual returns (bool){
        allowances[msg.sender][_to] = _value;

        emit Approve(msg.sender, _to, _value);

        return true;
    }

    function allowance(address _from, address _to) public view virtual returns (uint256) {
        return allowances[_from][_to];
    }

    function permit(address _from, address _to, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public virtual{
        require(_deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR(),
                        keccak256(abi.encode(
                                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                _from,_to,_value,nonces[_from]++,_deadline)))),_v,_r,_s);

            require(recoveredAddress != address(0) && recoveredAddress == _from, "INVALID_SIGNER");

            allowances[recoveredAddress][_to] = _value;
        }
        emit Approve(_from, _to, _value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32){
        bytes32 hashdata = keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR(),structHash));
        return hashdata;
    }
}