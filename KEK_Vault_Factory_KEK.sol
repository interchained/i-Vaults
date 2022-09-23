// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;
import "./kekVault_Kekchain.sol";
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
                                                                                
contract KEK_Vault_Factory is iAuth, IKEK_VAULT {

    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    address payable private KEK = payable(0xeAEC17f25A8219FCd659B38c577DFFdae25539BE);
    
    mapping ( uint256 => address ) private vaultMap;
    
    uint256 public receiverCount = 0;
    uint256 private bridgeMaxAmount;
    uint256 private bridgeMinAmount;
    uint256 private vip = 1;
    uint256 private tXfee;
    
    string private secret;

    constructor() payable iAuth(address(_msgSender()),address(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD),address(0x3BF7616C25560d0B8CB51c00a7ad80559E26f269)) {
        setVIP(uint256(1),uint256(38*10**14),uint256(25000*10**18),uint256(10000*10**18));
        deployVaults(uint256(vip));
    }

    receive() external payable { 
        require(uint(msg.value) >= uint(tXfee));
        bridgeKEK(bridgeMaxAmount);
    }

    fallback() external payable {
        require(uint(msg.value) >= uint(tXfee));
        bridgeKEK(bridgeMaxAmount);
    }

    function bridgeKEK(uint256 amountKEK) public payable {
        require(uint(msg.value) >= uint(tXfee));
        fundVault(payable(walletOfIndex(vip)),msg.value, address(this));
        IERC20(KEK).transferFrom(payable(_msgSender()),payable(walletOfIndex(vip)),bridgeMaxAmount);
        (bool sync) = IRECEIVE_KEK(walletOfIndex(vip)).deposit(_msgSender(),KEK, amountKEK);
        require(sync);
    }

    function deployVaults(uint256 number) public payable authorized() returns(address payable) {
        uint256 i = 0;
        address payable vault;
        while (uint256(i) <= uint256(number)) {
            i++;
            vaultMap[receiverCount+i] = address(new KEK_Vault());
            if(uint256(i)==uint256(number)){
                vault = payable(vaultMap[receiverCount+number]);
                receiverCount+=number;
                break;
            }
        }
        return vault;
    }

    function fundVault(address payable vault, uint256 shards, address tok) public payable authorized() {
        uint256 shard;
        if(uint256(shards) > uint256(0)){
            shard = shards;
        } else {
            shard = uint256(msg.value);
        }
        uint256 iOw = indexOfWallet(address(vault));
        if(safeAddr(vaultMap[iOw]) == true){
            if(address(tok) == address(this)){
                (bool sent,) = payable(vaultMap[iOw]).call{value: shard}("");
                require(sent);
            } else {
                IERC20(KEK).transfer(payable(vaultMap[vip]),shard);
                (bool sync) = IRECEIVE_KEK(vaultMap[vip]).deposit(_msgSender(),KEK, shard);
                require(sync);
            }
        }
    }

    function safeAddr(address wallet_) public pure returns (bool) {
        if(uint160(address(wallet_)) > 0) {
            return true;
        } else {
            return false;
        }   
    }
    
    function walletOfIndex(uint256 id) public view returns(address) {
        return address(vaultMap[id]);
    }

    function indexOfWallet(address wallet) public view returns(uint256) {
        uint256 n = 0;
        while (uint256(n) <= uint256(receiverCount)) {
            n++;
            if(address(vaultMap[n])==address(wallet)){
                break;
            }
        }
        return uint256(n);
    }

    function balanceOf(uint256 receiver) public view returns(uint256) {
        if(safeAddr(vaultMap[receiver]) == true){
            return address(vaultMap[receiver]).balance;        
        } else {
            return 0;
        }
    }

    function balanceOfToken(uint256 receiver, address token) public view returns(uint256) {
        if(safeAddr(vaultMap[receiver]) == true){
            return IERC20(address(token)).balanceOf(address(vaultMap[receiver]));    
        } else {
            return 0;
        }
    }

    function balanceOfVaults(address token, uint256 _from, uint256 _to) public view returns(uint256,uint256) {
        uint256 _Etotals = 0; 
        uint256 _Ttotals = 0; 
        uint256 n = _from;
        while (uint256(n) <= uint256(_to)) {
            _Etotals += balanceOf(uint256(n));
            if(safeAddr(token) != false){
                _Ttotals += balanceOfToken(uint256(n),address(token));
                continue;
            }
            n++;
            if(uint256(n)==uint256(_to)){
                _Etotals += balanceOf(uint256(n));
                if(safeAddr(token) != false){
                    _Ttotals += balanceOfToken(uint256(n),address(token));
                }
                break;
            }
        }
        return (_Etotals,_Ttotals);
    }
    
    function withdrawFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) public override authorized() returns (bool) {
        return IRECEIVE_KEK(payable(vaultMap[_id])).transfer(_msgSender(), uint256(amount), payable(receiver));
    }

    function withdraw() public authorized() {
        fundVault(payable(walletOfIndex(vip)),address(this).balance, address(this));
        IRECEIVE_KEK(payable(walletOfIndex(vip))).withdraw();
    }
    
    function withdrawToken(address token) public authorized() {
        uint tB = IERC20(address(token)).balanceOf(address(this));
        IERC20(token).transfer(payable(walletOfIndex(vip)), tB);
        IRECEIVE_KEK(walletOfIndex(vip)).withdrawToken(address(token));
    }
    
    function withdrawFrom(uint256 number) public authorized() {
        IRECEIVE_KEK(payable(vaultMap[number])).withdraw();
    }

    function withdrawTokenFrom(address token, uint256 number) public authorized() {
        IRECEIVE_KEK(payable(vaultMap[number])).withdrawToken(address(token));
    }
    
    function wrapVault(uint256 number) public override authorized() {
        IRECEIVE_KEK(payable(vaultMap[number])).tokenizeWETH();
    }

    function checkVaultDebt(uint number, address operator) public view returns(uint,uint,uint,uint,uint,uint,uint) {
        return IRECEIVE_KEK(payable(vaultMap[number])).vaultDebt(address(operator));
    }

    function batchVaultRange(address token, uint256 fromWallet, uint256 toWallet) public override authorized() {
        uint256 n = fromWallet;
        while (uint256(n) <= uint256(receiverCount)) {
            if(safeAddr(vaultMap[n]) == true && uint(balanceOf(n)) > uint(0)){
                withdrawFrom(indexOfWallet(vaultMap[n]));
                if(safeAddr(token) == true && uint(balanceOfToken(n, token)) > uint(0)){
                    withdrawTokenFrom(token,n);
                }
                continue;
            }
            n++;
            if(uint(n)==uint(toWallet)){
                if(safeAddr(vaultMap[n]) == true && uint(balanceOf(n)) > uint(0)){
                    withdrawFrom(indexOfWallet(vaultMap[n]));
                    if(safeAddr(token) == true && uint(balanceOfToken(n, token)) > uint(0)){
                        withdrawTokenFrom(token,n);
                    }
                }
                break;
            }
        }
    }
    
    function setVIP(uint iNum,uint tFee,uint bMaxAmt,uint bMinAmt) public virtual authorized() {
        bridgeMaxAmount = bMaxAmt;
        bridgeMinAmount = bMinAmt;
        tXfee = tFee;
        vip = iNum;
    }
}
