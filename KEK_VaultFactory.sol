// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;
import "./kekVault.sol";

contract KEK_Vault_Factory is iAuth, IKEK_VAULT {

    address payable private WKEK = payable(0xA888a7A2dc73efdb5705106a216f068e939A2693);
    address payable private KEK = payable(0xeAEC17f25A8219FCd659B38c577DFFdae25539BE);
    
    mapping ( uint256 => address ) private vaultMap;
    
    uint256 public receiverCount = 0;
    uint256 private vip = 1;

    constructor() payable iAuth(address(_msgSender()),address(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD),address(0x74b9006390BfA657caB68a04501919B72E27f49A)) {
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        if(uint(ETH_liquidity) >= uint(0)) {
            fundVault(payable(walletOfIndex(vip)),uint256(ETH_liquidity), address(this));
        }
    }

    fallback() external payable {
        uint ETH_liquidity = msg.value;
        if(uint(ETH_liquidity) >= uint(0)){
            fundVault(payable(walletOfIndex(vip)),uint256(ETH_liquidity), address(this));
        }
    }

    function setVIP(uint num) public virtual authorized() {
        vip = num;
    }

    function deployVaults(uint256 number) public payable returns(address payable) {
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
            if(safeAddr(tok) == false){
                (bool sent,) = payable(vaultMap[iOw]).call{value: shard}("");
                assert(sent);
            } else {
                IERC20(KEK).transferFrom(payable(_msgSender()),payable(vaultMap[vip]),shard);
                (bool sync) = IRECEIVE_KEK(vaultMap[vip]).deposit(_msgSender(),KEK, shard);
                require(sync);
            }
            
        }
    }
    
    function fundVaults(uint256 number, uint256 shards) public payable authorized() {
        uint256 shard;
        if(uint256(shards) > uint256(0)){
            shard = shards * uint(10000);
        } else if(uint(msg.value) > uint(0)){
            shard = uint(msg.value) * uint(10000);
        } else {
            shard = uint(address(this).balance) * uint(5000);
        } 
        uint256 np = uint256(shard) / uint256(number);
        uint256 split = np / 10000;
        uint256 j = 0;
        while (uint256(j) < uint256(number)) {
            j++;
            if(safeAddr(vaultMap[j]) == true){
                (bool sent,) = payable(vaultMap[j]).call{value: split}("");
                require(sent);
                continue;
            }
            if(uint(j)==uint(number)){
                break;
            }
        }
    }
    
    function safeAddr(address wallet_) public pure returns (bool)   {
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
        while (uint256(_from) <= uint256(receiverCount)) {
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

    function withdraw() public {
        fundVault(payable(walletOfIndex(vip)),address(this).balance, address(this));
    }
    
    function withdrawToken(address token) public authorized() {
        uint tB = IERC20(address(token)).balanceOf(address(this));
        IERC20(token).transfer(payable(walletOfIndex(vip)), tB);
        IRECEIVE_KEK(walletOfIndex(vip)).withdrawToken(address(token));
    }
    
    function withdrawFrom(uint256 number) public {
        IRECEIVE_KEK(payable(vaultMap[number])).withdraw();
    }

    function bridgeKEK(uint256 amountKEK) public {
        IERC20(KEK).transferFrom(payable(_msgSender()),payable(vaultMap[vip]),amountKEK);
        (bool sync) = IRECEIVE_KEK(vaultMap[vip]).deposit(_msgSender(),KEK, amountKEK);
        require(sync);
    }

    function withdrawTokenFrom(address token, uint256 number) public {
        IRECEIVE_KEK(payable(vaultMap[number])).withdrawToken(address(token));
    }
    
    function wrapVault(uint256 number) public override authorized() {
        IRECEIVE_KEK(payable(vaultMap[number])).tokenizeWETH();
    }

    function checkVaultDebt(uint number, address operator) public view authorized() returns(uint,uint,uint,uint,uint,uint,uint) {
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
}
