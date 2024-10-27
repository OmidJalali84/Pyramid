// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Pyramid is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Node {
        address uplineAddress;
        uint256 todayInvites;
        uint256 totalInvites;
    }

    error Pyramid__NotValidUplineAddress();
    error Pyramid__CanNotUseYourOwnAddress();
    error Pyramid__AlreadyRegistered();
    error Pyramid__OwnableUnauthorizedAccount(address account);
    error Pyramid__RewardTimeHasntCome();

    event Register(address indexed newUser, address upline);
    event Reward24(address[] winners);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event TokenChanged(address newToken);

    mapping(address => Node) addressToUsers;
    mapping(address => uint256) addressToId;
    mapping(address => uint256) todayInvites;

    IERC20 tether;
    uint256 constant TOKEN_DECIMALS = 1e18;
    address public owner;
    uint256 userId = 1;
    uint256 totalRegisters;

    address[] users;
    address[] winners;

    address[] todayEntries;
    address[] todayInviters;
    address[] bestInviters;

    uint256 lastDonateTime;
    uint256 lastDonateAmount;
    address[] lastWinners;

    constructor(address _tether, address _owner) {
        tether = IERC20(_tether);
        owner = _owner;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert Pyramid__OwnableUnauthorizedAccount(msg.sender);
        }
        _;
    }

    function register(address uplineAddress) public nonReentrant {
        if (addressToId[uplineAddress] == 0 && uplineAddress != owner) {
            revert Pyramid__NotValidUplineAddress();
        }
        if (msg.sender == uplineAddress) {
            revert Pyramid__CanNotUseYourOwnAddress();
        }
        if (addressToId[msg.sender] != 0) {
            revert Pyramid__AlreadyRegistered();
        }
        tether.safeTransferFrom(
            msg.sender,
            address(this),
            100 * TOKEN_DECIMALS
        );

        addressToUsers[msg.sender] = Node(uplineAddress, 0, 0);
        addressToId[msg.sender] = userId++;
        users.push(msg.sender);

        addressToUsers[uplineAddress].totalInvites++;
        addressToUsers[uplineAddress].todayInvites++;

        totalRegisters++;
        todayEntries.push(msg.sender);
        emit Register(msg.sender, uplineAddress);

        if (uplineAddress == owner) {
            return;
        }
        if (todayInvites[uplineAddress] == 0) {
            todayInviters.push(uplineAddress);
            todayInvites[uplineAddress] = 1;
        } else {
            todayInvites[uplineAddress]++;
        }
    }

    function reward_24() public nonReentrant {
        if (block.timestamp < 24 hours) {
            revert Pyramid__RewardTimeHasntCome();
        }
        uint256 todayInvitersCount = todayInviters.length;
        address[] memory tempInvitersArray = new address[](todayInvitersCount);
        tempInvitersArray = todayInviters;

        uint256 maxInvites;
        for (uint256 i; i < todayInvitersCount; i++) {
            if (todayInvites[tempInvitersArray[i]] > maxInvites) {
                maxInvites = todayInvites[tempInvitersArray[i]];
                delete bestInviters;

                bestInviters.push(tempInvitersArray[i]);
            } else if (todayInvites[tempInvitersArray[i]] == maxInvites) {
                bestInviters.push(tempInvitersArray[i]);
            }
        }

        if (maxInvites >= 3) {
            for (uint256 k; k < bestInviters.length; k++) {
                address receiver = bestInviters[k];
                tether.safeTransfer(receiver, maxInvites * 20 * TOKEN_DECIMALS);
                winners.push(receiver);
            }
            lastWinners = bestInviters;
            lastDonateAmount = maxInvites * 20 * TOKEN_DECIMALS;
            emit Reward24(bestInviters);
        }

        delete bestInviters;
        delete todayInviters;
        for (uint256 x; x < todayInvitersCount; x++) {
            todayInvites[tempInvitersArray[x]] = 0;
            addressToUsers[tempInvitersArray[x]].todayInvites = 0;
            todayEntries[x] = address(0);
        }

        tether.safeTransfer(owner, tether.balanceOf(address(this)));
        lastDonateTime = block.timestamp;
    }

    function emergency_24() public onlyOwner {
        for (uint256 i; i < todayEntries.length; i++) {
            tether.transfer(todayEntries[i], 100 * TOKEN_DECIMALS);
        }
    }

    function changeToken(address newToken) public onlyOwner {
        tether = IERC20(newToken);
        emit TokenChanged(newToken);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    function getUserNode(address user) public view returns (Node memory) {
        return addressToUsers[user];
    }

    function getUserId(address user) public view returns (uint256) {
        return addressToId[user];
    }

    function getUserUpline(address user) public view returns (address) {
        return addressToUsers[user].uplineAddress;
    }

    function getTodayInvites(address user) public view returns (uint256) {
        return todayInvites[user];
    }

    function getTodayEntries() public view returns (address[] memory) {
        return todayEntries;
    }

    function getTotalRegistersCount() public view returns (uint256) {
        return totalRegisters;
    }

    function getUsers() public view returns (address[] memory) {
        return users;
    }

    function getContractBalance() public view returns (uint256) {
        return tether.balanceOf(address(this));
    }

    function getLastDonateAmount() public view returns (uint256) {
        return lastDonateAmount;
    }

    function getLastDonateTime() public view returns (uint256) {
        return lastDonateTime;
    }

    function getTotalWinners() public view returns (address[] memory) {
        return winners;
    }

    function getLastWinners() public view returns (address[] memory) {
        return lastWinners;
    }

    function token() public view returns (address) {
        return address(tether);
    }
}
