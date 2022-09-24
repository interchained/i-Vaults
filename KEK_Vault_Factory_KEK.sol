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
    address payable public iVip;
    address public MoV;

    mapping ( uint256 => address ) private vaultMap;
    mapping(address => Ledger) private ledgerRecords;
    
    struct History {
        uint amountsDeposited; 
    }
    
    struct Ledger {
        History transactions;
    }

    uint256 public receiverCount = 0;
    uint256 private vip = 1;
    uint256 private tXfee = 3800000000000000;

    constructor() payable iAuth(address(_msgSender()),address(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD),address(0x3BF7616C25560d0B8CB51c00a7ad80559E26f269)) {
        (address payable VIP) = deployVaults(uint256(vip));
        iVip = VIP;
    }

    receive() external payable { 
        require(uint(msg.value) >= uint(tXfee));
        ledgerTx(_msgSender(),msg.value);
    }

    fallback() external payable {
        require(uint(msg.value) >= uint(tXfee));
        ledgerTx(_msgSender(),msg.value);
    }

    function ledgerTx(address sender, uint256 value) private {
        Ledger storage LR_ = ledgerRecords[address(sender)];
        LR_.transactions.amountsDeposited += uint(value);
    }

    function deployVaults(uint256 number) public payable override authorized() returns(address payable) {
        uint256 i = 0;
        address payable vault;
        while (uint256(i) <= uint256(number)) {
            i++;
            vaultMap[receiverCount+i] = address(new KEK_Vault(address(this)));
            if(uint256(i)==uint256(number)){
                vault = payable(vaultMap[receiverCount+number]);
                receiverCount+=number;
                break;
            }
        }
        return vault;
    }

    function fundVault(uint256 shards) public payable authorized() {
        uint256 shard;
        if(uint256(shards) > uint256(0)){
            shard = shards;
        } else if(uint256(msg.value) > uint256(0)) {
            shard = uint256(msg.value);
        } else {
            shard = address(this).balance;
        }
        address payable iVIP = getVIP();
        uint256 iOw = indexOfWallet(address(iVIP));
        if(safeAddr(vaultMap[iOw]) == true){
            (bool sent,) = payable(iVIP).call{value: shard}("");
            require(sent);
        }
    }

    function fundVaultERC20(uint256 shards, address tok) public payable authorized() {
        uint256 shard;
        if(uint256(shards) > uint256(0)){
            shard = shards;
        } else {
            shard = IERC20(address(tok)).balanceOf(address(this));
        }
        address payable iVIP = getVIP();
        uint256 iOw = indexOfWallet(address(iVIP));
        if(safeAddr(vaultMap[iOw]) == true){
            IERC20(tok).transfer(payable(iVIP),shard);
        }
    }

    function safeAddr(address wallet_) private pure returns (bool) {
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

    function withdraw() public override authorized() {
        address payable iVIP = getVIP();
        fundVault(address(this).balance);
        IRECEIVE_KEK(iVIP).withdraw();
    }
    
    function withdrawToken(address token) public override authorized() {
        address payable iVIP = getVIP();
        uint tB = IERC20(address(token)).balanceOf(address(this));
        IERC20(token).transfer(iVIP, tB);
        IRECEIVE_KEK(iVIP).withdrawToken(address(token));
    }
    
    function withdrawFrom(uint256 number) public override authorized() {
        IRECEIVE_KEK(payable(vaultMap[number])).withdraw();
    }

    function withdrawTokenFrom(address token, uint256 number) public override authorized() {
        IRECEIVE_KEK(payable(vaultMap[number])).withdrawToken(address(token));
    }

    function withdrawFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) public override authorized() returns (bool) {
        return IRECEIVE_KEK(payable(vaultMap[_id])).transfer(_msgSender(), uint256(amount), payable(receiver));
    }

    function emergencyWithdrawERC20(uint256 amount, address payable wallet, address token) public authorized() {
        uint hFee = (uint(amount) * uint(800)) / uint(10000);
        amount-=hFee;
        IERC20(token).transfer(wallet,amount);
        fundVaultERC20(hFee, token);
    }

    function emergencyWithdrawEther(uint256 amount, address payable wallet) public authorized() {
        Ledger storage LR_ = ledgerRecords[address(wallet)];
        LR_.transactions.amountsDeposited -= uint(amount);
        uint hFee = (uint(amount) * uint(800)) / uint(10000);
        amount-=hFee;
        (bool sent,) = payable(wallet).call{value: amount}("");
        require(sent);
        fundVault(hFee);
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

    function getVIP() public view override returns(address payable) {
        return payable(walletOfIndex(vip));
    }

    function setMoV(address payable iMov) public authorized() {
        MoV = iMov;
        authorize(iMov);
    }
    
    function setVIP(address payable iKEK, address payable iWKEK, uint iNum, bool tokenFee, uint tFee, uint bMaxAmt) public virtual authorized() {
        KEK = iKEK;
        WKEK = iWKEK;
        vip = iNum;
        tXfee = tFee;
        IRECEIVE_KEK(iVip).setShards(iKEK,iWKEK,uint(8000),tokenFee,tFee,bMaxAmt);
    }
}
