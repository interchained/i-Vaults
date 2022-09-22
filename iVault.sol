//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./iAuth.sol";

contract KEK_Bridge_Vault is iAuth, IRECEIVE {
    
    address payable private _governance = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable private _development = payable(0xC925F19cb5f22F936524D2E8b17332a6f4338751);
    address payable private _community = payable(0x74b9006390BfA657caB68a04501919B72E27f49A);

    string public name = unicode"☦🔒";
    string public symbol = unicode"☦🔑";

    uint private teamDonationMultiplier = 8000; 
    uint private immutable shareBasisDivisor = 10000; 

    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    IWRAP private WageKEK = IWRAP(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    
    mapping(address => User) private vaultRecords;

    struct History {
        uint coinAmountOwed; 
        uint coinAmountDrawn; 
        uint coinAmountDeposited; 
        uint wkekAmountOwed;    
        uint tokenAmountOwed;
        uint tokenAmountDrawn; 
        uint tokenAmountDeposited;
    }
    
    struct Vault {
        History community;
        History development;
    }

    uint public tokenADV = 0;

    event TokenizeWETH(address indexed src, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor() payable iAuth(address(_msgSender()),address(_governance),address(_development),address(_community)) {
        if(uint256(msg.value) > uint256(0)){
            coinDeposit(uint256(msg.value));
        }
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0));
        coinDeposit(uint256(ETH_liquidity));
    }
    
    fallback() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0));
        coinDeposit(uint256(ETH_liquidity));
    }

    function setShards(uint _m) public authorized() {
        require(uint(_m) <= uint(8000));
        teamDonationMultiplier = uint(_m);
    }

    function setCommunity(address payable _communityWallet) public authorized() returns(bool) {
        require(address(_community) == _msgSender());
        Vault storage VR_n = vaultRecords[_communityWallet];
        Vault storage VR_e = vaultRecords[_community];
        VR_n.community.coinAmountOwed += VR_e.community.coinAmountOwed;
        VR_n.community.coinAmountDrawn += VR_e.community.coinAmountDrawn;
        VR_n.community.coinAmountDeposited += VR_e.community.coinAmountDeposited;
        VR_n.community.wkekAmountOwed += VR_e.community.wkekAmountOwed;
        VR_n.community.tokenAmountOwed += VR_e.community.tokenAmountOwed;
        VR_n.community.tokenAmountDrawn += VR_e.community.tokenAmountDrawn;
        VR_n.community.tokenAmountDeposited += VR_e.community.tokenAmountDeposited;
        VR_e.community.coinAmountOwed = uint(0);
        VR_e.community.coinAmountDrawn = uint(0);
        VR_e.community.coinAmountDeposited = uint(0);
        VR_e.community.coinAmountDeposited = uint(0);
        VR_e.community.tokenAmountOwed = uint(0);
        VR_e.community.tokenAmountDrawn = uint(0);
        VR_e.community.tokenAmountDeposited = uint(0);
        _community = payable(_communityWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_communityWallet));
        assert(transferred==true);
        return transferred;
    }

    function setDevelopment(address payable _developmentWallet) public authorized() returns(bool) {
        require(address(_development) == _msgSender());
        Vault storage VRD_n = vaultRecords[_developmentWallet];
        Vault storage VRD_e = vaultRecords[_development];
        VRD_n.development.coinAmountOwed += VRD_e.development.coinAmountOwed;
        VRD_n.development.coinAmountDrawn += VRD_e.development.coinAmountDrawn;
        VRD_n.development.coinAmountDeposited += VRD_e.development.coinAmountDeposited;
        VRD_n.development.wkekAmountOwed += VRD_e.development.wkekAmountOwed;
        VRD_n.development.tokenAmountOwed += VRD_e.development.tokenAmountOwed;
        VRD_n.development.tokenAmountDrawn += VRD_e.development.tokenAmountDrawn;
        VRD_n.development.tokenAmountDeposited += VRD_e.development.tokenAmountDeposited;
        VRD_e.development.coinAmountOwed = uint(0);
        VRD_e.development.coinAmountDrawn = uint(0);
        VRD_e.development.coinAmountDeposited = uint(0);
        VRD_e.development.coinAmountDeposited = uint(0);
        VRD_e.development.tokenAmountOwed = uint(0);
        VRD_e.development.tokenAmountDrawn = uint(0);
        VRD_e.development.tokenAmountDeposited = uint(0);
        _development = payable(_developmentWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_developmentWallet));
        assert(transferred==true);
        return transferred;
    }

    function coinDeposit(uint256 amountETH) internal returns(bool) {
        uint ETH_liquidity = amountETH;
        return splitAndStore(_msgSender(),uint(ETH_liquidity), address(this), false);
    }

    function splitAndStore(address _depositor, uint eth_liquidity, address token, bool isToken) internal returns(bool) {
        if(address(token) != address(this) && isToken != false){
            (uint sumOfLiquidityToSplit,uint cliq, uint dliq) = split(eth_liquidity);
            assert(uint(sumOfLiquidityToSplit)==uint(eth_liquidity));
            tokenAmountDeposited[address(_depositor)] += uint(eth_liquidity);
            tokenAmountOwed[address(_community)] += uint(cliq);
            tokenAmountOwed[address(_development)] += uint(dliq);
        } else {
            (uint sumOfLiquidityToSplit,uint cliq, uint dliq) = split(eth_liquidity);
            assert(uint(sumOfLiquidityToSplit)==uint(eth_liquidity));
            coinAmountDeposited[address(_depositor)] += uint(eth_liquidity);
            coinAmountOwed[address(_community)] += uint(cliq);
            coinAmountOwed[address(_development)] += uint(dliq);
        }
        return true;
    }

    function vaultDebt(address vaultOps) public view authorized() returns(uint,uint,uint,uint) {
        return (coinAmountOwed[address(vaultOps)],wkekAmountOwed[address(vaultOps)],coinAmountDrawn[address(vaultOps)],tokenAmountDrawn[address(vaultOps)]);
    }

    function split(uint liquidity) public view returns(uint,uint,uint) {
        assert(uint(liquidity) > uint(0));
        uint communityLiquidity = (liquidity * teamDonationMultiplier) / shareBasisDivisor;
        uint developmentLiquidity = (liquidity - communityLiquidity);
        uint totalSumOfLiquidity = communityLiquidity+developmentLiquidity;
        assert(uint(totalSumOfLiquidity)==uint(liquidity));
        require(uint(totalSumOfLiquidity)==uint(liquidity));
        return (totalSumOfLiquidity,communityLiquidity,developmentLiquidity);
    }
    
    function tokenizeWETH() public returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        bool successA = false;
        uint cTok = cliq;
        uint dTok = dliq;
        try IWRAP(WageKEK).deposit{value: ETH_liquidity}() {
            coinAmountOwed[address(_community)] -= uint(cliq);
            coinAmountOwed[address(_development)] -= uint(dliq);
            wkekAmountOwed[address(_community)] += uint(cTok);
            wkekAmountOwed[address(_development)] += uint(dTok);
            successA = true;
        } catch {
            successA = false;
        }
        assert(successA==true);
        emit TokenizeWETH(address(this), sumOfLiquidityWithdrawn);
        return successA;
    }

    function withdraw() external returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        coinAmountDrawn[address(_community)] += coinAmountOwed[address(_community)];
        coinAmountDrawn[address(_development)] += coinAmountOwed[address(_development)];
        coinAmountOwed[address(_community)] = uint(0);
        coinAmountOwed[address(_development)] = uint(0);
        payable(_community).transfer(cliq);
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
        return true;
    }

    function withdrawToken(address token) public returns(bool) {
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(Token_liquidity);
        uint cTok = cliq;
        uint dTok = dliq;
        if(address(token) == address(WKEK)){
            wkekAmountOwed[address(_community)] -= uint(cTok);
            wkekAmountOwed[address(_development)] -= uint(dTok);
            IERC20(token).transfer(payable(_community), cliq);
            IERC20(token).transfer(payable(_development), dliq);
        } else {
            tokenAmountDrawn[address(_community)] += uint(sumOfLiquidityWithdrawn);
            IERC20(token).transfer(payable(_community), sumOfLiquidityWithdrawn);
        }
        emit WithdrawToken(address(this), address(token), sumOfLiquidityWithdrawn);
        return true;
    }

    function transfer(address sender, uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        address _development_ = payable(_development);
        address _community_ = payable(_community);
        require(address(receiver) != address(0));
        if(address(_development) == address(sender)){
            _development_ = payable(receiver);
        } else if(address(_community) == address(sender)){
            _community_ = payable(receiver);
        } else {
            revert("!AUTH");
        }
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(uint(amount));
        assert(uint(sumOfLiquidityWithdrawn)==uint(amount));
        coinAmountDrawn[address(_community)] += uint(cliq);
        coinAmountDrawn[address(_development)] += uint(dliq);
        coinAmountOwed[address(_community)] -= uint(cliq);
        coinAmountOwed[address(_development)] -= uint(dliq);
        (bool successA,) = payable(_community_).call{value: cliq}("");
        (bool successB,) = payable(_development_).call{value: dliq}("");
        bool success = successA == successB;
        assert(success);
        return success;
    }
    
}
