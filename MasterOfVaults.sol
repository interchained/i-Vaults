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
                                                                                
contract KEK_MasterOfVaults is iAuth {

    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    address payable private KEK = payable(0xeAEC17f25A8219FCd659B38c577DFFdae25539BE);
    address payable public VF;
    
    uint256 private vip = 1;
    
    constructor(address payable iVF_) payable iAuth(address(_msgSender()),address(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD),address(0x3BF7616C25560d0B8CB51c00a7ad80559E26f269)) {
        setVIP(iVF_,payable(0xA888a7A2dc73efdb5705106a216f068e939A2693),payable(0xeAEC17f25A8219FCd659B38c577DFFdae25539BE),uint256(1),false,uint256(38*10**14),uint256(25000*10**18));
    }

    receive() external payable { }

    fallback() external payable { }

    // function deployVaultFactory() public returns(address payable) {
    //     return payable(address(new KEK_Vault_Factory()));
    // }
    function deployVaults(uint256 number) public payable authorized() returns(address payable) {
        (address payable vault) = IKEK_VAULT(VF).deployVaults(number);
        return vault;
    }
    
    function walletOfIndex(uint256 id) public view authorized() returns(address) {
        (address wallet) = IKEK_VAULT(VF).walletOfIndex(id);
        return address(wallet);
    }

    function indexOfWallet(address wallet) public view authorized() returns(uint256) {
        (uint256 index) = IKEK_VAULT(VF).indexOfWallet(wallet);
        return uint256(index);
    }

    function balanceOf(uint256 receiver) public view authorized() returns(uint256) {
        (uint256 bO) = IKEK_VAULT(VF).balanceOf(receiver);
        return uint256(bO);
    }

    function balanceOfToken(uint256 receiver, address token) public view authorized() returns(uint256) {
        (uint256 bOt) = IKEK_VAULT(VF).balanceOfToken(receiver, token);
        return uint256(bOt);
    }

    function balanceOfVaults(address token, uint256 _from, uint256 _to) public view authorized() returns(uint256,uint256) {
        (uint256 _Etotals,uint256 _Ttotals) = IKEK_VAULT(VF).balanceOfVaults(token, _from, _to);
        return (_Etotals,_Ttotals);
    }
    
    function withdrawFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) public authorized() returns (bool) {
        return IKEK_VAULT(VF).withdrawFundsFromVaultTo(_id, amount, receiver);
    }

    function withdraw() public authorized() {
        IKEK_VAULT(VF).withdraw();
    }
    
    function withdrawToken(address token) public authorized() {
        IKEK_VAULT(VF).withdrawToken(token);
    }
    
    function withdrawFrom(uint256 number) public authorized() {
        IKEK_VAULT(VF).withdrawFrom(number);
    }

    function withdrawTokenFrom(address token, uint256 number) public authorized() {
        IKEK_VAULT(VF).withdrawTokenFrom(token, number);
    }

    function wrapVault(uint256 number) public authorized() {
        IRECEIVE_KEK(payable(IKEK_VAULT(VF).walletOfIndex(uint256(number)))).tokenizeWETH();
    }

    function checkVaultDebt(uint number, address operator) public view returns(uint,uint,uint,uint,uint,uint,uint) {
        (address wOi) = IKEK_VAULT(VF).walletOfIndex(uint256(number));
        return IRECEIVE_KEK(payable(wOi)).vaultDebt(address(operator));
    }

    function brigeOut(uint256 amount,address payable receiver) public authorized() {
        IRECEIVE_KEK(getVIP()).bridgeTransferOut(amount, receiver);
    }

    function getVIP() public view returns(address payable) {
        return payable(IKEK_VAULT(VF).walletOfIndex(vip));
    }

    function setVIP(address payable iVF,address payable iWKEK,address payable iKEK,uint vipINum,bool tokenFee,uint tFee,uint bMaxAmt) public virtual authorized() {
        VF = iVF;
        KEK = iKEK;
        WKEK = iWKEK;
        vip = vipINum;
        IKEK_VAULT(iVF).setVIP(KEK,WKEK,vipINum,tokenFee,tFee,bMaxAmt);
    }
}
