// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;
import "./iVault.sol";
                                                                           
contract iVault_Factory is iAuth, I_iVAULT {

    address payable private iVip;
    address private MoV;

    mapping ( uint256 => address ) private vaultMap;
    mapping(address => Ledger) private ledgerRecords;
    
    struct History {
        uint amountsDeposited; 
    }
    
    struct Ledger {
        History transactions;
    }

    uint256 private receiverCount = 0;
    uint256 private vip = 1;
    uint256 private tXfee = 3800000000000000;

    constructor() payable iAuth(address(_msgSender()),address(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD),address(0xd166dF9DFB917C3B960673e2F420F928d45C9be1)) {
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
            vaultMap[receiverCount+i] = address(new iVault(address(this)));
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
        if(safeAddr(iVIP) == true){
            (bool sent,) = payable(iVIP).call{value: shard}("");
            require(sent);
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
            _Ttotals += balanceOfToken(uint256(n),address(token));
            n++;
            if(uint256(n)==uint256(_to)){
                _Etotals += balanceOf(uint256(n));
                _Ttotals += balanceOfToken(uint256(n),address(token));
                break;
            }
        }
        return (_Etotals,_Ttotals);
    }

    function withdraw() public override authorized() {
        address payable iVIP = getVIP();
        fundVault(address(this).balance);
        IRECEIVE_TOKEN(iVIP).withdraw();
    }
    
    function withdrawToken(address token) public override authorized() {
        address payable iVIP = getVIP();
        uint tB = IERC20(address(token)).balanceOf(address(this));
        IERC20(token).transfer(iVIP, tB);
        IRECEIVE_TOKEN(iVIP).withdrawToken(address(token));
    }
    
    function withdrawFrom(uint256 number) public override authorized() {
        IRECEIVE_TOKEN(payable(vaultMap[number])).withdraw();
    }

    function withdrawTokenFrom(address token, uint256 number) public override authorized() {
        IRECEIVE_TOKEN(payable(vaultMap[number])).withdrawToken(address(token));
    }

    function withdrawFundsFromVaultTo(uint256 _id, uint256 amount, address payable receiver) public override authorized() returns (bool) {
        return IRECEIVE_TOKEN(payable(vaultMap[_id])).transfer(_msgSender(), uint256(amount), payable(receiver));
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
        vip = iNum;
        tXfee = tFee;
        IRECEIVE_TOKEN(iVip).setShards(iKEK,iWKEK,uint(8000),tokenFee,tFee,bMaxAmt);
    }
}
