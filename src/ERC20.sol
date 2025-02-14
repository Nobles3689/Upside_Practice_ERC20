// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approve(address indexed _from, address indexed _to, uint256 _value);
 
    mapping(address => uint256) private balances;//잔고
    mapping(address => mapping(address=>uint256)) private allowances;//인출 허용 내역
    uint256 private totalSupply;//총 금액

    string private name;//토큰 이름
    string private symbol;//토큰 심볼
    uint8 private decimal;//쪼갤 수 있는 범위

    bool private _paused;//pause 여부

    address private owner;//토큰 주인

    //EIP-2612
    mapping(address => uint256) public nonces;//서명 발급 횟수
    uint256 internal immutable INITIAL_CHAIN_ID;//토큰 생성시 체인 ID
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;//토큰 생성시 도메인 구분자

    constructor(string memory _name, string memory _symbol){
        //토큰 초기화
        name = _name;
        symbol = _symbol;
        //setUp 위해서 초기 발행 100 ETH
        balances[msg.sender] = 100 ether;
        totalSupply = 100 ether;
        //토큰 오너설정
        owner = msg.sender;
        //_paused 초기화
        _paused = false;
        //EIP-2612
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];//해당 주소가 가진 토큰 양
    }

    function transfer(address _to, uint256 _value) public virtual returns (bool){
        require(!_paused);//pause 확인
        //zero address에서의 송수신 막기
        require(msg.sender != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        //잔액 확인
        require(balances[msg.sender] >= _value, "You don't have enough balance.");
        //transfer
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        //이벤트 로그 찍기
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool){
        require(!_paused);//pause 확인
        //zero address에서의 송수신 막기
        require(msg.sender != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        //잔액 확인
        require(balances[msg.sender] >= _value, "You don't have enough balance.");
        //transfer
        balances[_from] -= _value;
        balances[_to] += _value;
        //이벤트 로그 찍기
        emit Transfer(_from, _to, _value);

        return true;
    }

    function pause() public{
        //권한 확인
        require(msg.sender == owner, "You are not owner");
        _paused = true;
    }

    function unpause() public{
        //권한 확인
        require(msg.sender == owner, "You are not owner");
        _paused = false;
    }

    function approve(address _to, uint256 _value) public virtual returns (bool){
        //토큰 인출 허용량 업데이트
        allowances[msg.sender][_to] = _value;
        //이벤트 로그 찍기
        emit Approve(msg.sender, _to, _value);

        return true;
    }

    function allowance(address _from, address _to) public view virtual returns (uint256) {
        //토큰 인출 허용량 반환
        return allowances[_from][_to];
    }

    function permit(address _from, address _to, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public virtual{
        require(_deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");//서명 유효기간 확인
        //EIP-712 형식대로 서명 메시지 구성, ecrecover로 주소 복구
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR(),
                        keccak256(abi.encode(
                                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                _from,_to,_value,
                                nonces[_from]++,//nonce값은 사용 후 증가 ( 재사용 방지 )
                                _deadline)))),
                                _v,_r,_s);
            //복구 주소 확인
            require(recoveredAddress != address(0) && recoveredAddress == _from, "INVALID_SIGNER");
            //허용량 업데이트
            allowances[recoveredAddress][_to] = _value;
        }
        //이벤트 로그 찍기
        emit Approve(_from, _to, _value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        //체인 ID가 바뀌었는지 확인, 바뀌었다면 바뀐거로 도메인 구분자 다시 계산
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();

    }
    //도메인 구분자 계산함수
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
    //서명 메시지 해시 생성 함수
    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32){
        bytes32 hashdata = keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR(),structHash));
        return hashdata;
    }
}