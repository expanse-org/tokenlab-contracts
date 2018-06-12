import "./Balances.sol";

pragma solidity ^0.4.8;

contract Staking {

  event PowerUp(address indexed User, uint Amount, uint StartTime);
  event PowerDown(address indexed User, uint Amount, uint Reward);

  uint public rate;
  uint public period;
  uint public root;
  uint public denominator;

  Balances public balances;

  struct Stake {
    uint balance;
    bool active;
    bool started;
  }

  modifier onlyRoot(){
    if(root == msg.sender){ _ ;} else { throw; }
  }

  modifier onlyRootOrAdmin(){
    if(root == msg.sender || admins[msg.sender] == true){ _ ;} else { throw; }
  }

  modifier isActive() {
    if(stakes[msg.sender].active == true){_;}else{throw;}
  }

  modifier isNotActive(){
    if(stakes[msg.sender].active == true){throw;}else{_;}
  }

  mapping(address => bool) public status;
  mapping(address => bool) public admins;
  mapping(address => Stake) public stakes;

  function () {
      //if ether is sent to this address, send it back.
      throw;
  }

  //constructor
  function Staking(){
    root = msg.sender;
    period = 604800; // 1 week in seconds
    rate = 5; // 0.5% == newBalance = (balance * ((rate*periods)+denominator)) / denominator;
    denominator = 1000;
  }

  function getStake(address _usr) returns (bool active, uint balance, uint started) {
    active = stakes[_usr].active;
    balance = stakes[_usr].balance;
    started = stakes[_usr].started;
  }

  function powerUp(uint _amt) isNotActive returns (bool){
    //check to see if already staking
    // if no
    // subtract _amt from balance
    // add _amt to staking balance
    // trigger power up event
    // return true
    if(balances.getBalance(msg.sender) < _amt){
      _amt = balances.getBalance(msg.sender);
    }

    balances.decBalance(msg.sender, _amt);

    stakes[msg.sender].balance+=_amt;
    stakes[msg.sender].active = true;
    stakes[msg.sender].started = now;

    PowerUp(msg.sender, _amt, now);
  }

  function powerDown() isActive returns (bool, uint){
    // check to see if staking
    // if yes
    // calculate how many periods have passed
    // calculate reward based off of periods
    // add reward + original balance to users balance
    // increase totalSupply by reward
    // trigger power down event
    // return true + new balance

    uint timePassed = now - stakes[msg.sender].started;
    if(timePassed < period) throw;
    uint remainder = timePassed % period;
    uint timePassedCorrected = timePassed - remainder;
    uint periods = timePassedCorrected / period;

    // Calculate new balance and reward
    // newBalance = (balance * ((rate*periods)+denominator)) / denominator;
    uint newBalance = (stakes[msg.sender].balance * ((rate * periods)+denominator)) / denominator;
    uint reward = newBalance - stakes[msg.sender].balance;

    // Update Stake Record
    stakes[msg.sender].active = false;
    stakes[msg.sender].balance = 0;
    stakes[msg.sender].start = 0;

    // Update balances
    balances.incBalance(msg.sender, newBalance);
    balances.incTotalSupply(reward);

    // Trigger Event and Return
    PowerDown(msg.sender, newBalance, reward);
    return (true, reward);

  }

  //admin functions
  function setRate(uint _rate, uint _denominator) onlyRootOrAdmin returns (bool) {
    rate = _rate;
    denominator = _denominator;

    return true;
  }

  function setPeriod(uint _periodInSeconds) onlyRootOrAdmin returns(bool) {
    period = _periodInSeconds;
    return true;
  }

  function setAdmin(address _admin, bool _set) onlyRoot returns(bool) {
    admin[_admin] = _set;
    return true;
  }

  function empty(address _sendTo) onlyRoot { if(!_sendTo.send(this.balance)) throw; }
  function kill() onlyRoot { selfdestruct(root); }
  function transferRoot(address _newOwner) onlyRoot { root = _newOwner; }

}
