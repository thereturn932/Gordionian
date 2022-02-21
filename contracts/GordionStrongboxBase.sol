//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GordionStrongbox {
    /**
    Events
     */
    event DepositAVAX(address indexed sender, uint256 amount);
    event DepositToken(address indexed sender, uint256 amount, address tokenAddress);
    event SubmitPaymentOrder(
        uint256 indexed id,
        address to,
        address token,
        uint256 value
    );
    event AcceptPaymentOrder(address indexed sender, uint256 indexed id);
    event RevokePaymentVote(address indexed sender, uint256 indexed id);
    event ExecutePayment(uint256 indexed id);

    modifier onlyOwners() {
        require(isOwner[msg.sender], "0x03");
        _;
    }

    struct Payment {
        uint256 id;
        address token;
        address to;
        uint256 value;
        bytes data;
        uint256 noConfirmations;
        mapping(address => bool) isConfirmed;
        bool executed;
    }

    Payment[] public orders;
    uint256 private reqConfNo;
    address[] owners;

    mapping(address => bool) public isOwner;
    mapping(address => uint256) public depositedAVAX;

    constructor(address[] memory ownerArray, uint8 noConf) {
        require(ownerArray.length != 0, "0x01");
        for (uint256 i = 0; i < ownerArray.length; i++) {
            require(ownerArray[i] != address(0x0), "0x02");
            isOwner[ownerArray[i]] = true;
        }
        owners = ownerArray;
        reqConfNo = noConf;
    }

    /*--------------PAYMENT MANAGEMENT--------------*/
    function depositAvax() external payable onlyOwners {
        depositedAVAX[msg.sender] += msg.value;

        emit DepositAVAX(msg.sender, msg.value);
    }

    function depositToken(address _token, uint _value) external onlyOwners {
        IERC20 token = IERC20(_token);
        require(token.allowance(msg.sender, address(this))>= _value, "0x15");
        token.transferFrom(msg.sender, address(this), _value);
        emit DepositToken(msg.sender, _value, _token);
    }

    function sendPaymentOrder(
        address _to,
        address _token,
        uint256 _value,
        bytes memory _data
    ) external onlyOwners {
        require(_to != address(0), "0x05");
        Payment storage order = orders.push();
        order.id = orders.length;
        order.to = _to;
        order.token = _token;
        order.value = _value;
        order.data = _data;
        order.isConfirmed[msg.sender] = true;
        order.noConfirmations++;

        emit SubmitPaymentOrder(order.id, order.to, order.token, order.value);
    }

    function acceptOrder(uint256 id) external onlyOwners {
        Payment storage order = orders[id - 1];
        require(order.isConfirmed[msg.sender] != true, "0x04");
        order.isConfirmed[msg.sender] = true;
        order.noConfirmations++;

        emit AcceptPaymentOrder(msg.sender, id);
    }

    function revokeVote(uint256 id) external onlyOwners{

        Payment storage order = orders[id - 1];
        require(order.isConfirmed[msg.sender], "0x06");
        order.isConfirmed[msg.sender] = false;
        order.noConfirmations--;

        emit RevokePaymentVote(msg.sender, id);
    }

    function executePayment(uint256 id) external onlyOwners{

        require(checkPayment(id), "0x07");
        Payment storage order = orders[id - 1];
        require(!order.executed, "0x09");
        if (order.token == address(0)) {
            avaxPayment(order);
        } else {
            tokenPayment(order);
        }

        emit ExecutePayment(id);
    }

    function avaxPayment(Payment storage order) internal {
        order.executed = true;
        (bool sent, ) = order.to.call{value: order.value}("");
        require(sent, "0x08");
    }

    function tokenPayment(Payment storage order) internal {
        order.executed = true;
        IERC20 _token = IERC20(order.token);
        _token.transfer(order.to, order.value);
    }

    function checkPayment(uint256 id) public view returns (bool) {
        Payment storage order = orders[id - 1];
        return order.noConfirmations >= reqConfNo;
    }
}
