// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SolarGreenToken.sol";

contract TokenBlockedForTime {
    struct Timelock {
        address beneficiary;
        uint256 releaseTime;
        uint256 amount;
    }
    address owner;
    uint256 private constant releaseTime_ = 1710712801;
    SolarGreenToken private sgrInstance;

    IERC20 private token;
    mapping(address => Timelock[]) private beneficiaryTimelocks;
    event TokensUnlocked(address indexed recipient, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
        sgrInstance = SolarGreenToken(address(this));
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Creates a new timelock for the specified beneficiary with the given release time and amount.
    function createTimelock(
        address beneficiary,
        uint256 amount
    ) public onlyOwner {
        require(
            releaseTime_ > block.timestamp,
            "Release time must be in the future"
        );
        require(amount > 0, "Amount must be greater than 0");
        beneficiaryTimelocks[beneficiary].push(
            Timelock(beneficiary, releaseTime_, amount)
        );
        token.transferFrom(msg.sender, address(this), amount);
    }

    // Returns the list of timelocks for the specified beneficiary.
    function getTimelocks(
        address beneficiary
    ) public view returns (Timelock[] memory) {
        return beneficiaryTimelocks[beneficiary];
    }

    // Transfers tokens held by the timelock to the beneficiaries whose release time has passed.
    function release(address user) external {
        require(
            sgrInstance.isUserInBlacklist(user),
            "User is in the blacklist"
        );
        require(user != address(0), "Invalid user address");
        require(
            beneficiaryTimelocks[user].length > 0,
            "No timelocks found for the user"
        );

        Timelock[] storage timelocks = beneficiaryTimelocks[user];
        uint256 totalReleased;
        for (uint256 i = 0; i < timelocks.length; i++) {
            Timelock storage timelock = timelocks[i];
            if (block.timestamp >= timelock.releaseTime) {
                token.transfer(timelock.beneficiary, timelock.amount);
                totalReleased += timelock.amount;
                delete timelocks[i];
                emit TokensUnlocked(user, timelock.amount);
            }
        }
        require(totalReleased > 0, "No tokens to release");
    }
}
