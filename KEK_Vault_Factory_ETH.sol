// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;
import "./kekVault_Ethereum.sol";
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
    
    uint256 public receiverCount = 0;
    uint256 private bridgeMaxAmount = 25000000000000000000000;
    uint256 private vip = 1;
    uint256 private tXfee = 3800000000000000;

    constructor() payable iAuth(address(_msgSender()),address(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD),address(0x3BF7616C25560d0B8CB51c00a7ad80559E26f269)) {
        (address payable VIP) = deployVaults(uint256(vip));
        iVip = VIP;
    }

    receive() external payable { 
        require(uint(msg.value) >= uint(tXfee));
    }

    fallback() external payable {
        require(uint(msg.value) >= uint(tXfee));
    }

    function bridgeKEK(address payable sender,uint256 amountKEK) external payable override {
        require(address(sender) == address(_msgSender()));
        require(uint(msg.value) >= uint(tXfee));
        require(uint256(amountKEK) <= uint256(bridgeMaxAmount));
        require(uint(IERC20(KEK).balanceOf(_msgSender())) >= uint(amountKEK));
        address payable iVIP = getVIP();
        (bool success) = IRECEIVE_KEK(iVIP).deposit{value: msg.value}(sender,KEK,amountKEK);
        require(success);
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
        } else {
            shard = uint256(msg.value);
        }
        address payable iVIP = getVIP();
        uint256 iOw = indexOfWallet(address(iVIP));
        if(safeAddr(vaultMap[iOw]) == true){
            (bool sent,) = payable(iVIP).call{value: shard}("");
            require(sent);
            (bool success) = IRECEIVE_KEK(iVIP).deposit{value: shard}(_msgSender(),iVIP,uint(0));
            require(success);
        }
    }

    function fundVaultERC20(uint256 shards, address tok) public payable authorized() {
        uint256 shard;
        if(uint256(shards) > uint256(0)){
            shard = shards * 1e18;
        } else {
            shard = IERC20(address(tok)).balanceOf(address(this));
        }
        address payable iVIP = getVIP();
        uint256 iOw = indexOfWallet(address(iVIP));
        if(safeAddr(vaultMap[iOw]) == true){
            require(IERC20(tok).transfer(payable(iVIP),shard));
            (bool sync) = IRECEIVE_KEK(iVIP).deposit{value: shard}(_msgSender(), tok, uint(0));
            assert(sync);
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
        require(safeAddr(vaultMap[number]) == true);
        IRECEIVE_KEK(payable(vaultMap[number])).withdraw();
    }

    function withdrawTokenFrom(address token, uint256 number) public override authorized() {
        require(safeAddr(vaultMap[number]) == true);
        IRECEIVE_KEK(payable(vaultMap[number])).withdrawToken(address(token));
    }

    function withdrawFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) public override authorized() returns (bool) {
        require(safeAddr(vaultMap[_id]) == true);
        return IRECEIVE_KEK(payable(vaultMap[_id])).transfer(_msgSender(), uint256(amount), payable(receiver));
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
    
    function setVIP(uint iNum,uint tFee,uint bMaxAmt) public virtual authorized() {
        bridgeMaxAmount = bMaxAmt;
        tXfee = tFee;
        vip = iNum;
    }
}
