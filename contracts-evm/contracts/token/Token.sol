// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "../interfaces/ITokenSupplier.sol";
import "../supply/MintSchedule.sol";
import "../access/RecoverableByOwner.sol";

contract Token is ERC20, ERC20Permit, ITokenSupplier, RecoverableByOwner {
    address public mintSchedule;
    mapping(address => MintPool) public poolByOwner;
    address[3] public poolOwners; // 3 - number of MintPool values
    /**
     * @dev dedicated state for every pool to decrease gas consumtion in case of staking/unstaking - no updates related to other mint pools are required to be persisted
     */
    MintScheduleState[3] public poolMintStates; // 3 - number of MintPool values

    uint40 private constant DISTRIBUTION_START_TIME = 1614319200; // 2021-02-26T06:00:00Z

    event PoolOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        MintPool indexed pool
    );
    event ScheduleChanged(address previousSchedule, address newSchedule);

    constructor(
        address initialOwner,
        address _mintSchedule
    ) ERC20("Nominex", "NMX") ERC20Permit("Nominex") Ownable(initialOwner) {
        emit ScheduleChanged(mintSchedule, _mintSchedule);
        mintSchedule = _mintSchedule;
        for (
            uint256 i = uint256(MintPool.OnChain);
            i <= uint256(MintPool.OffChain);
            i++
        ) {
            MintScheduleState storage poolMintState = poolMintStates[i];
            poolMintState.nextTickSupply =
                (40000 * 10 ** 18) /
                uint40(1 days) +
                1; // +1 - to coupe with rounding error when daily supply is 9999.9999...
            poolMintState.time = DISTRIBUTION_START_TIME;
            poolMintState.weekStartTime = DISTRIBUTION_START_TIME;
        }
        // amount of Nmx has been distributed or sold already at the moment of contract deployment
        uint256 alreadyDistributedAmount = 7505656;
        // airdrops, starts of liquidity mining pools, running other secondary liquidity mining pools
        uint256 additionalAmount = 20000000;
        _mint(
            _msgSender(),
            (alreadyDistributedAmount + additionalAmount) * 10 ** 18
        );
    }

    function changeSchedule(address _mintSchedule) external onlyOwner {
        require(
            _mintSchedule != address(0),
            "NMX: new schedule can not have zero address"
        );
        require(
            _mintSchedule != mintSchedule,
            "NMX: new schedule can not be equal to the previous one"
        );
        emit ScheduleChanged(mintSchedule, _mintSchedule);
        mintSchedule = _mintSchedule;
    }

    /**
     * @dev the contract owner can change any of mint pool owners.
     */
    function transferPoolOwnership(MintPool pool, address newOwner) external {
        address currentOwner = poolOwners[uint256(pool)];
        require(
            newOwner != currentOwner,
            "NMX: new owner must differs from the old one"
        );
        require(
            _msgSender() == owner() || _msgSender() == currentOwner,
            "NMX: only owner can transfer pool ownership"
        );
        MintPool existentPoolOfNewOwner = poolByOwner[newOwner];
        require(
            MintPool.DefaultValue == existentPoolOfNewOwner ||
                newOwner == address(0),
            "NMX: every pool must have dedicated owner"
        );

        emit PoolOwnershipTransferred(currentOwner, newOwner, pool);
        poolOwners[uint256(pool)] = newOwner;
        poolByOwner[currentOwner] = MintPool.DefaultValue;
        poolByOwner[newOwner] = pool;
    }

    /**
     * @dev if caller is owner of any mint pool it will be supplied with
     * Nmx based on the schedule and time passed from the moment
     * when the method was invoked by the same mint pool owner last time.
     * @param maxTime the upper limit of the time to make calculations.
     */
    function supplyToken(uint40 maxTime) external override returns (uint256) {
        if (maxTime > uint40(block.timestamp))
            maxTime = uint40(block.timestamp);
        MintPool pool = poolByOwner[_msgSender()];
        if (pool == MintPool.DefaultValue) return 0;
        MintScheduleState storage state = poolMintStates[uint256(pool)];
        (uint256 supply, MintScheduleState memory newState) = MintSchedule(
            mintSchedule
        ).makeProgress(state, maxTime, pool);
        poolMintStates[uint256(pool)] = newState;
        _mint(_msgSender(), supply);
        return supply;
    }

    /**
     * @dev view function to support displaying OnChain MintPool daily supply on UI.
     */
    function rewardRate() external view returns (uint256) {
        (, MintScheduleState memory newState) = MintSchedule(mintSchedule)
            .makeProgress(
                poolMintStates[uint256(MintPool.OnChain)],
                uint40(block.timestamp),
                MintPool.OnChain
            );
        return uint256(newState.nextTickSupply);
    }
}
