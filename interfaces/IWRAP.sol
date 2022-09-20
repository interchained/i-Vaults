//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IDividendDistributor {
    function deposit() external payable;
    function withdraw(uint amount) external;
    function transfer(address dst, uint amount) external returns (bool);
}
