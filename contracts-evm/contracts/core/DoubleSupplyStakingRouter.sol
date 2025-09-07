// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../supply/FixedRateNmxSupplier.sol";
import "./StakingRouter.sol";

contract DoubleSupplyStakingRouter is StakingRouter {
    address public immutable additionalSupplier;

    constructor(
        address initialOwner,
        address _nmx
    ) StakingRouter(initialOwner, _nmx) {
        FixedRateNmxSupplier fixedRateNmxSupplier = new FixedRateNmxSupplier(
            _nmx,
            address(this)
        );
        fixedRateNmxSupplier.transferOwnership(msg.sender);
        additionalSupplier = address(fixedRateNmxSupplier);
    }

    function receiveSupply(uint40 maxTime) internal override returns (uint256) {
        return
            StakingRouter.receiveSupply(maxTime) +
            INmxSupplier(additionalSupplier).supplyNmx(maxTime);
    }
}
