//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/INTERFACES_kekchain.sol";

abstract contract iAuth is _MSG {
    address private owner;
    mapping (address => bool) internal authorizations;

    constructor(address ca, address _community, address _development) {
        initialize(address(ca), address(_community), address(_development));
    }

    modifier authorized() virtual {
        require(isAuthorized(_msgSender())); _;
    }
    
    function initialize(address ca, address _community, address _development) private {
        owner = ca;
        authorizations[ca] = true;
        authorizations[_community] = true;
        authorizations[_development] = true;
    }

    function authorize(address adr) public virtual authorized() {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public virtual authorized() {
        authorizations[adr] = false;
    }

    function isAuthorized(address adr) internal view returns (bool) {
        return authorizations[adr];
    }
    
    function transferAuthorization(address fromAddr, address toAddr) public virtual authorized() returns(bool) {
        require(fromAddr == _msgSender());
        bool transferred = false;
        authorize(address(toAddr));
        unauthorize(address(fromAddr));
        transferred = true;
        return transferred;
    }
}
