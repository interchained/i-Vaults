//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IWRAP {
    function deposit() external payable;
    function withdraw(uint amount) external;
    function transfer(address dst, uint amount) external returns (bool);
}
interface IRECEIVE {
    event Transfer(address indexed from, address indexed to, uint value);

    function withdraw() external returns (bool);
    function tokenizeWETH() external returns (bool);
    function withdrawWETH(uint amount) external returns (bool);
    function withdrawToken(address token) external returns (bool);
    function split(uint liquidity) external view returns(uint,uint,uint);
    function transfer(address sender, uint256 eth, address payable receiver) external returns (bool success);
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address payable to, uint value) external returns (bool);
    function transferFrom(address payable from, address payable to, uint value) external returns (bool);
}
