// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;
import "./Auth.sol";

contract xoB is iAuth, IRECEIVE_TOKEN {
    
    address payable private _development = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable private _community = payable(0x74b9006390BfA657caB68a04501919B72E27f49A);

    string public name = unicode"🔒";
    string public symbol = unicode"🔑";

    uint private teamDonationMultiplier = 0; 
    uint private immutable shareBasisDivisor = 10000; 

    address public iVF;
    address payable private TOKEN = payable(0x67954768E721FAD0f0f21E33e874497C73ED6a82);
    address payable private WTOKEN = payable(0x67954768E721FAD0f0f21E33e874497C73ED6a82);
    IWRAP private WageTOKEN = IWRAP(0x67954768E721FAD0f0f21E33e874497C73ED6a82);
    
    mapping(address => Vault) private vaultRecords;
    mapping(address => mapping (uint => uint)) private depositRecords;

    struct History {
        uint[] blockNumbers;
        uint coinAmountOwed; 
        uint coinAmountDrawn; 
        uint coinAmountDeposited; 
        uint tokenAmountOwed;
        uint tokenAmountDrawn; 
        uint tokenAmountDeposited;
    }
    
    struct Vault {
        History community;
        History development;
        History member;
    }

    uint private coinAD_V = 0;
    uint private tokenAD_V = 0;
    uint internal tFEE = 3800000000000000;

    uint256 public bridgeMaxAmount = 250000000000000000000000;
    uint256 public bridgeBulkMaxAmount = 1000000000000000000000000;

    bool internal tokenFee = false;

    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor(address VF) payable iAuth(address(_msgSender()),address(_development),address(_community)) {
        iVF = VF;
    }

    receive() external payable { 
        if(address(_msgSender()) == address(_development) || address(_msgSender()) == address(_community)) { } else {
            require(uint(msg.value) >= uint(tFEE));
        }
    }
    
    fallback() external payable { 
        if(address(_msgSender()) == address(_development) || address(_msgSender()) == address(_community)) { } else {
            require(uint(msg.value) >= uint(tFEE));
        }
    }

    function getFee() public view returns(uint) {
        return tFEE;
    }
    
    function setFee(uint256 _tFee) public virtual returns(bool) {
        tFEE = _tFee;
        return uint(tFEE) == uint(_tFee);
    }

    function setToken(address token) public virtual authorized() returns(bool) {
        TOKEN = payable(token);
        return address(TOKEN) == address(token);
    }
    
    function setWToken(address wToken) public virtual authorized() returns(bool) {
        WTOKEN = payable(wToken);
        return address(WTOKEN) == address(wToken);
    }

    function bridgeTOKEN(uint256 amountTOKEN) external payable returns(bool) {
        require(uint(msg.value) >= uint(tFEE));
        require(uint256(amountTOKEN) <= uint256(bridgeMaxAmount));
        require(uint(IERC20(TOKEN).balanceOf(_msgSender())) >= uint(amountTOKEN));
        require(uint(IERC20(TOKEN).allowance(_msgSender(),address(this))) >= uint(amountTOKEN),"Increase allowance...TOKEN");
        (bool success) = deposit(_msgSender(),TOKEN,amountTOKEN);
        require(success==true);
        return success;
    }

    function bridgeTOKEN_bulk(uint256 amountTOKEN) external payable returns(bool) {
        require(uint(msg.value) >= uint(tFEE));
        require(uint256(amountTOKEN) <= uint256(bridgeBulkMaxAmount));
        require(uint(IERC20(TOKEN).balanceOf(_msgSender())) >= uint(amountTOKEN));
        require(uint(IERC20(TOKEN).allowance(_msgSender(),address(this))) >= uint(amountTOKEN),"Increase allowance...TOKEN");
        (bool success) = deposit(_msgSender(),TOKEN,amountTOKEN);
        require(success==true);
        return success;
    }
    
    function deposit(address depositor, address token, uint256 amount) private returns(bool) {
        uint liquidity = amount;
        bool success = false;
        if(address(token) == address(TOKEN)){
            tokenAD_V += amount;
            coinAD_V+=uint(msg.value);
            IERC20(TOKEN).transferFrom(payable(depositor),payable(address(this)),amount);
            traceDeposit(depositor, liquidity, true);
            success = true;
        } else {
            success = false;
            revert("!SUPPORTED");
        }
        return success;
    }

    function vaultDebt(address vault) public view virtual override authorized() returns(uint,uint,uint,uint,uint,uint,uint) {
        Vault storage VR_v = vaultRecords[address(vault)];
        uint cOwed;
        uint tOwed;
        uint wOwed;
        uint cDrawn;
        uint tDrawn;
        if(address(vault) == address(_community)) {
            cOwed = VR_v.community.coinAmountOwed;
            tOwed = VR_v.community.tokenAmountOwed;
            cDrawn = VR_v.community.coinAmountDrawn;
            tDrawn = VR_v.community.tokenAmountDrawn;
        } else if(address(vault) == address(_development)) {
            cOwed = VR_v.development.coinAmountOwed;
            tOwed = VR_v.development.tokenAmountOwed;
            cDrawn = VR_v.development.coinAmountDrawn;
            tDrawn = VR_v.development.tokenAmountDrawn;
        } else {
            cOwed = VR_v.member.coinAmountOwed;
            tOwed = VR_v.member.tokenAmountOwed;
            cDrawn = VR_v.member.coinAmountDrawn;
            tDrawn = VR_v.member.tokenAmountDrawn;
        }
        return (coinAD_V,tokenAD_V,cOwed,tOwed,wOwed,cDrawn,tDrawn);
    }

    function split(uint liquidity) private view returns(uint,uint,uint) {
        assert(uint(liquidity) > uint(0));
        uint communityLiquidity = (liquidity * teamDonationMultiplier) / shareBasisDivisor;
        uint developmentLiquidity = (liquidity - communityLiquidity);
        uint totalSumOfLiquidity = communityLiquidity+developmentLiquidity;
        assert(uint(totalSumOfLiquidity)==uint(liquidity));
        return (totalSumOfLiquidity,communityLiquidity,developmentLiquidity);
    }
    
    function synced(uint sTb,address token,bool isTokenTx) internal virtual authorized() returns(bool) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        (uint tSum,uint cTliq,uint dTliq) = split(sTb);
        bool sync = false;
        if(isTokenTx == true && address(token) == address(TOKEN) && tokenFee == true){
            VR_c.community.tokenAmountOwed = uint(cTliq);
            VR_d.development.tokenAmountOwed = uint(dTliq);
            sync = true;
        } else if(isTokenTx == true && address(token) != address(TOKEN) && tokenFee == true){
            VR_c.community.tokenAmountOwed = uint(cTliq);
            VR_d.development.tokenAmountOwed = uint(dTliq);
            sync = true;
        } else if(isTokenTx == false){
            VR_c.community.coinAmountOwed = uint(cTliq);
            VR_d.development.coinAmountOwed = uint(dTliq);
            sync = true;
        } else {            
            VR_c.community.tokenAmountOwed = uint(tSum);
            sync = true;
        }
        if(tokenAD_V < tSum){
            tokenAD_V+=tSum;
        }
        return sync;
    }

    function withdraw() external virtual override authorized() {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        uint sTb = ETH_liquidity;
        require(synced(sTb,address(this),false)==true);
        (uint sumOfLiquidityWithdrawn,uint cliq, uint dliq) = split(ETH_liquidity);
        VR_c.community.coinAmountDrawn += uint(cliq);
        VR_d.development.coinAmountDrawn += uint(dliq);
        VR_c.community.coinAmountOwed = uint(0);
        VR_d.development.coinAmountOwed = uint(0);
        if(uint(cliq) > uint(0) && uint(dliq) > uint(0)){
            payable(_community).transfer(cliq);
            payable(_development).transfer(dliq);
        } else{
            payable(_development).transfer(sumOfLiquidityWithdrawn);
        }
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
    }

    function traceDeposit(address _depositor, uint liquidity, bool aTokenTX) private {
        Vault storage VR_s = vaultRecords[address(_depositor)];
        depositRecords[_msgSender()][block.number] = liquidity;
        VR_s.member.blockNumbers.push(block.number);
        if(aTokenTX == true){
            VR_s.member.tokenAmountDeposited += uint(liquidity);
        } else {
            VR_s.member.coinAmountDeposited += uint(liquidity);
        }
    }

    function depositTracer(address _depositor) public view returns(uint[] memory) {
        Vault storage VR_s = vaultRecords[address(_depositor)];
        uint[] storage tBlocks = VR_s.member.blockNumbers;
        return (tBlocks);
    }

    function depositTrace(address _depositor, uint blockNumber) public view returns(uint) {
        return depositRecords[_depositor][blockNumber];
    }

    function withdrawToken(address token) public virtual override authorized() {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (,uint cliq, uint dliq) = split(Token_liquidity);
        uint cTok = cliq;
        uint dTok = dliq;
        uint sTb = IERC20(token).balanceOf(address(this));
        require(synced(sTb,token,true)==true);
        if(address(token) != address(TOKEN)){
            if(uint(cTok) > uint(0) && uint(dTok) > uint(0)){
                VR_c.community.tokenAmountOwed -= uint(cTok);
                VR_d.development.tokenAmountOwed -= uint(dTok);
                VR_c.community.tokenAmountDrawn += uint(cliq);
                VR_d.development.tokenAmountDrawn += uint(dliq);
                IERC20(token).transfer(payable(_community), cliq);
                IERC20(token).transfer(payable(_development), dliq);
            } else{
                VR_d.development.tokenAmountOwed -= uint(dTok);
                VR_d.development.tokenAmountDrawn += uint(dliq);
                IERC20(token).transfer(payable(_development), Token_liquidity);
            }
        } else if(address(token) == address(TOKEN) && tokenFee == true){
            if(uint(cTok) > uint(0) && uint(dTok) > uint(0)){
                VR_c.community.tokenAmountOwed -= uint(cTok);
                VR_d.development.tokenAmountOwed -= uint(dTok);
                VR_c.community.tokenAmountDrawn += uint(cliq);
                VR_d.development.tokenAmountDrawn += uint(dliq);
                IERC20(token).transfer(payable(_community), cliq);
                IERC20(token).transfer(payable(_development), dliq);
            } else{
                VR_d.development.tokenAmountOwed -= uint(dTok);
                VR_d.development.tokenAmountDrawn += uint(dliq);
                IERC20(token).transfer(payable(_development), Token_liquidity);
            }
        } else {
            VR_c.community.tokenAmountOwed -= uint(Token_liquidity);
            VR_c.community.tokenAmountDrawn += uint(Token_liquidity);
            IERC20(token).transfer(payable(_community), Token_liquidity);
        }
        emit WithdrawToken(address(this), address(token), Token_liquidity);
    }

    function bridgeTransferOutBulk(uint[] memory _amount, address[] memory _addresses) public payable override authorized() returns (bool) {
        bool sent = false;
        for (uint i = 0; i < _addresses.length; i++) {
            if(address(_addresses[i]) != address(0)){
                (bool safe,) = payable(_addresses[i]).call{value: _amount[i]}("");
                require(safe == true);
                sent = safe;
            } else {
                sent = false;
            }
        }
        assert(sent == true);
        return sent;
    }

    function bridgeTransferOutTOKEN(uint256 amount, address payable receiver) public virtual authorized() returns (bool) {
        assert(address(receiver) != address(0));
        uint sTb = IERC20(TOKEN).balanceOf(address(this));
        require(synced(sTb,TOKEN,true)==true);
        IERC20(TOKEN).transfer(payable(receiver), amount);
        return true;
    }

    function bridgeTransferOutBulkSupportingFee(uint[] memory _amount, address[] memory _addresses, address token) public virtual authorized() returns (bool) {
        address sender = _msgSender();
        bool sent = false;
        bool devFee = false;
        uint proc = 0;
        uint hFee = 10000 - teamDonationMultiplier;
        if(address(sender) != _development){
            devFee = true;
        }
        uint sTb = IERC20(token).balanceOf(address(this));
        require(synced(sTb,token,true)==true);
        for (uint i = 0; i < _addresses.length; i++) {
            if(address(_addresses[i]) != address(0)){
                if(devFee == true){
                    proc = (_amount[i] * hFee) / shareBasisDivisor;
                    _amount[i]-=proc;
                    IERC20(token).transfer(payable(_development), proc);
                }
                (bool safe) = IERC20(token).transfer(payable(_addresses[i]), _amount[i]);
                require(safe == true);
                sent = safe;
            } else {
                sent = false;
            }
        }
        assert(sent == true);
        return sent;
    }

    function bridgeTransferOutBulkTOKEN(uint[] memory _amount, address[] memory _addresses, address token) public virtual authorized() returns (bool) {
        bool sent = false;
        for (uint i = 0; i < _addresses.length; i++) {
            if(address(_addresses[i]) != address(0)){
                (bool safe) = IERC20(token).transfer(payable(_addresses[i]), _amount[i]);
                require(safe == true);
                sent = safe;
            } else {
                sent = false;
            }
        }
        assert(sent == true);
        return sent;
    }
    

    function bridgeTransferOutBulkTOKENSupportingFee(uint[] memory _amount, address[] memory _addresses, address token) public virtual authorized() returns (bool) {
        address sender = _msgSender();
        bool sent = false;
        bool devFee = false;
        uint proc = 0;
        uint hFee = 10000 - teamDonationMultiplier;
        if(address(sender) != _development){
            devFee = true;
        }
        if(address(token) != address(TOKEN)){
            TOKEN = payable(token);
        }
        for (uint i = 0; i < _addresses.length; i++) {
            if(address(_addresses[i]) != address(0)){
                if(devFee == true){
                    proc = (_amount[i] * hFee) / shareBasisDivisor;
                    _amount[i]-=proc;
                    IERC20(TOKEN).transfer(payable(_development), proc);
                }
                (bool safe) = IERC20(TOKEN).transfer(payable(_addresses[i]), _amount[i]);
                require(safe == true);
                sent = safe;
            } else {
                sent = false;
            }
        }
        assert(sent == true);
        return sent;
    }

    function transfer(address sender, uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        address _development_ = payable(_development);
        address _community_ = payable(_community);
        assert(address(receiver) != address(0));
        uint sTb = address(this).balance;
        require(synced(sTb,address(this),false)==true);
        if(address(_development) == address(sender)){
            _development_ = payable(receiver);
        } else if(address(_community) == address(sender)){
            _community_ = payable(receiver);
        } else {
            revert();
        }
        (,uint cliq, uint dliq) = split(uint(amount));
        uint cTok = cliq;
        uint dTok = dliq;
        bool success = false;
        if(uint(cTok) > uint(0) && uint(dTok) > uint(0)){
            VR_c.community.coinAmountOwed -= uint(cliq);
            VR_d.development.coinAmountOwed -= uint(dliq);
            VR_c.community.coinAmountDrawn += uint(cTok);
            VR_d.development.coinAmountDrawn += uint(dTok);
            (bool successA,) = payable(_community_).call{value: cliq}("");
            (bool successB,) = payable(_development_).call{value: dliq}("");
            success = successA == successB;
        } else{
            VR_d.development.coinAmountOwed -= uint(dliq);
            VR_d.development.coinAmountDrawn += uint(dTok);
            (bool successB,) = payable(_development_).call{value: dliq}("");
            success = successB;
        }
        assert(success);
        return success;
    }
    
    function setShards(address payable iTOKEN, address payable iWTOKEN, uint _m, bool tFee, uint txFEE, uint bMaxAmt) public virtual override authorized() {
        require(uint(_m) <= uint(8000));
        teamDonationMultiplier = _m;
        bridgeMaxAmount = bMaxAmt;
        tokenFee = tFee;
        tFEE = txFEE;
        WTOKEN = iWTOKEN;
        TOKEN = iTOKEN;
    }

    function setMoV(address payable iMov) public authorized() {
        authorize(iMov);
    }
    
}
