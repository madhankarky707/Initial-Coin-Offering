//SPDX-License-Identifier:NOLICENSE

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

pragma solidity 0.8.28;

contract Sale is Context, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    error ZeroTokenAcquired();

    address public immutable token;
    uint256 public immutable ethPerToken;
    uint64 public immutable claimDuration;
    Info public info;
    
    struct TokenPurchase {
        uint256 ethSpent;
        uint256 tokenAcquired;
        uint64 claimAt;
    }

    struct UserDetails {
        uint256 nextPurchaseIndex;
        uint256 totalTokensAcquired;
        uint256 totalEtherSpent;
        TokenPurchase[] tokenPurchases;
    }

    struct Info {
        uint256 totalTokensAcquired;
        uint256 totalEtherSpent;
    }

    mapping(address => UserDetails) private _userDetails;

    event Buy(address indexed user, uint256 ethAmount, uint256 tknAmount);
    event Claim(
        address indexed user, 
        uint256 indexed fromIndex, 
        uint256 indexed toIndex, 
        uint256 tknAmount
    );

    modifier onlyEoa() {
        require(_msgSender().code.length == 0, "OnlyEOA");
        _;
    }

    constructor(address token_, address owner_, uint256 ethPerToken_, uint64 duration_) Ownable(owner_) {
        require(token_.code.length != 0, "InvalidTokenAddress");
        require(ethPerToken_ != 0, "ZeroTokenAmount");
        require(duration_ != 0, "ZeroDuration");

        token = token_;
        ethPerToken = ethPerToken_;
        claimDuration = duration_;
    }

    receive() external payable {
        buy();
    }

    function buy() public payable onlyEoa nonReentrant {
        address _user = _msgSender();
        uint256 _ethAmount = msg.value;
        require(_ethAmount != 0, "ZeroEtherAmount");

        uint256 _tokennAcquired = computeToken(_ethAmount); // Compute token amount based on provided Ether
        assert(_tokennAcquired != 0); // Reverts if the computed token amount is zero

        require(payable(owner()).send(_ethAmount), "EtherTransferFailed"); // Transfers the received Ether to the contract owner
        UserDetails storage _userData = _userDetails[_user];

        TokenPurchase memory tokenPurchase = TokenPurchase({ 
            ethSpent : _ethAmount,
            tokenAcquired : _tokennAcquired,
            claimAt : uint64(block.timestamp + claimDuration)
        });
        _userData.tokenPurchases.push(tokenPurchase); // Records the purchase details in the user's purchase history
        _userData.totalEtherSpent += _ethAmount;
        _userData.totalTokensAcquired += _tokennAcquired;
        // Records the total Ether spent and total tokens acquired
        info.totalEtherSpent += _ethAmount;
        info.totalTokensAcquired += _tokennAcquired;
        emit Buy(_user, _ethAmount, _tokennAcquired);
    }

    function claim() public nonReentrant {
        address _user = _msgSender();
        UserDetails storage _userData = _userDetails[_user];
        TokenPurchase[] storage _userPurchases = _userData.tokenPurchases;

        uint256 _nextPurchaseIndex = _userData.nextPurchaseIndex;
        uint256 totPurchases = _userPurchases.length;
        require(_nextPurchaseIndex < totPurchases, "AlreadyClaimedAll"); // Reverts if the user has already claimed all purchased tokens

        uint256 totalTokenAcquired = 0;
        for (uint256 curPurchaseIndex = _nextPurchaseIndex; curPurchaseIndex < totPurchases; curPurchaseIndex++) { // Iterates through the user's purchases to claim any expired ones
            TokenPurchase memory _userPurchase = _userPurchases[curPurchaseIndex];
            if (_userPurchase.claimAt > block.timestamp) { // Breaks if a purchase record has not yet expired
                break;
            }
            _userData.nextPurchaseIndex++;
            totalTokenAcquired += _userPurchase.tokenAcquired;
        }
        if (totalTokenAcquired == 0) {
            revert ZeroTokenAcquired();
        }
        IERC20(token).safeTransfer(_user, totalTokenAcquired); // Transfers all expired token purchases to the user
        emit Claim(
            _user,
            _nextPurchaseIndex,
            _userData.nextPurchaseIndex,
             totalTokenAcquired
        );
    }

    function computeToken(uint256 ethAmount_) public view returns (uint256 tknAmount) {
        if (ethAmount_ == 0) {
            return 0;
        }
        uint256 tknUnits = 10 ** IERC20Metadata(token).decimals();
        tknAmount = ethAmount_ * tknUnits / ethPerToken;
    }

    function getUserDetails(address user) public view returns (uint256 nextPurchaseIndex, uint256 totalTokensAcquired, uint256 totalEtherSpent) {
        UserDetails memory _userData = _userDetails[user];
        return (
            _userData.nextPurchaseIndex,
            _userData.totalTokensAcquired,
            _userData.totalEtherSpent
        );
    }

    function getUserPurchasesAt(address user, uint256 purchaseIndex) public view returns (TokenPurchase memory) {
        TokenPurchase memory _tokenPurchase = _userDetails[user].tokenPurchases[purchaseIndex];
        return _tokenPurchase;
    }

    function getUserAllPurchases(address user) public view returns (TokenPurchase[] memory) {
        TokenPurchase[] memory _userPurchases = _userDetails[user].tokenPurchases;
        return _userPurchases;
    }
}