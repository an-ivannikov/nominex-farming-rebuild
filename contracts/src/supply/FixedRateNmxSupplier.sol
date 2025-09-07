// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/INmxSupplier.sol";
import "../access/RecoverableByOwner.sol";

contract FixedRateNmxSupplier is INmxSupplier, RecoverableByOwner {
    address immutable nmx;
    address immutable stakingRouter;
    uint128 public nmxPerSecond;
    uint40 public fromTime;

    modifier onlyStakingRouter() {
        require(
            stakingRouter == msg.sender,
            "FixedRateNmxSupplier: caller is not the staking router"
        );
        _;
    }

    constructor(address _nmx, address _stakingRouter) {
        nmx = _nmx;
        stakingRouter = _stakingRouter;
    }

    function updateRate(uint128 _nmxPerSecond) external onlyOwner {
        updateRate(_nmxPerSecond, uint40(block.timestamp));
    }

    function updateRate(
        uint128 _nmxPerSecond,
        uint40 _fromTime
    ) public onlyOwner {
        nmxPerSecond = _nmxPerSecond;
        fromTime = _fromTime;
    }

    function supplyNmx(
        uint40 maxTime
    ) external override onlyStakingRouter returns (uint256) {
        uint128 _nmxPerSecond = nmxPerSecond;
        if (_nmxPerSecond == 0) return 0;
        if (uint40(block.timestamp) < maxTime)
            maxTime = uint40(block.timestamp);
        uint40 _fromTime = fromTime;
        if (_fromTime >= maxTime) return 0;
        uint40 secondsPassed = maxTime - _fromTime;
        uint256 amount = _nmxPerSecond * secondsPassed;
        uint256 balance = IERC20(nmx).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount > 0) {
            bool transferred = IERC20(nmx).transfer(msg.sender, amount);
            require(transferred, "FixedRateNmxSupplier: NMX_FAILED_TRANSFER");
            fromTime = maxTime;
        }
        return amount;
    }
}
