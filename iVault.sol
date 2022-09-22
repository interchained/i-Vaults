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
    
    mapping(address => Vault) private vaultRecords;

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
        History member;
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

    function setCommunity(address payable _communityWallet) public virtual authorized() returns(bool) {
        require(address(_community) == _msgSender());
        Vault storage VR_n = vaultRecords[address(_communityWallet)];
        Vault storage VR_e = vaultRecords[address(_community)];
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

    function setDevelopment(address payable _developmentWallet) public virtual authorized() returns(bool) {
        require(address(_development) == _msgSender());
        Vault storage VRD_n = vaultRecords[address(_developmentWallet)];
        Vault storage VRD_e = vaultRecords[address(_development)];
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

    function coinDeposit(uint256 amountETH) internal virtual returns(bool) {
        uint ETH_liquidity = amountETH;
        return splitAndStore(_msgSender(),uint(ETH_liquidity), address(this), false);
    }

    function tokenDeposit(address token, uint256 tokenAmount) internal virtual returns(bool) {
        uint TOKEN_liquidity = tokenAmount;
        return splitAndStore(_msgSender(),uint(TOKEN_liquidity), address(token), true);
    }

    function splitAndStore(address _depositor, uint eth_liquidity, address token, bool isToken) internal virtual returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        Vault storage VR_s = vaultRecords[address(_depositor)];
        
        (uint sumOfLiquidityToSplit,uint cliq, uint dliq) = split(eth_liquidity);
        assert(uint(sumOfLiquidityToSplit)==uint(eth_liquidity));
        if(isToken == true){
            if(address(token) == address(WKEK)){
                VR_c.community.wkekAmountOwed += uint(cliq);
                VR_d.development.wkekAmountOwed += uint(dliq);
                VR_s.member.tokenAmountDeposited += uint(eth_liquidity);
            } else if(address(token) == address(KEK)){
                VR_c.community.wkekAmountOwed += uint(cliq);
                VR_s.member.tokenAmountDeposited += uint(eth_liquidity);
            } else {
                VR_c.community.tokenAmountOwed += uint(cliq);
                VR_d.development.tokenAmountOwed += uint(dliq);
                VR_s.member.tokenAmountDeposited += uint(eth_liquidity);
            }
        } else {
            VR_c.community.coinAmountOwed += uint(cliq);
            VR_d.development.coinAmountOwed += uint(dliq);
            VR_s.member.coinAmountDeposited += uint(eth_liquidity);
        }
        return true;
    }

    function vaultDebt(address vault) public view virtual override authorized() returns(uint,uint,uint,uint,uint) {
        Vault storage VR_v = vaultRecords[address(vault)];
        uint cOwed;
        uint tOwed;
        uint wOwed;
        uint cDrawn;
        uint tDrawn;
        if(address(vault) == address(_community)) {
            cOwed = VR_v.community.coinAmountOwed;
            tOwed = VR_v.community.tokenAmountOwed;
            wOwed = VR_v.community.wkekAmountOwed;
            cDrawn = VR_v.community.coinAmountDrawn;
            tDrawn = VR_v.community.tokenAmountDrawn;
        } else if(address(vault) == address(_development)) {
            cOwed = VR_v.development.coinAmountOwed;
            tOwed = VR_v.development.tokenAmountOwed;
            wOwed = VR_v.development.wkekAmountOwed;
            cDrawn = VR_v.development.coinAmountDrawn;
            tDrawn = VR_v.development.tokenAmountDrawn;
        } else {
            cOwed = VR_v.member.coinAmountOwed;
            tOwed = VR_v.member.tokenAmountOwed;
            wOwed = VR_v.member.wkekAmountOwed;
            cDrawn = VR_v.member.coinAmountDrawn;
            tDrawn = VR_v.member.tokenAmountDrawn;
        }
        return (cOwed,tOwed,wOwed,cDrawn,tDrawn);
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
    
    function tokenizeWETH() public virtual override returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        bool successA = false;
        uint cTok = cliq;
        uint dTok = dliq;
        try IWRAP(WageKEK).deposit{value: ETH_liquidity}() {
            VR_c.community.coinAmountOwed -= uint(cliq);
            VR_d.development.coinAmountOwed -= uint(dliq);
            VR_c.community.wkekAmountOwed += uint(cTok);
            VR_d.development.wkekAmountOwed += uint(dTok);
            successA = true;
        } catch {
            successA = false;
        }
        assert(successA==true);
        emit TokenizeWETH(address(this), sumOfLiquidityWithdrawn);
        return successA;
    }

    function withdraw() external virtual override returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        require(uint(VR_c.community.coinAmountOwed) == uint(cliq));
        require(uint(VR_d.development.coinAmountOwed) == uint(dliq));
        VR_c.community.coinAmountDrawn += uint(VR_c.community.coinAmountOwed);
        VR_d.development.coinAmountDrawn += uint(VR_d.development.coinAmountOwed);
        VR_c.community.coinAmountOwed = uint(0);
        VR_d.development.coinAmountOwed = uint(0);
        payable(_community).transfer(cliq);
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
        return true;
    }

    function withdrawToken(address token) public virtual override returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(Token_liquidity);
        uint cTok = cliq;
        uint dTok = dliq;
        if(address(token) == address(WKEK)){
            VR_c.community.wkekAmountOwed -= uint(cTok);
            VR_d.development.wkekAmountOwed -= uint(dTok);
            IERC20(token).transfer(payable(_community), cliq);
            IERC20(token).transfer(payable(_development), dliq);
        } else {
            VR_c.community.tokenAmountDrawn += uint(sumOfLiquidityWithdrawn);
            IERC20(token).transfer(payable(_community), sumOfLiquidityWithdrawn);
        }
        emit WithdrawToken(address(this), address(token), sumOfLiquidityWithdrawn);
        return true;
    }

    function transfer(address sender, uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
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
        uint cTok = cliq;
        uint dTok = dliq;
        VR_c.community.coinAmountDrawn += uint(cTok);
        VR_d.development.coinAmountDrawn += uint(dTok);
        VR_c.community.coinAmountOwed -= uint(cliq);
        VR_d.development.coinAmountOwed -= uint(dliq);
        (bool successA,) = payable(_community_).call{value: cliq}("");
        (bool successB,) = payable(_development_).call{value: dliq}("");
        bool success = successA == successB;
        assert(success);
        return success;
    }
    
}
