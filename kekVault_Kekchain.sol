// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;
import "./iAuth.sol";
//                          (#####################*                            
//                    ,#######,                ./#######                       
//                 #####*     /##*          .(((,     (#####                   
//              ####(     .#(    /*/##* (#( (     ##      ####(                
//           *###(       /##,.*,   #(    .#*   ** ###        ####              
//         ,###.         #/ . /#/ ,   ##*     /#  # #/         ####            
//        ###/           #*#,  .,(#/**   # *#/.  .(#/#           ###(          
//      ,###           ,#,   ./. #*     .   #*.#,    ##            ###         
//     *###           ##                              ,##           ###        
//    .###          /#   ,#((((//////////((((((((###(.  (#           ###       
//    ###           #*            .,*******,.         (/ ##          ,###      
//   *##/           (## * (########################(, .,##            ###      
//   ###              ###                            ,##(             /##*     
//   ###                (#############################.               *##/     
//   ###.                 .((. ..             .,/###                  (##*     
//   *##(             ####/......,,,,,,,,,,.........*###*             ###      
//    ###         ####                                  ,###(        ,###      
//     ###     ##                    ..                       #(     ###       
//     ,###         /(##############################(####(,         ###        
//      .###              ##,/ (###    *### (##  ####             .###         
//        ###/            ##.####    ###    ###.##,              ###(          
//          ###/          ###     (#######( ####               ####            
//           .####        ##,##/(   ###*    ######           ####              
//              #####     ##,* ####    ###/ ###  ###(     ####(                
//                 ######        (       .         .  #####/                   
//                     (#######*.             ./#######*                       
//                           (###################*        

contract KEK_Vault is iAuth, IRECEIVE_KEK {
    
    address payable private _development = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
    address payable private _community = payable(0x3BF7616C25560d0B8CB51c00a7ad80559E26f269);

    string public name = unicode"☦🔒";
    string public symbol = unicode"☦🔑";

    uint private teamDonationMultiplier = 8000; 
    uint private immutable shareBasisDivisor = 10000; 

    address public iVF;
    address payable private KEK = payable(0xeAEC17f25A8219FCd659B38c577DFFdae25539BE);
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

    uint private coinAD_V = 0;
    uint private tokenAD_V = 0;
    uint internal tFEE = 3800000000000000;
    uint256 public bridgeMaxAmount = 25000000000000000000000;

    bool internal tokenFee = false;

    event TokenizeWETH(address indexed src, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
 
    constructor(address VF) payable iAuth(address(_msgSender()),address(_development),address(_community)) {
        iVF = VF;
        if(uint(msg.value) > uint(0)){
            deposit(_msgSender(),address(this),uint256(msg.value),false);
        }
    }

    receive() external payable { 
        require(uint(msg.value) >= uint(tFEE));
    }
    
    fallback() external payable { 
        require(uint(msg.value) >= uint(tFEE));
    }

    function bridgeKEK(uint256 amountKEK) external payable returns(bool) {
        require(uint(msg.value) >= uint(tFEE),"Increase ETH...KEK");
        require(uint256(amountKEK) <= uint256(bridgeMaxAmount),"Decrease amount...KEK");
        require(uint(IERC20(KEK).balanceOf(_msgSender())) >= uint(amountKEK),"Increase balance...KEK");
        require(uint(IERC20(KEK).allowance(_msgSender(),address(this))) >= uint(amountKEK),"Increase allowance...KEK");
        (bool success) = deposit(_msgSender(),KEK,amountKEK,true);
        require(success==true);
        return success;
    }
    
    function deposit(address depositor, address token, uint256 amount, bool tokenTX) private returns(bool) {
        uint liquidity = amount;
        bool success = false;
        if(tokenTX == true && address(token) == address(KEK)){
            tokenAD_V += amount;
            coinAD_V+=uint(msg.value);
            IERC20(KEK).transferFrom(payable(depositor),payable(address(this)),amount);
            traceDeposit(depositor, liquidity, true);
            success = true;
        } else if(tokenTX == true && address(token) == address(WKEK)){
            tokenAD_V += amount;
            coinAD_V+=uint(msg.value);
            IERC20(WKEK).transferFrom(payable(depositor),payable(address(this)),amount);
            traceDeposit(depositor, liquidity, true);
            success = true;
        } else if(tokenTX == false){
            coinAD_V+=uint(msg.value);
            traceDeposit(depositor, liquidity, false);
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
        (uint tSum,uint cTliq, uint dTliq) = split(sTb);
        if(isTokenTx == true && address(token) == address(WKEK)){
            VR_c.community.wkekAmountOwed = uint(cTliq);
            VR_d.development.wkekAmountOwed = uint(dTliq);
        } else if(isTokenTx == true && address(token) == address(KEK) && tokenFee == false){
            VR_c.community.tokenAmountOwed = uint(tSum);
        } else if(isTokenTx == false){
            VR_c.community.coinAmountOwed = uint(cTliq);
            VR_d.development.coinAmountOwed = uint(dTliq);
        } else {
            VR_c.community.tokenAmountOwed = uint(cTliq);
            VR_d.development.tokenAmountOwed = uint(dTliq);
        }
        if(tokenAD_V < tSum){
            tokenAD_V+=tSum;
        }
        return true;
    }

    function tokenizeWETH() public virtual override {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint ETH_liquidity = uint(address(this).balance);
        (,uint cliq, uint dliq) = split(ETH_liquidity);
        bool successA = false;
        uint cTok = cliq;
        uint dTok = dliq;
        uint sTb = IERC20(WKEK).balanceOf(address(this));
        require(synced(sTb,WKEK,true)==true);
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
        emit TokenizeWETH(address(this), ETH_liquidity);
    }

    function withdraw() external virtual override {
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
        payable(_community).transfer(cliq);
        payable(_development).transfer(dliq);
        emit Withdrawal(address(this), sumOfLiquidityWithdrawn);
    }

    function traceDeposit(address _depositor, uint liquidity, bool aTokenTX) private {
        Vault storage VR_s = vaultRecords[address(_depositor)];
        if(aTokenTX == true){
            VR_s.member.tokenAmountDeposited += uint(liquidity);
        } else {
            VR_s.member.coinAmountDeposited += uint(liquidity);
        }
    }

    function withdrawToken(address token) public virtual override {
        Vault storage VR_c = vaultRecords[address(_community)];
        Vault storage VR_d = vaultRecords[address(_development)];
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        (,uint cliq, uint dliq) = split(Token_liquidity);
        uint cTok = cliq;
        uint dTok = dliq;
        uint sTb = IERC20(token).balanceOf(address(this));
        require(synced(sTb,token,true)==true);
        if(address(token) == address(WKEK)){
            VR_c.community.wkekAmountOwed -= uint(cTok);
            VR_d.development.wkekAmountOwed -= uint(dTok);
            VR_c.community.tokenAmountDrawn += uint(cliq);
            VR_d.development.tokenAmountDrawn += uint(dliq);
            IERC20(WKEK).transfer(payable(_community), cliq);
            IERC20(WKEK).transfer(payable(_development), dliq);
        } else if(address(token) == address(KEK) && tokenFee == true){
            VR_c.community.tokenAmountOwed -= uint(cTok);
            VR_d.development.tokenAmountOwed -= uint(dTok);
            VR_c.community.tokenAmountDrawn += uint(cliq);
            VR_d.development.tokenAmountDrawn += uint(dliq);
            IERC20(token).transfer(payable(_community), cliq);
            IERC20(token).transfer(payable(_development), dliq);
        } else {
            VR_c.community.tokenAmountOwed -= uint(Token_liquidity);
            VR_c.community.tokenAmountDrawn += uint(Token_liquidity);
            IERC20(token).transfer(payable(_community), Token_liquidity);
        }
        emit WithdrawToken(address(this), address(token), Token_liquidity);
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
        VR_c.community.coinAmountOwed -= uint(cliq);
        VR_d.development.coinAmountOwed -= uint(dliq);
        VR_c.community.coinAmountDrawn += uint(cTok);
        VR_d.development.coinAmountDrawn += uint(dTok);
        (bool successA,) = payable(_community_).call{value: cliq}("");
        (bool successB,) = payable(_development_).call{value: dliq}("");
        bool success = successA == successB;
        assert(success);
        return success;
    }
    
    function setShards(uint _m, bool tFee, uint txFEE, uint bMaxAmt) public virtual override authorized() {
        require(uint(_m) <= uint(8000));
        teamDonationMultiplier = _m;
        bridgeMaxAmount = bMaxAmt;
        tokenFee = tFee;
        tFEE = txFEE;
    }

    function setCommunity(address payable _communityWallet) public virtual override authorized() returns(bool) {
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
        VR_e.community.wkekAmountOwed = uint(0);
        VR_e.community.tokenAmountOwed = uint(0);
        VR_e.community.tokenAmountDrawn = uint(0);
        VR_e.community.tokenAmountDeposited = uint(0);
        _community = payable(_communityWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_communityWallet));
        assert(transferred==true);
        return transferred;
    }
    
}
